using Constellation.Common;

namespace Constellation.Events;

/** The event types that an app has registered, and the version of the registration. */
@friendlyName("RegisteredEventTypes")
model RegisteredEventTypes {
  /** The registration. It has only the types with no `removedAt`. */
  registration: EventTypeRegistration;

  /** Version of the registration. It increases with each change. */
  version: int32;

  /** Time of the last change. */
  registeredAt: utcDateTime;
}

/** One page of registrations. */
model RegisteredEventTypesPage is CursorPage<RegisteredEventTypes>;

/** The result of a registration. It does not have the JSON Schemas. */
@friendlyName("EventTypeRegistrationResult")
model EventTypeRegistrationResult {
  /** Key of the app. */
  app: AppKey;

  /** Version of the registration. It increases with each change. */
  version: int32;

  /** Time of the last change. */
  registeredAt: utcDateTime;

  /** Count of the types with no `removedAt`. */
  eventTypeCount: int32;
}

/** One event type in the catalog. */
@friendlyName("CatalogEventType")
model CatalogEventType {
  /** Type of the event. */
  type: EventType;

  /** Key of the app that registered the type. */
  app: AppKey;

  /** The `source` of the events of the app. */
  source: string;

  /** Description of the event. */
  description: string;

  /** JSON Schema (draft 2020-12) document for `data`. */
  dataSchema: Record<unknown>;

  /** True if the event type is deprecated. */
  deprecated: boolean;

  /** Time of the first registration of the type. */
  createdAt: utcDateTime;

  /** Time of the last change of the type. */
  updatedAt: utcDateTime;

  /** Time at which the app removed the type from its registration. Absent if the type is registered. */
  removedAt?: utcDateTime;
}

/** One page of catalog event types. */
model CatalogEventTypePage is CursorPage<CatalogEventType>;
