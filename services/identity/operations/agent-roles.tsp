using Http;
using OpenAPI;
using Constellation.Common;

namespace Constellation.Identity;

/**
 * Operations on the roles of an agent. An agent has no implicit role.
 * The source of an assignment from the API is `api`.
 * Error code of `NotFound` on all operations: `agent_not_found`.
 */
@route("/v1/agents/{agentId}/roles")
interface AgentRoles {
  /** List the roles of an agent. */
  @extension("x-required-scopes", #["identity:role:read"])
  @list
  @get
  list(@path agentId: string, ...CursorPageParams):
    | RoleAssignmentPage
    | NotFound
    | CommonErrors;

  /** Give a role to an agent. Error code of `UnprocessableContent`: `role_unknown`. */
  @extension("x-required-scopes", #["identity:role:assign"])
  @route("/{role}")
  @put
  assign(@path agentId: string, @path role: RoleRef):
    | RoleAssignment
    | NotFound
    | UnprocessableContent
    | CommonErrors;

  /** Remove a role from an agent. A role that the agent does not have gives 204. */
  @extension("x-required-scopes", #["identity:role:assign"])
  @route("/{role}")
  @delete
  remove(@path agentId: string, @path role: RoleRef):
    | {
        @statusCode _: 204;
      }
    | NotFound
    | CommonErrors;
}
