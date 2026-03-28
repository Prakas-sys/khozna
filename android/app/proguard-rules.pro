# Flutter Wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }
# Firebase Messaging
-keep class com.google.firebase.messaging.** { *; }
-keep public class com.google.firebase.messaging.FirebaseMessagingService
-dontwarn com.google.firebase.messaging.**
-dontwarn com.google.firebase.**

# Firebase Common
-keep class com.google.firebase.** { *; }

# Google Play Services
-keep class com.google.android.gms.** { *; }

# Google Play Core
-keep class com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**

# Flutter Plugins that use reflection or background services
-keep class io.flutter.plugins.** { *; }
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-keep class com.sidlatau.safe_device.** { *; }

# Kotlin Coroutines (R8 sometimes strips these)
-keep class kotlinx.coroutines.** { *; }
-keep class kotlin.coroutines.** { *; }

# Standard Android
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes EnclosingMethod
-keepattributes InnerClasses

# Do not optimize/shrink Flutter's entry point
-keep class com.khozna.khozna.MainActivity { *; }

# Prevent R8 from removing View constructors needed by XML inflation
-keepclassmembers class * extends android.view.View { 
   <init>(android.content.Context, android.util.AttributeSet); 
   <init>(android.content.Context, android.util.AttributeSet, int); 
}

# Prevent R8 from breaking Enum.values()
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# Handle Parcelable correctly
-keep class * implements android.os.Parcelable {
  public static final android.os.Parcelable$Creator *;
}
