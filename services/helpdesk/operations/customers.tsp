using Http;
using OpenAPI;
using Constellation.Common;

namespace Constellation.Helpdesk;

/** Operations on customers. */
@route("/v1/customers")
interface Customers {
  /**
   * List the customers. The order is `createdAt` descending, then `id` descending.
   * The page token is opaque. A token of another operation or with other filters gives 400 `invalid_page_token`.
   * There is no filter. To find a customer by email address, use `Customers_lookup`.
   * Each response, also an error response, has `Cache-Control: no-store` and `Pragma: no-cache`.
   * Error code of `ServiceUnavailable`: `unavailable`. It has `Retry-After` when the database is not available.
   */
  @extension("x-required-scopes", #["helpdesk:customer:read"])
  @list
  @get
  list(...CursorPageParams):
    | CustomerPageResponse
    | HelpdeskServiceUnavailable
    | HelpdeskCommonErrors;

  /**
   * Get one customer. Error code of `NotFound`: `customer_not_found`.
   * Each response, also an error response, has `Cache-Control: no-store` and `Pragma: no-cache`.
   * Error code of `ServiceUnavailable`: `unavailable`. It has `Retry-After` when the database is not available.
   */
  @extension("x-required-scopes", #["helpdesk:customer:read"])
  @route("/{customerId}")
  @get
  get(
    /** ID of the customer. */
    @path customerId: ResourceId,
  ):
    | CustomerResponse
    | HelpdeskNotFound
    | HelpdeskServiceUnavailable
    | HelpdeskCommonErrors;

  /**
   * Find the one customer with an email address. The address is in the body and not in the URL, because logs and traces keep a URL.
   * The match is exact and has no case. The operation does not change data. It needs `helpdesk:customer:read`.
   * Error code of `NotFound`: `customer_not_found`.
   * The response has `Cache-Control: no-store` and `Pragma: no-cache`. This is also true for the error responses.
   * Error code of `ServiceUnavailable`: `unavailable`. It has `Retry-After` when the database is not available.
   */
  @extension("x-required-scopes", #["helpdesk:customer:read"])
  @route(":lookup")
  @post
  lookup(@body lookup: CustomerLookup):
    | CustomerResponse
    | HelpdeskNotFound
    | HelpdeskServiceUnavailable
    | HelpdeskCommonErrors;

  /**
   * Create a customer. The service writes the event `helpdesk.customer.created`.
   * Error code of `Conflict`: `customer_email_taken`. Two customers cannot have the same email address, with no case.
   * Error code of `UnprocessableContent`: `validation_failed`. The response lists the fields that are not valid.
   * Each response, also an error response, has `Cache-Control: no-store` and `Pragma: no-cache`.
   * Error code of `ServiceUnavailable`: `unavailable`. It has `Retry-After` when the database is not available.
   */
  @extension("x-required-scopes", #["helpdesk:customer:write"])
  @post
  create(@body customer: CustomerCreate):
    | CustomerCreatedResponse
    | HelpdeskConflict
    | HelpdeskUnprocessableContent
    | HelpdeskServiceUnavailable
    | HelpdeskCommonErrors;

  /**
   * Change a customer. A field that is not in the body does not change. The service cannot delete the phone number.
   * A body with no field gives 400 `empty_update`.
   * An update with no real change returns 200 with the current customer. It writes no event and no audit entry.
   * A real change writes the event `helpdesk.customer.updated`.
   * Error code of `NotFound`: `customer_not_found`. Error code of `Conflict`: `customer_email_taken`.
   * Error code of `UnprocessableContent`: `validation_failed`.
   * Each response, also an error response, has `Cache-Control: no-store` and `Pragma: no-cache`.
   * Error code of `ServiceUnavailable`: `unavailable`. It has `Retry-After` when the database is not available.
   */
  @extension("x-required-scopes", #["helpdesk:customer:write"])
  @route("/{customerId}")
  @patch
  update(
    /** ID of the customer. */
    @path customerId: ResourceId,

    @body update: CustomerUpdate,
  ):
    | CustomerResponse
    | HelpdeskNotFound
    | HelpdeskConflict
    | HelpdeskUnprocessableContent
    | HelpdeskServiceUnavailable
    | HelpdeskCommonErrors;
}
