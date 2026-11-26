using Http;
using OpenAPI;
using Constellation.Common;

namespace Constellation.Identity;

/**
 * Self-service operations on the passkeys of the user of the access token.
 * Only a user access token with no `act` can call them. Other tokens get 403 with the code `user_token_required`.
 * The registration and the login with a passkey are hosted pages of the identity service. They are not in this contract.
 * When the service turns off passkeys, the operations stay available.
 * The list shows the stored passkeys, and the user can rename and remove them.
 * A stored passkey then does not count as a second factor.
 */
@route("/v1/me/passkeys")
interface MePasskeys {
  /**
   * List the passkeys of the user. The order is `createdAt` ascending, then `id` ascending.
   * Error code of `Forbidden`: `user_token_required`.
   */
  @extension("x-required-scopes", #["identity:mfa:manage_own"])
  @list
  @get
  list(...CursorPageParams): PasskeyPage | CommonErrors;

  /**
   * Rename a passkey of the user.
   * The token needs a fresh MFA login: `amr` contains `mfa` and `auth_time` is at most 5 minutes old.
   * Else the response is 401 with the code `reauthentication_required` and the header
   * `WWW-Authenticate: Bearer error="insufficient_user_authentication", error_description="A fresh MFA login is necessary", max_age="300"`.
   * A token with no `amr` (service, agent, exchange, or API token) gets the same response.
   * A token with `act` does not satisfy MFA.
   * The operation writes an audit entry with the action `identity:mfa:passkey_rename`, the target user, the result,
   * and a change summary with the old name and the new name.
   * Error code of `Forbidden`: `user_token_required`.
   * Error code of `NotFound`: `passkey_not_found`. A passkey of another user, an unknown ID,
   * or an ID that is not a UUID gives the same 404.
   * `UnprocessableContent` has the schema errors of `PasskeyUpdate`.
   * The order of the checks: the token (401), the scopes (403), `user_token_required` (403),
   * `reauthentication_required` (401), `passkey_not_found` (404), the schema (422).
   */
  @extension("x-required-scopes", #["identity:mfa:manage_own"])
  @route("/{passkeyId}")
  @patch
  update(@path passkeyId: string, @body update: PasskeyUpdate):
    | Passkey
    | ReauthenticationRequired
    | NotFound
    | UnprocessableContent
    | CommonErrors;

  /**
   * Remove a passkey of the user.
   * The token needs a fresh MFA login: `amr` contains `mfa` and `auth_time` is at most 5 minutes old.
   * Else the response is 401 with the code `reauthentication_required` and the header
   * `WWW-Authenticate: Bearer error="insufficient_user_authentication", error_description="A fresh MFA login is necessary", max_age="300"`.
   * A token with no `amr` (service, agent, exchange, or API token) gets the same response.
   * A token with `act` does not satisfy MFA.
   * The operation writes an audit entry with the action `identity:mfa:passkey_remove`, the target user, and the result.
   * It sends a security notice to the user.
   * The removal revokes all sessions and all refresh tokens of the user that were made with a passkey (`amr` contains `hwk`).
   * The removal also revokes the personal API tokens that a session with `hwk` in `amr` made.
   * The service records the `amr` of the making session in the API token. The `ApiToken` model does not show it.
   * The service does not record which passkey made a session, so the revocation does not depend on the removed passkey.
   * An old refresh token of such a session then gets no new access token.
   * Error code of `Forbidden`: `user_token_required`.
   * Error code of `NotFound`: `passkey_not_found`. A passkey of another user, an unknown ID,
   * or an ID that is not a UUID gives the same 404.
   * Error code of `Conflict`: `mfa_required`. The policy requires MFA for the user and the passkey is the last second factor.
   * The rule counts TOTP and the passkeys that the service accepts.
   * Error code of `Conflict`: `last_login_method`. The removal would leave the user with no login method.
   * The methods that count are a password, a passkey that the service accepts, and a link of a provider that is on.
   * A provider is on when the operator sets the client ID. A stored passkey does not count when the service turns off passkeys.
   * A link of a provider that is off does not count.
   * The order of the checks: the token (401), the scopes (403), `user_token_required` (403),
   * `reauthentication_required` (401), `passkey_not_found` (404), `mfa_required` (409), `last_login_method` (409).
   */
  @extension("x-required-scopes", #["identity:mfa:manage_own"])
  @route("/{passkeyId}")
  @delete
  remove(@path passkeyId: string):
    | {
        @statusCode _: 204;
      }
    | ReauthenticationRequired
    | NotFound
    | Conflict
    | CommonErrors;
}
