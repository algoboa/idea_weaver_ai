import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/models/app_user.dart';

/// Subscription limits for different plans
class SubscriptionLimits {
  static const int freeMapLimit = 3;
  static const int freeAiUsageLimit = 10;
  static const int proMapLimit = -1; // Unlimited
  static const int proAiUsageLimit = -1; // Unlimited
}

/// Subscription service for managing user subscriptions
class SubscriptionService {
  final FirebaseFirestore _firestore;

  SubscriptionService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Get user subscription data
  Future<AppUser?> getUserSubscription(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    if (!doc.exists || doc.data() == null) {
      return null;
    }
    return AppUser.fromJson(doc.data()!);
  }

  /// Create or update user data
  Future<void> updateUserData(AppUser user) async {
    await _firestore.collection('users').doc(user.id).set(user.toJson());
  }

  /// Check if user can create a new mind map
  Future<bool> canCreateMindMap(String userId) async {
    final user = await getUserSubscription(userId);
    if (user == null) return true; // New user can create

    if (user.subscriptionPlan == SubscriptionPlan.pro) {
      return true;
    }

    return user.mindMapCount < SubscriptionLimits.freeMapLimit;
  }

  /// Check if user can use AI feature
  Future<bool> canUseAi(String userId) async {
    final user = await getUserSubscription(userId);
    if (user == null) return true; // New user can use AI

    if (user.subscriptionPlan == SubscriptionPlan.pro) {
      return true;
    }

    return user.aiUsageCount < SubscriptionLimits.freeAiUsageLimit;
  }

  /// Increment AI usage count
  Future<void> incrementAiUsage(String userId) async {
    await _firestore.collection('users').doc(userId).update({
      'aiUsageCount': FieldValue.increment(1),
      'aiUsageResetDate': _getNextResetDate().toIso8601String(),
    });
  }

  /// Increment mind map count
  Future<void> incrementMindMapCount(String userId) async {
    await _firestore.collection('users').doc(userId).update({
      'mindMapCount': FieldValue.increment(1),
    });
  }

  /// Decrement mind map count
  Future<void> decrementMindMapCount(String userId) async {
    await _firestore.collection('users').doc(userId).update({
      'mindMapCount': FieldValue.increment(-1),
    });
  }

  /// Upgrade user to Pro plan
  Future<void> upgradeToProPlan(String userId) async {
    await _firestore.collection('users').doc(userId).update({
      'subscriptionPlan': 'pro',
      'subscriptionStartDate': DateTime.now().toIso8601String(),
      'subscriptionEndDate': _getSubscriptionEndDate().toIso8601String(),
    });
  }

  /// Cancel Pro subscription (downgrade to free)
  Future<void> cancelProPlan(String userId) async {
    await _firestore.collection('users').doc(userId).update({
      'subscriptionPlan': 'free',
      'subscriptionEndDate': null,
    });
  }

  /// Check and reset monthly AI usage if needed
  Future<void> checkAndResetAiUsage(String userId) async {
    final user = await getUserSubscription(userId);
    if (user == null) return;

    final resetDate = user.aiUsageResetDate;
    if (resetDate != null && DateTime.now().isAfter(resetDate)) {
      await _firestore.collection('users').doc(userId).update({
        'aiUsageCount': 0,
        'aiUsageResetDate': _getNextResetDate().toIso8601String(),
      });
    }
  }

  /// Get remaining AI usage for the month
  Future<int> getRemainingAiUsage(String userId) async {
    final user = await getUserSubscription(userId);
    if (user == null) return SubscriptionLimits.freeAiUsageLimit;

    if (user.subscriptionPlan == SubscriptionPlan.pro) {
      return -1; // Unlimited
    }

    return SubscriptionLimits.freeAiUsageLimit - user.aiUsageCount;
  }

  /// Get remaining mind map slots
  Future<int> getRemainingMindMaps(String userId) async {
    final user = await getUserSubscription(userId);
    if (user == null) return SubscriptionLimits.freeMapLimit;

    if (user.subscriptionPlan == SubscriptionPlan.pro) {
      return -1; // Unlimited
    }

    return SubscriptionLimits.freeMapLimit - user.mindMapCount;
  }

  DateTime _getNextResetDate() {
    final now = DateTime.now();
    // Reset on the first of next month
    if (now.month == 12) {
      return DateTime(now.year + 1, 1, 1);
    }
    return DateTime(now.year, now.month + 1, 1);
  }

  DateTime _getSubscriptionEndDate() {
    // Monthly subscription ends in 30 days
    return DateTime.now().add(const Duration(days: 30));
  }

  /// Stream of user subscription data
  Stream<AppUser?> watchUserSubscription(String userId) {
    return _firestore.collection('users').doc(userId).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) {
        return null;
      }
      return AppUser.fromJson(doc.data()!);
    });
  }
}

/// Provider for subscription service
final subscriptionServiceProvider = Provider<SubscriptionService>((ref) {
  return SubscriptionService();
});
