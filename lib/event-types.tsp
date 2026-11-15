import "@typespec/http";
using Http;
namespace Constellation.Common;

/** One event type that a service publishes. */
@friendlyName("EventTypeDefinition")
model EventTypeDefinition {
  /** Type of the event. */
  type: EventType;

  /** Description of the event. */
  description: string;

  /** JSON Schema (draft 2020-12) document for `data`. */
  dataSchema: Record<unknown>;

  /** True if the event type is deprecated. */
  deprecated?: boolean;
}

/** The event types that a service registers with the events service. */
@friendlyName("EventTypeRegistration")
model EventTypeRegistration {
  /** The `source` of the events of the service. */
  source: string;

  /** Key of the application. */
  app: AppKey;

  /** Event types of the application. */
  eventTypes: EventTypeDefinition[];
}
