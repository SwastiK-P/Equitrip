package com.swastik.equitrip.ui.equi

import androidx.compose.animation.core.Animatable
import androidx.compose.animation.core.FastOutSlowInEasing
import androidx.compose.animation.core.LinearEasing
import androidx.compose.animation.core.RepeatMode
import androidx.compose.animation.core.Spring
import androidx.compose.animation.core.animateFloat
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.infiniteRepeatable
import androidx.compose.animation.core.rememberInfiniteTransition
import androidx.compose.animation.core.spring
import androidx.compose.animation.core.tween
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.wrapContentWidth
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.runtime.withFrameNanos
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.clipToBounds
import androidx.compose.ui.draw.scale
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.layout.onSizeChanged
import androidx.compose.ui.res.vectorResource
import androidx.compose.ui.text.AnnotatedString
import androidx.compose.ui.text.SpanStyle
import androidx.compose.ui.text.buildAnnotatedString
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.withStyle
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.IntOffset
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.swastik.equitrip.R
import com.swastik.equitrip.model.Traveller
import com.swastik.equitrip.ui.components.Avatar
import com.swastik.equitrip.ui.components.pressable
import com.swastik.equitrip.ui.theme.Brand
import kotlin.math.cos
import kotlin.math.roundToInt
import kotlin.math.sin

/**
 * Equi's face on a violet disc — iOS `EquiOrb`. Header, empty state, gutter and the
 * typing bubble all use this one, so the "alive" ring while thinking is defined once.
 */
@Composable
fun EquiOrb(size: Dp, thinking: Boolean = false, modifier: Modifier = Modifier) {
    val pulse = rememberInfiniteTransition(label = "orb")
    val ring by pulse.animateFloat(
        0f, 1f, infiniteRepeatable(tween(1100, easing = FastOutSlowInEasing)), label = "ring",
    )
    val breathe by pulse.animateFloat(
        1f, 1.035f, infiniteRepeatable(tween(1600, easing = FastOutSlowInEasing), RepeatMode.Reverse), label = "breathe",
    )
    Box(modifier.size(size), contentAlignment = Alignment.Center) {
        if (thinking) {
            Box(
                Modifier.size(size).graphicsLayer {
                    scaleX = 1f + ring * 0.45f; scaleY = 1f + ring * 0.45f; alpha = (1f - ring) * 0.8f
                }.border(2.dp, Brand.accent.copy(alpha = 0.35f), CircleShape),
            )
        }
        Box(
            Modifier.size(size).scale(if (thinking) breathe else 1f).clip(CircleShape)
                .background(Brush.verticalGradient(listOf(Brand.accent, Brand.accentDeep))),
            contentAlignment = Alignment.Center,
        ) {
            Icon(ImageVector.vectorResource(R.drawable.ic_equi), null, tint = Color.White, modifier = Modifier.size(size * 0.5f))
        }
    }
}

/** The user's own face in the gutter, ringed white so it holds against the canvas. */
@Composable
fun MeAvatar(me: Traveller?, size: Dp) {
    Box(Modifier.size(size).clip(CircleShape).border(1.75.dp, Color.White.copy(alpha = 0.9f), CircleShape)) {
        if (me != null) Avatar(me, size)
        else Box(Modifier.fillMaxSize().background(Brand.accent.copy(alpha = 0.2f)))
    }
}

