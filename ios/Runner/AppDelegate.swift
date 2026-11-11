import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private let controlChannelName = "com.safeer.octetpulse/voip_control"
  private let telemetryChannelName = "com.safeer.octetpulse/voip_telemetry"

  private var isCallActive = false
  private var isMuted = false
  private var isSpeakerOn = false
  private var isRecording = false
  private var currentCodec = "OPUS-HD"
  private var activeCallId = ""
  private var callDurationSeconds = 0
  private var telemetryTimer: Timer?
  private var eventSink: FlutterEventSink?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
    setupVoipBridge(messenger: controller.binaryMessenger)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }

  private func setupVoipBridge(messenger: FlutterBinaryMessenger) {
    let methodChannel = FlutterMethodChannel(name: controlChannelName, binaryMessenger: messenger)
    methodChannel.setMethodCallHandler { [weak self] (call, result) in
      guard let self = self else { return }
      switch call.method {
      case "initiateCall":
        let args = call.arguments as? [String: Any]
        let calleeId = args?["calleeId"] as? String ?? "unknown"
        let calleeName = args?["calleeName"] as? String ?? "Colleague"
        let codec = args?["codec"] as? String ?? "OPUS-HD"
        self.isCallActive = true
        self.isMuted = false
        self.isSpeakerOn = false
        self.currentCodec = codec
        self.activeCallId = "call_\(UUID().uuidString.prefix(8))"
        self.callDurationSeconds = 0

        result([
          "status": "initiated",
          "callId": self.activeCallId,
          "calleeId": calleeId,
          "calleeName": calleeName,
          "cipher": "SRTP-AES256",
          "codec": self.currentCodec,
          "timestamp": Int64(Date().timeIntervalSince1970 * 1000)
        ])
      case "endCall":
        self.isCallActive = false
        self.isRecording = false
        let duration = self.callDurationSeconds
        self.callDurationSeconds = 0
        let oldId = self.activeCallId
        self.activeCallId = ""
        result([
          "status": "terminated",
          "callId": oldId,
          "durationSeconds": duration,
          "timestamp": Int64(Date().timeIntervalSince1970 * 1000)
        ])
      case "toggleMute":
        let args = call.arguments as? [String: Any]
        if let force = args?["isMuted"] as? Bool {
          self.isMuted = force
        } else {
          self.isMuted.toggle()
        }
        result(["isMuted": self.isMuted])
      case "toggleSpeaker":
        let args = call.arguments as? [String: Any]
        if let force = args?["isSpeakerOn"] as? Bool {
          self.isSpeakerOn = force
        } else {
          self.isSpeakerOn.toggle()
        }
        result(["isSpeakerOn": self.isSpeakerOn])
      case "setAudioCodec":
        let args = call.arguments as? [String: Any]
        self.currentCodec = args?["codec"] as? String ?? "OPUS-HD"
        result(["codec": self.currentCodec])
      case "startRecording":
        self.isRecording = true
        let args = call.arguments as? [String: Any]
        let callId = args?["callId"] as? String ?? self.activeCallId
        result([
          "status": "recording_active",
          "callId": callId,
          "cipher": "AES-256-GCM",
          "isRecording": true,
          "timestamp": Int64(Date().timeIntervalSince1970 * 1000)
        ])
      case "stopRecording":
        self.isRecording = false
        result([
          "status": "recording_stopped",
          "isRecording": false,
          "cipher": "AES-256-GCM",
          "timestamp": Int64(Date().timeIntervalSince1970 * 1000)
        ])
      case "toggleRecording":
        let args = call.arguments as? [String: Any]
        if let force = args?["isRecording"] as? Bool {
          self.isRecording = force
        } else {
          self.isRecording.toggle()
        }
        result([
          "isRecording": self.isRecording,
          "cipher": "AES-256-GCM"
        ])
      default:
        result(FlutterMethodNotImplemented)
      }
    }

    let eventChannel = FlutterEventChannel(name: telemetryChannelName, binaryMessenger: messenger)
    eventChannel.setStreamHandler(VoipStreamHandler(appDelegate: self))
  }

  fileprivate func startTelemetry(sink: @escaping FlutterEventSink) {
    self.eventSink = sink
    telemetryTimer?.invalidate()
    telemetryTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { [weak self] _ in
      guard let self = self else { return }
      if self.isCallActive {
        self.callDurationSeconds += 1
      }
      var waveforms: [Double] = []
      for _ in 0..<16 {
        if self.isCallActive && !self.isMuted {
          waveforms.append(0.15 + (Double.random(in: 0.0...1.0) * 0.75))
        } else {
          waveforms.append(0.05 + (Double.random(in: 0.0...1.0) * 0.05))
        }
      }

      let data: [String: Any] = [
        "isActive": self.isCallActive,
        "callId": self.activeCallId,
        "callDurationSec": self.callDurationSeconds,
        "bitrateKbps": self.isCallActive ? (48.0 + (Double.random(in: 0.0...1.0) * 16.0)) : 0.0,
        "packetLossPercent": self.isCallActive ? (Double.random(in: 0.0...1.0) * 0.45) : 0.0,
        "jitterMs": self.isCallActive ? (2.1 + (Double.random(in: 0.0...1.0) * 3.4)) : 0.0,
        "mosScore": self.isCallActive ? (4.25 + (Double.random(in: 0.0...1.0) * 0.18)) : 4.40,
        "cipher": "SRTP-AES256",
        "audioCodec": self.currentCodec,
        "isMuted": self.isMuted,
        "isSpeakerOn": self.isSpeakerOn,
        "isRecording": self.isRecording,
        "waveforms": waveforms,
        "timestamp": Int64(Date().timeIntervalSince1970 * 1000)
      ]
      sink(data)
    }
  }

  fileprivate func stopTelemetry() {
    telemetryTimer?.invalidate()
    telemetryTimer = nil
    eventSink = nil
  }
}

class VoipStreamHandler: NSObject, FlutterStreamHandler {
  private weak var appDelegate: AppDelegate?

  init(appDelegate: AppDelegate) {
    self.appDelegate = appDelegate
  }

  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    appDelegate?.startTelemetry(sink: events)
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    appDelegate?.stopTelemetry()
    return nil
  }
}
