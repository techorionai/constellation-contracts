namespace Constellation.Common;

/** Type of an event, for example `helpdesk.ticket.created`. */
@pattern("^[a-z][a-z0-9_]*(\\.[a-z][a-z0-9_]*){2,}$")
@maxLength(128)
@friendlyName("EventType")
scalar EventType extends string;

/** Type of a principal. */
@friendlyName("PrincipalType")
union PrincipalType {
  "user",
  "agent",
  "service",
  "workflow",
}

/** CloudEvents 1.0 event in JSON format, with actor attributes. */
model CloudEvent<T> {
  /** CloudEvents version. */
  specversion: "1.0";

  /** ID of the event. Unique for each `source`. */
  @maxLength(128)
  id: string;

  /** URI reference of the service that made the event, for example `/helpdesk`. */
  @maxLength(256)
  source: string;

  /** Type of the event. */
  type: EventType;

  /** Time when the event happened. */
  time: utcDateTime;

  /** ID of the resource, for example the ticket ID. */
  subject?: string;

  /** Media type of `data`. */
  datacontenttype: "application/json";

  /** URI of the schema of `data`. */
  dataschema?: url;

  /** Data of the event. */
  data: T;

  /** The `sub` of the token: the ID of the principal. */
  actor: string;

  /** Type of the principal in `actor`. */
  actortype: PrincipalType;

  /** The `act` of the token: the agent that acts for the user. */
  act?: string;

  /** Type of the principal in `act`. */
  acttype?: PrincipalType;

  /** W3C trace context (CloudEvents distributed tracing extension). */
  traceparent?: string;
}

/** A CloudEvent when the type of `data` is not known. */
@friendlyName("CloudEventEnvelope")
model CloudEventEnvelope is CloudEvent<Record<unknown>>;
