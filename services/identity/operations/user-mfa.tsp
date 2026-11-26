using Http;
using OpenAPI;
using Constellation.Common;

namespace Constellation.Identity;

/** Operations on the MFA of a user, for an administrator. */
@route("/v1/users/{userId}/mfa")
interface UserMfa {
  /** Read the MFA state of a user. The permission is `identity:mfa:read`, not `identity:user:read`. Error code of `NotFound`: `user_not_found`. */
  @extension("x-required-scopes", #["identity:mfa:read"])
  @get
  get(@path userId: string): MfaStatus | NotFound | CommonErrors;

  /**
   * Reset the MFA of a user. The operation removes all second factors (TOTP and passkeys) and recovery codes of the user.
   * It revokes all sessions and refresh tokens of the user. It does not remove the password or the API tokens.
   * A user with no second factor also gives 204, and the sessions are also revoked.
   * The token needs a fresh MFA login: `amr` contains `mfa` and `auth_time` is at most 5 minutes old.
   * Else the response is 401 with the code `reauthentication_required` and the header
   * `WWW-Authenticate: Bearer error="insufficient_user_authentication", error_description="A fresh MFA login is necessary", max_age="300"`.
   * A token with no `amr` (service, agent, exchange, or API token) gets the same response.
   * A token with `act` does not satisfy MFA.
   * Error code of `NotFound`: `user_not_found`.
   * Error code of `Conflict`: `mfa_required`. The `userId` is the `sub` of the token.
   * An administrator cannot reset the own MFA with this operation. The check goes around the rule of `MeTotp_remove`.
   * The administrator uses the subcommand `identity reset-mfa <email>` of the identity service for this recovery.
   * The operation writes an audit entry with the action `identity:mfa:reset`, the target user, and the result.
   * It sends a security notice to the user.
   * The order of the checks: the token (401), the scopes (403), `reauthentication_required` (401),
   * `user_not_found` (404), `mfa_required` (409).
   */
  @extension("x-required-scopes", #["identity:mfa:reset", "identity:admin"])
  @delete
  reset(@path userId: string):
    | {
        @statusCode _: 204;
      }
    | ReauthenticationRequired
    | NotFound
    | Conflict
    | CommonErrors;
}
