import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

/// Development-only fault injection. Label every use in your evidence.
enum SaveFault { none, lostAck, unavailable, exhausted }

enum SaveFailure {
  collision,
  permissionDenied,
  unauthenticated,
  unavailable,
  resourceExhausted,
  unknown,
  notFound,
  mismatch,
}

class AttemptException implements Exception {
  AttemptException(this.kind, this.message);
  final SaveFailure kind;
  final String message;

  @override
  String toString() => message;
}

/// Path: users/{uid}/attempts/{roundId}. Six fields, immutable once created.
class AttemptRepository {
  AttemptRepository({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  DocumentReference<Map<String, dynamic>> _ref(String uid, String roundId) =>
      _db.collection('users').doc(uid).collection('attempts').doc(roundId);

  /// Generates an ID locally. This reserves nothing on the server.
  String newRoundId(String uid) =>
      _db.collection('users').doc(uid).collection('attempts').doc().id;

  /// Create-once with reconciliation. Safe to call again with the same ID.
  Future<void> saveOnce({
    required String uid,
    required String roundId,
    required int correctCount,
    SaveFault fault = SaveFault.none,
  }) async {
    if (correctCount < 0 || correctCount > 10) {
      throw ArgumentError('correctCount must be 0..10');
    }
    if (fault == SaveFault.unavailable) {
      throw AttemptException(SaveFailure.unavailable,
          'DEV FAULT (injected): unavailable. Retry when online.');
    }
    if (fault == SaveFault.exhausted) {
      throw AttemptException(SaveFailure.resourceExhausted,
          'DEV FAULT (injected): quota exhausted. Retry later.');
    }

    final ref = _ref(uid, roundId);
    try {
      // The callback must stay pure: no UI, no random IDs, no other network.
      await _db.runTransaction<void>((tx) async {
        final snap = await tx.get(ref);
        if (snap.exists) {
          final d = snap.data()!;
          final same = d['schemaVersion'] == 1 &&
              d['variant'] == 'A' &&
              d['categoryId'] == 9 &&
              d['questionCount'] == 10 &&
              d['correctCount'] == correctCount;
          if (!same) {
            throw AttemptException(SaveFailure.collision,
                'Round ID already holds different data. Not overwritten.');
          }
          return; // identical retry: reuse, do not write again
        }
        tx.set(ref, {
          'schemaVersion': 1,
          'variant': 'A',
          'categoryId': 9,
          'questionCount': 10,
          'correctCount': correctCount,
          'submittedAt': FieldValue.serverTimestamp(),
        });
      });
    } on FirebaseException catch (e) {
      throw _map(e);
    }

    // DEV ONLY: the commit above is real. Hide only the acknowledgement.
    if (fault == SaveFault.lostAck) {
      throw TimeoutException(
          'DEV FAULT (injected): acknowledgement suppressed after commit.');
    }
  }

  /// Server-only read. Throws FirebaseException if the server cannot be reached.
  Future<void> verify({
    required String uid,
    required String roundId,
    required int correctCount,
  }) async {
    final snap =
        await _ref(uid, roundId).get(const GetOptions(source: Source.server));
    if (!snap.exists) {
      throw AttemptException(SaveFailure.notFound, 'No server record yet.');
    }
    if (snap.metadata.hasPendingWrites) {
      throw AttemptException(SaveFailure.unknown, 'Pending writes present.');
    }
    final d = snap.data()!;
    final ok = d.length == 6 &&
        d['schemaVersion'] == 1 &&
        d['variant'] == 'A' &&
        d['categoryId'] == 9 &&
        d['questionCount'] == 10 &&
        d['correctCount'] == correctCount &&
        d['submittedAt'] is Timestamp;
    if (!ok) {
      throw AttemptException(
          SaveFailure.mismatch, 'Server record differs from this round.');
    }
  }

  AttemptException _map(FirebaseException e) {
    switch (e.code) {
      case 'permission-denied':
        return AttemptException(SaveFailure.permissionDenied,
            'Permission denied by Firestore rules.');
      case 'unauthenticated':
        return AttemptException(
            SaveFailure.unauthenticated, 'Please sign in again.');
      case 'unavailable':
        return AttemptException(SaveFailure.unavailable,
            'Cloud unavailable or offline. Nothing was confirmed; retry when online.');
      case 'resource-exhausted':
        return AttemptException(
            SaveFailure.resourceExhausted, 'Quota exhausted. Retry later.');
      default:
        // deadline-exceeded and others: the commit may or may not have happened.
        return AttemptException(
            SaveFailure.unknown, 'Save status unknown (${e.code}).');
    }
  }
}
