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
   * The match is exact and has no case. The service changes the `from` address to lower case first.
   * A rule of the kind `address` matches when the full `from` address is equal to the value.
   * A rule of the kind `domain` matches when the domain part of `from` (the text after the last `@`) is equal to the value.
   * A domain rule has no subdomain match and no suffix match. The rule `example.com` does not permit `mail.example.com` or `evilexample.com`.
   * The operation writes an audit entry with the action `email:sender_rule:create`, the app, the kind, the value, and the result.
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
   * The operation writes an audit entry with the action `email:sender_rule:delete`, the app, the kind, the value, and the result.
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
