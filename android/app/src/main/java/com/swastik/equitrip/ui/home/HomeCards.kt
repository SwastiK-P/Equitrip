package com.swastik.equitrip.ui.home

import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.spring
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicText
import androidx.compose.foundation.text.TextAutoSize
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowForward
import androidx.compose.material.icons.filled.Luggage
import androidx.compose.material.icons.filled.NotificationsActive
import androidx.compose.material.icons.filled.UnfoldMore
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.drawBehind
import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.PathEffect
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import coil3.compose.AsyncImage
import com.swastik.equitrip.model.AppNotification
import com.swastik.equitrip.model.ItineraryItem
import com.swastik.equitrip.model.Money
import com.swastik.equitrip.model.Settlement
import com.swastik.equitrip.model.Trip
import com.swastik.equitrip.model.Traveller
import com.swastik.equitrip.model.TripPhase
import com.swastik.equitrip.model.plural
import com.swastik.equitrip.ui.components.Avatar
import com.swastik.equitrip.ui.components.AvatarStack
import com.swastik.equitrip.ui.components.Hairline
import com.swastik.equitrip.ui.components.KindBadge
import com.swastik.equitrip.ui.components.ProgressTrack
import com.swastik.equitrip.ui.components.SurfaceCard
import com.swastik.equitrip.ui.components.SymbolBadge
import com.swastik.equitrip.ui.components.icon
import com.swastik.equitrip.ui.components.pressable
import com.swastik.equitrip.ui.theme.Brand
import com.swastik.equitrip.ui.theme.Rounded
import com.swastik.equitrip.ui.theme.display
import com.swastik.equitrip.ui.theme.figure
import com.swastik.equitrip.ui.theme.tripTitle
import java.time.ZoneId
import java.time.format.DateTimeFormatter

// MARK: Balance

/**
 * The one number the app exists to answer — iOS Home's `balanceHero`. Scoped to all trips
 * or to one, because the portfolio figure adds unlike currencies together and the question
 * people act on is usually "what do I owe from Goa?".
 */
@Composable
fun BalanceHero(
    trips: List<Trip>,
    scope: Trip?,
    owedToYou: Double,
    youOwe: Double,
    currency: String,
    activeCount: Int,
    onScope: (Trip?) -> Unit,
    onSettleUp: () -> Unit,
) {
    val net = owedToYou - youOwe
    val tone = when {
        net > 0 -> Brand.accent
        net < 0 -> Brand.danger
        else -> Brand.ink
    }
    val caption = if (scope != null) when {
        net > 0 -> "You're ahead on ${scope.title}"
        net < 0 -> "You're behind on ${scope.title}"
        else -> "Everything's square on ${scope.title}"
    } else {
        val active = if (activeCount == 1) "1 active trip" else "$activeCount active trips"
        when {
            net > 0 -> "You're ahead across $active"
            net < 0 -> "You're behind across $active"
            else -> "Everything's square across $active"
        }
    }

    SurfaceCard(corner = 28.dp, elevation = 16.dp) {
        Column(Modifier.padding(20.dp)) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                ScopePicker(trips, scope, onScope)
                Spacer(Modifier.weight(1f))
                Text("Net position", fontSize = 13.sp, fontWeight = FontWeight.Medium, color = Brand.inkTertiary)
            }
            Text(
                Money.format(net, currency, signed = true),
                Modifier.padding(top = 10.dp),
                style = figure(46.sp),
                color = tone,
                maxLines = 1,
            )
            Text(caption, fontSize = 13.5.sp, color = Brand.inkSecondary)

            SplitBar(owedToYou, youOwe, Modifier.padding(top = 20.dp))

            Row(Modifier.padding(top = 16.dp), verticalAlignment = Alignment.CenterVertically) {
                HeroFigure("You're owed", Money.format(owedToYou, currency), Brand.accent, Modifier.weight(1f))
                Box(Modifier.width(1.dp).height(32.dp).background(Brand.cardStroke.copy(alpha = 0.10f)))
                HeroFigure("You owe", Money.format(youOwe, currency), Brand.danger, Modifier.weight(1f).padding(start = 16.dp))
            }

            Button(
                onClick = onSettleUp,
                modifier = Modifier.fillMaxWidth().padding(top = 18.dp).height(50.dp),
                colors = ButtonDefaults.buttonColors(containerColor = Brand.accent),
            ) {
                Text("Settle up", fontSize = 15.5.sp, fontWeight = FontWeight.SemiBold)
                Spacer(Modifier.width(6.dp))
                Icon(Icons.AutoMirrored.Filled.ArrowForward, contentDescription = null, modifier = Modifier.size(16.dp))
            }
        }
    }
}

