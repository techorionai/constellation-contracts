using Http;
using OpenAPI;
using Constellation.Common;

namespace Constellation.Email;

/** Operations on messages. */
@route("/v1/messages")
interface Messages {
  /**
   * Send a message. The body has `template` or `content`. A body with both or with neither is not valid.
   * The service puts the message in a queue and returns 202 with the `Message`. The status is `queued`,
   * or `suppressed` when all recipients are on the suppression list. The caller reads the status later or from the events.
   * Limits: `to` has 1 to 50 addresses. The total of `to`, `cc`, and `bcc` is a maximum of 50 addresses.
   * A schema cannot count 3 arrays, so the service checks the total and gives 422 `validation_failed`.
   * The service also gives 422 `validation_failed` for more than 50 template variables.
   * The body has a maximum of 2 MiB. A larger body gives 413 `content_too_large`.
   * The header `Idempotency-Key` is optional. The service keeps a key for each caller app for 24 hours.
   * The same key with the same body returns the first `Message` with 202.
   * The same key with a different body gives 422 `idempotency_key_reused`.
   * A retry with the same key while the first request is in progress gives 409 `idempotency_request_in_progress` with `Retry-After`.
   * A principal with no `app` claim gives 422 `sender_not_allowed`. A `from` address that no sender rule of the caller app allows also gives 422 `sender_not_allowed`.
   * Other codes of `UnprocessableContent`: `template_not_found`, `template_variables_invalid`.
   * Each response, also an error response, has `Cache-Control: no-store` and `Pragma: no-cache`.
   * Error code of `ServiceUnavailable`: `unavailable`. It has `Retry-After` when the database is not available.
   */
  @extension("x-required-scopes", #["email:message:send"])
  @post
  send(...IdempotencyKeyHeader, @body request: SendMessageRequest):
    | EmailAccepted<Message>
    | EmailConflict
    | EmailContentTooLarge
    | EmailUnprocessableContent
    | EmailTooManyRequests
    | EmailCommonErrors;

  /**
   * Get one message. It has the metadata and the status for each recipient. It has no subject, no text, no HTML, and no template variables.
   * A principal with `email:message:read` sees only the messages of its own `app` claim. A principal with no `app` claim sees no message with this permission only.
   * A message of another app gives 404 `message_not_found`. A principal with `email:message:read_all` sees all messages.
   * The service deletes a message 24 hours after `sendAt`. After this time, the operation gives 404 `message_not_found`.
   * Each response, also an error response, has `Cache-Control: no-store` and `Pragma: no-cache`.
   * Error code of `ServiceUnavailable`: `unavailable`. It has `Retry-After` when the database is not available.
   */
  @extension("x-required-scopes", #["email:message:read"])
  @route("/{id}")
  @get
  get(
    /** ID of the message. */
    @path id: ResourceId,
  ): EmailOk<Message> | EmailNotFound | EmailCommonErrors;

  /**
   * List the messages. The order is `createdAt` descending, then `id` descending.
   * The page token is opaque. A token of another operation or with other filters gives 400 `invalid_page_token`.
   * A principal with `email:message:read` sees only the messages of its own `app` claim. A principal with no `app` claim sees no message with this permission only.
   * A principal with `email:message:read_all` sees all messages.
   * The service deletes a message 24 hours after `sendAt`. The list does not show a deleted message.
   * No filter has an address.
   * Each response, also an error response, has `Cache-Control: no-store` and `Pragma: no-cache`.
   * Error code of `ServiceUnavailable`: `unavailable`. It has `Retry-After` when the database is not available.
   */
  @extension("x-required-scopes", #["email:message:read"])
  @list
  @get
  list(...CursorPageParams, ...MessageFilters):
    | EmailOk<MessagePage>
    | EmailCommonErrors;
}
