using Http;
using OpenAPI;
using Constellation.Common;

namespace Constellation.Identity;

/**
 * Self-service operations on the MFA of the user of the access token.
 * Only a user access token with no `act` can call them. Other tokens get 403 with the code `user_token_required`.
 * The enrollment of TOTP and the recovery codes are hosted pages of the identity service. They are not in this contract.
 */
@route("/v1/me/mfa")
interface MeMfa {
  /** Read the MFA state of the user. Error code of `Forbidden`: `user_token_required`. */
  @extension("x-required-scopes", #["identity:mfa:manage_own"])
  @get
  get(): MfaStatus | CommonErrors;
}

/**
 * Self-service operation on the TOTP factor of the user of the access token.
 * Only a user access token with no `act` can call it. Other tokens get 403 with the code `user_token_required`.
 */
@route("/v1/me/totp")
interface MeTotp {
  /**
   * Remove the TOTP factor and all recovery codes of the user.
   * The token needs a fresh MFA login: `amr` contains `mfa` and `auth_time` is at most 5 minutes old.
   * Else the response is 401 with the code `reauthentication_required` and the header
   * `WWW-Authenticate: Bearer error="insufficient_user_authentication", error_description="A fresh MFA login is necessary", max_age="300"`.
   * A token with no `amr` (service, agent, exchange, or API token) gets the same response.
   * A token with `act` does not satisfy MFA.
   * The operation writes an audit entry with the action `identity:mfa:totp_remove`, the target user, and the result.
   * It sends a security notice to the user.
   * Error code of `Forbidden`: `user_token_required`.
   * Error code of `NotFound`: `totp_not_found`.
   * Error code of `Conflict`: `mfa_required`. The policy requires MFA for the user and TOTP is the last second factor.
   * The rule counts TOTP and the passkeys that the service accepts.
   * The order of the checks: the token (401), the scopes (403), `user_token_required` (403),
   * `reauthentication_required` (401), `totp_not_found` (404), `mfa_required` (409).
   */
  @extension("x-required-scopes", #["identity:mfa:manage_own"])
  @delete
  remove():
    | {
        @statusCode _: 204;
      }
    | ReauthenticationRequired
    | NotFound
    | Conflict
    | CommonErrors;
}
