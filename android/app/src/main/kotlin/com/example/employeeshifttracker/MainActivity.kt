package com.shift.schedule.app

import android.content.Intent
import android.net.Uri
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import com.google.android.gms.ads.MobileAds
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.shift.schedule.app/mail"

    override fun configureFlutterEngine(flutterEngine: io.flutter.embedding.engine.FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Register all plugins including Google Mobile Ads
        io.flutter.plugins.GeneratedPluginRegistrant.registerWith(flutterEngine)
        
        // Initialize Google Mobile Ads SDK
        MobileAds.initialize(this) {}

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "openGmail") {
                val to = call.argument<String>("to")
                val subject = call.argument<String>("subject")
                val body = call.argument<String>("body")
                openGmail(to, subject, body, result)
            } else {
                result.notImplemented()
            }
        }
    }

    private fun openGmail(to: String?, subject: String?, body: String?, result: MethodChannel.Result) {
        try {
            val intent = Intent(Intent.ACTION_SEND).apply {
                type = "message/rfc822"
                putExtra(Intent.EXTRA_EMAIL, arrayOf(to))
                putExtra(Intent.EXTRA_SUBJECT, subject)
                putExtra(Intent.EXTRA_TEXT, body)
                // Removed setPackage to allow any mail app
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            if (intent.resolveActivity(packageManager) != null) {
                startActivity(intent)
                result.success(null)
            } else {
                result.error("NO_MAIL_APP", "No mail app is installed", null)
            }
        } catch (e: Exception) {
            result.error("ERROR", e.message, null)
        }
    }
}
