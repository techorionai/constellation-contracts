import "@typespec/http";

using Http;
using Constellation.Common;

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

// Error responses with the no-store headers. An error response can have personal data or text from customers.

/** The request is not valid. The response has the no-store headers. */
@error
@friendlyName("HelpdeskBadRequest")
model HelpdeskBadRequest {
  ...BadRequest;
  ...HelpdeskNoStoreHeaders;
}

/** The request has no valid credentials. The response has the no-store headers. */
@error
@friendlyName("HelpdeskUnauthorized")
model HelpdeskUnauthorized {
  ...Unauthorized;
  ...HelpdeskNoStoreHeaders;
}

/** The principal does not have the permission. The response has the no-store headers. */
@error
@friendlyName("HelpdeskForbidden")
model HelpdeskForbidden {
  ...Forbidden;
  ...HelpdeskNoStoreHeaders;
}

/** The resource does not exist. The response has the no-store headers. */
@error
@friendlyName("HelpdeskNotFound")
model HelpdeskNotFound {
  ...NotFound;
  ...HelpdeskNoStoreHeaders;
}

/** The request conflicts with the state of the resource. The response has the no-store headers. */
@error
@friendlyName("HelpdeskConflict")
model HelpdeskConflict {
  ...Conflict;
  ...HelpdeskNoStoreHeaders;
}

/** The request is well formed, but the service cannot process its content. The response has the no-store headers. */
@error
@friendlyName("HelpdeskUnprocessableContent")
model HelpdeskUnprocessableContent {
  ...UnprocessableContent;
  ...HelpdeskNoStoreHeaders;
}

/** The service has an internal error. The response has the no-store headers. */
@error
@friendlyName("HelpdeskInternalServerError")
model HelpdeskInternalServerError {
  ...InternalServerError;
  ...HelpdeskNoStoreHeaders;
}

/** The service is not available. The response has the no-store headers. */
@error
@friendlyName("HelpdeskServiceUnavailable")
model HelpdeskServiceUnavailable {
  ...ServiceUnavailable;
  ...HelpdeskNoStoreHeaders;
}

/** Errors that most helpdesk operations can return. */
alias HelpdeskCommonErrors =
  | HelpdeskBadRequest
  | HelpdeskUnauthorized
  | HelpdeskForbidden
  | HelpdeskInternalServerError;
