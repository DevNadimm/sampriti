# Flutter Engine Rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Play Core (Deferred Components in Flutter Engine)
-dontwarn com.google.android.play.core.**

# Google & Firebase
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes SourceFile,LineNumberTable
-dontwarn com.google.android.gms.**
-keep class com.google.firebase.** { *; }

# Desugaring
-dontwarn java.lang.invoke.**
-dontwarn java.time.**
