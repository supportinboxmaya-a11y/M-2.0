plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("kotlin-parcelize")
}

android {
    namespace = "com.maya.app"
    compileSdk = 34

    defaultConfig {
        applicationId = "com.maya.app"
        minSdk = 24
        targetSdk = 34
        versionCode = 1
        versionName = "1.0.0"
        vectorDrawables.useSupportLibrary = true
    }

    signingConfigs {
        create("release") {
            storeFile = file("../keystore/maya-release.keystore")
            storePassword = System.getenv("KEYSTORE_PASSWORD") ?: "maya2024release"
            keyAlias = "maya-release"
            keyPassword = System.getenv("KEY_PASSWORD") ?: "maya2024release"
        }
    }

    buildTypes {
        release {
            isMinifyEnabled = false
            signingConfig = signingConfigs.getByName("release")
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
    }

    kotlinOptions {
        jvmTarget = "1.8"
        freeCompilerArgs += listOf("-Xopt-in=kotlin.RequiresOptIn")
    }

    buildFeatures {
        compose = true
        viewBinding = true
    }

    composeOptions {
        kotlinCompilerExtensionVersion = "1.5.10"
    }

    packagingOptions {
        resources {
            excludes += "/META-INF/{AL2.0,LGPL2.1,LICENSE,NOTICE}"
        }
    }
}

dependencies {
    val kotlin_version: String by extra("1.9.22")
    val compose_version: String by extra("1.5.10")
    val activity_version: String by extra("1.8.2")
    val lifecycle_version: String by extra("2.7.0")
    val navigation_version: String by extra("2.7.6")
    val retrofit_version: String by extra("2.11.0")
    val okhttp_version: String by extra("4.12.0")
    val coroutines_version: String by extra("1.7.3")
    val coil_version: String by extra("2.6.0")
    val material_version: String by extra("1.11.0")
    val core_ktx_version: String by extra("1.12.0")
    val fragment_version: String by extra("1.6.2")
    val constraint_layout_version: String by extra("2.1.4")

    // Core Android
    implementation("androidx.core:core-ktx:$core_ktx_version")
    implementation("androidx.lifecycle:lifecycle-runtime-ktx:$lifecycle_version")
    implementation("androidx.lifecycle:lifecycle-livedata-ktx:$lifecycle_version")
    implementation("androidx.lifecycle:lifecycle-livedata-compose:$lifecycle_version")
    implementation("androidx.lifecycle:lifecycle-viewmodel-compose:$lifecycle_version")
    implementation("androidx.activity:activity-compose:$activity_version")
    implementation("androidx.fragment:fragment-ktx:$fragment_version")
    implementation("androidx.constraintlayout:constraintlayout-compose:1.0.1")

    // Material Components (for XML theming)
    implementation("com.google.android.material:material:$material_version")

    // Material 2 for Compose (from Compose BOM)
    // Material 3 removed - was causing Theme.Material3.DayNight.NoActionBar resource conflict

    // Compose BOM
    implementation(platform("androidx.compose:compose-bom:2023.10.01"))
    implementation("androidx.compose.ui:ui")
    implementation("androidx.compose.ui:ui-graphics")
    implementation("androidx.compose.ui:ui-tooling-preview")
    implementation("androidx.compose.foundation:foundation")
    implementation("androidx.compose.material:material")
    implementation("androidx.compose.runtime:runtime")
    implementation("androidx.compose.animation:animation")
    implementation("androidx.compose.ui:ui-tooling")

    // Navigation
    implementation("androidx.navigation:navigation-compose:$navigation_version")

    // Coroutines
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:$coroutines_version")
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-core:$coroutines_version")

    // Retrofit & OkHttp
    implementation("com.squareup.retrofit2:retrofit:$retrofit_version")
    implementation("com.squareup.retrofit2:converter-gson:$retrofit_version")
    implementation("com.squareup.okhttp3:okhttp:$okhttp_version")
    implementation("com.squareup.okhttp3:logging-interceptor:$okhttp_version")

    // Gson
    implementation("com.google.code.gson:gson:2.10.1")

    // Coil for images
    implementation("io.coil-kt:coil-compose:$coil_version")

    // Serialization
    implementation("org.jetbrains.kotlinx:kotlinx-serialization-json:1.6.0")

    // WorkManager
    implementation("androidx.work:work-runtime-ktx:2.9.0")

    // Testing
    testImplementation("junit:junit:4.13.2")
    androidTestImplementation("androidx.test.ext:junit:1.1.5")
    androidTestImplementation("androidx.test.espresso:espresso-core:3.5.1")
    androidTestImplementation("androidx.compose.ui:ui-test-junit4:1.5.10")
    debugImplementation("androidx.compose.ui:ui-tooling:1.5.10")
    debugImplementation("androidx.compose.ui:ui-test-manifest:1.5.10")
}