/** Three dots rising in turn inside a bubble, beside a thinking orb — iOS `EquiThinkingBubble`. */
@Composable
fun TypingBubble() {
    val wave = rememberInfiniteTransition(label = "typing")
    Row(verticalAlignment = Alignment.Bottom) {
        EquiOrb(26.dp, thinking = true)
        Spacer(Modifier.width(8.dp))
        Row(
            Modifier.clip(bubbleShape(mine = false, tail = true)).background(Brand.card)
                .border(0.5.dp, Brand.hairline, bubbleShape(mine = false, tail = true))
                .padding(horizontal = 16.dp, vertical = 14.dp),
            horizontalArrangement = Arrangement.spacedBy(5.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            repeat(3) { index ->
                val phase by wave.animateFloat(
                    0f, 1f,
                    infiniteRepeatable(tween(1200, delayMillis = 0, easing = LinearEasing)),
                    label = "dot$index",
                )
                // Each dot peaks a fifth of a cycle after the one before it.
                val t = ((phase - index * 0.18f) % 1f + 1f) % 1f
                val lift = if (t < 0.4f) sin(t / 0.4f * Math.PI).toFloat() else 0f
                Box(
                    Modifier.size(7.dp)
                        .graphicsLayer { translationY = -lift * 5.dp.toPx() }
                        .clip(CircleShape)
                        .background(Brand.inkTertiary.copy(alpha = 0.45f + 0.55f * lift)),
                )
            }
        }
    }
}

/**
 * iMessage grouping: fully rounded while more from the same side follows; the last in a
 * run gets the tucked-in corner that reads as "end of thought".
 */
fun bubbleShape(mine: Boolean, tail: Boolean): RoundedCornerShape {
    val small = if (tail) 6.dp else 20.dp
    return if (mine) RoundedCornerShape(20.dp, 20.dp, small, 20.dp) else RoundedCornerShape(20.dp, 20.dp, 20.dp, small)
}

/**
 * A reply laid out as it's written: a lead line, `- ` bullets and `1.` steps as a list with
 * hanging indents, blank lines as breathing room, `**…**` in semibold. Partial text renders
 * the same way, so a streaming reply is structured from its first line.
 */
@Composable
fun EquiReplyText(text: String, modifier: Modifier = Modifier) {
    val lines = text.lines()
    Column(modifier, verticalArrangement = Arrangement.spacedBy(5.dp)) {
        var gap = false
        lines.forEach { raw ->
            val line = raw.trim()
            if (line.isEmpty()) { gap = true; return@forEach }
            val top = if (gap) 6.dp else 0.dp
            gap = false
            val bullet = BULLET.matchEntire(line)
            val step = STEP.matchEntire(line)
            when {
                bullet != null -> ListRow("•", bullet.groupValues[1], top)
                step != null -> ListRow("${step.groupValues[1]}.", step.groupValues[2], top)
                else -> Text(inline(line), Modifier.padding(top = top), color = Brand.ink, fontSize = 15.5.sp, lineHeight = 22.sp)
            }
        }
    }
}

@Composable
private fun ListRow(marker: String, body: String, top: Dp) {
    Row(Modifier.padding(top = top, start = 2.dp)) {
        Text(marker, Modifier.width(16.dp), color = Brand.accent, fontSize = 15.5.sp, lineHeight = 22.sp, fontWeight = FontWeight.Bold)
        Text(inline(body), color = Brand.ink, fontSize = 15.sp, lineHeight = 21.sp)
    }
}

private val BULLET = Regex("^[-•*]\\s+(.*)$")
private val STEP = Regex("^(\\d{1,2})[.)]\\s+(.*)$")

/** `**bold**` to a semibold span; an unclosed `**` mid-stream is shown bold to the end. */
private fun inline(text: String): AnnotatedString = buildAnnotatedString {
    val parts = text.split("**")
    parts.forEachIndexed { i, part ->
        if (i % 2 == 1) withStyle(SpanStyle(fontWeight = FontWeight.SemiBold)) { append(part) } else append(part)
    }
}

/**
 * One lane of starter questions drifting sideways — iOS `EquiMarqueeRow`. The offset is set
 * per frame in layout, so a tile is tappable where it's drawn, and the strip is laid twice
 * so the wrap is invisible.
 */
@Composable
fun PromptLane(prompts: List<Pair<ImageVector, String>>, speed: Float, start: Float, onPick: (String) -> Unit) {
    var cycle by remember { mutableIntStateOf(0) }
    var x by remember { mutableFloatStateOf(0f) }
    LaunchedEffect(cycle) {
        if (cycle == 0) return@LaunchedEffect
        x = -cycle * start
        var last = 0L
        while (true) withFrameNanos { now ->
            if (last != 0L) {
                x += speed * (now - last) / 1_000_000_000f
                if (x <= -cycle) x += cycle
                if (x > 0) x -= cycle
            }
            last = now
        }
    }
    Box(Modifier.fillMaxWidth().clipToBounds()) {
        Row(Modifier.wrapContentWidth(Alignment.Start, unbounded = true).offset { IntOffset(x.roundToInt(), 0) }) {
            repeat(2) { copy ->
                Row(
                    Modifier.then(if (copy == 0) Modifier.onSizeChanged { cycle = it.width } else Modifier),
                ) {
                    prompts.forEach { (icon, text) -> PromptTile(icon, text) { onPick(text) } }
                }
            }
        }
    }
}

@Composable
private fun PromptTile(icon: ImageVector, text: String, onClick: () -> Unit) {
    Row(
        Modifier.padding(end = 10.dp).clip(RoundedCornerShape(16.dp)).background(Brand.card)
            .border(0.5.dp, Brand.hairline, RoundedCornerShape(16.dp)).pressable(onClick)
            .padding(horizontal = 14.dp, vertical = 11.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Icon(icon, null, tint = Brand.accent, modifier = Modifier.size(16.dp))
        Spacer(Modifier.width(8.dp))
        Text(text, color = Brand.ink, fontSize = 14.sp, fontWeight = FontWeight.Medium, maxLines = 1)
    }
}

/**
 * Equi's backdrop — the Android stand-in for iOS `EquiAuroraBackground`: two soft violet
 * pools drifting over the canvas, a little quicker and brighter while a reply is coming.
 */
@Composable
fun EquiAurora(thinking: Boolean, modifier: Modifier = Modifier) {
    val drift = rememberInfiniteTransition(label = "aurora")
    val angle by drift.animateFloat(0f, (2 * Math.PI).toFloat(), infiniteRepeatable(tween(22_000, easing = LinearEasing)), label = "angle")
    val glow by animateFloatAsState(if (thinking) 1f else 0f, spring(stiffness = Spring.StiffnessVeryLow), label = "glow")
    Canvas(modifier.fillMaxSize()) {
        val w = size.width
        val h = size.height
        val a = Offset(w * (0.2f + 0.12f * cos(angle)), h * (0.18f + 0.06f * sin(angle * 2)))
        val b = Offset(w * (0.85f + 0.1f * sin(angle)), h * (0.55f + 0.08f * cos(angle)))
        drawCircle(
            Brush.radialGradient(listOf(Brand.accent.copy(alpha = 0.10f + 0.06f * glow), Color.Transparent), a, w * 0.75f),
            radius = w * 0.75f, center = a,
        )
        drawCircle(
            Brush.radialGradient(listOf(Brand.violet.copy(alpha = 0.08f + 0.05f * glow), Color.Transparent), b, w * 0.7f),
            radius = w * 0.7f, center = b,
        )
    }
}

/** A pop-in for a new bubble: a little rise, scale and fade from the speaker's side. */
@Composable
fun Modifier.bubbleEntrance(animate: Boolean, fromEnd: Boolean): Modifier {
    val progress = remember { Animatable(if (animate) 0f else 1f) }
    LaunchedEffect(Unit) { if (animate) progress.animateTo(1f, spring(dampingRatio = 0.78f, stiffness = 420f)) }
    return graphicsLayer {
        val p = progress.value
        alpha = p.coerceIn(0f, 1f)
        scaleX = 0.92f + 0.08f * p
        scaleY = 0.92f + 0.08f * p
        translationY = (1f - p) * 14.dp.toPx()
        translationX = (1f - p) * (if (fromEnd) 10.dp.toPx() else -10.dp.toPx())
        transformOrigin = androidx.compose.ui.graphics.TransformOrigin(if (fromEnd) 1f else 0f, 1f)
    }
}
