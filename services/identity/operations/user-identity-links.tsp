using Http;
using OpenAPI;
using Constellation.Common;

namespace Constellation.Identity;

/**
 * Operations on the upstream identity links of a user, for an administrator.
 * A user has a maximum of one link for each provider. The values of `{provider}` are `google` and `microsoft` in lower case.
 * Any other value gives 404 `identity_link_not_found`.
 * A `userId` that is not a UUID gives 404 `user_not_found`.
 */
@route("/v1/users/{userId}/identity-links")
interface UserIdentityLinks {
  /**
   * List the identity links of a user. The order is `createdAt` ascending, then `provider` ascending.
   * The permission is `identity:identity_link:read`, not `identity:user:read`.
   * Error code of `NotFound`: `user_not_found`.
   * The order of the checks: the token (401), the scopes (403), `user_not_found` (404).
   */
  @extension("x-required-scopes", #["identity:identity_link:read"])
  @list
  @get
  list(@path userId: string, ...CursorPageParams):
    | IdentityLinkPage
    | NotFound
    | CommonErrors;

  /**
   * Remove an identity link of a user.
   * The token needs a fresh MFA login: `amr` contains `mfa` and `auth_time` is at most 5 minutes old.
   * Else the response is 401 with the code `reauthentication_required` and the header
   * `WWW-Authenticate: Bearer error="insufficient_user_authentication", error_description="A fresh MFA login is necessary", max_age="300"`.
   * A token with no `amr` (service, agent, exchange, or API token) gets the same response.
   * A token with `act` does not satisfy MFA.
   * The operation writes an audit entry with the action `identity:identity_link:remove`, the target user, the provider, and the result.
   * It sends a security notice to the user.
   * The removal revokes all sessions and all refresh tokens of the user that were made with an upstream login (`amr` contains `fed`).
   * The removal also revokes the personal API tokens that a session with `fed` in `amr` made.
   * The service records the `amr` of the making session in the API token. The `ApiToken` model does not show it.
   * Error code of `NotFound`: `user_not_found` or `identity_link_not_found`.
   * Error code of `Conflict`: `last_login_method`. The removal would leave the user with no login method.
   * The methods that count are a password, a passkey that the service accepts, and a link of a provider that is on.
   * A provider is on when the operator sets the client ID. A stored passkey does not count when the service turns off passkeys.
   * A link of a provider that is off does not count.
   * An administrator can use the operation on the own account. The rules are the same.
   * The order of the checks: the token (401), the scopes (403), `reauthentication_required` (401),
   * `user_not_found` (404), `identity_link_not_found` (404), `last_login_method` (409).
   */
  @extension(
    "x-required-scopes",
    #["identity:identity_link:remove", "identity:admin"]
  )
  @route("/{provider}")
  @delete
  remove(@path userId: string, @path provider: string):
    | {
        @statusCode _: 204;
      }
    | ReauthenticationRequired
    | NotFound
    | Conflict
    | CommonErrors;
}
