package com.rawasi.azhar

import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        createNotificationChannel()
    }

    /**
     * The channel every push notification from the dashboard is posted to.
     *
     * Without it, Firebase falls back to Android's generic "Miscellaneous"
     * channel, which on Samsung and most other phones has DEFAULT importance:
     * messages land silently in the notification shade, folded into one group,
     * with no pop-up banner. Only the first one tends to be noticed, so the
     * rest look as if they never arrived - which is exactly what happened.
     *
     * IMPORTANCE_HIGH is what makes each message pop up as a banner. It has to
     * be right the first time: Android lets an app create a channel, but never
     * raise its importance afterwards - only the user can, in settings.
     *
     * Created here, on every launch (it is a no-op once it exists), because the
     * app has to be opened once to sign in and register for notifications
     * anyway, so the channel always exists before the first message can arrive.
     */
    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return

        val channel = NotificationChannel(
            CHANNEL_ID,
            "إشعارات رواسي",
            NotificationManager.IMPORTANCE_HIGH,
        ).apply {
            description = "رسائل من إدارة رواسي"
            enableVibration(true)
        }

        getSystemService(NotificationManager::class.java)?.createNotificationChannel(channel)
    }

    companion object {
        /** Must match services.fcm.android_channel on the server and the manifest. */
        const val CHANNEL_ID = "rawasi_notifications"
    }
}
