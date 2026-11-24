using Http;
using OpenAPI;
using Constellation.Common;

namespace Constellation.Identity;

/** Operation on the API tokens of a user, for an administrator. */
@route("/v1/users/{userId}/api-tokens")
interface UserApiTokens {
  /** List the API tokens of a user. Error code of `NotFound`: `user_not_found`. */
  @extension("x-required-scopes", #["identity:api_token:read"])
  @list
  @get
  list(@path userId: string, ...CursorPageParams):
    | ApiTokenPage
    | NotFound
    | CommonErrors;
}

/** Operation on the API token of any user, for an administrator. */
@route("/v1/api-tokens")
interface ApiTokens {
  /** Revoke the API token of any user. Error code of `NotFound`: `api_token_not_found`. Revoke of a revoked token gives 204. */
  @extension("x-required-scopes", #["identity:api_token:revoke"])
  @route("/{tokenId}")
  @delete
  revoke(@path tokenId: string):
    | {
        @statusCode _: 204;
      }
    | NotFound
    | CommonErrors;
}
