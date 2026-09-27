package com.swastik.equitrip.ui.equi

import androidx.compose.animation.AnimatedContent
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.animateColorAsState
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.spring
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.scaleIn
import androidx.compose.animation.scaleOut
import androidx.compose.animation.slideInVertically
import androidx.compose.animation.slideOutVertically
import androidx.compose.animation.togetherWith
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.interaction.collectIsFocusedAsState
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.asPaddingValues
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.ime
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBars
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.AddComment
import androidx.compose.material.icons.filled.ArrowUpward
import androidx.compose.material.icons.filled.Stop
import androidx.compose.material.icons.outlined.Backpack
import androidx.compose.material.icons.outlined.Bed
import androidx.compose.material.icons.outlined.CalendarMonth
import androidx.compose.material.icons.outlined.Checklist
import androidx.compose.material.icons.outlined.DirectionsWalk
import androidx.compose.material.icons.outlined.EventBusy
import androidx.compose.material.icons.outlined.FlightLand
import androidx.compose.material.icons.outlined.Group
import androidx.compose.material.icons.outlined.Map
import androidx.compose.material.icons.outlined.PieChart
import androidx.compose.material.icons.outlined.Restaurant
import androidx.compose.material.icons.outlined.SwapHoriz
import androidx.compose.material.icons.outlined.WbSunny
import androidx.compose.material.icons.outlined.Wallet
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.derivedStateOf
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.scale
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.SpanStyle
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.buildAnnotatedString
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.withStyle
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.swastik.equitrip.AppViewModel
import com.swastik.equitrip.equi.EquiMessage
import com.swastik.equitrip.equi.EquiSource
import com.swastik.equitrip.ui.components.LocalBottomBarInset
import com.swastik.equitrip.ui.components.TopFade
import com.swastik.equitrip.ui.components.pressable
import com.swastik.equitrip.ui.home.CircleButton
import com.swastik.equitrip.ui.theme.Brand
import com.swastik.equitrip.ui.theme.Rounded

private val LANES: List<List<Pair<ImageVector, String>>> = listOf(
    listOf(
        Icons.Outlined.Bed to "Where am I staying?",
        Icons.Outlined.Backpack to "What should I pack?",
        Icons.Outlined.FlightLand to "When do I land?",
        Icons.Outlined.EventBusy to "Any gaps in the plan?",
        Icons.Outlined.CalendarMonth to "What's up next?",
    ),
    listOf(
        Icons.Outlined.Wallet to "Am I over budget?",
        Icons.Outlined.SwapHoriz to "What do I owe?",
        Icons.Outlined.PieChart to "Where's the money going?",
        Icons.Outlined.Group to "Who paid the most?",
        Icons.Outlined.Restaurant to "How much on food so far?",
    ),
    listOf(
        Icons.Outlined.Map to "How's it going so far?",
        Icons.Outlined.WbSunny to "What's the weather like?",
        @Suppress("DEPRECATION") Icons.Outlined.DirectionsWalk to "What's worth seeing?",
        Icons.Outlined.Checklist to "What's still unbooked?",
    ),
)

/**
 * Equi's tab on Android — iOS `EquiAssistantView` on a phone: a drifting wall of starter
 * questions, then a thread with Equi's face and yours in the gutter, a typing bubble while
 * a reply is coming, and follow-ups under the newest answer.
 */
