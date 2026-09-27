package com.swastik.equitrip.ui.components

import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import coil3.compose.AsyncImage
import com.swastik.equitrip.R
import com.swastik.equitrip.model.Traveller
import com.swastik.equitrip.ui.theme.Rounded

/**
 * The same 15 faces as iOS, chosen the same way: a stored name from the set is used as is,
 * and anything else (older memoji names, an empty default) is folded onto the set by the
 * same djb2 hash as `Traveller.artwork(for:)`, so a person has one face on every device.
 */
object Avatars {
    private val faces = intArrayOf(
        R.drawable.avatar01, R.drawable.avatar02, R.drawable.avatar03, R.drawable.avatar04, R.drawable.avatar05,
        R.drawable.avatar06, R.drawable.avatar07, R.drawable.avatar08, R.drawable.avatar09, R.drawable.avatar10,
        R.drawable.avatar11, R.drawable.avatar12, R.drawable.avatar13, R.drawable.avatar14, R.drawable.avatar15,
    )
    private val names = (1..15).map { "Avatar%02d".format(it) }

    fun artwork(asset: String): Int {
        val index = names.indexOf(asset).takeIf { it >= 0 } ?: run {
            var hash = 5381UL
            asset.codePoints().forEach { hash = hash * 33UL + it.toULong() }
            (hash % faces.size.toULong()).toInt()
        }
        return faces[index]
    }
}

/** A person's face: their photo when they've set one, otherwise their artwork. */
@Composable
fun Avatar(traveller: Traveller, size: Dp = 36.dp, modifier: Modifier = Modifier) {
    Box(modifier.size(size).clip(CircleShape), contentAlignment = Alignment.Center) {
        Image(
            painterResource(Avatars.artwork(traveller.avatarAsset)),
            contentDescription = traveller.name,
            contentScale = ContentScale.Crop,
            modifier = Modifier.size(size),
        )
        traveller.avatarUrl?.let {
            AsyncImage(it, contentDescription = traveller.name, contentScale = ContentScale.Crop, modifier = Modifier.size(size))
        }
    }
}

/** Overlapping faces with a ring cut out of each, and a "+n" when there are more. */
@Composable
fun AvatarStack(people: List<Traveller>, size: Dp = 28.dp, max: Int = 4, ring: Color = Color.White) {
    val shown = people.take(max)
    val overflow = people.size - shown.size
    val step = size * 0.62f
    val slots = shown.size + if (overflow > 0) 1 else 0
    Box(Modifier.width(step * (slots - 1).coerceAtLeast(0) + size).height(size)) {
        shown.forEachIndexed { index, person ->
            Avatar(
                person, size,
                Modifier.offset(x = step * index).border(1.5.dp, ring, CircleShape),
            )
        }
        if (overflow > 0) {
            Box(
                Modifier.offset(x = step * shown.size).size(size).clip(CircleShape)
                    .background(Color.Black.copy(alpha = 0.35f)).border(1.5.dp, ring, CircleShape),
                contentAlignment = Alignment.Center,
            ) { Text("+$overflow", color = Color.White, fontFamily = Rounded, fontSize = (size.value * 0.38f).sp) }
        }
    }
}
