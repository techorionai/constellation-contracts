import "@typespec/json-schema";

using TypeSpec.JsonSchema;

namespace Constellation.Helpdesk;

/** A UUID in lowercase text form. The pattern is RE2 syntax. */
@friendlyName("EventResourceId")
@pattern("^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$")
@format("uuid")
scalar EventResourceId extends string;

/** Fields of a ticket that the event `helpdesk.ticket.updated` can name. */
@friendlyName("TicketChangedField")
union TicketChangedField {
  "subject",
  "description",
  "priority",
}

/** Fields of a customer that the event `helpdesk.customer.updated` can name. */
@friendlyName("CustomerChangedField")
union CustomerChangedField {
  "name",
  "email",
  "phone",
}

/** Data of the event `helpdesk.ticket.created`. It has no free text and no personal data. */
@jsonSchema
@friendlyName("TicketCreatedData")
model TicketCreatedData {
  /** ID of the ticket. */
  ticketId: EventResourceId;

  /** Number of the ticket. */
  @minValue(1)
  number: int64;

  /** Status of the ticket. */
  status: TicketStatus;

  /** Priority of the ticket. */
  priority: TicketPriority;

  /** ID of the customer of the ticket. */
  customerId: EventResourceId;
}

/** Data of the event `helpdesk.ticket.updated`. It names the changed fields. It does not give their values. */
@jsonSchema
@friendlyName("TicketUpdatedData")
model TicketUpdatedData {
  /** ID of the ticket. */
  ticketId: EventResourceId;

  /** Number of the ticket. */
  @minValue(1)
  number: int64;

  /** Names of the fields that changed. */
  @minItems(1)
  @maxItems(3)
  @JsonSchema.uniqueItems
  changedFields: TicketChangedField[];
}

/** Data of the event `helpdesk.ticket.status_changed`. */
@jsonSchema
@friendlyName("TicketStatusChangedData")
model TicketStatusChangedData {
  /** ID of the ticket. */
  ticketId: EventResourceId;

  /** Number of the ticket. */
  @minValue(1)
  number: int64;

  /** Status before the change. */
  from: TicketStatus;

  /** Status after the change. */
  to: TicketStatus;
}

/** Data of the event `helpdesk.customer.created`. It has no personal data. */
@jsonSchema
@friendlyName("CustomerCreatedData")
model CustomerCreatedData {
  /** ID of the customer. */
  customerId: EventResourceId;
}

/** Data of the event `helpdesk.customer.updated`. It names the changed fields. It does not give their values. */
@jsonSchema
@friendlyName("CustomerUpdatedData")
model CustomerUpdatedData {
  /** ID of the customer. */
  customerId: EventResourceId;

  /** Names of the fields that changed. */
  @minItems(1)
  @maxItems(3)
  @JsonSchema.uniqueItems
  changedFields: CustomerChangedField[];
}
