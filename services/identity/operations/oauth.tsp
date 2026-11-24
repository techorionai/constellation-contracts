using Http;
using Constellation.Common;

namespace Constellation.Identity;

/**
 * OAuth 2.0 and OIDC endpoints. They use standard paths with no `/v1` prefix.
 * Errors follow RFC 6749. The token and revoke operations authenticate the client in the form body.
 * A service client uses `private_key_jwt`. A public client sends `client_id` only.
 * This text applies to the token and revoke operations only. The introspect operation accepts
 * service clients with `private_key_jwt` only.
 */
@route("/oauth")
interface OAuth {
  /**
   * Get an access token. The `grant_type` is `client_credentials`, `authorization_code`, `refresh_token`,
   * or `urn:ietf:params:oauth:grant-type:token-exchange` (RFC 8693).
   * The `scope` of the request can have OIDC scopes. The `scope` of the response has permission keys only.
   * The response has the headers `Cache-Control: no-store` and `Pragma: no-cache`.
   *
   * Token exchange rules. The parameters `subject_token`, `subject_token_type`, `audience`, and `scope` are required.
   * `actor_token` and `actor_token_type` are optional and appear together.
   * `requested_token_type` is optional. Its only value is `urn:ietf:params:oauth:token-type:access_token`.
   * The actor token is the ID of an agent, not a signed token.
   * The error codes are:
   * `invalid_client` (401): only a service client with `private_key_jwt` can use the grant.
   * `unauthorized_client`: the client does not have the permission `identity:token:exchange`.
   * `invalid_request`: a repeated parameter, `actor_token` without `actor_token_type` or the reverse, or a missing required parameter.
   * `unsupported_token_type`: `subject_token_type` is not the access token URI,
   * or `actor_token_type` is not `urn:constellation:params:oauth:token-type:agent-id`,
   * or `requested_token_type` is not the access token URI.
   * `invalid_grant`: the subject token is not a JWT user access token (`typ` `at+jwt`) of the identity issuer,
   * or it is expired, or its `principal_type` is not `user`, or it has `act`, or its user does not exist or is disabled.
   * A service token, a token with `act`, an exchanged token, and an API token (`cpat_`) are not valid subject tokens.
   * `invalid_grant` is also the code if the `aud` of the subject token is not the `app` of the authenticated client.
   * `invalid_grant` is also the code if the agent does not exist, is disabled, or does not belong to the authenticated client.
   * The error text is the same for all three cases.
   * `invalid_target`: `audience` is not one app key, or it is `identity`.
   * `invalid_scope`: the granted scope is the permissions of the user. If there is an actor,
   * it is also intersected with the permissions of the agent. A requested scope that is not in the granted set fails.
   * `invalid_scope` is also the code for an OIDC scope (`openid`, `profile`, `email`, `offline_access`),
   * and for a scope that does not start with `<audience>:`.
   * The response has no `refresh_token` and no `id_token`.
   * The `exp` of the new token is not later than the `exp` of the subject token.
   * The new token has `sub` of the user. If there is an actor, it has `act` with `principal_type` `agent`.
   * The response has `issued_token_type`.
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
   * Introspect a token (RFC 7662). Only a service client with `private_key_jwt` can call it.
   * Any other caller gets 401 `invalid_client` and learns nothing about the token.
   * Other callers are a public client, a bad or missing assertion, `client_secret`, and `Authorization: Basic`.
   * A repeated form field gives `invalid_request`.
   * In some cases the identity service returns `active: false` and no other field. The cases are:
   * an unknown, expired, or revoked token, and a token of a disabled user.
   * Also a JWT, and a token with no scope for the caller app.
   * For an active token, `scope` is the stored scope of the token.
   * Intersect it with the current permissions of the user.
   * Then keep only the scopes that start with `<caller app>:`.
   * If the result is empty, the response is `{active:false}`. `aud` is the caller app.
   * The response has the headers `Cache-Control: no-store` and `Pragma: no-cache`.
   */
  @useAuth(NoAuth)
  @route("/introspect")
  @post
  introspect(
    @header contentType: "application/x-www-form-urlencoded",
    @body body: IntrospectRequest,
  ): IntrospectResponse | OAuthError;

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
