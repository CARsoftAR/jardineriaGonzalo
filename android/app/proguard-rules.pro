# ProGuard / R8 Rules para Jardinería Gonzalo y flutter_local_notifications

# Preservar atributos de firma genérica para deserialización Gson / TypeToken (CRÍTICO)
-keepattributes *Annotation*,Signature,InnerClasses,EnclosingMethod

# flutter_local_notifications
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-keepclassmembers class com.dexterous.flutterlocalnotifications.** { *; }
-dontwarn com.dexterous.flutterlocalnotifications.**

# Gson y TypeTokens
-keep class com.google.gson.** { *; }
-keepclassmembers class com.google.gson.** { *; }
-keep class * extends com.google.gson.TypeToken
-keepclassmembers class * extends com.google.gson.TypeToken { *; }

# Anotaciones Keep de AndroidX
-keepclassmembers class * {
    @androidx.annotation.Keep <fields>;
    @androidx.annotation.Keep <methods>;
}

# Flutter Timezone y Time4J
-keep class net.time4j.** { *; }
-dontwarn net.time4j.**

# SQLite & sqflite
-keep class com.tekartik.sqflite.** { *; }
-keepclassmembers class com.tekartik.sqflite.** { *; }
-dontwarn com.tekartik.sqflite.**

# Core Flutter & Plugins
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.plugins.**
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
