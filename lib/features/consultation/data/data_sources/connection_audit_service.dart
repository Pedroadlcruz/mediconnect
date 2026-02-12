import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:injectable/injectable.dart';
import 'package:mediconnect/features/consultation/domain/entities/connection_status.dart';
import 'package:permission_handler/permission_handler.dart';

abstract class ConnectionAuditService {
  Future<ConnectionStatus> checkConnection();
}

@LazySingleton(as: ConnectionAuditService)
class ConnectionAuditServiceImpl implements ConnectionAuditService {
  @override
  Future<ConnectionStatus> checkConnection() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    // Assuming singular return type based on lint error
    final hasInternet = connectivityResult != ConnectivityResult.none;

    // 2. Permission Checks
    final cameraStatus = await Permission.camera.request();
    final micStatus = await Permission.microphone.request();

    final hasCameraPermission = cameraStatus.isGranted;
    final hasMicrophonePermission = micStatus.isGranted;

    // 3. Hardware Availability (simplified)
    // In a real scenario, you'd enumerate devices and try to open streams.
    // For now, assume if permission is granted, hardware is likely available
    // or test by opening a dummy stream.
    bool isCameraAvailable = false;
    bool isMicrophoneAvailable = false;

    if (hasCameraPermission && hasMicrophonePermission) {
      try {
        final devices = await navigator.mediaDevices.enumerateDevices();
        isCameraAvailable = devices.any((d) => d.kind == 'videoinput');
        isMicrophoneAvailable = devices.any((d) => d.kind == 'audioinput');

        // Optional: Try opening a stream to prove it works (can be slow)
        // final stream = await navigator.mediaDevices.getUserMedia({'video': true, 'audio': true});
        // isCameraAvailable = stream.getVideoTracks().isNotEmpty;
        // isMicrophoneAvailable = stream.getAudioTracks().isNotEmpty;
        // stream.getTracks().forEach((t) => t.stop());
      } catch (e) {
        // Log error
      }
    }

    return ConnectionStatus(
      hasInternet: hasInternet,
      hasCameraPermission: hasCameraPermission,
      hasMicrophonePermission: hasMicrophonePermission,
      isCameraAvailable: isCameraAvailable,
      isMicrophoneAvailable: isMicrophoneAvailable,
    );
  }
}
