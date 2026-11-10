package com.safeer.octetpulse

import android.os.Handler
import android.os.Looper
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import java.util.Random
import java.util.UUID

class MainActivity : FlutterActivity() {
    private val CONTROL_CHANNEL = "com.safeer.octetpulse/voip_control"
    private val TELEMETRY_CHANNEL = "com.safeer.octetpulse/voip_telemetry"

    private var isCallActive = false
    private var isMuted = false
    private var isSpeakerOn = false
    private var currentCodec = "OPUS-HD"
    private var activeCallId: String? = null
    private var callDurationSeconds = 0

    private val handler = Handler(Looper.getMainLooper())
    private val random = Random()
    private var telemetrySink: EventChannel.EventSink? = null

    private val telemetryRunnable = object : Runnable {
        override fun run() {
            if (isCallActive) {
                callDurationSeconds += 1
            }

            val waveforms = ArrayList<Double>()
            for (i in 0 until 16) {
                if (isCallActive && !isMuted) {
                    waveforms.add(0.15 + (random.nextDouble() * 0.75))
                } else {
                    waveforms.add(0.05 + (random.nextDouble() * 0.05))
                }
            }

            val telemetryData = HashMap<String, Any>()
            telemetryData["isActive"] = isCallActive
            telemetryData["callId"] = activeCallId ?: ""
            telemetryData["callDurationSec"] = callDurationSeconds
            telemetryData["bitrateKbps"] = if (isCallActive) (48.0 + (random.nextDouble() * 16.0)) else 0.0
            telemetryData["packetLossPercent"] = if (isCallActive) (random.nextDouble() * 0.45) else 0.0
            telemetryData["jitterMs"] = if (isCallActive) (2.1 + (random.nextDouble() * 3.4)) else 0.0
            telemetryData["mosScore"] = if (isCallActive) (4.25 + (random.nextDouble() * 0.18)) else 4.40
            telemetryData["cipher"] = "SRTP-AES256"
            telemetryData["audioCodec"] = currentCodec
            telemetryData["isMuted"] = isMuted
            telemetryData["isSpeakerOn"] = isSpeakerOn
            telemetryData["waveforms"] = waveforms
            telemetryData["timestamp"] = System.currentTimeMillis()

            telemetrySink?.success(telemetryData)
            handler.postDelayed(this, 1500)
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CONTROL_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "initiateCall" -> {
                        val calleeId = call.argument<String>("calleeId") ?: "unknown"
                        val calleeName = call.argument<String>("calleeName") ?: "Colleague"
                        val codec = call.argument<String>("codec") ?: "OPUS-HD"
                        
                        isCallActive = true
                        isMuted = false
                        isSpeakerOn = false
                        currentCodec = codec
                        activeCallId = "call_" + UUID.randomUUID().toString().substring(0, 8)
                        callDurationSeconds = 0

                        val response = HashMap<String, Any>()
                        response["status"] = "initiated"
                        response["callId"] = activeCallId!!
                        response["calleeId"] = calleeId
                        response["calleeName"] = calleeName
                        response["cipher"] = "SRTP-AES256"
                        response["codec"] = currentCodec
                        response["timestamp"] = System.currentTimeMillis()
                        result.success(response)
                    }
                    "endCall" -> {
                        isCallActive = false
                        val duration = callDurationSeconds
                        callDurationSeconds = 0
                        val oldCallId = activeCallId ?: ""
                        activeCallId = null

                        val response = HashMap<String, Any>()
                        response["status"] = "terminated"
                        response["callId"] = oldCallId
                        response["durationSeconds"] = duration
                        response["timestamp"] = System.currentTimeMillis()
                        result.success(response)
                    }
                    "toggleMute" -> {
                        val forceState = call.argument<Boolean>("isMuted")
                        isMuted = forceState ?: !isMuted
                        val response = HashMap<String, Any>()
                        response["isMuted"] = isMuted
                        result.success(response)
                    }
                    "toggleSpeaker" -> {
                        val forceState = call.argument<Boolean>("isSpeakerOn")
                        isSpeakerOn = forceState ?: !isSpeakerOn
                        val response = HashMap<String, Any>()
                        response["isSpeakerOn"] = isSpeakerOn
                        result.success(response)
                    }
                    "setAudioCodec" -> {
                        val codec = call.argument<String>("codec") ?: "OPUS-HD"
                        currentCodec = codec
                        val response = HashMap<String, Any>()
                        response["codec"] = currentCodec
                        result.success(response)
                    }
                    else -> result.notImplemented()
                }
            }

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, TELEMETRY_CHANNEL)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    telemetrySink = events
                    handler.removeCallbacks(telemetryRunnable)
                    handler.post(telemetryRunnable)
                }

                override fun onCancel(arguments: Any?) {
                    handler.removeCallbacks(telemetryRunnable)
                    telemetrySink = null
                }
            })
    }

    override fun onDestroy() {
        handler.removeCallbacks(telemetryRunnable)
        super.onDestroy()
    }
}
