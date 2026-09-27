package com.swastik.equitrip.ui.theme

import android.graphics.Typeface
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.LocalTextStyle
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Typography
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.Font
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontStyle
import androidx.compose.ui.text.font.FontVariation
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.LineHeightStyle
import androidx.compose.ui.unit.TextUnit
import androidx.compose.ui.unit.em
import androidx.compose.ui.unit.sp
import com.swastik.equitrip.R
import com.swastik.equitrip.model.ActivityKind
import com.swastik.equitrip.model.ItineraryKind
import com.swastik.equitrip.model.TitleStyle
import com.swastik.equitrip.model.TripPhase

/** The iOS `Brand` palette (light values), so both apps read as one product. */
object Brand {
    val canvasTop = Color(0xFFFFF9F5)
    val canvasBottom = Color(0xFFF8E4D5)
    val card = Color(0xFFFFFFFF)
    val cardStroke = Color(0xFF1A1109)
    val ink = Color(0xFF1A1109)
    val inkSecondary = Color(0xFF6B5B50)
    val inkTertiary = Color(0xFF9C8C80)
    val accent = Color(0xFF4B45C6)
    val accentDeep = Color(0xFF3A34A8)
    val cta = Color(0xFF21150D)
    val danger = Color(0xFFC5442E)
    val positive = Color(0xFF1E7A55)
    val blue = Color(0xFF2F6FED)
    val teal = Color(0xFF0E7490)
    val violet = Color(0xFF7C4DE0)
    val amber = Color(0xFFD97706)
    val stone = Color(0xFF6B5B50)

    val hairline = cardStroke.copy(alpha = 0.08f)
    val shadow = Color(0xFF5A3319).copy(alpha = 0.16f)

    fun moneyTone(amount: Double) = when {
        amount > 0 -> accent
        amount < 0 -> danger
        else -> inkSecondary
    }

    fun tint(kind: ItineraryKind) = when (kind) {
        ItineraryKind.FLIGHT -> blue
        ItineraryKind.TRAIN -> teal
        ItineraryKind.DRIVE -> accent
        ItineraryKind.STAY -> violet
        ItineraryKind.ACTIVITY -> positive
        ItineraryKind.MEAL -> amber
        ItineraryKind.OTHER -> stone
    }

    fun tint(phase: TripPhase) = when (phase) {
        TripPhase.LIVE -> positive
        TripPhase.UPCOMING -> accent
        TripPhase.PAST -> inkTertiary
    }

    fun tint(kind: ActivityKind) = when (kind) {
        ActivityKind.PAYMENT, ActivityKind.INVITED, ActivityKind.SETTLEMENT_REQUESTED -> accent
        ActivityKind.RECALCULATION, ActivityKind.DEPARTURE_REQUESTED, ActivityKind.BOOKING_CHANGED -> amber
        ActivityKind.REFUND, ActivityKind.CONFIRMED, ActivityKind.SETTLEMENT_CONFIRMED -> positive
        ActivityKind.JOINED, ActivityKind.LEFT -> violet
        ActivityKind.BOOKING -> blue
        ActivityKind.BOOKING_REMOVED, ActivityKind.DISPUTED, ActivityKind.SETTLEMENT_DECLINED -> danger
    }
}

/**
 * Nunito stands in for SF Rounded, which iOS uses for every figure and the greeting —
 * Android has no rounded system face.
 */
val Rounded = FontFamily(
    listOf(FontWeight.Medium, FontWeight.SemiBold, FontWeight.Bold, FontWeight.ExtraBold).map { weight ->
        Font(R.font.rounded_nunito, weight, variationSettings = FontVariation.Settings(FontVariation.weight(weight.weight)))
    },
)

fun figure(size: TextUnit, weight: FontWeight = FontWeight.Bold) =
    TextStyle(fontFamily = Rounded, fontWeight = weight, fontSize = size)

private val Condensed = FontFamily(Typeface.create("sans-serif-condensed", Typeface.NORMAL))

/**
 * A trip's name in the typeface its organiser picked — iOS `TripTitleStyle.font`. The three
 * Apple faces without an Android counterpart are replaced with the nearest open font:
 * Futura Condensed → Bebas Neue, Snell Roundhand → Great Vibes, American Typewriter → Courier Prime.
 */
