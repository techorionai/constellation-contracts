import "@typespec/http";

using Http;

namespace Constellation.Email;

/** A UUID in lowercase text form. The pattern is RE2 syntax. */
@friendlyName("ResourceId")
@pattern("^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$")
@format("uuid")
scalar ResourceId extends string;

/**
 * An email address. The contract checks only the length.
 * The service checks the form of the address.
 */
@friendlyName("EmailAddress")
@minLength(3)
@maxLength(254)
scalar EmailAddress extends string;

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
