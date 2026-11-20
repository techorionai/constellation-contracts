using Http;
using Constellation.Common;

namespace Constellation.Identity;

/** Grant type of a token request. The union is open, so a later release can add a grant type. */
@friendlyName("GrantType")
union GrantType {
  "client_credentials",
  "authorization_code",
  "refresh_token",
  string,
}

/** Form body of a token request. The OAuth field names are in snake case, as RFC 6749 requires. */
@friendlyName("TokenRequest")
model TokenRequest {
  /** The grant type. */
  grant_type: GrantType;

  /** ID of the client. */
  client_id?: string;

  /** Type of the client assertion. For a service client it is `urn:ietf:params:oauth:client-assertion-type:jwt-bearer`. */
  client_assertion_type?: string;

  /** Signed JWT (`private_key_jwt`) that authenticates a service client. */
  @secret
  client_assertion?: string;

  /** Requested scopes. */
  scope?: RequestScopeString;

  /** Application key of the audience of the access token. */
  audience?: AppKey;

  /** Authorization code. For the grant `authorization_code`. */
  @secret
  code?: string;

  /** PKCE code verifier. For the grant `authorization_code`. */
  @secret
  code_verifier?: string;

  /** Redirect URI of the authorize request. For the grant `authorization_code`. */
  redirect_uri?: string;

  /** Refresh token. For the grant `refresh_token`. */
  @secret
  refresh_token?: string;
}

/** Result of a successful token request. */
@friendlyName("TokenResponse")
model TokenResponse {
  /** The access token. */
  @secret
  access_token: string;

  /** Type of the token. */
  token_type: "Bearer";

  /** Lifetime of the access token in seconds. */
  expires_in: int32;

  /** Permission keys that the access token grants. It has no OIDC scope. */
  scope: ScopeString;

  /** Refresh token. Present if the request had the scope `offline_access`. */
  @secret
  refresh_token?: string;

  /** ID token. Present if the request had the scope `openid`. */
  @secret
  id_token?: string;
}

/** Type hint of a token in a revoke request. The union is open. */
@friendlyName("TokenTypeHint")
union TokenTypeHint {
  "refresh_token",
  "access_token",
  string,
}

/** Form body of a revoke request (RFC 7009). */
@friendlyName("RevokeRequest")
model RevokeRequest {
  /** The token to revoke. */
  @secret
  token: string;

  /** Type of the token. */
  token_type_hint?: TokenTypeHint;

  /** ID of the client. */
  client_id?: string;

  /** Type of the client assertion. */
  client_assertion_type?: string;

  /** Signed JWT that authenticates a service client. */
  @secret
  client_assertion?: string;
}

/** Error code of an OAuth operation. The union is open. */
@friendlyName("OAuthErrorCode")
union OAuthErrorCode {
  "invalid_request",
  "invalid_client",
  "invalid_grant",
  "unauthorized_client",
  "unsupported_grant_type",
  "invalid_scope",
  "invalid_target",
  "unsupported_token_type",
  "temporarily_unavailable",
  "server_error",
  string,
}

/**
 * Error body of an OAuth operation (RFC 6749 section 5.2).
 * The status is 400, except for these codes. `invalid_client` is 401.
 * `server_error` is 500. `temporarily_unavailable` is 503.
 */
@error
@friendlyName("OAuthError")
model OAuthError {
  /** Media type of the response. */
  @header contentType: "application/json";

  /** Status of the response. */
  @statusCode statusCode: 400 | 401 | 500 | 503;

  /** The error code. */
  error: OAuthErrorCode;

  /** Text for a developer. It has no internal data and no secret. */
  error_description?: string;
}

/** The access token is not valid (RFC 6750). The response has no body. */
@error
@friendlyName("InvalidToken")
model InvalidToken {
  /** Status of the response. */
  @statusCode statusCode: 401;

  /** Challenge, for example `Bearer error="invalid_token"`. */
  @header("WWW-Authenticate") wwwAuthenticate: string;
}

/** The access token has the wrong type (RFC 6750). The response has no body. */
@error
@friendlyName("InsufficientScope")
model InsufficientScope {
  /** Status of the response. */
  @statusCode statusCode: 403;

  /** Challenge, for example `Bearer error="insufficient_scope"`. */
  @header("WWW-Authenticate") wwwAuthenticate: string;
}

/** A page that the server shows to a person in a browser. */
@friendlyName("HtmlPage")
model HtmlPage {
  /** Media type of the response. */
  @header contentType: "text/html";

  /** Status of the response. */
  @statusCode statusCode: 200;

  /** The HTML text. */
  @body body: string;
}

/** A redirect to another URL. */
@friendlyName("Redirect")
model Redirect {
  /** Status of the response. */
  @statusCode statusCode: 302;

  /** The URL to go to. */
  @header location: string;
}
