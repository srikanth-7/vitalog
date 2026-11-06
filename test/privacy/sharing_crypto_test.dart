import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitalog/features/family_health/data/sharing/sharing_crypto.dart';

void main() {
  test('sealed profile data opens only with its key and its row', () async {
    final key = await SharingCrypto.newProfileKey();
    final box = await SharingCrypto.seal(utf8.encode('Ramesh Kumar'), key,
        aad: utf8.encode('profile-1'));
    expect(utf8.decode(box, allowMalformed: true), isNot(contains('Ramesh')));
    expect(
        utf8.decode(
            await SharingCrypto.open(box, key, aad: utf8.encode('profile-1'))),
        'Ramesh Kumar');
    // Moved to another row, or opened with another key: refused.
    await expectLater(
        SharingCrypto.open(box, key, aad: utf8.encode('profile-2')),
        throwsA(isA<SecretBoxAuthenticationError>()));
    await expectLater(
        SharingCrypto.open(box, await SharingCrypto.newProfileKey(),
            aad: utf8.encode('profile-1')),
        throwsA(isA<SecretBoxAuthenticationError>()));
  });

  test('a profile key wrapped for Dad opens only on Dad\'s phone', () async {
    final profileKey = await SharingCrypto.newProfileKey();
    final dad = await SharingCrypto.newAccountKeyPair();
    final stranger = await SharingCrypto.newAccountKeyPair();
    final wrapped =
        await SharingCrypto.wrapFor(profileKey, await dad.extractPublicKey());
    expect(await (await SharingCrypto.unwrap(wrapped, dad)).extractBytes(),
        await profileKey.extractBytes());
    await expectLater(SharingCrypto.unwrap(wrapped, stranger),
        throwsA(isA<SecretBoxAuthenticationError>()));
  });

  test('an invite opens with its link; the server copy alone is useless',
      () async {
    final profileKey = await SharingCrypto.newProfileKey();
    final invite = await SharingCrypto.newInvite(profileKey);

    // Shared text → parsed back on Dad's phone → profile key.
    final link = InviteLink.parse(invite.link.toUri().toString())!;
    final opened = await SharingCrypto.openInvite(link, invite.wrappedKey);
    expect(await opened.extractBytes(), await profileKey.extractBytes());

    // The server can check a claim, but only with the link's secret.
    expect(
        await SharingCrypto.claimHashFor(
            link.secret, base64Url.decode('${link.id}==')),
        invite.claimHash);

    // Without the #secret (all the server ever sees), nothing opens.
    final guess = InviteLink(id: invite.link.id, secret: List.filled(32, 0));
    await expectLater(SharingCrypto.openInvite(guess, invite.wrappedKey),
        throwsA(isA<SecretBoxAuthenticationError>()));
    expect(invite.link.toUri().path,
        isNot(contains(base64Url.encode(link.secret))));
  });

  test('only complete Vitalog invite links are accepted', () {
    expect(InviteLink.parse('https://vitalog.app/i/abc'), isNull); // no secret
    expect(InviteLink.parse('https://evil.example/i/abc#AAAA'), isNull);
    expect(InviteLink.parse('not a link'), isNull);
  });

  test('links are found in a pasted message and via the app scheme',
      () async {
    final invite = await SharingCrypto.newInvite(
        await SharingCrypto.newProfileKey());
    final web = invite.link.toUri().toString();
    final app = web.replaceFirst(
        'https://${InviteLink.host}/i/', '${InviteLink.appScheme}://invite/');
    for (final text in [web, 'Join me on Vitalog: $web.', app]) {
      final link = InviteLink.parse(text)!;
      expect(link.id, invite.link.id);
      expect(link.secret, invite.link.secret);
    }
    // A truncated secret is refused, not half-used.
    expect(InviteLink.parse(web.substring(0, web.length - 5)), isNull);
  });

  test('the claim token hashes to the stored claim hash; previews seal',
      () async {
    final invite = await SharingCrypto.newInvite(
        await SharingCrypto.newProfileKey());
    final token = await SharingCrypto.claimTokenFor(invite.link);
    expect(token, matches(RegExp(r'^[0-9a-f]{64}$')));
    // What open_invite() does: base64url(sha256(hex-decoded token)).
    final bytes = [
      for (var i = 0; i < token.length; i += 2)
        int.parse(token.substring(i, i + 2), radix: 16)
    ];
    expect(
        base64Url
            .encode((await Sha256().hash(bytes)).bytes)
            .replaceAll('=', ''),
        invite.claimHash);

    final box = await SharingCrypto.sealPreview(
        invite.link, utf8.encode('Ramesh Kumar'));
    expect(utf8.decode(await SharingCrypto.openPreview(invite.link, box)),
        'Ramesh Kumar');
    final other = await SharingCrypto.newInvite(
        await SharingCrypto.newProfileKey());
    await expectLater(SharingCrypto.openPreview(other.link, box),
        throwsA(isA<SecretBoxAuthenticationError>()));
  });
}
