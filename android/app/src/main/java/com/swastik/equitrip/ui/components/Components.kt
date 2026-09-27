package com.swastik.equitrip.ui.components

import androidx.compose.animation.core.Animatable
import androidx.compose.animation.core.Spring
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.spring
import androidx.compose.animation.core.tween
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.interaction.collectIsPressedAsState
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.add
import androidx.compose.foundation.layout.statusBars
import androidx.compose.foundation.layout.windowInsetsTopHeight
import androidx.compose.ui.draw.drawBehind
import androidx.compose.ui.graphics.Brush
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ColumnScope
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.CallMade
import androidx.compose.material.icons.automirrored.filled.Undo
import androidx.compose.material.icons.filled.Bed
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.ChevronRight
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.filled.DirectionsCar
import androidx.compose.material.icons.filled.Edit
import androidx.compose.material.icons.filled.Flight
import androidx.compose.material.icons.filled.Hiking
import androidx.compose.material.icons.filled.MarkEmailUnread
import androidx.compose.material.icons.filled.PersonAdd
import androidx.compose.material.icons.filled.PersonRemove
import androidx.compose.material.icons.filled.Place
import androidx.compose.material.icons.filled.ReportProblem
import androidx.compose.material.icons.filled.Restaurant
import androidx.compose.material.icons.filled.Schedule
import androidx.compose.material.icons.filled.Sync
import androidx.compose.material.icons.filled.SwapHoriz
import androidx.compose.material.icons.filled.Train
import androidx.compose.material.icons.filled.Verified
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.runtime.staticCompositionLocalOf
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.composed
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.swastik.equitrip.model.ActivityKind
import com.swastik.equitrip.model.ItineraryKind
import com.swastik.equitrip.ui.theme.Brand
import com.swastik.equitrip.ui.theme.figure

/** White card on the canvas with the warm, low shadow iOS `.cardSurface()` uses. */
@Composable
fun SurfaceCard(
    modifier: Modifier = Modifier,
    corner: Dp = 24.dp,
    elevation: Dp = 10.dp,
    content: @Composable ColumnScope.() -> Unit,
) {
    val shape = RoundedCornerShape(corner)
    Column(
        modifier
            .fillMaxWidth()
            .shadow(elevation, shape, ambientColor = Brand.shadow, spotColor = Brand.shadow)
            .clip(shape)
            .background(Brand.card)
            .border(0.5.dp, Brand.hairline, shape),
        content = content,
    )
}

/**
 * Title, an inline caption, and an optional "Action ›" — iOS `SectionHeader`, all on one
 * baseline so the link sits beside the title rather than hanging off the caption.
 */
@Composable
fun SectionHeader(
    title: String,
    modifier: Modifier = Modifier,
    caption: String? = null,
    action: String? = null,
    onAction: () -> Unit = {},
) {
    // The caption takes all the slack (not a share of it with a spacer), so the action always
    // ends flush with the cards' right edge.
    Row(modifier.fillMaxWidth().padding(start = 4.dp), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
        Text(title, Modifier.alignByBaseline(), style = figure(18.sp), color = Brand.ink, maxLines = 1)
        Text(
            caption.orEmpty(), Modifier.alignByBaseline().weight(1f),
            fontSize = 12.5.sp, fontWeight = FontWeight.Medium, color = Brand.inkTertiary,
            maxLines = 1, overflow = TextOverflow.Ellipsis,
        )
        action?.let {
            Row(Modifier.alignByBaseline().pressable(onAction), verticalAlignment = Alignment.CenterVertically) {
                Text(it, fontSize = 13.5.sp, fontWeight = FontWeight.SemiBold, color = Brand.accent)
                Spacer(Modifier.width(2.dp))
                Icon(Icons.Filled.ChevronRight, null, tint = Brand.accent, modifier = Modifier.size(16.dp))
            }
        }
    }
}

@Composable
fun Hairline(inset: Dp = 16.dp) {
    Box(Modifier.fillMaxWidth().padding(start = inset).height(0.5.dp).background(Brand.hairline))
}

/** A glyph on a soft tinted square — iOS `SymbolBadge`. */
@Composable
fun SymbolBadge(icon: ImageVector, tint: Color, size: Dp = 36.dp) {
    Box(
        Modifier.size(size).clip(RoundedCornerShape(size * 0.3f)).background(tint.copy(alpha = 0.12f)),
        contentAlignment = Alignment.Center,
    ) { Icon(icon, contentDescription = null, tint = tint, modifier = Modifier.size(size * 0.5f)) }
}

@Composable
fun KindBadge(kind: ItineraryKind, size: Dp = 36.dp) = SymbolBadge(kind.icon(), Brand.tint(kind), size)

