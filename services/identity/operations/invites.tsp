using Http;
using OpenAPI;
using Constellation.Common;

namespace Constellation.Identity;

/** Operations on invites. */
@route("/v1/users/{userId}/invites")
interface Invites {
  /** Create a new invite for a user. Error code of `Conflict`: `user_disabled`. */
  @extension("x-required-scopes", #["identity:user:write"])
  @post
  create(@path userId: string):
    | {
        @statusCode _: 201;
        @body body: Invite;
      }
    | NotFound
    | Conflict
    | CommonErrors;
}
