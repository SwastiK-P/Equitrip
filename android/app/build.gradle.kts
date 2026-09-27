import java.util.Properties

plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.plugin.compose")
    id("org.jetbrains.kotlin.plugin.serialization")
}

// The Supabase project is the one the iOS app ships with. Rather than copying its URL and
// publishable key into a second file that can drift (and that CLAUDE.md forbids), the build
// reads them out of the Swift source. `local.properties` can override either for another project.
val supabase: Pair<String, String> = run {
    val local = Properties().apply {
        rootProject.file("local.properties").takeIf { it.exists() }?.inputStream()?.use(::load)
    }
    val swift = rootProject.file("../Equitrip/Services/SupabaseConfig.swift")
        .takeIf { it.exists() }?.readText().orEmpty()
    fun fromSwift(name: String) =
        Regex("""static let $name\s*=\s*(?:URL\(string:\s*)?"([^"]+)"""").find(swift)?.groupValues?.get(1)
    val url = local.getProperty("supabase.url") ?: fromSwift("url") ?: ""
    val key = local.getProperty("supabase.key") ?: fromSwift("publishableKey") ?: ""
    url to key
}

val groqDebugKey: String = Properties().apply {
    rootProject.file("local.properties").takeIf { it.exists() }?.inputStream()?.use(::load)
}.getProperty("groq.key").orEmpty()

android {
    namespace = "com.swastik.equitrip"
    compileSdk = 37

    defaultConfig {
        applicationId = "com.swastik.equitrip"
        minSdk = 26
        targetSdk = 37
        versionCode = 1
        versionName = "0.1"
        buildConfigField("String", "SUPABASE_URL", "\"${supabase.first}\"")
        buildConfigField("String", "SUPABASE_KEY", "\"${supabase.second}\"")
    }

    buildTypes {
        // Equi reaches Groq through the `equi-chat` Edge Function, which holds the key. A debug
        // build may carry `groq.key` from local.properties to test before that's deployed;
        // a release build never carries one.
        debug {
            buildConfigField("String", "GROQ_KEY", "\"${groqDebugKey}\"")
        }
        release {
            isMinifyEnabled = false
            buildConfigField("String", "GROQ_KEY", "\"\"")
        }
    }
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    buildFeatures {
        compose = true
        buildConfig = true
    }
}

dependencies {
    val composeBom = platform("androidx.compose:compose-bom:2026.09.00")
    implementation(composeBom)
    implementation("androidx.compose.material3:material3")
    implementation("androidx.compose.material:material-icons-extended")
    implementation("androidx.compose.ui:ui")
    implementation("androidx.compose.ui:ui-tooling-preview")
    debugImplementation("androidx.compose.ui:ui-tooling")

    implementation("androidx.core:core-ktx:1.19.1")
    implementation("androidx.activity:activity-compose:1.13.0")
    implementation("androidx.lifecycle:lifecycle-viewmodel-compose:2.11.0")
    implementation("androidx.lifecycle:lifecycle-runtime-compose:2.11.0")

    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.11.0")
    implementation("org.jetbrains.kotlinx:kotlinx-serialization-json:1.11.0")
    implementation("com.squareup.okhttp3:okhttp:5.5.0")
    implementation("io.coil-kt.coil3:coil-compose:3.6.3")
    implementation("io.coil-kt.coil3:coil-network-okhttp:3.6.3")
    // Booking PDF → text for the Nugen import (the platform can only render pages).
    implementation("com.tom-roush:pdfbox-android:2.0.27.0")
}
