import "@typespec/http";

using Http;

namespace Constellation.Email;

/** A UUID in lowercase text form. The pattern is RE2 syntax. */
@friendlyName("ResourceId")
@pattern("^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$")
@format("uuid")
scalar ResourceId extends string;

/**
 * An email address. The contract checks the length and that the address has no control character and no space.
 * The service checks the form of the address.
 * The service gives 422 `validation_failed` for an address with CR, LF, or another control character.
 */
@friendlyName("EmailAddress")
@minLength(3)
@maxLength(254)
@pattern("^[^\\x00-\\x20\\x7F]+$")
scalar EmailAddress extends string;

/**
 * Text that the service writes into a mail header, for example a display name or a subject.
 * The text has no control character. This includes CR and LF.
 * The service gives 422 `validation_failed` for a value with CR, LF, or another control character.
 * This rule also applies to the result of a template render of the subject.
 */
@friendlyName("HeaderText")
@minLength(1)
@maxLength(998)
@pattern("^[^\\x00-\\x1F\\x7F]+$")
scalar HeaderText extends string;

/** Display name of a sender. A maximum of 100 characters. It has no control character. */
@friendlyName("SenderDisplayName")
@minLength(1)
@maxLength(100)
@pattern("^[^\\x00-\\x1F\\x7F]+$")
scalar SenderDisplayName extends string;

/** A message ID for the headers `In-Reply-To` and `References`. It has no control character. */
@friendlyName("MessageIdText")
@minLength(1)
@maxLength(998)
@pattern("^[^\\x00-\\x1F\\x7F]+$")
scalar MessageIdText extends string;

/** Value of a template variable. A maximum of 10000 characters. */
@friendlyName("TemplateVariableValue")
@maxLength(10000)
scalar TemplateVariableValue extends string;

/**
 * Header of a request that a caller can send again with no second effect.
 * The key has 1 to 255 printable ASCII characters. The service keeps a key for each caller app for 24 hours.
 */
@friendlyName("IdempotencyKeyHeader")
model IdempotencyKeyHeader {
  /** Key of the request. The same key with the same body returns the first result. */
  @header("Idempotency-Key")
  @minLength(1)
  @maxLength(255)
  @pattern("^[ -~]+$")
  idempotencyKey?: string;
}

/** Reason why a message failed. */
@friendlyName("EmailFailureCode")
union EmailFailureCode {
  "permanent_rejection",
  "attempts_exhausted",
  "expired",
}

/**
 * Type of a bounce. `permanent` is a rejection of the 5xx class.
 * `transient` is a rejection of the 4xx class. `undetermined` is a rejection with no known class.
 */
@friendlyName("EmailBounceType")
union EmailBounceType {
  "permanent",
  "transient",
  "undetermined",
}

/**
 * Response headers for a response that has email addresses or message text.
 * A cache must not keep the response.
 */
alias EmailNoStoreHeaders = {
  /** Cache rule. */
  @header("Cache-Control") cacheControl: "no-store";

  /** Cache rule for old HTTP/1.0 caches. */
  @header("Pragma") pragma: "no-cache";
};
