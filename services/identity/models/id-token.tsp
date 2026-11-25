using Constellation.Common;

namespace Constellation.Identity;

/** List of client IDs. */
@minItems(1)
model IdTokenAudienceList is string[];

/** The audience of an ID token: one client ID, or an array with one or more client IDs. */
@friendlyName("IdTokenAudience")
union IdTokenAudience {
  string,
  IdTokenAudienceList,
}

/**
 * Claims of an ID token (OIDC Core 1.0 section 2).
 * The identity service writes `aud` as one string. A verifier accepts both forms.
 */
@friendlyName("IdTokenClaims")
model IdTokenClaims {
  /** The URL of the identity service. */
  iss: url;

  /** The ID of the user. */
  `sub`: string;

  /** The client ID. */
  aud: IdTokenAudience;

  /** Expiry time in seconds since the Unix epoch. */
  exp: int64;

  /** Issue time in seconds since the Unix epoch. */
  iat: int64;

  /** The time of the last login of the session. The identity service always sets it. */
  auth_time: int64;

  /** The `nonce` of the authorize request. */
  nonce?: string;

  /** The ID of the session (OIDC Front-Channel and Back-Channel Logout). */
  sid?: string;

  /** The methods that the user used for the login of the session. The same rule as in `AccessTokenClaims`. */
  amr?: AuthenticationMethod[];

  /** Only with the scope `email`. */
  email?: string;

  /** Only with the scope `email`. */
  email_verified?: boolean;

  /** Only with the scope `profile`. */
  name?: string;
}
