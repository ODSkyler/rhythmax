# audio_service
-keep class com.ryanheise.audioservice.** { *; }

# media session / notification
-keep class androidx.media.** { *; }
-keep class androidx.core.app.NotificationCompat { *; }

# kotlin (safe keep)
-keep class kotlin.** { *; }