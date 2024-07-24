# Inisialisasi pengaturan dasar
-keep class * extends android.app.Activity
-keep class * extends android.app.Service
-keep class * extends android.content.BroadcastReceiver
-keep class * extends android.content.ContentProvider
-keep class * extends android.app.Application

# Pertahankan class yang diperlukan untuk komponen Android
-keep class com.nextccgmedia.flue.** { *; }
-dontwarn com.nextccgmedia.flue.**

# Pertahankan class yang dibutuhkan oleh Flutter
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }

# Pertahankan class yang dibutuhkan oleh libraries eksternal
-keep class com.google.android.gms.** { *; }
-keep class com.google.firebase.** { *; }
-keep class com.squareup.** { *; }

# Menghindari penghapusan class yang diperlukan
-keepattributes *Annotation*

# Menghindari penghapusan method yang diperlukan
-keepclassmembers class * {
    @androidx.annotation.Keep <methods>;
}

# Menghindari penghapusan method dengan parameter tertentu
-keepclassmembers class * {
    public static void main(java.lang.String[]);
}
