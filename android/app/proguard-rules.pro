# Add project specific ProGuard rules here.
# You can control the set of applied configuration files using the
# proguardFiles setting in build.gradle.
#
# For more details, see
#   http://developer.android.com/guide/developing/tools/proguard.html

# If your project uses WebView with JS, uncomment the following
# and specify the fully qualified class name to the JavaScript interface
# class:
#-keepclassmembers class fqcn.of.javascript.interface.for.webview {
#   public *;
#}

# Uncomment this to preserve the line number information for
# debugging stack traces.
#-keepattributes SourceFile,LineNumberTable

# If you keep the line number information, uncomment this to
# hide the original source file name.
#-renamesourcefileattribute SourceFile

# Flutter specific rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Keep native methods
-keepclassmembers class * {
    native <methods>;
}

# Keep Parcelable classes
-keep class * implements android.os.Parcelable {
  public static final android.os.Parcelable$Creator *;
}

# Keep Serializable classes
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

# Keep R classes
-keep class **.R$* {
    public static <fields>;
}

# Keep native libraries
-keep class com.google.android.gms.** { *; }
-keep class com.google.firebase.** { *; }

# Keep Supabase classes
-keep class io.supabase.** { *; }

# Keep image picker classes
-keep class com.github.dhaval2404.imagepicker.** { *; }

# Keep permission handler
-keep class com.baseflow.permissionhandler.** { *; }

# Keep geolocator
-keep class com.baseflow.geolocator.** { *; }

# Keep cached network image
-keep class com.github.brianegan.cached_network_image.** { *; }

# Keep flutter local notifications
-keep class com.dexterous.** { *; }

# Keep shared preferences
-keep class androidx.preference.** { *; }

# Keep SQLite
-keep class org.sqlite.** { *; }
-keep class org.sqlite.database.** { *; }

# Keep HTTP client
-keep class okhttp3.** { *; }
-keep class okio.** { *; }

# Keep Google Sign In
-keep class com.google.android.gms.auth.** { *; }
-keep class com.google.android.gms.common.** { *; }

# Keep Facebook Auth
-keep class com.facebook.** { *; }

# Keep URL launcher
-keep class io.flutter.plugins.urllauncher.** { *; }

# Keep intl
-keep class com.google.gson.** { *; }

# Keep Google Fonts
-keep class androidx.collection.** { *; }

# Keep SVG
-keep class com.caverock.androidsvg.** { *; }

# Keep sizer
-keep class com.adaptui.** { *; }

# Keep provider
-keep class provider.** { *; }

# Keep image picker
-keep class io.flutter.plugins.imagepicker.** { *; }

# Keep cached network image
-keep class com.github.brianegan.cached_network_image.** { *; }

# Keep flutter local notifications
-keep class com.dexterous.** { *; }

# Keep shared preferences
-keep class androidx.preference.** { *; }

# Keep SQLite
-keep class org.sqlite.** { *; }
-keep class org.sqlite.database.** { *; }

# Keep HTTP client
-keep class okhttp3.** { *; }
-keep class okio.** { *; }

# Keep Google Sign In
-keep class com.google.android.gms.auth.** { *; }
-keep class com.google.android.gms.common.** { *; }

# Keep Facebook Auth
-keep class com.facebook.** { *; }

# Keep URL launcher
-keep class io.flutter.plugins.urllauncher.** { *; }

# Keep intl
-keep class com.google.gson.** { *; }

# Keep Google Fonts
-keep class androidx.collection.** { *; }

# Keep SVG
-keep class com.caverock.androidsvg.** { *; }

# Keep sizer
-keep class com.adaptui.** { *; }

# Keep provider
-keep class provider.** { *; }