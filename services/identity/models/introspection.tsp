using Constellation.Common;

namespace Constellation.Identity;

/** Type hint of a token in an introspection request. The union is open. */
@friendlyName("IntrospectTokenTypeHint")
union IntrospectTokenTypeHint {
  "refresh_token",
  "access_token",
  "api_token",
  string,
}

/** Type of an introspected token. The union is open. */
@friendlyName("IntrospectedTokenType")
union IntrospectedTokenType {
  "api_token",
  string,
}

/**
 * Form body of an introspection request (RFC 7662).
 * The client fields are optional in the schema. A missing assertion gives the OAuth error `invalid_client`.
 */
@friendlyName("IntrospectRequest")
model IntrospectRequest {
  /** The token to introspect. */
  @secret
  @maxLength(512)
  token: string;

  /** Type of the token. */
  token_type_hint?: IntrospectTokenTypeHint;

  /** ID of the client. */
  client_id?: string;

  /** Type of the client assertion. It is `urn:ietf:params:oauth:client-assertion-type:jwt-bearer`. */
  client_assertion_type?: string;

  /** Signed JWT (`private_key_jwt`) that authenticates a service client. */
  @secret
  client_assertion?: string;
}

/**
 * Result of an introspection request (RFC 7662).
 * If `active` is false, no other field is present.
 */
@friendlyName("IntrospectResponse")
model IntrospectResponse {
  ...NoStoreHeaders;

  /** True if the token is active for the caller. */
  active: boolean;

  /** Permission keys of the token that the caller can use. */
  scope?: ScopeString;

  /** ID of the user. */
  `sub`?: string;

  /** The caller app. */
  aud?: AppKey;

  /** Expiry time in seconds since the Unix epoch. */
  exp?: int64;

  /** Issue time in seconds since the Unix epoch. */
  iat?: int64;

  /** ID of the API token. */
  jti?: string;

  /** Type of the token. It is `api_token` for an API token. */
  token_type?: IntrospectedTokenType;

  /** Type of the principal. It is `user`. */
  principal_type?: PrincipalType;
}
