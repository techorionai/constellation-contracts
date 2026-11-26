using Constellation.Common;

namespace Constellation.Identity;

/**
 * A passkey (WebAuthn credential) of a user. It has no key material.
 * The name rule: the name has no leading or trailing white space and no line break.
 * Names are not unique for a user. The service stores the name as sent.
 */
@friendlyName("Passkey")
model Passkey {
  /** ID in the identity service. It is not the WebAuthn credential ID. */
  @format("uuid")
  id: string;

  /**
   * A name that the user gives. The name has no leading or trailing white space and no line break.
   * Names are not unique for a user. The service stores the name as sent.
   */
  @minLength(1)
  @maxLength(64)
  @pattern("^\\S(.*\\S)?$")
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
   * The new name. The name has no leading or trailing white space and no line break.
   * Names are not unique for a user. The service stores the name as sent.
   */
  @minLength(1)
  @maxLength(64)
  @pattern("^\\S(.*\\S)?$")
  name: string;
}

/** One page of passkeys. */
model PasskeyPage is CursorPage<Passkey>;