fun ItineraryKind.icon(): ImageVector = when (this) {
    ItineraryKind.FLIGHT -> Icons.Filled.Flight
    ItineraryKind.TRAIN -> Icons.Filled.Train
    ItineraryKind.DRIVE -> Icons.Filled.DirectionsCar
    ItineraryKind.STAY -> Icons.Filled.Bed
    ItineraryKind.ACTIVITY -> Icons.Filled.Hiking
    ItineraryKind.MEAL -> Icons.Filled.Restaurant
    ItineraryKind.OTHER -> Icons.Filled.Place
}

fun ActivityKind.icon(): ImageVector = when (this) {
    ActivityKind.PAYMENT -> Icons.AutoMirrored.Filled.CallMade
    ActivityKind.RECALCULATION -> Icons.Filled.Sync
    ActivityKind.REFUND -> Icons.AutoMirrored.Filled.Undo
    ActivityKind.JOINED -> Icons.Filled.PersonAdd
    ActivityKind.INVITED -> Icons.Filled.MarkEmailUnread
    ActivityKind.DEPARTURE_REQUESTED -> Icons.Filled.Schedule
    ActivityKind.LEFT -> Icons.Filled.PersonRemove
    ActivityKind.BOOKING, ActivityKind.SETTLEMENT_CONFIRMED -> Icons.Filled.Check
    ActivityKind.BOOKING_CHANGED -> Icons.Filled.Edit
    ActivityKind.BOOKING_REMOVED -> Icons.Filled.Delete
    ActivityKind.CONFIRMED -> Icons.Filled.Verified
    ActivityKind.DISPUTED -> Icons.Filled.ReportProblem
    ActivityKind.SETTLEMENT_REQUESTED -> Icons.Filled.SwapHoriz
    ActivityKind.SETTLEMENT_DECLINED -> Icons.Filled.Close
}

/**
 * A bar of equal cells rather than a smooth fill — iOS `ProgressTrack`. The cells carry
 * meaning (a trip's days), which a continuous bar would throw away.
 */
@Composable
fun ProgressTrack(value: Double, tint: Color, cells: Int, empty: Color, height: Dp = 5.dp) {
    val count = cells.coerceAtLeast(1)
    val clamped = value.coerceIn(0.0, 1.0)
    val filled = if (clamped <= 0) 0 else Math.ceil(count * clamped).toInt().coerceIn(1, count)
    Row(Modifier.fillMaxWidth().height(height), horizontalArrangement = Arrangement.spacedBy(3.dp)) {
        repeat(count) { index ->
            Box(Modifier.weight(1f).fillMaxHeight().clip(CircleShape).background(if (index < filled) tint else empty))
        }
    }
}

/** Sections rise into place one after another on first appearance — iOS `.staggered`. */
fun Modifier.staggered(index: Int): Modifier = composed {
    val progress = remember { Animatable(0f) }
    LaunchedEffect(Unit) {
        progress.animateTo(1f, tween(durationMillis = 420, delayMillis = 60 * index))
    }
    graphicsLayer {
        alpha = progress.value
        translationY = (1f - progress.value) * 18.dp.toPx()
    }
}

/** Shrinks slightly under the finger — iOS `PressableButtonStyle`. */
fun Modifier.pressable(onClick: () -> Unit): Modifier = composed {
    val interaction = remember { MutableInteractionSource() }
    val pressed by interaction.collectIsPressedAsState()
    val scale by animateFloatAsState(if (pressed) 0.97f else 1f, spring(stiffness = Spring.StiffnessMediumLow), label = "press")
    graphicsLayer { scaleX = scale; scaleY = scale }
        .clickable(interactionSource = interaction, indication = null, onClick = onClick)
}

/**
 * The canvas fading in under the status bar once content scrolls beneath it — the Android
 * stand-in for iOS `.scrollEdgeEffectStyle(.soft, for: .top)`. Hidden while nothing is under it,
 * so a photograph at the top of a page isn't washed out at rest.
 */
@Composable
fun TopFade(visible: Boolean, modifier: Modifier = Modifier) {
    val alpha by animateFloatAsState(if (visible) 1f else 0f, label = "fade")
    Box(
        modifier.fillMaxWidth().graphicsLayer { this.alpha = alpha }
            .windowInsetsTopHeight(WindowInsets.statusBars.add(WindowInsets(top = 18.dp)))
            .drawBehind {
                drawRect(
                    Brush.verticalGradient(
                        0f to Brand.canvasTop, 0.6f to Brand.canvasTop.copy(alpha = 0.92f), 1f to Brand.canvasTop.copy(alpha = 0f),
                        startY = 0f, endY = size.height,
                    ),
                )
            },
    )
}

/** The tab bar's height, which pages scroll under and add to their own bottom padding. */
val LocalBottomBarInset = staticCompositionLocalOf { 0.dp }
