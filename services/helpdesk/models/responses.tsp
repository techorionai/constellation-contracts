import "@typespec/http";

using Http;

namespace Constellation.Helpdesk;

/** A Customer response with the no-store headers. */
@friendlyName("CustomerResponse")
model CustomerResponse {
  /** Status of the response. */
  @statusCode statusCode: 200;

  ...HelpdeskNoStoreHeaders;

  /** The customer. */
  @body body: Customer;
}

/** A created Customer response with the no-store headers. */
@friendlyName("CustomerCreatedResponse")
model CustomerCreatedResponse {
  /** Status of the response. */
  @statusCode statusCode: 201;

  ...HelpdeskNoStoreHeaders;

  /** The new customer. */
  @body body: Customer;
}

/** A page response with the no-store headers. */
@friendlyName("CustomerPageResponse")
model CustomerPageResponse {
  /** Status of the response. */
  @statusCode statusCode: 200;

  ...HelpdeskNoStoreHeaders;

  /** The page. */
  @body body: CustomerPage;
}

/** A Ticket response with the no-store headers. */
@friendlyName("TicketResponse")
model TicketResponse {
  /** Status of the response. */
  @statusCode statusCode: 200;

  ...HelpdeskNoStoreHeaders;

  /** The ticket. */
  @body body: Ticket;
}

/** A created Ticket response with the no-store headers. */
@friendlyName("TicketCreatedResponse")
model TicketCreatedResponse {
  /** Status of the response. */
  @statusCode statusCode: 201;

  ...HelpdeskNoStoreHeaders;

  /** The new ticket. */
  @body body: Ticket;
}

/** A page response with the no-store headers. */
@friendlyName("TicketPageResponse")
model TicketPageResponse {
  /** Status of the response. */
  @statusCode statusCode: 200;

  ...HelpdeskNoStoreHeaders;

  /** The page. */
  @body body: TicketPage;
}
