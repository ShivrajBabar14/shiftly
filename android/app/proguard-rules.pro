# Basic Android & Flutter Protection
-keepattributes *Annotation*,Signature,InnerClasses,EnclosingMethod
-keep class * extends android.app.Activity
-keep class * extends android.app.Application
-keep class * extends android.app.Service
-keep class * extends android.content.BroadcastReceiver
-keep class * extends android.content.ContentProvider

# Razorpay & Payment Services
-keep class com.razorpay.** { *; }
-dontwarn com.razorpay.**
-keep class org.apache.** { *; }

# Google Pay/Wallet Services
-keep class com.google.android.gms.wallet.** { *; }
-dontwarn com.google.android.gms.wallet.**
-keep class com.google.android.gms.pay.** { *; }
-dontwarn com.google.android.gms.pay.**

# Flutter Protection
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.embedding.** { *; }

# JSON & Serialization
-keepclassmembers class * {
    public *;
}
-keep class * implements java.io.Serializable { *; }

# Platform Channels
-keep class * extends java.util.ListResourceBundle {
    protected Object[][] getContents();
}
-keep public class * extends android.view.View {
    public <init>(android.content.Context);
    public <init>(android.content.Context, android.util.AttributeSet);
    public <init>(android.content.Context, android.util.AttributeSet, int);
    public void set*(***);
}

# Debugging Info
-renamesourcefileattribute SourceFile
-keepattributes SourceFile,LineNumberTable,Exceptions,Signature,Deprecated

# Resource IDs
-keepclassmembers class **.R$* {
    public static <fields>;
}

# JavaScript Interface
-keepclassmembers class * {
    @android.webkit.JavascriptInterface <methods>;
}

# Play Core
-keep class com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**