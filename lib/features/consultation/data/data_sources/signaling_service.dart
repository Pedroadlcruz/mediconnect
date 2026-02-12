import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class SignalingService {
  final FirebaseFirestore _db;

  SignalingService(this._db);

  Future<String> createRoom(RTCPeerConnection peerConnection) async {
    // Collect ICE candidates early
    late DocumentReference
    roomRef; // Declare roomRef here to be accessible in onIceCandidate
    peerConnection.onIceCandidate = (RTCIceCandidate? candidate) {
      if (candidate == null) {
        print(
          'DEBUG: [SignalingService] Caller ICE candidate gathering complete',
        );
        return;
      }
      print(
        'DEBUG: [SignalingService] Sending caller candidate: ${candidate.candidate}',
      );
      roomRef.collection('callerCandidates').add({
        'candidate': candidate.candidate,
        'sdpMid': candidate.sdpMid,
        'sdpMLineIndex': candidate.sdpMLineIndex,
      });
    };

    roomRef = _db
        .collection('rooms')
        .doc(); // Initialize roomRef after onIceCandidate is set

    // Collect ICE candidates was moved above

    // Create connection offer
    RTCSessionDescription offer = await peerConnection.createOffer();
    await peerConnection.setLocalDescription(offer);

    Map<String, dynamic> roomWithOffer = {
      'offer': {'type': offer.type, 'sdp': offer.sdp},
    };

    print('DEBUG: [SignalingService] Setting room offer in Firestore...');
    await roomRef.set(roomWithOffer);
    var roomId = roomRef.id;
    print('DEBUG: [SignalingService] Room offer set, ID: $roomId');

    // Listen for remote answer
    print('DEBUG: [SignalingService] Listening for remote answer...');
    roomRef.snapshots().listen((snapshot) async {
      if (!snapshot.exists) return;
      Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
      if (peerConnection.signalingState !=
              RTCSignalingState.RTCSignalingStateStable &&
          data['answer'] != null) {
        print(
          'DEBUG: [SignalingService] Remote answer received, setting remote description...',
        );
        var answer = RTCSessionDescription(
          data['answer']['sdp'],
          data['answer']['type'],
        );
        await peerConnection.setRemoteDescription(answer);
        print('DEBUG: [SignalingService] Remote description (answer) set');
      }
    });

    // Listen for remote ICE candidates
    roomRef.collection('calleeCandidates').snapshots().listen((snapshot) {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          Map<String, dynamic> data = change.doc.data() as Map<String, dynamic>;
          print(
            'DEBUG: [SignalingService] Adding callee candidate: ${data['candidate']}',
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
                  'DEBUG: [SignalingService] Error adding callee candidate: $e',
                ),
              );
        }
      }
    });

    return roomId;
  }

  Future<void> joinRoom(String roomId, RTCPeerConnection peerConnection) async {
    print('DEBUG: [SignalingService] Joining room $roomId...');
    final roomRef = _db.collection('rooms').doc(roomId);
    final roomSnapshot = await roomRef.get();

    if (roomSnapshot.exists) {
      // Send local ICE candidates early
      peerConnection.onIceCandidate = (RTCIceCandidate? candidate) {
        if (candidate == null) {
          print(
            'DEBUG: [SignalingService] Callee ICE candidate gathering complete',
          );
          return;
        }
        print(
          'DEBUG: [SignalingService] Sending callee candidate: ${candidate.candidate}',
        );
        roomRef.collection('calleeCandidates').add({
          'candidate': candidate.candidate,
          'sdpMid': candidate.sdpMid,
          'sdpMLineIndex': candidate.sdpMLineIndex,
        });
      };

      print(
        'DEBUG: [SignalingService] Room exists, setting remote description...',
      );
      Map<String, dynamic> data = roomSnapshot.data() as Map<String, dynamic>;

      // Send local ICE candidates was moved above

      // Set remote offer
      var offer = data['offer'];
      if (offer == null) {
        print('DEBUG: [SignalingService] Error: Room exists but has no offer!');
        throw Exception('Room exists but has no offer');
      }

      await peerConnection.setRemoteDescription(
        RTCSessionDescription(offer['sdp'], offer['type']),
      );

      // Create answer
      print('DEBUG: [SignalingService] Creating answer...');
      RTCSessionDescription answer = await peerConnection.createAnswer();
      await peerConnection.setLocalDescription(answer);

      Map<String, dynamic> roomWithAnswer = {
        'answer': {'type': answer.type, 'sdp': answer.sdp},
      };

      print('DEBUG: [SignalingService] Updating room with answer...');
      await roomRef.update(roomWithAnswer);
      print('DEBUG: [SignalingService] Room updated with answer');

      // Listen for remote ICE candidates
      roomRef.collection('callerCandidates').snapshots().listen((snapshot) {
        for (var change in snapshot.docChanges) {
          if (change.type == DocumentChangeType.added) {
            Map<String, dynamic> data =
                change.doc.data() as Map<String, dynamic>;
            print(
              'DEBUG: [SignalingService] Adding caller candidate: ${data['candidate']}',
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
                    'DEBUG: [SignalingService] Error adding caller candidate: $e',
                  ),
                );
          }
        }
      });

      // Send local ICE candidates
      peerConnection.onIceCandidate = (RTCIceCandidate? candidate) {
        if (candidate == null) {
          print(
            'DEBUG: [SignalingService] Callee ICE candidate gathering complete',
          );
          return;
        }
        print(
          'DEBUG: [SignalingService] Sending callee candidate: ${candidate.candidate}',
        );
        roomRef.collection('calleeCandidates').add({
          'candidate': candidate.candidate,
          'sdpMid': candidate.sdpMid,
          'sdpMLineIndex': candidate.sdpMLineIndex,
        });
      };
    } else {
      print('DEBUG: [SignalingService] Error: Room $roomId not found!');
      throw Exception('Room not found');
    }
  }

  Future<void> hangUp(String roomId) async {
    // Delete room logic or mark as closed
    // _db.collection('rooms').doc(roomId).delete();
    // Usually handled by Cloud Functions for cleanup
  }
}
