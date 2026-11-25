namespace Constellation.Identity;

/** The TOTP factor of a user. */
@friendlyName("TotpStatus")
model TotpStatus {
  /** The time of the TOTP setup. */
  createdAt: utcDateTime;

  /** The time of the last accepted TOTP code. Absent when no code was used. */
  lastUsedAt?: utcDateTime;
}

/** The MFA state of a user. A client ignores a field that it does not know. */
@friendlyName("MfaStatus")
model MfaStatus {
  /** The user has one or more second factors. */
  enabled: boolean;

  /** The policy requires MFA for this user, for example an admin. */
  required: boolean;

  /** Present when TOTP is set up. Absent when TOTP is not set up. */
  totp?: TotpStatus;

  /** The number of recovery codes that are not used. */
  @minValue(0)
  @maxValue(10)
  recoveryCodesRemaining: int32;
}
