class ConnectionStatus {
  final bool hasInternet;
  final bool hasCameraPermission;
  final bool hasMicrophonePermission;
  final bool isCameraAvailable;
  final bool isMicrophoneAvailable;

  const ConnectionStatus({
    required this.hasInternet,
    required this.hasCameraPermission,
    required this.hasMicrophonePermission,
    required this.isCameraAvailable,
    required this.isMicrophoneAvailable,
  });

  bool get isReady =>
      hasInternet &&
      hasCameraPermission &&
      hasMicrophonePermission &&
      isCameraAvailable &&
      isMicrophoneAvailable;
}
