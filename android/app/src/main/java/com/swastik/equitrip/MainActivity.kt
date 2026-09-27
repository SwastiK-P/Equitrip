package com.swastik.equitrip

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.SystemBarStyle
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.activity.viewModels
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.toArgb
import com.swastik.equitrip.ui.AuthScreen
import com.swastik.equitrip.ui.RootScreen
import com.swastik.equitrip.ui.theme.EquitripTheme

/** Routes signed out → `AuthScreen`, signed in → the tabs. Light system bars only, as on iOS. */
class MainActivity : ComponentActivity() {
    private val vm: AppViewModel by viewModels()

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val transparent = Color.Transparent.toArgb()
        enableEdgeToEdge(
            statusBarStyle = SystemBarStyle.light(transparent, transparent),
            navigationBarStyle = SystemBarStyle.light(transparent, transparent),
        )
        setContent {
            EquitripTheme {
                if (vm.signedIn) RootScreen(vm) else AuthScreen(vm)
            }
        }
    }
}
