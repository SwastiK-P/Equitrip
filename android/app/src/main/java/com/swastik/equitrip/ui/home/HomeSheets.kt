package com.swastik.equitrip.ui.home

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.Logout
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.FilledTonalButton
import androidx.compose.material3.Icon
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.rememberModalBottomSheetState
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.swastik.equitrip.AppViewModel
import com.swastik.equitrip.model.AppNotification
import com.swastik.equitrip.ui.components.Avatar
import com.swastik.equitrip.ui.components.Hairline
import com.swastik.equitrip.ui.components.SectionHeader
import com.swastik.equitrip.ui.components.SurfaceCard
import com.swastik.equitrip.ui.theme.Brand
import com.swastik.equitrip.ui.theme.figure

/** What the bell opens: new first, then everything earlier. Opening one marks it read. */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun NotificationsSheet(vm: AppViewModel, onDismiss: () -> Unit) {
    val unread = vm.notifications.filter { it.isUnread }
    val read = vm.notifications.filter { !it.isUnread }
    ModalBottomSheet(
        onDismissRequest = onDismiss,
        sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true),
        containerColor = Brand.canvasTop,
    ) {
        Row(Modifier.fillMaxWidth().padding(horizontal = 20.dp), verticalAlignment = Alignment.CenterVertically) {
            Text("Notifications", fontSize = 24.sp, fontWeight = FontWeight.Bold, color = Brand.ink, modifier = Modifier.weight(1f))
            if (unread.isNotEmpty()) TextButton(onClick = { vm.markAllRead() }) { Text("Mark all read") }
        }
        LazyColumn(
            Modifier.fillMaxWidth(),
            contentPadding = androidx.compose.foundation.layout.PaddingValues(20.dp),
            verticalArrangement = Arrangement.spacedBy(20.dp),
        ) {
            if (vm.notifications.isEmpty()) item {
                Text(
                    "You're all caught up. Payments, bookings and people joining show up here.",
                    fontSize = 14.sp, color = Brand.inkSecondary,
                )
            }
            if (unread.isNotEmpty()) item { Group("New", unread, vm) }
            if (read.isNotEmpty()) item { Group("Earlier", read, vm) }
        }
    }
}

@Composable
private fun Group(title: String, items: List<AppNotification>, vm: AppViewModel) {
    Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
        SectionHeader(title)
        SurfaceCard(elevation = 4.dp) {
            items.forEachIndexed { index, item ->
                if (index > 0) Hairline()
                ActivityRow(item) { vm.markRead(item) }
            }
        }
    }
}

/** Who you're signed in as, and the way out. */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ProfileSheet(vm: AppViewModel, onDismiss: () -> Unit) {
    ModalBottomSheet(onDismissRequest = onDismiss, containerColor = Brand.canvasTop) {
        Column(
            Modifier.fillMaxWidth().padding(horizontal = 24.dp).navigationBarsPadding().padding(bottom = 16.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(6.dp),
        ) {
            vm.me?.let { Avatar(it, 88.dp) }
            Spacer(Modifier.height(6.dp))
            Text(vm.myName ?: "Traveller", style = figure(24.sp), color = Brand.ink)
            vm.myEmail?.let { Text(it, fontSize = 14.sp, color = Brand.inkSecondary) }
            vm.me?.upiId?.let { Text("UPI · $it", fontSize = 13.sp, color = Brand.inkTertiary) }
            Spacer(Modifier.height(18.dp))
            FilledTonalButton(
                onClick = { onDismiss(); vm.signOut() },
                modifier = Modifier.fillMaxWidth().height(50.dp),
                shape = RoundedCornerShape(25.dp),
                colors = ButtonDefaults.filledTonalButtonColors(
                    containerColor = Brand.danger.copy(alpha = 0.10f), contentColor = Brand.danger,
                ),
            ) {
                Icon(Icons.AutoMirrored.Filled.Logout, contentDescription = null)
                Spacer(Modifier.padding(4.dp))
                Text("Sign out", fontWeight = FontWeight.SemiBold)
            }
        }
    }
}
