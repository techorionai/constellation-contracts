using Http;
using OpenAPI;
using Constellation.Common;

namespace Constellation.Identity;

/**
 * Self-service operations on the personal API tokens of the user of the access token.
 * Only a user access token with no `act` can call them. Other tokens get 403 with the code `user_token_required`.
 */
@route("/v1/me/api-tokens")
interface MeApiTokens {
  /**
   * Create a personal API token. The response has the token one time only.
   * Error code of `Forbidden`: `user_token_required`.
   * Error codes of `UnprocessableContent`: `scope_not_granted` and `token_limit`.
   * `scope_not_granted` means that a requested scope is not a permission of the user.
   * It has one entry in `errors` for each key, with `field` `/scope` and `code` `scope_not_granted`.
   * `token_limit` means that the user has the maximum number of active tokens,
   * or the maximum number of token records that the service keeps. The service sets both limits.
   * Error code of `TooManyRequests`: `rate_limited`. Error code of `ServiceUnavailable`: `unavailable`.
   */
  @extension("x-required-scopes", #["identity:api_token:manage_own"])
  @post
  create(@body token: ApiTokenCreate):
    | {
        ...NoStoreHeaders;
        @statusCode _: 201;
        @body body: ApiTokenCreated;
      }
    | UnprocessableContent
    | TooManyRequests
    | ServiceUnavailable
    | CommonErrors;

  /** List the API tokens of the user. Error code of `Forbidden`: `user_token_required`. */
  @extension("x-required-scopes", #["identity:api_token:manage_own"])
  @list
  @get
  list(...CursorPageParams): ApiTokenPage | CommonErrors;

  /**
   * Revoke an API token of the user. A token of another user or an unknown ID gives 404 `api_token_not_found`.
   * Revoke of a revoked token gives 204. Error code of `Forbidden`: `user_token_required`.
   */
  @extension("x-required-scopes", #["identity:api_token:manage_own"])
  @route("/{tokenId}")
  @delete
  revoke(@path tokenId: string):
    | {
        @statusCode _: 204;
      }
    | NotFound
    | CommonErrors;
}
