using Http;
using OpenAPI;
using Constellation.Common;

namespace Constellation.Email;

/** Operations on suppressions. */
@route("/v1/suppressions")
interface Suppressions {
  /**
   * List the suppressions. The order is `createdAt` descending, then `id` descending.
   * The page token is opaque. A token of another operation or with other filters gives 400 `invalid_page_token`.
   * There is no address filter. To find a suppression by address, use `Suppressions_lookup`.
   * Each response, also an error response, has `Cache-Control: no-store` and `Pragma: no-cache`.
   * Error code of `ServiceUnavailable`: `unavailable`. It has `Retry-After` when the database is not available.
   */
  @extension("x-required-scopes", #["email:suppression:read"])
  @list
  @get
  list(...CursorPageParams, ...SuppressionFilters):
    | EmailOk<SuppressionPage>
    | EmailCommonErrors;

  /**
   * Find the one suppression with an address. The address is in the body and not in the URL, because logs and traces keep a URL.
   * The match is exact and has no case. The operation does not change data. It needs `email:suppression:read`.
   * Error code of `NotFound`: `suppression_not_found`.
   * Each response, also an error response, has `Cache-Control: no-store` and `Pragma: no-cache`.
   * Error code of `ServiceUnavailable`: `unavailable`. It has `Retry-After` when the database is not available.
   */
  @extension("x-required-scopes", #["email:suppression:read"])
  @route(":lookup")
  @post
  lookup(@body lookup: SuppressionLookup):
    | EmailOk<Suppression>
    | EmailNotFound
    | EmailTooManyRequests
    | EmailCommonErrors;

  /**
   * Create a manual suppression. The reason is `manual`.
   * The operation writes an audit entry with the action `email:suppression:create` and the result. The entry does not have the address in clear text.
   * Error code of `Conflict`: `suppression_exists`. Error code of `UnprocessableContent`: `validation_failed`.
   * Each response, also an error response, has `Cache-Control: no-store` and `Pragma: no-cache`.
   * Error code of `ServiceUnavailable`: `unavailable`. It has `Retry-After` when the database is not available.
   */
  @extension("x-required-scopes", #["email:suppression:write"])
  @post
  create(@body suppression: SuppressionCreate):
    | EmailCreated<Suppression>
    | EmailConflict
    | EmailUnprocessableContent
    | EmailTooManyRequests
    | EmailCommonErrors;

  /**
   * Delete a suppression of any reason. Error code of `NotFound`: `suppression_not_found`.
   * The operation writes an audit entry with the action `email:suppression:delete`, the reason of the deleted suppression, and the result. The entry does not have the address in clear text.
   * Each response, also an error response, has `Cache-Control: no-store` and `Pragma: no-cache`.
   * Error code of `ServiceUnavailable`: `unavailable`. It has `Retry-After` when the database is not available.
   */
  @extension("x-required-scopes", #["email:suppression:write"])
  @route("/{id}")
  @delete
  delete(
    /** ID of the suppression. */
    @path id: ResourceId,
  ): EmailNoContent | EmailNotFound | EmailTooManyRequests | EmailCommonErrors;
}
