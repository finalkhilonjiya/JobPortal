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

# === ✅ Keep Required Libraries === #

# Supabase
-keep class io.supabase.** { *; }

# Image Picker
-keep class com.github.dhaval2404.imagepicker.** { *; }
-keep class io.flutter.plugins.imagepicker.** { *; }

# Permission Handler
-keep class com.baseflow.permissionhandler.** { *; }

# Geolocator
-keep class com.baseflow.geolocator.** { *; }

# Cached Network Image
-keep class com.github.brianegan.cached_network_image.** { *; }

# Flutter Local Notifications
-keep class com.dexterous.** { *; }

# Shared Preferences
-keep class androidx.preference.** { *; }

# SQLite
-keep class org.sqlite.** { *; }
-keep class org.sqlite.database.** { *; }

# HTTP Client
-keep class okhttp3.** { *; }
-keep class okio.** { *; }

# Google Sign-In (only auth/common parts, no Firebase)
-keep class com.google.android.gms.auth.api.signin.** { *; }
-keep class com.google.android.gms.common.api.** { *; }
-keep class com.google.android.gms.tasks.** { *; }
-keep class com.google.android.gms.common.** { *; }

# Facebook Auth
-keep class com.facebook.** { *; }

# URL Launcher
-keep class io.flutter.plugins.urllauncher.** { *; }

# Gson (used by intl/Supabase/HTTP APIs)
-keep class com.google.gson.** { *; }

# Google Fonts
-keep class androidx.collection.** { *; }

# SVG support
-keep class com.caverock.androidsvg.** { *; }

# Sizer
-keep class com.adaptui.** { *; }

# Provider
-keep class provider.** { *; }