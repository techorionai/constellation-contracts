import "@typespec/http";

using Http;

using Constellation.Common;

namespace Constellation.Email;

/** The request is not valid. The response has the no-store headers. */
@error
@friendlyName("EmailBadRequest")
model EmailBadRequest {
  ...BadRequest;
  ...EmailNoStoreHeaders;
}

/** The request has no valid credentials. The response has the no-store headers. */
@error
@friendlyName("EmailUnauthorized")
model EmailUnauthorized {
  ...Unauthorized;
  ...EmailNoStoreHeaders;
}

/** The principal does not have the permission. The response has the no-store headers. */
@error
@friendlyName("EmailForbidden")
model EmailForbidden {
  ...Forbidden;
  ...EmailNoStoreHeaders;
}

/** The resource does not exist. The response has the no-store headers. */
@error
@friendlyName("EmailNotFound")
model EmailNotFound {
  ...NotFound;
  ...EmailNoStoreHeaders;
}

/** The request conflicts with the state of the resource. The response has the no-store headers. */
@error
@friendlyName("EmailConflict")
model EmailConflict {
  ...Conflict;
  ...EmailNoStoreHeaders;
}

/** A request with the same idempotency key is in progress. The response has the no-store headers. It always has the Retry-After header. */
@error
@friendlyName("EmailRequestInProgress")
model EmailRequestInProgress {
  ...Conflict;
  ...EmailNoStoreHeaders;

  /** Seconds to wait before the next request. */
  @minValue(0)
  @header("Retry-After")
  retryAfter: int32;
}

/** The request body is too large. The response has the no-store headers. */
@error
@friendlyName("EmailContentTooLarge")
model EmailContentTooLarge {
  ...ContentTooLarge;
  ...EmailNoStoreHeaders;
}

/** The request is well formed, but the service cannot process its content. The response has the no-store headers. */
@error
@friendlyName("EmailUnprocessableContent")
model EmailUnprocessableContent {
  ...UnprocessableContent;
  ...EmailNoStoreHeaders;
}

/** The client sent too many requests. The response has the no-store headers. */
@error
@friendlyName("EmailTooManyRequests")
model EmailTooManyRequests {
  ...TooManyRequests;
  ...EmailNoStoreHeaders;
}

/** The service has an internal error. The response has the no-store headers. */
@error
@friendlyName("EmailInternalServerError")
model EmailInternalServerError {
  ...InternalServerError;
  ...EmailNoStoreHeaders;
}

/** The service is not available. The response has the no-store headers. */
@error
@friendlyName("EmailServiceUnavailable")
model EmailServiceUnavailable {
  ...ServiceUnavailable;
  ...EmailNoStoreHeaders;
}

/** Errors that most email operations can return. */
alias EmailCommonErrors =
  | EmailBadRequest
  | EmailUnauthorized
  | EmailForbidden
  | EmailInternalServerError
  | EmailServiceUnavailable;
