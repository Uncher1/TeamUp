# TeamUp — R8/ProGuard keep rules for libraries that use JNI/reflection and
# would otherwise be stripped or renamed by the release shrinker.

# flutter_webrtc (native WebRTC accessed via JNI)
-keep class org.webrtc.** { *; }
-keep class com.cloudwebrtc.webrtc.** { *; }
-dontwarn org.webrtc.**

# Google ML Kit (on-device translation + language identification)
-keep class com.google.mlkit.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.mlkit.**
-dontwarn com.google.android.gms.**

# ota_update — receiver/provider are referenced from AndroidManifest
-keep class sk.fourq.otaupdate.** { *; }

# Audio record / playback (defensive; some use reflection)
-keep class com.llfbandit.record.** { *; }
-keep class xyz.luan.audioplayers.** { *; }

# Keep annotations & native method names
-keepattributes *Annotation*, Signature, InnerClasses, EnclosingMethod
-keepclasseswithmembernames class * {
    native <methods>;
}
