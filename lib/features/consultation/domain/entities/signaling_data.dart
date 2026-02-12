import 'package:equatable/equatable.dart';

class SignalingData extends Equatable {
  final String? type; // 'offer', 'answer', 'candidate'
  final String? sdp;
  final String? candidate;
  final String? sdpMid;
  final int? sdpMLineIndex;

  const SignalingData({
    this.type,
    this.sdp,
    this.candidate,
    this.sdpMid,
    this.sdpMLineIndex,
  });

  @override
  List<Object?> get props => [type, sdp, candidate, sdpMid, sdpMLineIndex];
}