@Composable
fun EquiScreen(vm: AppViewModel) {
    val chat = vm.equi
    var draft by rememberSaveable { mutableStateOf("") }
    val list = rememberLazyListState()
    val scrolled by remember { derivedStateOf { list.firstVisibleItemIndex > 0 || list.firstVisibleItemScrollOffset > 0 } }
    val top = WindowInsets.statusBars.asPaddingValues().calculateTopPadding()
    val ime = WindowInsets.ime.asPaddingValues().calculateBottomPadding()
    val bottom = maxOf(LocalBottomBarInset.current, ime)
    val composerFocus = remember { MutableInteractionSource() }
    val focused by composerFocus.collectIsFocusedAsState()
    // Bubbles pop in once, when they arrive — not again when scrolled back into view.
    val seen = remember { mutableSetOf<String>().apply { chat.messages.forEach { add(it.id) } } }

    val send = { text: String ->
        if (!chat.busy && text.isNotBlank()) {
            chat.ask(text, vm.currentTrips, vm.myId)
            draft = ""
        }
    }

    val lastText = chat.messages.lastOrNull()?.text?.length
    LaunchedEffect(chat.messages.size, lastText, chat.thinking) {
        val count = list.layoutInfo.totalItemsCount
        if (count > 0) list.animateScrollToItem(count - 1, scrollOffset = Int.MAX_VALUE / 2)
    }

    Box(Modifier.fillMaxSize()) {
        EquiAurora(chat.busy)
        Column(Modifier.fillMaxSize()) {
            Header(thinking = chat.busy, canReset = chat.messages.isNotEmpty(), top = top) { chat.clear(); seen.clear() }

            Box(Modifier.weight(1f).fillMaxWidth()) {
                if (chat.messages.isEmpty() && !chat.busy) {
                    EmptyState(compact = focused || ime > 0.dp, onPick = send)
                } else {
                    LazyColumn(
                        Modifier.fillMaxSize(),
                        state = list,
                        contentPadding = PaddingValues(start = 14.dp, end = 14.dp, top = 12.dp, bottom = 16.dp),
                    ) {
                        itemsIndexed(chat.messages, key = { _, m -> m.id }) { index, message ->
                            val next = chat.messages.getOrNull(index + 1)
                            val lastInGroup = next == null || next.isUser != message.isUser
                            val sameAsPrevious = chat.messages.getOrNull(index - 1)?.isUser == message.isUser
                            val fresh = seen.add(message.id)
                            Box(Modifier.padding(top = if (index == 0) 0.dp else if (sameAsPrevious) 4.dp else 14.dp)) {
                                when (message.source) {
                                    EquiSource.USER -> UserRow(message, vm, lastInGroup, fresh)
                                    EquiSource.CONSENT -> ConsentRow(
                                        fresh,
                                        onAllow = { chat.resolveConsent(message, true, vm.currentTrips, vm.myId) },
                                        onDecline = { chat.resolveConsent(message, false, vm.currentTrips, vm.myId) },
                                        text = message.text,
                                    )
                                    EquiSource.EQUI -> if (message.text.isNotEmpty()) EquiRow(
                                        message, lastInGroup, fresh,
                                        showSuggestions = index == chat.messages.lastIndex && !chat.busy,
                                        onAsk = send,
                                    )
                                }
                            }
                        }
                        if (chat.thinking) item(key = "typing") {
                            Box(Modifier.padding(top = 14.dp).bubbleEntrance(animate = true, fromEnd = false)) { TypingBubble() }
                        }
                    }
                    TopFade(scrolled)
                }
            }

            Composer(
                draft, { draft = it },
                busy = chat.busy,
                focus = composerFocus,
                onSend = { send(draft) },
                onStop = chat::stop,
                modifier = Modifier.padding(start = 14.dp, end = 14.dp, top = 6.dp, bottom = bottom + 10.dp),
            )
        }
    }
}

