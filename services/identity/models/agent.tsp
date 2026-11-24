using Constellation.Common;

namespace Constellation.Identity;

/** An agent principal. */
@friendlyName("Agent")
model Agent {
  /** ID of the agent. */
  @format("uuid")
  id: string;

  /** Name of the agent. It is unique and case-sensitive. */
  @minLength(1)
  @maxLength(100)
  name: string;

  /** ID of the service client that can act as the agent. */
  clientId: string;

  /** True if the agent is enabled. */
  enabled: boolean;

  /** Time when the agent was created. */
  createdAt: utcDateTime;

  /** Time when the agent was changed. */
  updatedAt: utcDateTime;
}

/** Request to create an agent. */
@friendlyName("AgentCreate")
model AgentCreate {
  /** Name of the agent. It is unique and case-sensitive. */
  @minLength(1)
  @maxLength(100)
  name: string;

  /** ID of the service client that can act as the agent. */
  clientId: string;
}

/** Request to change an agent. A field that is not present does not change. */
@friendlyName("AgentUpdate")
model AgentUpdate {
  /** Name of the agent. */
  @minLength(1)
  @maxLength(100)
  name?: string;

  /** True to enable the agent. False to disable it. */
  enabled?: boolean;
}

/** One page of agents. */
model AgentPage is CursorPage<Agent>;
