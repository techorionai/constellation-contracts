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
   * A filter value that is not valid gives 400 `invalid_parameter`.
   * The response has `Cache-Control: no-store` and `Pragma: no-cache`.
   * Error code of `ServiceUnavailable`: `unavailable`. It has `Retry-After` when the database is not available.
   */
  @extension("x-required-scopes", #["helpdesk:customer:read"])
  @list
  @get
  list(...CursorPageParams, ...CustomerFilters):
    | CustomerPageResponse
    | ServiceUnavailable
    | CommonErrors;

  /**
   * Get one customer. Error code of `NotFound`: `customer_not_found`.
   * The response has `Cache-Control: no-store` and `Pragma: no-cache`.
   * Error code of `ServiceUnavailable`: `unavailable`. It has `Retry-After` when the database is not available.
   */
  @extension("x-required-scopes", #["helpdesk:customer:read"])
  @route("/{customerId}")
  @get
  get(
    /** ID of the customer. */
    @path @format("uuid") customerId: string,
  ): CustomerResponse | NotFound | ServiceUnavailable | CommonErrors;

  /**
   * Create a customer. The service writes the event `helpdesk.customer.created`.
   * Error code of `Conflict`: `customer_email_taken`. Two customers cannot have the same email address, with no case.
   * Error code of `UnprocessableContent`: `validation_failed`. The response lists the fields that are not valid.
   * The response has `Cache-Control: no-store` and `Pragma: no-cache`.
   * Error code of `ServiceUnavailable`: `unavailable`. It has `Retry-After` when the database is not available.
   */
  @extension("x-required-scopes", #["helpdesk:customer:write"])
  @post
  create(@body customer: CustomerCreate):
    | CustomerCreatedResponse
    | Conflict
    | UnprocessableContent
    | ServiceUnavailable
    | CommonErrors;

  /**
   * Change a customer. A field that is not in the body does not change. The service cannot delete the phone number.
   * A body with no field gives 400 `empty_update`.
   * An update with no real change returns 200 with the current customer. It writes no event and no audit entry.
   * A real change writes the event `helpdesk.customer.updated`.
   * Error code of `NotFound`: `customer_not_found`. Error code of `Conflict`: `customer_email_taken`.
   * Error code of `UnprocessableContent`: `validation_failed`.
   * The response has `Cache-Control: no-store` and `Pragma: no-cache`.
   * Error code of `ServiceUnavailable`: `unavailable`. It has `Retry-After` when the database is not available.
   */
  @extension("x-required-scopes", #["helpdesk:customer:write"])
  @route("/{customerId}")
  @patch
  update(
    /** ID of the customer. */
    @path @format("uuid") customerId: string,

    @body update: CustomerUpdate,
  ):
    | CustomerResponse
    | NotFound
    | Conflict
    | UnprocessableContent
    | ServiceUnavailable
    | CommonErrors;
}