@Composable
private fun Header(thinking: Boolean, canReset: Boolean, top: androidx.compose.ui.unit.Dp, onReset: () -> Unit) {
    Box(Modifier.fillMaxWidth().padding(start = 16.dp, end = 16.dp, top = top + 6.dp, bottom = 6.dp)) {
        Row(
            Modifier.align(Alignment.Center).shadow(10.dp, RoundedCornerShape(22.dp), ambientColor = Brand.shadow, spotColor = Brand.shadow)
                .clip(RoundedCornerShape(22.dp)).background(Brand.card.copy(alpha = 0.92f))
                .border(0.5.dp, Brand.hairline, RoundedCornerShape(22.dp))
                .padding(start = 8.dp, end = 18.dp, top = 7.dp, bottom = 7.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            EquiOrb(30.dp, thinking = thinking)
            Spacer(Modifier.width(10.dp))
            Column {
                Text("Equi", style = TextStyle(fontFamily = Rounded, fontWeight = FontWeight.Bold, fontSize = 16.sp, color = Brand.ink))
                AnimatedContent(
                    thinking,
                    transitionSpec = { (fadeIn() + slideInVertically { it / 2 }) togetherWith (fadeOut() + slideOutVertically { -it / 2 }) },
                    label = "status",
                ) { busy ->
                    Text(if (busy) "Thinking…" else "Your trip assistant", fontSize = 11.5.sp, fontWeight = FontWeight.Medium, color = Brand.inkTertiary)
                }
            }
        }
        AnimatedVisibility(
            canReset,
            Modifier.align(Alignment.CenterEnd),
            enter = scaleIn(initialScale = 0.6f) + fadeIn(),
            exit = scaleOut(targetScale = 0.6f) + fadeOut(),
        ) {
            CircleButton(Icons.Outlined.AddComment, "New conversation", onClick = onReset)
        }
    }
}

@Composable
private fun EmptyState(compact: Boolean, onPick: (String) -> Unit) {
    Column(
        Modifier.fillMaxSize(),
        verticalArrangement = Arrangement.Center,
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        EquiOrb(if (compact) 56.dp else 76.dp, modifier = Modifier.bubbleEntrance(animate = true, fromEnd = false))
        Spacer(Modifier.size(18.dp))
        Text(
            buildAnnotatedString {
                append("Ask ")
                withStyle(SpanStyle(color = Brand.accent)) { append("Equi") }
                append(" anything")
            },
            Modifier.bubbleEntrance(animate = true, fromEnd = false),
            fontSize = 30.sp, fontWeight = FontWeight.SemiBold, color = Brand.ink, letterSpacing = (-0.5).sp,
        )
        Spacer(Modifier.size(6.dp))
        Text(
            "About the plan, the money, or what's next.",
            fontSize = 14.sp, color = Brand.inkTertiary, textAlign = TextAlign.Center,
        )
        AnimatedVisibility(!compact, enter = fadeIn() + slideInVertically { it / 6 }, exit = fadeOut() + slideOutVertically { it / 6 }) {
            Column(Modifier.padding(top = 36.dp), verticalArrangement = Arrangement.spacedBy(10.dp)) {
                LANES.forEachIndexed { i, lane ->
                    // Each lane at its own pace and the middle one the other way, so the wall
                    // never reads as one block sliding sideways.
                    PromptLane(lane, speed = listOf(-14f, 11f, -9f)[i], start = listOf(0f, 0.35f, 0.7f)[i], onPick = onPick)
                }
            }
        }
    }
}

@Composable
private fun UserRow(message: EquiMessage, vm: AppViewModel, lastInGroup: Boolean, fresh: Boolean) {
    Row(
        Modifier.fillMaxWidth().bubbleEntrance(fresh, fromEnd = true),
        horizontalArrangement = Arrangement.End,
        verticalAlignment = Alignment.Bottom,
    ) {
        Spacer(Modifier.width(48.dp))
        Text(
            message.text,
            Modifier.weight(1f, fill = false)
                .shadow(8.dp, bubbleShape(mine = true, tail = lastInGroup), ambientColor = Brand.accent.copy(alpha = 0.3f), spotColor = Brand.accent.copy(alpha = 0.3f))
                .clip(bubbleShape(mine = true, tail = lastInGroup))
                .background(Brush.verticalGradient(listOf(Brand.accent, Brand.accentDeep)))
                .padding(horizontal = 14.dp, vertical = 10.dp),
            color = Color.White, fontSize = 15.5.sp, lineHeight = 21.sp,
        )
        Spacer(Modifier.width(8.dp))
        if (lastInGroup) MeAvatar(vm.me, 26.dp) else Spacer(Modifier.size(26.dp))
    }
}

@Composable
private fun EquiRow(message: EquiMessage, lastInGroup: Boolean, fresh: Boolean, showSuggestions: Boolean, onAsk: (String) -> Unit) {
    Column(Modifier.fillMaxWidth().bubbleEntrance(fresh, fromEnd = false)) {
        Row(verticalAlignment = Alignment.Bottom) {
            if (lastInGroup) EquiOrb(26.dp) else Spacer(Modifier.size(26.dp))
            Spacer(Modifier.width(8.dp))
            EquiReplyText(
                message.text,
                Modifier.widthIn(max = 310.dp)
                    .shadow(6.dp, bubbleShape(mine = false, tail = lastInGroup), ambientColor = Brand.shadow, spotColor = Brand.shadow)
                    .clip(bubbleShape(mine = false, tail = lastInGroup))
                    .background(Brand.card)
                    .border(0.5.dp, Brand.hairline, bubbleShape(mine = false, tail = lastInGroup))
                    .padding(horizontal = 14.dp, vertical = 11.dp),
            )
            Spacer(Modifier.width(40.dp))
        }
        AnimatedVisibility(
            showSuggestions && message.suggestions.isNotEmpty(),
            enter = fadeIn() + slideInVertically { it / 2 },
            exit = fadeOut(),
        ) {
            Row(
                Modifier.padding(top = 10.dp).horizontalScroll(rememberScrollState()).padding(start = 34.dp),
                horizontalArrangement = Arrangement.spacedBy(8.dp),
            ) {
                message.suggestions.forEach { suggestion ->
                    Text(
                        suggestion,
                        Modifier.clip(CircleShape).background(Brand.accent.copy(alpha = 0.08f))
                            .border(0.5.dp, Brand.accent.copy(alpha = 0.22f), CircleShape)
                            .pressable { onAsk(suggestion) }.padding(horizontal = 13.dp, vertical = 8.dp),
                        color = Brand.accentDeep, fontSize = 13.5.sp, fontWeight = FontWeight.Medium, maxLines = 1,
                    )
                }
            }
        }
    }
}

@Composable
private fun ConsentRow(fresh: Boolean, onAllow: () -> Unit, onDecline: () -> Unit, text: String) {
    Row(Modifier.fillMaxWidth().bubbleEntrance(fresh, fromEnd = false), verticalAlignment = Alignment.Bottom) {
        EquiOrb(26.dp)
        Spacer(Modifier.width(8.dp))
        Column(
            Modifier.widthIn(max = 310.dp)
                .shadow(6.dp, bubbleShape(mine = false, tail = true), ambientColor = Brand.shadow, spotColor = Brand.shadow)
                .clip(bubbleShape(mine = false, tail = true)).background(Brand.card)
                .border(0.5.dp, Brand.hairline, bubbleShape(mine = false, tail = true))
                .padding(14.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            Text(text, color = Brand.ink, fontSize = 15.sp, lineHeight = 21.sp)
            Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                Chip("Ask Groq", filled = true, onClick = onAllow)
                Chip("Not now", filled = false, onClick = onDecline)
            }
        }
    }
}

@Composable
private fun Chip(label: String, filled: Boolean, onClick: () -> Unit) {
    Text(
        label,
        Modifier.clip(CircleShape).background(if (filled) Brand.accent else Brand.ink.copy(alpha = 0.05f))
            .pressable(onClick).padding(horizontal = 15.dp, vertical = 8.dp),
        color = if (filled) Color.White else Brand.ink, fontSize = 13.5.sp, fontWeight = FontWeight.SemiBold,
    )
}

@Composable
private fun Composer(
    text: String,
    onChange: (String) -> Unit,
    busy: Boolean,
    focus: MutableInteractionSource,
    onSend: () -> Unit,
    onStop: () -> Unit,
    modifier: Modifier,
) {
    val shape = RoundedCornerShape(26.dp)
    val ready = busy || text.isNotBlank()
    val tint by animateColorAsState(if (ready) Brand.accent else Brand.ink.copy(alpha = 0.10f), label = "send")
    val pop by animateFloatAsState(if (ready) 1f else 0.86f, spring(dampingRatio = 0.5f, stiffness = 500f), label = "pop")
    Row(
        modifier.fillMaxWidth()
            .shadow(12.dp, shape, ambientColor = Brand.shadow, spotColor = Brand.shadow)
            .clip(shape).background(Brand.card).border(0.5.dp, Brand.hairline, shape)
            .padding(start = 18.dp, end = 6.dp, top = 6.dp, bottom = 6.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Box(Modifier.weight(1f).padding(vertical = 8.dp)) {
            if (text.isEmpty()) Text("Ask Equi about your trips", color = Brand.inkTertiary, fontSize = 15.5.sp)
            BasicTextField(
                value = text,
                onValueChange = onChange,
                modifier = Modifier.fillMaxWidth(),
                textStyle = TextStyle(color = Brand.ink, fontSize = 15.5.sp, lineHeight = 21.sp),
                cursorBrush = SolidColor(Brand.accent),
                maxLines = 4,
                interactionSource = focus,
                keyboardOptions = KeyboardOptions(imeAction = ImeAction.Send),
                keyboardActions = KeyboardActions(onSend = { onSend() }),
            )
        }
        Spacer(Modifier.width(8.dp))
        Box(
            Modifier.size(40.dp).scale(pop).clip(CircleShape).background(tint)
                .pressable { if (busy) onStop() else onSend() },
            contentAlignment = Alignment.Center,
        ) {
            AnimatedContent(
                busy,
                transitionSpec = { (scaleIn(initialScale = 0.5f) + fadeIn()) togetherWith (scaleOut(targetScale = 0.5f) + fadeOut()) },
                label = "sendIcon",
            ) { stopping ->
                Icon(
                    if (stopping) Icons.Filled.Stop else Icons.Filled.ArrowUpward,
                    if (stopping) "Stop" else "Send",
                    tint = if (ready) Color.White else Brand.inkTertiary,
                    modifier = Modifier.size(if (stopping) 16.dp else 20.dp),
                )
            }
        }
    }
}
