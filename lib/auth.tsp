namespace Constellation.Common;

/**
 * Space-separated permission keys, for example `helpdesk:ticket:read helpdesk:ticket:write`.
 * It holds permission keys only. It never holds an OIDC scope.
 */
@pattern("^(?:[a-z][a-z0-9_]*:[a-z][a-z0-9_]*:[a-z][a-z0-9_]*|identity:admin)(?: (?:[a-z][a-z0-9_]*:[a-z][a-z0-9_]*:[a-z][a-z0-9_]*|identity:admin))*$")
@maxLength(4096)
@friendlyName("ScopeString")
scalar ScopeString extends string;

/**
 * Space-separated scope values in a token request or an authorize request.
 * Each value is a permission key or one of `openid`, `profile`, `email`, and `offline_access`.
 */
@pattern("^(?:[a-z][a-z0-9_]*:[a-z][a-z0-9_]*:[a-z][a-z0-9_]*|identity:admin|openid|profile|email|offline_access)(?: (?:[a-z][a-z0-9_]*:[a-z][a-z0-9_]*:[a-z][a-z0-9_]*|identity:admin|openid|profile|email|offline_access))*$")
@maxLength(4096)
@friendlyName("RequestScopeString")
scalar RequestScopeString extends string;

/** Reference to a role in the form `<app>:<role>`, for example `helpdesk:agent`. */
@pattern("^[a-z][a-z0-9_]*:[a-z][a-z0-9_]*$")
@maxLength(97)
@friendlyName("RoleRef")
scalar RoleRef extends string;

/** One or more application keys. Use it as the audience of a token. */
@minItems(1)
@friendlyName("AppKeyList")
model AppKeyList is AppKey[];

/** The agent that acts for the subject of a token. It has one level. It has no nested `act`. */
@friendlyName("ActorClaim")
model ActorClaim {
  /** ID of the acting principal. */
  `sub`: string;

  /** Type of the acting principal. */
  principal_type: PrincipalType;
}

/**
 * A method that the user used for the login of a session (RFC 8176).
 * RFC 8176 registers all values except `rec` and `fed`. The registered values are not a complete set.
 * The values are `pwd` (password), `otp` (TOTP code), `rec` (recovery code),
 * `hwk` (passkey), `user` (user verification of a passkey), `fed` (upstream OIDC login),
 * and `mfa` (two or more factors, or one passkey with user verification).
 * A service that needs MFA checks that `amr` contains `mfa`. It does not check the other values.
 */
@friendlyName("AuthenticationMethod")
union AuthenticationMethod {
  string,
  "pwd",
  "otp",
  "rec",
  "hwk",
  "user",
  "fed",
  "mfa",
}

/**
 * Claims of an access token (RFC 9068).
 * The JWT header `typ` is `at+jwt`. The header `alg` is `ES256`.
 * The identity service writes `aud` as one string and always sets `nbf`.
 * A verifier accepts both forms of `aud`.
 */
@friendlyName("AccessTokenClaims")
model AccessTokenClaims {
  /** Issuer of the token: the URL of the identity service. */
  iss: url;

  /** ID of the principal: a user, a service, an agent, or a workflow. */
  `sub`: string;

  /** Audience of the token: one application key, or an array of application keys. */
  aud: AppKey | AppKeyList;

  /** Expiry time in seconds since the Unix epoch. */
  exp: int64;

  /** Issue time in seconds since the Unix epoch. */
  iat: int64;

  /** Time in seconds since the Unix epoch before which a verifier must not accept the token. */
  nbf?: int64;

  /** Unique ID of the token. */
  jti: string;

  /** ID of the client that asked for the token. */
  client_id: string;

  /** Permission keys that the token grants. */
  scope: ScopeString;

  /** Type of the principal in `sub`. */
  principal_type: PrincipalType;

  /**
   * The agent that acts for the subject. The identity service sets it for a token exchange with an actor.
   * `act.principal_type` is `agent`. `act.sub` is the ID of the agent.
   */
  act?: ActorClaim;

  /**
   * The methods that the user used for the login of the session.
   * Only in user tokens from the code flow and from refresh.
   * Not in service, agent, workflow, or exchange tokens.
   * Absent when the session has no recorded method.
   */
  amr?: AuthenticationMethod[];

  /** The time of the last login of the session, in seconds since the Unix epoch. Only in user tokens from the code flow and from refresh. */
  auth_time?: int64;
}
