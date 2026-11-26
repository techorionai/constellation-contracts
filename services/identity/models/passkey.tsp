using Constellation.Common;

namespace Constellation.Identity;

/**
 * A passkey (WebAuthn credential) of a user. It has no key material.
 * The name rule: see the `name` field.
 * Names are not unique for a user. The service stores the name as sent.
 */
@friendlyName("Passkey")
model Passkey {
  /** ID in the identity service. It is not the WebAuthn credential ID. */
  @format("uuid")
  id: string;

  /**
   * A name that the user gives. The name has no leading or trailing white space, no control character, no format character (for example U+200B or U+202E), and no line or paragraph separator.
   * The pattern uses Unicode property classes. A client must use it in Unicode mode (the `u` flag in ECMAScript). It then gives the same result as Go RE2.
   * Names are not unique for a user. The service stores the name as sent.
   */
  @minLength(1)
  @maxLength(64)
  @pattern("^[^\\p{Cc}\\p{Cf}\\p{Zl}\\p{Zp}\\p{Zs}](?:[^\\p{Cc}\\p{Cf}\\p{Zl}\\p{Zp}]*[^\\p{Cc}\\p{Cf}\\p{Zl}\\p{Zp}\\p{Zs}])?$")
  name: string;

  /** The time of the registration. */
  createdAt: utcDateTime;

  /** The time of the last accepted assertion. Absent when the passkey was not used. */
  lastUsedAt?: utcDateTime;

  /** The authenticator says that the credential is backed up (WebAuthn flag BS) at the last registration or assertion. */
  synced: boolean;
}

/** Request to rename a passkey. */
@friendlyName("PasskeyUpdate")
model PasskeyUpdate {
  /**
   * The new name. The name has no leading or trailing white space, no control character, no format character (for example U+200B or U+202E), and no line or paragraph separator.
   * The pattern uses Unicode property classes. A client must use it in Unicode mode (the `u` flag in ECMAScript). It then gives the same result as Go RE2.
   * Names are not unique for a user. The service stores the name as sent.
   */
  @minLength(1)
  @maxLength(64)
  @pattern("^[^\\p{Cc}\\p{Cf}\\p{Zl}\\p{Zp}\\p{Zs}](?:[^\\p{Cc}\\p{Cf}\\p{Zl}\\p{Zp}]*[^\\p{Cc}\\p{Cf}\\p{Zl}\\p{Zp}\\p{Zs}])?$")
  name: string;
}

/** One page of passkeys. */
model PasskeyPage is CursorPage<Passkey>;
