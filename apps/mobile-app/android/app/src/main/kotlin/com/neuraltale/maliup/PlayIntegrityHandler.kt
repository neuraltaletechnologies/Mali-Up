package com.neuraltale.maliup

import android.content.Context
import com.google.android.play.core.integrity.IntegrityManagerFactory
import com.google.android.play.core.integrity.IntegrityTokenRequest
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Bridges the native Play Integrity (classic) API to Dart. Requests a fresh
 * integrity token for a caller-supplied nonce; verification happens
 * server-side (see functions/src/index.ts), never on-device.
 */
class PlayIntegrityHandler(private val context: Context) : MethodChannel.MethodCallHandler {

    companion object {
        const val CHANNEL = "com.neuraltale.maliup/play_integrity"

        // GCP project number for neuraltale-mali-up (from android/app/google-services.json
        // -> project_info.project_number, matches the "1:596683133951:..." app ID prefix).
        private const val CLOUD_PROJECT_NUMBER = 596683133951L
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        if (call.method != "requestToken") {
            result.notImplemented()
            return
        }
        val nonce = call.argument<String>("nonce")
        if (nonce.isNullOrEmpty()) {
            result.error("invalid_argument", "nonce is required", null)
            return
        }

        val integrityManager = IntegrityManagerFactory.create(context)
        val request = IntegrityTokenRequest.builder()
            .setNonce(nonce)
            .setCloudProjectNumber(CLOUD_PROJECT_NUMBER)
            .build()

        integrityManager.requestIntegrityToken(request)
            .addOnSuccessListener { response -> result.success(response.token()) }
            .addOnFailureListener { exception ->
                result.error("integrity_token_failed", exception.message, null)
            }
    }
}
