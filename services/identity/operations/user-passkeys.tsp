using Http;
using OpenAPI;
using Constellation.Common;

namespace Constellation.Identity;

/** Operations on the passkeys of a user, for an administrator. */
@route("/v1/users/{userId}/passkeys")
interface UserPasskeys {
  /**
   * List the passkeys of a user. The order is `createdAt` ascending, then `id` ascending.
   * The permission is `identity:mfa:read`, not `identity:user:read`.
   * When the service turns off passkeys, the operation stays available and shows the stored passkeys.
   * Error code of `NotFound`: `user_not_found`.
   */
  @extension("x-required-scopes", #["identity:mfa:read"])
  @list
  @get
  list(@path userId: string, ...CursorPageParams):
    | PasskeyPage
    | NotFound
    | CommonErrors;
}
