using Http;
using OpenAPI;
using Constellation.Common;

namespace Constellation.Email;

/** Operations on sender rules. */
@route("/v1/sender-rules")
interface SenderRules {
  /**
   * List the sender rules. The order is `createdAt` descending, then `id` descending.
   * The page token is opaque. A token of another operation or with other filters gives 400 `invalid_page_token`.
   * Each response, also an error response, has `Cache-Control: no-store` and `Pragma: no-cache`.
   * Error code of `ServiceUnavailable`: `unavailable`. It has `Retry-After` when the database is not available.
   */
  @extension("x-required-scopes", #["email:sender:read"])
  @list
  @get
  list(...CursorPageParams, ...SenderRuleFilters):
    | EmailOk<SenderRulePage>
    | EmailCommonErrors;

  /**
   * Create a sender rule. The service permits a `from` address when a rule of the caller app has the same address, or the same domain.
   * Error code of `Conflict`: `sender_rule_exists`. Error code of `UnprocessableContent`: `validation_failed`.
   * Each response, also an error response, has `Cache-Control: no-store` and `Pragma: no-cache`.
   * Error code of `ServiceUnavailable`: `unavailable`. It has `Retry-After` when the database is not available.
   */
  @extension("x-required-scopes", #["email:sender:write"])
  @post
  create(@body rule: SenderRuleCreate):
    | EmailCreated<SenderRule>
    | EmailConflict
    | EmailUnprocessableContent
    | EmailTooManyRequests
    | EmailCommonErrors;

  /**
   * Delete a sender rule. Error code of `NotFound`: `sender_rule_not_found`.
   * Each response, also an error response, has `Cache-Control: no-store` and `Pragma: no-cache`.
   * Error code of `ServiceUnavailable`: `unavailable`. It has `Retry-After` when the database is not available.
   */
  @extension("x-required-scopes", #["email:sender:write"])
  @route("/{id}")
  @delete
  delete(
    /** ID of the sender rule. */
    @path id: ResourceId,
  ): EmailNoContent | EmailNotFound | EmailTooManyRequests | EmailCommonErrors;
}
