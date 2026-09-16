package com.example.crm_call_sample

import android.content.Context
import android.telephony.PhoneStateListener
import android.telephony.TelephonyManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel

class MainActivity : FlutterActivity() {
    private val CALL_STATE_CHANNEL = "com.example.crm_call_sample/call_state"
    private var telephonyManager: TelephonyManager? = null
    private var eventSink: EventChannel.EventSink? = null

    private val phoneStateListener = object : PhoneStateListener() {
        @Deprecated("Deprecated in Java")
        override fun onCallStateChanged(state: Int, phoneNumber: String?) {
            val stateString = when (state) {
                TelephonyManager.CALL_STATE_IDLE -> "IDLE"
                TelephonyManager.CALL_STATE_OFFHOOK -> "OFFHOOK"
                TelephonyManager.CALL_STATE_RINGING -> "RINGING"
                else -> "UNKNOWN"
            }
            runOnUiThread {
                eventSink?.success(stateString)
            }
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        telephonyManager = getSystemService(Context.TELEPHONY_SERVICE) as? TelephonyManager

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, CALL_STATE_CHANNEL).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    eventSink = events
                    try {
                        @Suppress("DEPRECATION")
                        telephonyManager?.listen(phoneStateListener, PhoneStateListener.LISTEN_CALL_STATE)
                    } catch (_: Exception) {}
                }

                override fun onCancel(arguments: Any?) {
                    try {
                        @Suppress("DEPRECATION")
                        telephonyManager?.listen(phoneStateListener, PhoneStateListener.LISTEN_NONE)
                    } catch (_: Exception) {}
                    eventSink = null
                }
            }
        )
    }
}
