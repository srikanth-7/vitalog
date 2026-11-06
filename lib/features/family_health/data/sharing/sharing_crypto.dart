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

  /// What the server stores and compares to accept a claim exactly once:
  /// SHA-256 of the claim token. One-way, and derived separately from the
  /// key that opens the invite, so knowing it doesn't help open anything.
  static Future<String> claimHashFor(List<int> secret, List<int> id) async {
    final digest = await Sha256().hash(await _claimToken(secret, id));
    return _b64(digest.bytes);
  }

  /// The claim token the claimant sends (hex); `open_invite` hashes it.
  static Future<String> claimTokenFor(InviteLink link) async => [
        for (final b in await _claimToken(link.secret, _unb64(link.id)))
          b.toRadixString(16).padLeft(2, '0')
      ].join();

  static Future<List<int>> _claimToken(List<int> secret, List<int> id) async =>
      (await _hkdf.deriveKey(
              secretKey: SecretKey(secret), nonce: id, info: _claimInfo))
          .extractBytes();

  /// The invite's preview ("who shared whom"), sealed with the invite key,
  /// so only someone holding the link can read it before claiming.
  static Future<Uint8List> sealPreview(InviteLink link, List<int> clear) async {
    final id = _unb64(link.id);
    return seal(clear, await _inviteKey(link.secret, id),
        aad: utf8.encode('preview:${link.id}'));
  }

  static Future<List<int>> openPreview(
      InviteLink link, List<int> sealed) async {
    final id = _unb64(link.id);
    return open(sealed, await _inviteKey(link.secret, id),
        aad: utf8.encode('preview:${link.id}'));
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

  /// The invite web host: serves the "Open in Vitalog" page at `/i/<id>`
  /// and the app-link files (invite_site/). Change it here AND in
  /// AndroidManifest.xml (and the iOS associated domain, when added).
  // ponytail: placeholder until the product owner picks the domain.
  static const host = 'vitalog.app';

  /// The app's own scheme: the web page hands the link over with it when the
  /// phone didn't open the app directly (no app link verified yet).
  static const appScheme = 'com.vitalog.app';

  Uri toUri() =>
      Uri(scheme: 'https', host: host, path: '/i/$id', fragment: _b64(secret));

  /// Null for anything that isn't a complete Vitalog invite link:
  /// `https://<host>/i/<id>#<secret>` or `com.vitalog.app://invite/<id>#…`.
  /// Tolerates text around it (a pasted message).
  static InviteLink? parse(String text) {
    final found =
        RegExp(r'(https://|com\.vitalog\.app://)[^\s#]+#[A-Za-z0-9_-]+')
            .firstMatch(text);
    final uri = found == null ? null : Uri.tryParse(found[0]!);
    if (uri == null || uri.fragment.isEmpty) return null;
    final String id;
    if (uri.scheme == 'https' &&
        uri.host == host &&
        uri.pathSegments.length == 2 &&
        uri.pathSegments.first == 'i') {
      id = uri.pathSegments.last;
    } else if (uri.scheme == appScheme &&
        uri.host == 'invite' &&
        uri.pathSegments.length == 1) {
      id = uri.pathSegments.single;
    } else {
      return null;
    }
    try {
      final secret = _unb64(uri.fragment);
      return secret.length == 32 && _unb64(id).length == 16
          ? InviteLink(id: id, secret: secret)
          : null;
    } on FormatException {
      return null;
    }
  }
}

String _b64(List<int> bytes) => base64Url.encode(bytes).replaceAll('=', '');

List<int> _unb64(String s) =>
    base64Url.decode(s.padRight(s.length + (4 - s.length % 4) % 4, '='));