/** Owed-to-you against owed-by-you as one bar of upright cells — the ratio is what you read. */
@Composable
private fun SplitBar(owedToYou: Double, youOwe: Double, modifier: Modifier = Modifier) {
    val cells = 28
    val total = owedToYou + youOwe
    val fraction = if (total > 0) owedToYou / total else 0.5
    val owed by animateFloatAsState((cells * fraction).toFloat(), spring(dampingRatio = 0.85f), label = "split")
    Row(modifier.fillMaxWidth().height(13.dp), horizontalArrangement = Arrangement.spacedBy(2.5.dp)) {
        repeat(cells) { index ->
            Box(
                Modifier.weight(1f).fillMaxHeight().clip(RoundedCornerShape(2.5.dp))
                    .background(if (index < Math.round(owed)) Brand.accent else Brand.danger.copy(alpha = 0.32f)),
            )
        }
    }
}

@Composable
private fun HeroFigure(label: String, value: String, dot: Color, modifier: Modifier = Modifier) {
    Column(modifier.padding(start = 2.dp), verticalArrangement = Arrangement.spacedBy(3.dp)) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Box(Modifier.size(6.dp).clip(CircleShape).background(dot))
            Spacer(Modifier.width(5.dp))
            Text(label, fontSize = 12.5.sp, fontWeight = FontWeight.Medium, color = Brand.inkSecondary)
        }
        Text(value, style = figure(19.sp, FontWeight.SemiBold), color = Brand.ink, maxLines = 1)
    }
}

