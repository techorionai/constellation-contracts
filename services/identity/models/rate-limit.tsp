using Http;

namespace Constellation.Identity;

/**
 * An OAuth operation limits the rate of requests (RFC 6749 section 5.2).
 * The `error` is `temporarily_unavailable`. The client tries again after `Retry-After`.
 * The body has the same fields as `OAuthError`.
 * The status, the body, and `Retry-After` do not change when a `client_id` or a user exists or does not exist.
 * The response does not give the limit key, the limit value, or the remaining requests.
 */
@error
@friendlyName("OAuthTooManyRequests")
model OAuthTooManyRequests {
  /** Media type of the response. */
  @header contentType: "application/json";

  /** Status of the response. */
  @statusCode statusCode: 429;

  /** Seconds to wait before the next request. */
  @minValue(1)
  @header("Retry-After")
  retryAfter: int32;

  /** The response has the value `no-store`. */
  @header("Cache-Control") cacheControl: "no-store";

  /** The response has the value `no-cache`. */
  @header("Pragma") pragma: "no-cache";

  /** The error code. It is `temporarily_unavailable`. */
  error: OAuthErrorCode;

  /** Text for a developer. It has no internal data and no secret. */
  error_description?: string;
}

/**
 * An OAuth operation cannot do the request now, for example because the rate limiter is not available.
 * The `error` is `temporarily_unavailable`. The body has the same fields as `OAuthError`.
 */
@error
@friendlyName("OAuthServiceUnavailable")
model OAuthServiceUnavailable {
  /** Media type of the response. */
  @header contentType: "application/json";

  /** Status of the response. */
  @statusCode statusCode: 503;

  /** Seconds to wait before the next request. */
  @minValue(1)
  @header("Retry-After")
  retryAfter?: int32;

  /** The response has the value `no-store`. */
  @header("Cache-Control") cacheControl: "no-store";

  /** The response has the value `no-cache`. */
  @header("Pragma") pragma: "no-cache";

  /** The error code. It is `temporarily_unavailable`. */
  error: OAuthErrorCode;

  /** Text for a developer. It has no internal data and no secret. */
  error_description?: string;
}

/**
 * A page that tells a person in a browser to try again later. The service limits the rate of requests.
 * The status, the body, and `Retry-After` do not change when a `client_id` or a user exists or does not exist.
 * The response does not give the limit key, the limit value, or the remaining requests.
 * The emitter writes the body as an inline string schema. The generated file has no named schema for this model.
 */
@error
@friendlyName("HtmlTooManyRequests")
model HtmlTooManyRequests {
  /** Media type of the response. */
  @header contentType: "text/html";

  /** Status of the response. */
  @statusCode statusCode: 429;

  /** Seconds to wait before the next request. */
  @minValue(1)
  @header("Retry-After")
  retryAfter: int32;

  /** The HTML text. */
  @body body: string;
}

/**
 * A page that tells a person in a browser to try again later. The service cannot do the request now.
 * The emitter writes the body as an inline string schema. The generated file has no named schema for this model.
 */
@error
@friendlyName("HtmlServiceUnavailable")
model HtmlServiceUnavailable {
  /** Media type of the response. */
  @header contentType: "text/html";

  /** Status of the response. */
  @statusCode statusCode: 503;

  /** Seconds to wait before the next request. */
  @minValue(1)
  @header("Retry-After")
  retryAfter?: int32;

  /** The HTML text. */
  @body body: string;
}
