using Http;
using OpenAPI;
using Constellation.Common;

namespace Constellation.Identity;

/** Operations on invites. */
@route("/v1/users/{userId}/invites")
interface Invites {
  /**
   * Create a new invite for a user. An invite is only for a user with the status `invited`.
   * An invite does not reset the password of an `active` user.
   * Error codes of `Conflict`: `user_not_invited` (the user is `active`)
   * and `user_disabled` (the user is `disabled`, and this code wins over `user_not_invited`).
   */
  @extension("x-required-scopes", #["identity:user:write"])
  @post
  create(@path userId: string):
    | {
        ...NoStoreHeaders;
        @statusCode _: 201;
        @body body: Invite;
      }
    | NotFound
    | Conflict
    | CommonErrors;
}
