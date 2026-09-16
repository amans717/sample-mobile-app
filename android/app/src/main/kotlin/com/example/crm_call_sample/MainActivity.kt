package com.example.crm_call_sample

import android.content.Context
import android.os.Build
import android.telephony.PhoneStateListener
import android.telephony.TelephonyCallback
import android.telephony.TelephonyManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel

class MainActivity : FlutterActivity() {
    private val CALL_STATE_CHANNEL = "com.example.crm_call_sample/call_state"
    private var telephonyManager: TelephonyManager? = null
    private var eventSink: EventChannel.EventSink? = null

    // For Android 12+ (API 31+)
    private var telephonyCallback: Any? = null

    // For older Android versions
    private var phoneStateListener: PhoneStateListener? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        telephonyManager = getSystemService(Context.TELEPHONY_SERVICE) as TelephonyManager

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, CALL_STATE_CHANNEL).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    eventSink = events
                    registerCallStateListener()
                }

                override fun onCancel(arguments: Any?) {
                    unregisterCallStateListener()
                    eventSink = null
                }
            }
        )
    }

    private fun registerCallStateListener() {
        val tm = telephonyManager ?: return

        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                val callback = object : TelephonyCallback(), TelephonyCallback.CallStateListener {
                    override fun onCallStateChanged(state: Int) {
                        notifyCallState(state)
                    }
                }
                telephonyCallback = callback
                tm.registerTelephonyCallback(mainExecutor, callback)
            } else {
                val listener = object : PhoneStateListener() {
                    @Deprecated("Deprecated in Java")
                    override fun onCallStateChanged(state: Int, phoneNumber: String?) {
                        notifyCallState(state)
                    }
                }
                phoneStateListener = listener
                @Suppress("DEPRECATION")
                tm.listen(listener, PhoneStateListener.LISTEN_CALL_STATE)
            }
        } catch (e: SecurityException) {
            eventSink?.error("PERMISSION_DENIED", "READ_PHONE_STATE permission not granted", e.localizedMessage)
        } catch (e: Exception) {
            eventSink?.error("ERROR", e.localizedMessage, null)
        }
    }

    private fun unregisterCallStateListener() {
        val tm = telephonyManager ?: return
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                (telephonyCallback as? TelephonyCallback)?.let {
                    tm.unregisterTelephonyCallback(it)
                }
                telephonyCallback = null
            } else {
                phoneStateListener?.let {
                    @Suppress("DEPRECATION")
                    tm.listen(it, PhoneStateListener.LISTEN_NONE)
                }
                phoneStateListener = null
            }
        } catch (_: Exception) {
        }
    }

    private fun notifyCallState(state: Int) {
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
