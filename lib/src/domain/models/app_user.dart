/// Subscription plan types
enum SubscriptionPlan {
  free,
  pro,
}

/// Represents a user in the app
class AppUser {
  final String id;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final SubscriptionPlan subscriptionPlan;
  final int mindMapCount;
  final int aiUsageCount;
  final int maxMindMaps;
  final int maxMonthlyAiUsage;
  final DateTime createdAt;
  final DateTime? lastLoginAt;
  final DateTime? aiUsageResetDate;
  final DateTime? subscriptionStartDate;
  final DateTime? subscriptionEndDate;

  AppUser({
    required this.id,
    required this.email,
    this.displayName,
    this.photoUrl,
    this.subscriptionPlan = SubscriptionPlan.free,
    this.mindMapCount = 0,
    this.aiUsageCount = 0,
    int? maxMindMaps,
    int? maxMonthlyAiUsage,
    DateTime? createdAt,
    this.lastLoginAt,
    this.aiUsageResetDate,
    this.subscriptionStartDate,
    this.subscriptionEndDate,
  })  : maxMindMaps = maxMindMaps ?? (subscriptionPlan == SubscriptionPlan.pro ? -1 : 3),
        maxMonthlyAiUsage =
            maxMonthlyAiUsage ?? (subscriptionPlan == SubscriptionPlan.pro ? -1 : 10),
        createdAt = createdAt ?? DateTime.now();

  bool get canCreateMindMap {
    if (subscriptionPlan == SubscriptionPlan.pro) return true;
    return mindMapCount < maxMindMaps;
  }

  bool get canUseAi {
    if (subscriptionPlan == SubscriptionPlan.pro) return true;
    return aiUsageCount < maxMonthlyAiUsage;
  }

  bool get isPro => subscriptionPlan == SubscriptionPlan.pro;

  AppUser copyWith({
    String? id,
    String? email,
    String? displayName,
    String? photoUrl,
    SubscriptionPlan? subscriptionPlan,
    int? mindMapCount,
    int? aiUsageCount,
    int? maxMindMaps,
    int? maxMonthlyAiUsage,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    DateTime? aiUsageResetDate,
    DateTime? subscriptionStartDate,
    DateTime? subscriptionEndDate,
  }) {
    return AppUser(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      subscriptionPlan: subscriptionPlan ?? this.subscriptionPlan,
      mindMapCount: mindMapCount ?? this.mindMapCount,
      aiUsageCount: aiUsageCount ?? this.aiUsageCount,
      maxMindMaps: maxMindMaps ?? this.maxMindMaps,
      maxMonthlyAiUsage: maxMonthlyAiUsage ?? this.maxMonthlyAiUsage,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      aiUsageResetDate: aiUsageResetDate ?? this.aiUsageResetDate,
      subscriptionStartDate: subscriptionStartDate ?? this.subscriptionStartDate,
      subscriptionEndDate: subscriptionEndDate ?? this.subscriptionEndDate,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'subscriptionPlan': subscriptionPlan.name,
      'mindMapCount': mindMapCount,
      'aiUsageCount': aiUsageCount,
      'maxMindMaps': maxMindMaps,
      'maxMonthlyAiUsage': maxMonthlyAiUsage,
      'createdAt': createdAt.toIso8601String(),
      'lastLoginAt': lastLoginAt?.toIso8601String(),
      'aiUsageResetDate': aiUsageResetDate?.toIso8601String(),
      'subscriptionStartDate': subscriptionStartDate?.toIso8601String(),
      'subscriptionEndDate': subscriptionEndDate?.toIso8601String(),
    };
  }

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as String,
      email: json['email'] as String,
      displayName: json['displayName'] as String?,
      photoUrl: json['photoUrl'] as String?,
      subscriptionPlan: SubscriptionPlan.values.firstWhere(
        (p) => p.name == json['subscriptionPlan'],
        orElse: () => SubscriptionPlan.free,
      ),
      mindMapCount: json['mindMapCount'] as int? ?? 0,
      aiUsageCount: json['aiUsageCount'] as int? ?? 0,
      maxMindMaps: json['maxMindMaps'] as int?,
      maxMonthlyAiUsage: json['maxMonthlyAiUsage'] as int?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      lastLoginAt: json['lastLoginAt'] != null
          ? DateTime.parse(json['lastLoginAt'] as String)
          : null,
      aiUsageResetDate: json['aiUsageResetDate'] != null
          ? DateTime.parse(json['aiUsageResetDate'] as String)
          : null,
      subscriptionStartDate: json['subscriptionStartDate'] != null
          ? DateTime.parse(json['subscriptionStartDate'] as String)
          : null,
      subscriptionEndDate: json['subscriptionEndDate'] != null
          ? DateTime.parse(json['subscriptionEndDate'] as String)
          : null,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppUser && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
