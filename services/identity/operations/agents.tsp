using Http;
using OpenAPI;
using Constellation.Common;

namespace Constellation.Identity;

/** Operations on agents. */
@route("/v1/agents")
interface Agents {
  /**
   * Create an agent. The token needs `identity:agent:write` and `identity:admin`.
   * Error code of `Conflict`: `agent_name_taken`.
   * Error codes of `UnprocessableContent`: `client_not_found` and `client_not_service`.
   */
  @extension("x-required-scopes", #["identity:agent:write", "identity:admin"])
  @post
  create(@body agent: AgentCreate):
    | {
        @statusCode _: 201;
        @body body: Agent;
      }
    | Conflict
    | UnprocessableContent
    | CommonErrors;

  /** List the agents. */
  @extension("x-required-scopes", #["identity:agent:read"])
  @list
  @get
  list(...CursorPageParams): AgentPage | CommonErrors;

  /** Get one agent. Error code of `NotFound`: `agent_not_found`. */
  @extension("x-required-scopes", #["identity:agent:read"])
  @route("/{agentId}")
  @get
  get(@path agentId: string): Agent | NotFound | CommonErrors;

  /**
   * Change an agent. The token needs `identity:agent:write` and `identity:admin`.
   * Error code of `NotFound`: `agent_not_found`. Error code of `Conflict`: `agent_name_taken`.
   */
  @extension("x-required-scopes", #["identity:agent:write", "identity:admin"])
  @route("/{agentId}")
  @patch
  update(@path agentId: string, @body update: AgentUpdate):
    | Agent
    | NotFound
    | Conflict
    | CommonErrors;
}
