class FriendInvitationModel {
  final int friendshipId;
  final int userId;
  final String name;
  final String email;

  const FriendInvitationModel({
    required this.friendshipId,
    required this.userId,
    required this.name,
    required this.email,
  });

  factory FriendInvitationModel.fromJson(Map<String, dynamic> json) {
    return FriendInvitationModel(
      friendshipId: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      userId: int.tryParse(json['user_id']?.toString() ?? '') ?? 0,
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
    );
  }
}

class SocialStreakModel {
  final int id;
  final int friendshipId;
  final int friendId;
  final String friendName;
  final String friendEmail;
  final int currentStreak;
  final int longestStreak;
  final bool meCheckedIn;
  final bool friendCheckedIn;
  final bool nudgedMeToday;

  const SocialStreakModel({
    required this.id,
    required this.friendshipId,
    required this.friendId,
    required this.friendName,
    required this.friendEmail,
    required this.currentStreak,
    required this.longestStreak,
    required this.meCheckedIn,
    required this.friendCheckedIn,
    required this.nudgedMeToday,
  });

  factory SocialStreakModel.fromJson(Map<String, dynamic> json) {
    return SocialStreakModel(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      friendshipId: int.tryParse(json['friendship_id']?.toString() ?? '') ?? 0,
      friendId: int.tryParse(json['friend_id']?.toString() ?? '') ?? 0,
      friendName: json['friend_name']?.toString() ?? '',
      friendEmail: json['friend_email']?.toString() ?? '',
      currentStreak:
          int.tryParse(json['current_streak']?.toString() ?? '') ?? 0,
      longestStreak:
          int.tryParse(json['longest_streak']?.toString() ?? '') ?? 0,
      meCheckedIn:
          json['me_checked_in'] == true ||
          json['me_checked_in']?.toString() == '1',
      friendCheckedIn:
          json['friend_checked_in'] == true ||
          json['friend_checked_in']?.toString() == '1',
      nudgedMeToday:
          json['nudged_me_today'] == true ||
          json['nudged_me_today']?.toString() == '1',
    );
  }
}

class SocialOverviewModel {
  final List<FriendInvitationModel> pendingInvitations;
  final List<SocialStreakModel> streaks;

  const SocialOverviewModel({
    this.pendingInvitations = const [],
    this.streaks = const [],
  });

  factory SocialOverviewModel.fromJson(Map<String, dynamic> json) {
    return SocialOverviewModel(
      pendingInvitations: (json['pending_invitations'] as List? ?? const [])
          .whereType<Map>()
          .map(
            (item) =>
                FriendInvitationModel.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList(),
      streaks: (json['streaks'] as List? ?? const [])
          .whereType<Map>()
          .map(
            (item) =>
                SocialStreakModel.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList(),
    );
  }
}
