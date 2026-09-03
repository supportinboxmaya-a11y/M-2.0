# ProGuard rules for MayaApp

# Keep the application class
-keep class com.maya.app.MayaApplication { *; }

# Keep model classes for Gson serialization
-keep class com.maya.app.model.** { *; }

# Keep API interfaces for Retrofit
-keep class com.maya.app.api.MayaApi { *; }

# Keep AuthManager for singleton access
-keep class com.maya.app.api.AuthManager { *; }

# Keep ApiClient for singleton access
-keep class com.maya.app.api.ApiClient { *; }

# Keep ViewModels
-keep class com.maya.app.ui.AppViewModel { *; }

# Keep Room entities (if using Room in future)
# -keep class com.maya.app.db.** { *; }

# Keep WorkManager workers
-keep class * extends androidx.work.Worker { *; }

# OkHttp and Retrofit
-dontwarn okhttp3.**
-dontwarn retrofit2.**
-keep class okhttp3.** { *; }
-keep class retrofit2.** { *; }

# Gson
-dontwarn com.google.gson.**
-keep class com.google.gson.** { *; }

# Kotlinx Coroutines
-dontwarn kotlinx.coroutines.**
-keep class kotlinx.coroutines.** { *; }

# Kotlinx Serialization
-dontwarn kotlinx.serialization.**
-keep class kotlinx.serialization.** { *; }

# Coil
-dontwarn coil3.**
-dontwarn io.coil-kt.**
-keep class coil3.** { *; }
-keep class io.coil-kt.** { *; }

# AndroidX Compose
-dontwarn androidx.compose.**
-keep class androidx.compose.** { *; }

# Material
-dontwarn com.google.android.material.**
-keep class com.google.android.material.** { *; }

# Keep Parcelable implementations
-keep class * implements android.os.Parcelable { *; }

# Keep enum values
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep setters in Views so that animations can still work
-keepclassmembers public class * extends android.view.View {
    void set*(***);
    *** get*();
}

# Remove logging in release builds
-assumenosideeffects class android.util.Log {
    public static *** d(...);
    public static *** v(...);
    public static *** i(...);
}