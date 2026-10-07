# R8 rules for the release build.
#
# Flutter's own engine and plugin entry points are reached from native code,
# so R8 cannot see those references and would otherwise strip them.
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**

# flutter_local_notifications keeps its scheduled-notification types through
# Gson, which reads them reflectively.
-keep class com.dexterous.** { *; }
-dontwarn com.dexterous.**

# Firebase Cloud Messaging.
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**

# Strip Android logging from the release binary: anything a stray Log.d might
# print about a request can never reach logcat on a student's phone.
-assumenosideeffects class android.util.Log {
    public static *** d(...);
    public static *** v(...);
    public static *** i(...);
}
