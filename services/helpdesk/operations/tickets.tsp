using Http;
using OpenAPI;
using Constellation.Common;

namespace Constellation.Helpdesk;

/** Operations on tickets. */
@route("/v1/tickets")
interface Tickets {
  /**
   * List the tickets. The order is `createdAt` descending, then `id` descending.
   * The page token is opaque. A token of another operation or with other filters gives 400 `invalid_page_token`.
   * A filter value that is not valid gives 400 `invalid_parameter`.
   * Each response, also an error response, has `Cache-Control: no-store` and `Pragma: no-cache`.
   * Error code of `ServiceUnavailable`: `unavailable`. It has `Retry-After` when the database is not available.
   */
  @extension("x-required-scopes", #["helpdesk:ticket:read"])
  @list
  @get
  list(...CursorPageParams, ...TicketFilters):
    | TicketPageResponse
    | HelpdeskServiceUnavailable
    | HelpdeskCommonErrors;

  /**
   * Get one ticket. Error code of `NotFound`: `ticket_not_found`.
   * Each response, also an error response, has `Cache-Control: no-store` and `Pragma: no-cache`.
   * Error code of `ServiceUnavailable`: `unavailable`. It has `Retry-After` when the database is not available.
   */
  @extension("x-required-scopes", #["helpdesk:ticket:read"])
  @route("/{ticketId}")
  @get
  get(
    /** ID of the ticket. */
    @path ticketId: ResourceId,
  ):
    | TicketResponse
    | HelpdeskNotFound
    | HelpdeskServiceUnavailable
    | HelpdeskCommonErrors;

  /**
   * Create a ticket. The status of the new ticket is `open`. The default priority is `normal`. The service sets the number.
   * The token needs `helpdesk:ticket:write` only. The service checks that the customer exists. It does not need `helpdesk:customer:read`.
   * The service writes the event `helpdesk.ticket.created`.
   * Error code of `UnprocessableContent`: `customer_unknown` when the customer does not exist, or `validation_failed`.
   * Each response, also an error response, has `Cache-Control: no-store` and `Pragma: no-cache`.
   * Error code of `ServiceUnavailable`: `unavailable`. It has `Retry-After` when the database is not available.
   */
  @extension("x-required-scopes", #["helpdesk:ticket:write"])
  @post
  create(@body ticket: TicketCreate):
    | TicketCreatedResponse
    | HelpdeskUnprocessableContent
    | HelpdeskServiceUnavailable
    | HelpdeskCommonErrors;

  /**
   * Change a ticket. A field that is not in the body does not change. The service cannot delete the description.
   * A body with no field gives 400 `empty_update`.
   * An update with no real change returns 200 with the current ticket. It writes no event and no audit entry.
   * A change of the status writes the event `helpdesk.ticket.status_changed`. A change of other fields writes `helpdesk.ticket.updated`.
   * Error code of `NotFound`: `ticket_not_found`. Error code of `UnprocessableContent`: `validation_failed`.
   * Each response, also an error response, has `Cache-Control: no-store` and `Pragma: no-cache`.
   * Error code of `ServiceUnavailable`: `unavailable`. It has `Retry-After` when the database is not available.
   */
  @extension("x-required-scopes", #["helpdesk:ticket:write"])
  @route("/{ticketId}")
  @patch
  update(
    /** ID of the ticket. */
    @path ticketId: ResourceId,

    @body update: TicketUpdate,
  ):
    | TicketResponse
    | HelpdeskNotFound
    | HelpdeskUnprocessableContent
    | HelpdeskServiceUnavailable
    | HelpdeskCommonErrors;
}
