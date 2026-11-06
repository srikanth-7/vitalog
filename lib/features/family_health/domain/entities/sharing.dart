// Family sharing (docs/SHARING.md): who can see a profile, and invites.

/// Someone with access to a shared profile. [name] is what they call
/// themselves (sealed on the server); null when it couldn't be read.
class SharedPerson {
  const SharedPerson(
      {required this.userId, required this.name, required this.isYou});
  final String userId;
  final String? name;
  final bool isYou;
}

class PendingInvite {
  const PendingInvite({required this.id, required this.expiresAt});
  final String id;
  final DateTime expiresAt;
}

/// The family card: everyone with access, and invites not yet used.
class ProfileSharing {
  const ProfileSharing({required this.people, required this.pending});
  final List<SharedPerson> people;
  final List<PendingInvite> pending;
}

enum InviteStatus {
  ok,

  /// This account can already see the profile.
  already,

  /// Someone else used it (one use only).
  used,
  expired,

  /// Unknown, cancelled, tampered with, or locked after wrong tries.
  gone,

  /// Too many wrong tries from this account; wait an hour.
  limited,

  /// Not a Vitalog invite link at all.
  invalid,
}

/// What a link says before it's accepted: [name] was shared with you by
/// [from], with [reports] reports.
class InvitePreview {
  const InvitePreview(this.status,
      {this.name, this.from, this.reports = 0, this.profileId});
  final InviteStatus status;
  final String? name;
  final String? from;
  final int reports;
  final String? profileId;
}

/// A new invite: the link to share (the secret is in its `#fragment`), and
/// the recovery key when making it created this account's key.
typedef NewInvite = ({Uri link, String? newRecoveryKey});

/// An accepted invite: [status] ok or already → [memberId] is the member it
/// became on this phone; anything else → nothing changed.
typedef AcceptedInvite = ({
  InviteStatus status,
  String? memberId,
  String? newRecoveryKey,
});

/// The profile can't be shared yet (a sample member, or not signed in).
class CannotShare implements Exception {
  const CannotShare();
}

/// Sharing failed after this account's key was made: the recovery key
/// still has to be shown once.
class SharingFailed implements Exception {
  const SharingFailed(this.cause, {required this.newRecoveryKey});
  final Object cause;
  final String? newRecoveryKey;
}
