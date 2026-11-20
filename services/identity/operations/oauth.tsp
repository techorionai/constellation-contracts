using Http;
using Constellation.Common;

namespace Constellation.Identity;

/**
 * OAuth 2.0 and OIDC endpoints. They use standard paths with no `/v1` prefix.
 * Errors follow RFC 6749. The token and revoke operations authenticate the client in the form body.
 * A service client uses `private_key_jwt`. A public client sends `client_id` only.
 */
@route("/oauth")
interface OAuth {
  /**
   * Get an access token. The `grant_type` is `client_credentials`, `authorization_code`, or `refresh_token`.
   * The `scope` of the request can have OIDC scopes. The `scope` of the response has permission keys only.
   * The response has the headers `Cache-Control: no-store` and `Pragma: no-cache`.
   */
  @useAuth(NoAuth)
  @route("/token")
  @post
  token(
    @header contentType: "application/x-www-form-urlencoded",
    @body body: TokenRequest,
  ): TokenResponse | OAuthError;

  /**
   * Revoke a token (RFC 7009).
   * The response is 200 with no body. This is also true for an unknown token.
   */
  @useAuth(NoAuth)
  @route("/revoke")
  @post
  revoke(
    @header contentType: "application/x-www-form-urlencoded",
    @body body: RevokeRequest,
  ):
    | {
        @statusCode _: 200;
      }
    | OAuthError;

  /**
   * Get the claims of the user of an access token.
   * It accepts a user access token of the identity issuer with any audience.
   * All clients are first-party, so the response has all four claims.
   * A service token gets 403 with `error="insufficient_scope"`.
   * The response has the headers `Cache-Control: no-store` and `Pragma: no-cache`.
   */
  @route("/userinfo")
  @get
  userinfo(): UserInfo | InvalidToken | InsufficientScope;

  /**
   * Start the authorization code flow with PKCE.
   * The server shows a login page, or it redirects with `code` and `state`, or with an error.
   * The query has `response_type` (`code`), `client_id`, `redirect_uri`, `scope`, `state`, `nonce`,
   * `code_challenge`, and `code_challenge_method` (`S256`). `prompt` and `max_age` are optional.
   */
  @useAuth(NoAuth)
  @route("/authorize")
  @get
  authorize(
    @query response_type: "code",
    @query client_id: string,
    @query redirect_uri: string,
    @query scope: RequestScopeString,
    @query state: string,
    @query nonce: string,
    @query code_challenge: string,
    @query code_challenge_method: "S256",
    @query prompt?: string,
    @query max_age?: int32,
  ): HtmlPage | Redirect;

  /**
   * End the session of a user (OIDC RP-initiated logout).
   * The server shows a page, or it redirects to `post_logout_redirect_uri` with `state`.
   */
  @useAuth(NoAuth)
  @route("/end_session")
  @get
  endSession(
    @query id_token_hint?: string,
    @query post_logout_redirect_uri?: string,
    @query state?: string,
  ): HtmlPage | Redirect;
}
