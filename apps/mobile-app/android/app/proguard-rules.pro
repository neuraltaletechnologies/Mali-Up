# Flutter Wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Firebase
#
# No blanket `-keep class com.google.firebase.** { *; }`: every Firebase SDK
# ships its own consumer ProGuard rules (firebase-components keeps every
# ComponentRegistrar so Firebase can self-initialise under R8; firebase-auth
# keeps its reflected fields; @Keep-annotated internals survive via
# proguard-android-optimize.txt). A blanket keep on top of that only stops R8
# from shrinking Firebase code this app never calls.
#
# The one app-level gap R8 can't see: Firestore (de)serialises model classes
# reflectively by @PropertyName. This app uses Map<String,dynamic> everywhere
# (no toObject/toObjects), so this keep matches nothing today — it just
# future-proofs the day someone adds an annotated POJO.
-keepclassmembers class * {
  @com.google.firebase.firestore.PropertyName <methods>;
  @com.google.firebase.firestore.PropertyName <fields>;
}

# Play Core (referenced by Flutter deferred components — not used by this app)
-dontwarn com.google.android.play.core.splitcompat.SplitCompatApplication
-dontwarn com.google.android.play.core.splitinstall.SplitInstallException
-dontwarn com.google.android.play.core.splitinstall.SplitInstallManager
-dontwarn com.google.android.play.core.splitinstall.SplitInstallManagerFactory
-dontwarn com.google.android.play.core.splitinstall.SplitInstallRequest$Builder
-dontwarn com.google.android.play.core.splitinstall.SplitInstallRequest
-dontwarn com.google.android.play.core.splitinstall.SplitInstallSessionState
-dontwarn com.google.android.play.core.splitinstall.SplitInstallStateUpdatedListener
-dontwarn com.google.android.play.core.tasks.OnFailureListener
-dontwarn com.google.android.play.core.tasks.OnSuccessListener
-dontwarn com.google.android.play.core.tasks.Task
