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

/** The agent that acts for the subject of a token. */
@friendlyName("ActorClaim")
model ActorClaim {
  /** ID of the acting principal. */
  `sub`: string;

  /** Type of the acting principal. */
  principal_type: PrincipalType;
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

  /** The agent that acts for the subject. Reserved for token exchange. */
  act?: ActorClaim;
}