@Composable
private fun ScopePicker(trips: List<Trip>, scope: Trip?, onScope: (Trip?) -> Unit) {
    var open by remember { mutableStateOf(false) }
    Box {
        Row(
            Modifier.clip(CircleShape).background(Brand.accent.copy(alpha = 0.12f)).pressable { open = true }
                .padding(horizontal = 10.dp, vertical = 5.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Text(
                scope?.title ?: "All trips",
                fontSize = 12.5.sp, fontWeight = FontWeight.SemiBold, color = Brand.accent,
                maxLines = 1, overflow = TextOverflow.Ellipsis, modifier = Modifier.widthIn(max = 160.dp),
            )
            Icon(Icons.Filled.UnfoldMore, contentDescription = null, tint = Brand.accent, modifier = Modifier.size(14.dp))
        }
        DropdownMenu(
            expanded = open,
            onDismissRequest = { open = false },
            shape = RoundedCornerShape(20.dp),
            containerColor = Brand.card,
        ) {
            ScopeRow("All trips", "Everything, one figure", null, scope == null) { onScope(null); open = false }
            trips.forEach { trip ->
                ScopeRow(trip.title, trip.dateRange, trip, scope?.id == trip.id) { onScope(trip); open = false }
            }
        }
    }
}

@Composable
private fun ScopeRow(title: String, subtitle: String, trip: Trip?, selected: Boolean, onClick: () -> Unit) {
    DropdownMenuItem(
        onClick = onClick,
        leadingIcon = {
            Box(Modifier.size(38.dp).clip(RoundedCornerShape(10.dp)).background(Brand.accent.copy(alpha = 0.14f)), contentAlignment = Alignment.Center) {
                if (trip?.coverUrl != null) {
                    AsyncImage(trip.coverUrl, null, contentScale = ContentScale.Crop, modifier = Modifier.fillMaxSize())
                } else {
                    Icon(Icons.Filled.Luggage, null, tint = Brand.accent, modifier = Modifier.size(18.dp))
                }
            }
        },
        text = {
            Column {
                Text(title, fontWeight = if (selected) FontWeight.Bold else FontWeight.Medium, color = Brand.ink, maxLines = 1)
                Text(subtitle, fontSize = 12.sp, color = Brand.inkTertiary)
            }
        },
    )
}

// MARK: Current trip

/**
 * The trip that's happening, as a photograph — iOS `CurrentTripCard`. A frosted panel at
 * the foot carries where you are in it and the one figure that matters right now.
 */
@Composable
fun CurrentTripCard(trip: Trip, me: String?, onClick: () -> Unit) {
    val shape = RoundedCornerShape(28.dp)
    Box(
        Modifier.fillMaxWidth().height(300.dp)
            .pressable(onClick)
            .clip(shape)
            .border(0.5.dp, Color.White.copy(alpha = 0.12f), shape),
    ) {
        CoverImage(trip, Modifier.fillMaxSize())
        Box(
            Modifier.fillMaxSize().background(
                Brush.verticalGradient(0.30f to Color.Transparent, 1f to Color.Black.copy(alpha = 0.62f)),
            ),
        )

        Row(Modifier.fillMaxWidth().padding(14.dp), verticalAlignment = Alignment.CenterVertically) {
            if (trip.phase != TripPhase.LIVE) PhaseChip(trip.phase)
            Spacer(Modifier.weight(1f))
            AvatarStack(trip.travellers, size = 28.dp, max = 4)
        }

        Column(Modifier.align(Alignment.BottomStart).padding(10.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
            Column(Modifier.padding(horizontal = 6.dp)) {
                val style = tripTitle(trip.titleStyle, 30f)
                BasicText(
                    trip.titleStyle.display(trip.title),
                    style = style.copy(color = Color.White),
                    maxLines = 1,
                    autoSize = TextAutoSize.StepBased(minFontSize = style.fontSize * 0.75f, maxFontSize = style.fontSize),
                )
                Text(
                    "${trip.dateRange} · ${plural(trip.items.size, "booking")} · ${Money.format(trip.totalCost, trip.currencyCode)}",
                    fontSize = 12.5.sp, fontWeight = FontWeight.Medium, color = Color.White.copy(alpha = 0.8f), maxLines = 1,
                )
            }
            FootPanel(trip, me)
        }
    }
}

@Composable
private fun FootPanel(trip: Trip, me: String?) {
    val shape = RoundedCornerShape(18.dp)
    Row(
        Modifier.fillMaxWidth().clip(shape).background(Color.Black.copy(alpha = 0.30f))
            .border(0.5.dp, Color.White.copy(alpha = 0.16f), shape)
            .padding(horizontal = 14.dp, vertical = 12.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(9.dp)) {
            Text(trip.progressLabel, fontSize = 12.5.sp, fontWeight = FontWeight.SemiBold, color = Color.White, maxLines = 1)
            ProgressTrack(trip.progress, Color.White, trip.dayCount, Color.White.copy(alpha = 0.22f))
        }
        Box(Modifier.padding(horizontal = 14.dp).width(1.dp).height(34.dp).background(Color.White.copy(alpha = 0.18f)))
        Column(horizontalAlignment = Alignment.End) {
            val balance = me?.let { trip.remainingBalance(it) } ?: 0.0
            val shows = me != null && trip.showsBalance
            Text(
                when {
                    !shows -> Money.format(me?.let { trip.cost(it) } ?: 0.0, trip.currencyCode)
                    balance == 0.0 -> "Settled"
                    else -> Money.format(balance, trip.currencyCode, signed = true)
                },
                style = figure(21.sp),
                color = Color.White,
            )
            Row(verticalAlignment = Alignment.CenterVertically) {
                if (shows) {
                    Box(Modifier.size(5.dp).clip(CircleShape).background(Brand.moneyTone(balance)))
                    Spacer(Modifier.width(4.dp))
                }
                Text(
                    when {
                        !shows -> "your share"
                        balance > 0 -> "you get back"
                        balance < 0 -> "you owe"
                        else -> "all square"
                    },
                    fontSize = 10.5.sp, fontWeight = FontWeight.Medium, color = Color.White.copy(alpha = 0.72f),
                )
            }
        }
    }
}

@Composable
private fun PhaseChip(phase: TripPhase) {
    Row(
        Modifier.clip(CircleShape).background(Color.Black.copy(alpha = 0.28f)).padding(horizontal = 10.dp, vertical = 6.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Box(Modifier.size(5.dp).clip(CircleShape).background(Brand.tint(phase)))
        Spacer(Modifier.width(5.dp))
        Text(phase.label, fontSize = 11.5.sp, fontWeight = FontWeight.SemiBold, color = Color.White)
    }
}

/** The trip's photograph, or a designed fallback in the brand gradient. */
@Composable
fun CoverImage(trip: Trip, modifier: Modifier = Modifier) {
    Box(modifier.background(Brush.linearGradient(listOf(Brand.accent, Brand.violet))), contentAlignment = Alignment.Center) {
        Icon(Icons.Filled.Luggage, null, tint = Color.White.copy(alpha = 0.35f), modifier = Modifier.size(64.dp))
        trip.coverUrl?.let {
            AsyncImage(it, contentDescription = null, contentScale = ContentScale.Crop, modifier = Modifier.fillMaxSize())
        }
    }
}

/** A dashed empty slot where a trip would be. */
@Composable
fun NoTripCard() {
    Column(
        Modifier.fillMaxWidth().drawBehind {
            drawRoundRect(
                Brand.cardStroke.copy(alpha = 0.16f),
                cornerRadius = CornerRadius(24.dp.toPx()),
                style = Stroke(1.5.dp.toPx(), pathEffect = PathEffect.dashPathEffect(floatArrayOf(7.dp.toPx(), 6.dp.toPx()))),
            )
        }.padding(vertical = 28.dp, horizontal = 24.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(8.dp),
    ) {
        Icon(Icons.Filled.Luggage, null, tint = Brand.accent, modifier = Modifier.size(28.dp))
        Text("No trips yet", fontSize = 15.sp, fontWeight = FontWeight.SemiBold, color = Brand.ink)
        Text(
            "Trips you create or join show up here.",
            fontSize = 12.sp, color = Brand.inkSecondary, textAlign = TextAlign.Center,
        )
    }
}

// MARK: Rows

private val clock = DateTimeFormatter.ofPattern("h:mm")
private val meridiem = DateTimeFormatter.ofPattern("a")

/** One booking with its time in a gutter on the left — iOS Home `ItineraryRow`. */
@Composable
fun UpNextRow(item: ItineraryItem, trip: Trip) {
    Row(Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 13.dp), verticalAlignment = Alignment.CenterVertically) {
        Column(Modifier.width(44.dp), horizontalAlignment = Alignment.CenterHorizontally) {
            val time = item.time?.atZoneSameInstant(ZoneId.systemDefault())
            if (time != null) {
                Text(time.format(clock), style = figure(14.sp), color = Brand.ink)
                Text(time.format(meridiem).uppercase(), fontSize = 9.5.sp, fontWeight = FontWeight.SemiBold, color = Brand.inkTertiary)
            } else {
                Text(
                    "All\nday", fontSize = 10.5.sp, lineHeight = 12.sp, fontWeight = FontWeight.SemiBold,
                    color = Brand.inkTertiary, textAlign = TextAlign.Center,
                )
            }
        }
        Spacer(Modifier.width(12.dp))
        KindBadge(item.kind, 34.dp)
        Spacer(Modifier.width(12.dp))
        Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(2.dp)) {
            Text(item.title, fontSize = 14.5.sp, fontWeight = FontWeight.SemiBold, color = Brand.ink, maxLines = 1, overflow = TextOverflow.Ellipsis)
            Text(
                item.vendor.ifBlank { item.split.label },
                fontSize = 12.sp, color = Brand.inkSecondary, maxLines = 1, overflow = TextOverflow.Ellipsis,
            )
        }
        Spacer(Modifier.width(4.dp))
        AvatarStack(trip.bearers(item), size = 22.dp, max = 3)
    }
}

@Composable
fun ActivityRow(item: AppNotification, onClick: (() -> Unit)? = null) {
    Row(
        Modifier.fillMaxWidth().then(if (onClick != null) Modifier.pressable(onClick) else Modifier)
            .padding(horizontal = 16.dp, vertical = 13.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        SymbolBadge(item.kind.icon(), Brand.tint(item.kind), 36.dp)
        Spacer(Modifier.width(12.dp))
        Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(2.dp)) {
            Text(
                item.title, fontSize = 13.5.sp, color = Brand.ink, maxLines = 2,
                fontWeight = if (item.isUnread) FontWeight.SemiBold else FontWeight.Normal,
            )
            Text(
                if (item.body.isBlank()) item.time else "${item.body} · ${item.time}",
                fontSize = 11.5.sp, color = Brand.inkTertiary, maxLines = 2,
            )
        }
        if (item.isUnread) {
            Spacer(Modifier.width(6.dp))
            Box(Modifier.size(7.dp).clip(CircleShape).background(Brand.accent))
        }
    }
}

// MARK: Inbox

/** Payments somebody says they made to you — the thing on Home that's waiting for an answer. */
@Composable
fun PendingSettlementsCard(entries: List<Pair<Trip, Settlement>>, onOpen: (Trip, Settlement) -> Unit) {
    Column(verticalArrangement = Arrangement.spacedBy(11.dp)) {
        Row(Modifier.padding(start = 4.dp), verticalAlignment = Alignment.CenterVertically) {
            Icon(Icons.Filled.NotificationsActive, null, tint = Brand.accent, modifier = Modifier.size(14.dp))
            Spacer(Modifier.width(6.dp))
            Text(
                if (entries.size == 1) "Someone paid you" else "${entries.size} payments to confirm",
                fontSize = 13.sp, fontWeight = FontWeight.Bold, color = Brand.accent,
            )
        }
        SurfaceCard(corner = 20.dp) {
            entries.forEachIndexed { index, (trip, settlement) ->
                if (index > 0) Hairline()
                val payer = trip.traveller(settlement.fromId)
                Row(Modifier.fillMaxWidth().pressable { onOpen(trip, settlement) }.padding(13.dp), verticalAlignment = Alignment.CenterVertically) {
                    payer?.let { Avatar(it, 38.dp) }
                    Spacer(Modifier.width(12.dp))
                    Column(Modifier.weight(1f)) {
                        Text(
                            "${payer?.name ?: "Someone"} paid you ${Money.format(settlement.amount, settlement.currencyCode)}",
                            fontSize = 13.5.sp, fontWeight = FontWeight.SemiBold, color = Brand.ink, maxLines = 2,
                        )
                        Text("${trip.title} · ${settlement.method.label}", fontSize = 11.5.sp, color = Brand.inkTertiary, maxLines = 1)
                    }
                    Spacer(Modifier.width(6.dp))
                    Text(
                        "Review",
                        Modifier.clip(CircleShape).background(Brand.cta).padding(horizontal = 11.dp, vertical = 6.dp),
                        fontSize = 12.5.sp, fontWeight = FontWeight.SemiBold, color = Color.White,
                    )
                }
            }
        }
    }
}

// MARK: Top bar

/** A round white button — the bell, and anything else that floats over the canvas. */
@Composable
fun CircleButton(icon: ImageVector, description: String, badge: Int = 0, onClick: () -> Unit) {
    Box {
        Box(
            Modifier.size(45.dp).clip(CircleShape).background(Brand.card)
                .border(0.5.dp, Brand.hairline, CircleShape).pressable(onClick),
            contentAlignment = Alignment.Center,
        ) { Icon(icon, contentDescription = description, tint = Brand.ink, modifier = Modifier.size(21.dp)) }
        if (badge > 0) {
            Box(
                Modifier.align(Alignment.TopEnd).size(18.dp).clip(CircleShape).background(Brand.danger)
                    .border(1.5.dp, Brand.canvasTop, CircleShape),
                contentAlignment = Alignment.Center,
            ) {
                Text(
                    if (badge > 9) "9+" else "$badge",
                    style = TextStyle(fontFamily = Rounded, fontWeight = FontWeight.Bold, fontSize = 10.sp, color = Color.White),
                )
            }
        }
    }
}

/** Your face with a dashed ring — "this is yours to change". */
@Composable
fun ProfileButton(me: Traveller?, onClick: () -> Unit) {
    Box(
        Modifier.size(45.dp).pressable(onClick).drawBehind {
            drawCircle(
                Brand.accent.copy(alpha = 0.6f),
                style = Stroke(1.5.dp.toPx(), pathEffect = PathEffect.dashPathEffect(floatArrayOf(4.5.dp.toPx(), 3.5.dp.toPx()))),
                radius = size.minDimension / 2 - 0.75.dp.toPx(),
            )
        },
        contentAlignment = Alignment.Center,
    ) {
        if (me != null) Avatar(me, 38.dp)
        else Box(Modifier.size(38.dp).clip(CircleShape).background(MaterialTheme.colorScheme.surfaceContainerHigh))
    }
}