fun tripTitle(style: TitleStyle, size: Float): TextStyle = when (style) {
    TitleStyle.CLASSIC -> TextStyle(fontFamily = FontFamily.Serif, fontWeight = FontWeight.Bold, fontSize = size.sp)
    TitleStyle.BOLD -> TextStyle(
        fontWeight = FontWeight.Black, fontStyle = FontStyle.Italic,
        fontSize = (size * 1.02f).sp, letterSpacing = (-0.035).em,
    )
    TitleStyle.AIRY -> TextStyle(fontFamily = Condensed, fontSize = (size * 0.8f).sp, letterSpacing = 0.22.em)
    TitleStyle.POSTER -> TextStyle(
        fontFamily = FontFamily(Font(R.font.poster_bebas_neue)),
        fontSize = (size * 1.08f).sp, letterSpacing = 0.01.em,
    )
    TitleStyle.CLEAN -> TextStyle(fontWeight = FontWeight.Bold, fontSize = (size * 0.96f).sp)
    TitleStyle.SCRIPT -> TextStyle(fontFamily = FontFamily(Font(R.font.script_great_vibes)), fontSize = (size * 1.08f).sp)
    TitleStyle.TYPEWRITER -> TextStyle(
        fontFamily = FontFamily(Font(R.font.typewriter_courier_prime_bold)),
        fontSize = (size * 0.86f).sp,
    )
}

fun TitleStyle.display(title: String) = if (this == TitleStyle.AIRY || this == TitleStyle.POSTER) title.uppercase() else title

private val colors = lightColorScheme(
    primary = Brand.accent,
    onPrimary = Color.White,
    primaryContainer = Color(0xFFE4E2FF),
    onPrimaryContainer = Brand.accentDeep,
    secondary = Brand.cta,
    onSecondary = Color.White,
    secondaryContainer = Color(0xFFF3E6DC),
    onSecondaryContainer = Brand.ink,
    tertiary = Brand.positive,
    background = Brand.canvasTop,
    onBackground = Brand.ink,
    surface = Brand.canvasTop,
    onSurface = Brand.ink,
    onSurfaceVariant = Brand.inkSecondary,
    surfaceContainerLowest = Color.White,
    surfaceContainerLow = Color(0xFFFFF4EC),
    surfaceContainer = Color(0xFFFBEDE2),
    surfaceContainerHigh = Color(0xFFF6E6DA),
    surfaceContainerHighest = Color(0xFFF1DFD1),
    outline = Color(0xFFCDBCB0),
    outlineVariant = Color(0xFFEBDDD2),
    error = Brand.danger,
)

/**
 * Material's type scale with its tracking taken out. The stock body and label styles carry
 * 0.25–0.5sp of letter spacing, which reads as airy and loose next to the iOS app's SF Pro.
 */
private val typography = Typography().run {
    copy(
        titleLarge = titleLarge.copy(letterSpacing = 0.sp),
        titleMedium = titleMedium.copy(letterSpacing = 0.sp),
        titleSmall = titleSmall.copy(letterSpacing = 0.sp),
        bodyLarge = bodyLarge.copy(letterSpacing = 0.sp),
        bodyMedium = bodyMedium.copy(letterSpacing = 0.sp),
        bodySmall = bodySmall.copy(letterSpacing = 0.sp),
        labelLarge = labelLarge.copy(letterSpacing = 0.sp),
        labelMedium = labelMedium.copy(letterSpacing = 0.sp),
        labelSmall = labelSmall.copy(letterSpacing = 0.sp),
    )
}

/**
 * What a bare `Text` inherits. Material's default is `bodyLarge`, whose 24sp line height is
 * fixed rather than proportional — so a 12sp caption set with only `fontSize` sat in a line
 * twice its height, and every two-line row came apart. A relative line height scales with
 * whatever size a row picks.
 */
private val defaultText = TextStyle(
    fontSize = 16.sp,
    lineHeight = 1.3.em,
    letterSpacing = 0.sp,
    lineHeightStyle = LineHeightStyle(LineHeightStyle.Alignment.Center, LineHeightStyle.Trim.Both),
)

@Composable
fun EquitripTheme(content: @Composable () -> Unit) {
    MaterialTheme(colorScheme = colors, typography = typography) {
        CompositionLocalProvider(LocalTextStyle provides defaultText, content = content)
    }
}

/** The warm canvas every screen sits on — iOS `CanvasBackground`. */
@Composable
fun Canvas(modifier: Modifier = Modifier, content: @Composable () -> Unit) {
    Box(
        modifier
            .fillMaxSize()
            .background(Brush.verticalGradient(listOf(Brand.canvasTop, Brand.canvasBottom))),
    ) { content() }
}
