using Http;
using OpenAPI;
using Constellation.Common;

namespace Constellation.Identity;

/** Operations on the roles of a service client. */
@route("/v1/clients/{clientId}/roles")
interface ClientRoles {
  /** List the roles of a service client. Error code of `UnprocessableContent`: `client_type_unsupported`. */
  @extension("x-required-scopes", #["identity:role:read"])
  @list
  @get
  list(@path clientId: string, ...CursorPageParams):
    | RoleAssignmentPage
    | NotFound
    | UnprocessableContent
    | CommonErrors;

  /**
   * Give a role to a service client. Error code of `Conflict`: `client_managed_by_config`.
   * Error codes of `UnprocessableContent`: `role_unknown` and `client_type_unsupported`.
   */
  @extension("x-required-scopes", #["identity:role:assign"])
  @route("/{role}")
  @put
  assign(@path clientId: string, @path role: RoleRef):
    | RoleAssignment
    | NotFound
    | Conflict
    | UnprocessableContent
    | CommonErrors;

  /**
   * Remove a role from a service client. Error code of `Conflict`: `client_managed_by_config`.
   * Error code of `UnprocessableContent`: `client_type_unsupported`.
   */
  @extension("x-required-scopes", #["identity:role:assign"])
  @route("/{role}")
  @delete
  remove(@path clientId: string, @path role: RoleRef):
    | {
        @statusCode _: 204;
      }
    | NotFound
    | Conflict
    | UnprocessableContent
    | CommonErrors;
}
