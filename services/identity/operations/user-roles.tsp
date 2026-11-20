using Http;
using OpenAPI;
using Constellation.Common;

namespace Constellation.Identity;

/** Operations on the roles of a user. */
@route("/v1/users/{userId}/roles")
interface UserRoles {
  /** List the roles of a user. */
  @extension("x-required-scopes", #["identity:role:read"])
  @list
  @get
  list(@path userId: string, ...CursorPageParams):
    | RoleAssignmentPage
    | NotFound
    | CommonErrors;

  /** Give a role to a user. Error code of `UnprocessableContent`: `role_unknown`. */
  @extension("x-required-scopes", #["identity:role:assign"])
  @route("/{role}")
  @put
  assign(@path userId: string, @path role: RoleRef):
    | RoleAssignment
    | NotFound
    | UnprocessableContent
    | CommonErrors;

  /** Remove a role from a user. Error code of `Conflict`: `last_admin`. */
  @extension("x-required-scopes", #["identity:role:assign"])
  @route("/{role}")
  @delete
  remove(@path userId: string, @path role: RoleRef):
    | {
        @statusCode _: 204;
      }
    | NotFound
    | Conflict
    | CommonErrors;
}
