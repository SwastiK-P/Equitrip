package com.swastik.equitrip.ui.components

import android.graphics.Bitmap
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import coil3.imageLoader
import coil3.request.ImageRequest
import coil3.request.SuccessResult
import coil3.request.allowHardware
import coil3.toBitmap
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

/**
 * The colour a photograph is, in one swatch — iOS `CoverTint`. A trip card's panel is washed
 * in it, so a card for a beach reads blue and one for a desert reads sand before you look.
 * Null until the image has been sampled, and for a trip with no photo.
 */
@Composable
fun rememberCoverTint(url: String?): Color? {
    val context = LocalContext.current
    var tint by remember(url) { mutableStateOf<Color?>(null) }
    LaunchedEffect(url) {
        if (url == null) return@LaunchedEffect
        val request = ImageRequest.Builder(context).data(url).size(24).allowHardware(false).build()
        val bitmap = (context.imageLoader.execute(request) as? SuccessResult)?.image?.toBitmap() ?: return@LaunchedEffect
        tint = withContext(Dispatchers.Default) { average(bitmap) }
    }
    return tint
}

/** The mean of the pixels, pushed a little towards saturation so it doesn't read as grey. */
private fun average(bitmap: Bitmap): Color {
    var r = 0L
    var g = 0L
    var b = 0L
    val pixels = IntArray(bitmap.width * bitmap.height)
    bitmap.getPixels(pixels, 0, bitmap.width, 0, 0, bitmap.width, bitmap.height)
    pixels.forEach {
        r += (it shr 16) and 0xFF
        g += (it shr 8) and 0xFF
        b += it and 0xFF
    }
    val n = pixels.size.coerceAtLeast(1)
    val hsv = FloatArray(3)
    android.graphics.Color.RGBToHSV((r / n).toInt(), (g / n).toInt(), (b / n).toInt(), hsv)
    hsv[1] = (hsv[1] * 1.4f).coerceAtMost(0.75f)
    hsv[2] = hsv[2].coerceIn(0.45f, 0.85f)
    return Color(android.graphics.Color.HSVToColor(hsv))
}
