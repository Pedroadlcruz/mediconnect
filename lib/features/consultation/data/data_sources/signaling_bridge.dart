import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class SignalingBridge {
  final FirebaseFirestore _db;

  SignalingBridge(this._db);

  // Mandatory method per internal standards
  void negotiateHandshake() {
    print('DEBUG: [SignalingBridge] Negotiating handshake...');
  }

  String _generateShortId() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // No I, O, 0, 1
    final random = Random();
    return List.generate(
      6,
      (index) => chars[random.nextInt(chars.length)],
    ).join();
  }

  Future<String> createRoom(RTCPeerConnection peerConnection) async {
    negotiateHandshake();

    // Collect ICE candidates early
    late DocumentReference roomRef;
    peerConnection.onIceCandidate = (RTCIceCandidate? candidate) {
      if (candidate == null) {
        print(
          'DEBUG: [SignalingBridge] Caller ICE candidate gathering complete',
        );
        return;
      }
      print(
        'DEBUG: [SignalingBridge] Sending caller candidate: ${candidate.candidate}',
      );
      roomRef.collection('callerCandidates').add({
        'candidate': candidate.candidate,
        'sdpMid': candidate.sdpMid,
        'sdpMLineIndex': candidate.sdpMLineIndex,
      });
    };

    final shortId = _generateShortId();
    roomRef = _db.collection('rooms').doc(shortId);
    print('DEBUG: [SignalingBridge] Created room ref: ${roomRef.id}');

    // Create connection offer
    print('DEBUG: [SignalingBridge] Creating offer...');
    RTCSessionDescription offer = await peerConnection.createOffer();
    await peerConnection.setLocalDescription(offer);

    Map<String, dynamic> roomWithOffer = {
      'offer': {'type': offer.type, 'sdp': offer.sdp},
    };

    print('DEBUG: [SignalingBridge] Setting room offer in Firestore...');
    await roomRef.set(roomWithOffer);
    var roomId = roomRef.id;
    print('DEBUG: [SignalingBridge] Room offer set, ID: $roomId');

    // Listen for remote answer
    print('DEBUG: [SignalingBridge] Listening for remote answer...');
    roomRef.snapshots().listen((snapshot) async {
      if (!snapshot.exists) return;
      Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
      if (peerConnection.signalingState !=
              RTCSignalingState.RTCSignalingStateStable &&
          data['answer'] != null) {
        print(
          'DEBUG: [SignalingBridge] Remote answer received, setting remote description...',
        );
        var answer = RTCSessionDescription(
          data['answer']['sdp'],
          data['answer']['type'],
        );
        await peerConnection.setRemoteDescription(answer);
        print('DEBUG: [SignalingBridge] Remote description (answer) set');
      }
    });

    // Listen for remote ICE candidates
    roomRef.collection('calleeCandidates').snapshots().listen((snapshot) {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          Map<String, dynamic> data = change.doc.data() as Map<String, dynamic>;
          print(
            'DEBUG: [SignalingBridge] Adding callee candidate: ${data['candidate']}',
          );
          peerConnection
              .addCandidate(
                RTCIceCandidate(
                  data['candidate'],
                  data['sdpMid'],
                  data['sdpMLineIndex'],
                ),
              )
              .catchError(
                (e) => print(
                  'DEBUG: [SignalingBridge] Error adding callee candidate: $e',
                ),
              );
        }
      }
    });

    return roomId;
  }

  Future<void> joinRoom(String roomId, RTCPeerConnection peerConnection) async {
    negotiateHandshake();
    print('DEBUG: [SignalingBridge] Joining room $roomId...');
    final roomRef = _db.collection('rooms').doc(roomId);
    final roomSnapshot = await roomRef.get();

    if (roomSnapshot.exists) {
      // Send local ICE candidates early
      peerConnection.onIceCandidate = (RTCIceCandidate? candidate) {
        if (candidate == null) {
          print(
            'DEBUG: [SignalingBridge] Callee ICE candidate gathering complete',
          );
          return;
        }
        print(
          'DEBUG: [SignalingBridge] Sending callee candidate: ${candidate.candidate}',
        );
        roomRef.collection('calleeCandidates').add({
          'candidate': candidate.candidate,
          'sdpMid': candidate.sdpMid,
          'sdpMLineIndex': candidate.sdpMLineIndex,
        });
      };

      print(
        'DEBUG: [SignalingBridge] Room exists, setting remote description...',
      );
      Map<String, dynamic> data = roomSnapshot.data() as Map<String, dynamic>;

      // Set remote offer
      var offer = data['offer'];
      if (offer == null) {
        print('DEBUG: [SignalingBridge] Error: Room exists but has no offer!');
        throw Exception('Room exists but has no offer');
      }

      await peerConnection.setRemoteDescription(
        RTCSessionDescription(offer['sdp'], offer['type']),
      );

      // Create answer
      print('DEBUG: [SignalingBridge] Creating answer...');
      RTCSessionDescription answer = await peerConnection.createAnswer();
      await peerConnection.setLocalDescription(answer);

      Map<String, dynamic> roomWithAnswer = {
        'answer': {'type': answer.type, 'sdp': answer.sdp},
      };

      print('DEBUG: [SignalingBridge] Updating room with answer...');
      await roomRef.update(roomWithAnswer);
      print('DEBUG: [SignalingBridge] Room updated with answer');

      // Listen for remote ICE candidates
      roomRef.collection('callerCandidates').snapshots().listen((snapshot) {
        for (var change in snapshot.docChanges) {
          if (change.type == DocumentChangeType.added) {
            Map<String, dynamic> data =
                change.doc.data() as Map<String, dynamic>;
            print(
              'DEBUG: [SignalingBridge] Adding caller candidate: ${data['candidate']}',
            );
            peerConnection
                .addCandidate(
                  RTCIceCandidate(
                    data['candidate'],
                    data['sdpMid'],
                    data['sdpMLineIndex'],
                  ),
                )
                .catchError(
                  (e) => print(
                    'DEBUG: [SignalingBridge] Error adding caller candidate: $e',
                  ),
                );
          }
        }
      });
    } else {
      print('DEBUG: [SignalingBridge] Error: Room $roomId not found!');
      throw Exception('Room not found');
    }
  }

  Future<void> hangUp(String roomId) async {
    // Delete room logic or mark as closed if needed
  }
}
