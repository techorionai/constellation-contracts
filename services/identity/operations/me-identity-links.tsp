using Http;
using OpenAPI;
using Constellation.Common;

namespace Constellation.Identity;

/**
 * Self-service operations on the upstream identity links of the user of the access token.
 * Only a user access token with no `act` can call them. Other tokens get 403 with the code `user_token_required`.
 * The login with an upstream account and the link of an upstream account are hosted pages of the identity service.
 * They are not in this contract. No operation of this contract creates a link.
 * A user has a maximum of one link for each provider. The values of `{provider}` are `google` and `microsoft` in lower case.
 * Any other value gives 404 `identity_link_not_found`.
 */
@route("/v1/me/identity-links")
interface MeIdentityLinks {
  /**
   * List the identity links of the user. The order is `createdAt` ascending, then `provider` ascending.
   * Error code of `Forbidden`: `user_token_required`.
   */
  @extension("x-required-scopes", #["identity:identity_link:manage_own"])
  @list
  @get
  list(...CursorPageParams): IdentityLinkPage | CommonErrors;

  /**
   * Remove an identity link of the user.
   * The token needs a fresh login: `auth_time` is at most 5 minutes old. The operation does not check `amr` for `mfa`.
   * A user with a local second factor has `mfa` in every login, so the rule includes the second factor for such a user.
   * Else the response is 401 with the code `reauthentication_required` and the header
   * `WWW-Authenticate: Bearer error="insufficient_user_authentication", error_description="A fresh login is necessary", max_age="300"`.
   * A token with no `amr` or `auth_time` (service, agent, exchange, or API token) gets the same response.
   * A token with `act` does not satisfy the rule.
   * The operation writes an audit entry with the action `identity:identity_link:remove`, the target user, the provider, and the result.
   * It sends a security notice to the user.
   * The removal revokes all sessions and all refresh tokens of the user that were made with an upstream login (`amr` contains `fed`).
   * The current session is also revoked if it has `fed`.
   * Error code of `Forbidden`: `user_token_required`.
   * Error code of `NotFound`: `identity_link_not_found`. A provider that the user did not link, an unknown provider, or a wrong-case provider gives the same 404.
   * Error code of `Conflict`: `last_login_method`. The removal would leave the user with no login method.
   * The methods that count are a password, a passkey that the service accepts, and a link of a provider that is on.
   * A provider is on when the operator sets the client ID. A stored passkey does not count when the service turns off passkeys.
   * A link of a provider that is off does not count.
   * The order of the checks: the token (401), the scopes (403), `user_token_required` (403),
   * `reauthentication_required` (401), `identity_link_not_found` (404), `last_login_method` (409).
   */
  @extension("x-required-scopes", #["identity:identity_link:manage_own"])
  @route("/{provider}")
  @delete
  remove(@path provider: string):
    | {
        @statusCode _: 204;
      }
    | ReauthenticationRequired
    | NotFound
    | Conflict
    | CommonErrors;
}
