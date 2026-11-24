using Constellation.Common;

namespace Constellation.Identity;

/** A personal API token. It has no secret. */
@friendlyName("ApiToken")
model ApiToken {
  /** ID of the token. */
  @format("uuid")
  id: string;

  /** ID of the user that owns the token. */
  userId: string;

  /** Name of the token. */
  @minLength(1)
  @maxLength(100)
  name: string;

  /** Permission keys of the token. */
  scope: ScopeString;

  /** Time when the token was created. */
  createdAt: utcDateTime;

  /** Time when the token expires. */
  expiresAt: utcDateTime;

  /** Time when the token was last used. */
  lastUsedAt?: utcDateTime;

  /** Time when the token was revoked. */
  revokedAt?: utcDateTime;
}

/** Request to create a personal API token. */
@friendlyName("ApiTokenCreate")
model ApiTokenCreate {
  /** Name of the token. */
  @minLength(1)
  @maxLength(100)
  name: string;

  /** Permission keys of the token, at least one. An OIDC scope is not valid. */
  scope: ScopeString;

  /** Days until the token expires. The identity service can set a lower maximum. */
  @minValue(1)
  @maxValue(365)
  expiresInDays?: int32 = 90;
}

/** A new personal API token. The response has the token one time only. */
@friendlyName("ApiTokenCreated")
model ApiTokenCreated {
  ...ApiToken;

  /**
   * The token. The format is `cpat_` followed by 43 base64url characters (32 random bytes).
   * The identity service shows it one time only.
   */
  @secret
  token: string;
}

/** One page of personal API tokens. */
model ApiTokenPage is CursorPage<ApiToken>;
