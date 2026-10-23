import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

/// End-to-end encryption for shared profiles (docs/SHARING.md). The server
/// stores only what this file produces: sealed boxes it can't open, wrapped
/// keys it can't unwrap, and a claim hash it can check but not reverse.
///
/// - Every profile has its own random AES-256 **profile key**. Everything
///   about the profile (name, sex, birth year, reports, results) is sealed
///   with it on the phone before upload.
/// - Every account has an X25519 **account key pair**, made on the phone; the
///   private half never leaves the Keychain / Keystore.
/// - Access = the profile key wrapped for an account's public key.
/// - An invite = the profile key wrapped with a key derived from a random
///   secret that travels only in the link's `#fragment`.
abstract final class SharingCrypto {
  static final _aes = AesGcm.with256bits();
  static final _x25519 = X25519();
  static final _hkdf = Hkdf(hmac: Hmac.sha256(), outputLength: 32);

  // Domain separation: a key derived for one purpose is useless for another.
  static final _wrapInfo = utf8.encode('vitalog/wrap/v1');
  static final _inviteInfo = utf8.encode('vitalog/invite/v1');
  static final _claimInfo = utf8.encode('vitalog/claim/v1');

  static Future<SecretKey> newProfileKey() => _aes.newSecretKey();

  static Future<SimpleKeyPair> newAccountKeyPair() => _x25519.newKeyPair();

  /// nonce ‖ ciphertext ‖ mac. [aad] binds the box to where it belongs (e.g.
  /// the profile id), so a box can't be moved to another row unnoticed.
  static Future<Uint8List> seal(List<int> clear, SecretKey key,
      {List<int> aad = const []}) async {
    final box = await _aes.encrypt(clear, secretKey: key, aad: aad);
    return Uint8List.fromList(box.concatenation());
  }

  /// Throws [SecretBoxAuthenticationError] on a wrong key, tampering or a
  /// box moved to a different [aad].
  static Future<List<int>> open(List<int> sealed, SecretKey key,
          {List<int> aad = const []}) =>
      _aes.decrypt(
          SecretBox.fromConcatenation(sealed,
              nonceLength: _aes.nonceLength,
              macLength: _aes.macAlgorithm.macLength),
          secretKey: key,
          aad: aad);

  /// [profileKey] sealed so only the holder of [recipient]'s private key can
  /// open it: ephemeral X25519 → HKDF → AES-GCM. Output: ephemeral public
  /// key (32 bytes) ‖ sealed key.
  static Future<Uint8List> wrapFor(
      SecretKey profileKey, SimplePublicKey recipient) async {
    final ephemeral = await _x25519.newKeyPair();
    final ephemeralPublic = await ephemeral.extractPublicKey();
    final kek = await _wrapKey(
        await _x25519.sharedSecretKey(
            keyPair: ephemeral, remotePublicKey: recipient),
        ephemeralPublic.bytes,
        recipient.bytes);
    final sealed = await seal(await profileKey.extractBytes(), kek,
        aad: [...ephemeralPublic.bytes, ...recipient.bytes]);
    return Uint8List.fromList([...ephemeralPublic.bytes, ...sealed]);
  }

  static Future<SecretKey> unwrap(List<int> wrapped, SimpleKeyPair me) async {
    final ephemeralPublic = wrapped.sublist(0, 32);
    final mine = await me.extractPublicKey();
    final kek = await _wrapKey(
        await _x25519.sharedSecretKey(
            keyPair: me,
            remotePublicKey:
                SimplePublicKey(ephemeralPublic, type: KeyPairType.x25519)),
        ephemeralPublic,
        mine.bytes);
    return SecretKey(await open(wrapped.sublist(32), kek,
        aad: [...ephemeralPublic, ...mine.bytes]));
  }

  static Future<SecretKey> _wrapKey(
          SecretKey shared, List<int> ephemeral, List<int> recipient) =>
      _hkdf.deriveKey(
          secretKey: shared,
          nonce: [...ephemeral, ...recipient],
          info: _wrapInfo);

  /// Makes an invite for [profileKey]. The returned [Invite.link] is what
  /// the user shares; [Invite.wrappedKey] and [Invite.claimHash] go to the
  /// server. Neither lets the server (or a thief of its data) open the key.
  static Future<Invite> newInvite(SecretKey profileKey) async {
    final id = _random(16);
    final secret = _random(32);
    return Invite(
      link: InviteLink(id: _b64(id), secret: secret),
      wrappedKey: await seal(
          await profileKey.extractBytes(), await _inviteKey(secret, id),
          aad: id),
      claimHash: await claimHashFor(secret, id),
    );
  }

  /// The claimant's phone opens the invite with the link's secret.
  static Future<SecretKey> openInvite(
      InviteLink link, List<int> wrappedKey) async {
    final id = _unb64(link.id);
    return SecretKey(
        await open(wrappedKey, await _inviteKey(link.secret, id), aad: id));
  }

  /// What the server stores and compares to accept a claim exactly once.
  /// One-way, and derived separately from the key that opens the invite,
  /// so knowing it doesn't help open anything.
  static Future<String> claimHashFor(List<int> secret, List<int> id) async {
    final token = await _hkdf.deriveKey(
        secretKey: SecretKey(secret), nonce: id, info: _claimInfo);
    final digest = await Sha256().hash(await token.extractBytes());
    return _b64(digest.bytes);
  }

  static Future<SecretKey> _inviteKey(List<int> secret, List<int> id) => _hkdf
      .deriveKey(secretKey: SecretKey(secret), nonce: id, info: _inviteInfo);

  static List<int> _random(int n) => SecretKeyData.random(length: n).bytes;
}

class Invite {
  const Invite(
      {required this.link, required this.wrappedKey, required this.claimHash});
  final InviteLink link;
  final Uint8List wrappedKey;
  final String claimHash;
}

/// `https://<host>/i/<id>#<secret>`. Browsers and apps never send the part
/// after `#` to a server, so the secret only exists in the shared message.
class InviteLink {
  const InviteLink({required this.id, required this.secret});
  final String id;
  final List<int> secret;

  // ponytail: placeholder host; set the real domain once app links
  // (Android App Links / iOS Universal Links) are configured for it.
  static const host = 'vitalog.app';

  Uri toUri() =>
      Uri(scheme: 'https', host: host, path: '/i/$id', fragment: _b64(secret));

  /// Null for anything that isn't a complete Vitalog invite link.
  static InviteLink? parse(String text) {
    final uri = Uri.tryParse(text.trim());
    if (uri == null || uri.host != host || uri.pathSegments.length != 2) {
      return null;
    }
    if (uri.pathSegments.first != 'i' || uri.fragment.isEmpty) return null;
    try {
      final secret = _unb64(uri.fragment);
      return secret.length == 32
          ? InviteLink(id: uri.pathSegments.last, secret: secret)
          : null;
    } on FormatException {
      return null;
    }
  }
}

String _b64(List<int> bytes) => base64Url.encode(bytes).replaceAll('=', '');

List<int> _unb64(String s) =>
    base64Url.decode(s.padRight(s.length + (4 - s.length % 4) % 4, '='));
