import "@typespec/http";

using Http;

namespace Constellation.Common;

/** Problem details for an HTTP API (RFC 9457). */
@error
@friendlyName("Problem")
model Problem {
  /** Media type of the response. */
  @header contentType: "application/problem+json";

  /** URI reference that identifies the problem type. */
  type: url = "about:blank";

  /** Short summary of the problem. It contains no internal data. */
  title: string;

  /** HTTP status code. */
  status: int32;

  /** Explanation of this occurrence of the problem. It contains no internal data. */
  detail?: string;

  /** URI reference of this occurrence. It contains no personal data and no secret. */
  instance?: string;

  /** Stable code that a machine can read, for example `ticket_not_found`. */
  @maxLength(64)
  code: string;

  /** ID of the request. An operator uses it to find the error in the logs. */
  requestId?: string;

  /** ID of the trace. An operator uses it to find the error in the traces. */
  traceId?: string;

  /** Field errors. Only for validation errors. */
  errors?: FieldError[];
}

/** One incorrect field of a request. */
@friendlyName("FieldError")
model FieldError {
  /** JSON Pointer to the incorrect value. */
  field: string;

  /** Stable code that a machine can read. */
  code: string;

  /** Message for a person. */
  message: string;
}

/** The request is not valid. */
@error
@friendlyName("BadRequest")
model BadRequest extends Problem {
  @statusCode statusCode: 400;
}

/** The request has no valid credentials. */
@error
@friendlyName("Unauthorized")
model Unauthorized extends Problem {
  @statusCode statusCode: 401;
}

/**
 * The token does not show a fresh MFA login (RFC 9470). The code is `reauthentication_required`.
 * The client must start a new authorization request with `max_age`. A token refresh does not help.
 * The header `WWW-Authenticate` is optional in this model, because the 401 response of an operation also covers `Unauthorized`.
 * An operation that uses this model always sends the header with the code `reauthentication_required`.
 */
@error
@friendlyName("ReauthenticationRequired")
model ReauthenticationRequired extends Problem {
  @statusCode statusCode: 401;

  /** Challenge, for example `Bearer error="insufficient_user_authentication", error_description="A fresh MFA login is necessary", max_age="300"`. `error_description` is optional. */
  @header("WWW-Authenticate") wwwAuthenticate?: string;
}

/** The principal does not have the permission. */
@error
@friendlyName("Forbidden")
model Forbidden extends Problem {
  @statusCode statusCode: 403;

  /** Permissions that the principal lacks. An agent uses them to ask the user for approval. */
  missingScopes?: PermissionKey[];
}

/** The resource does not exist. */
@error
@friendlyName("NotFound")
model NotFound extends Problem {
  @statusCode statusCode: 404;
}

/** The request conflicts with the state of the resource. */
@error
@friendlyName("Conflict")
model Conflict extends Problem {
  @statusCode statusCode: 409;
}

/** The request is well formed, but the server cannot process its content. */
@error
@friendlyName("UnprocessableContent")
model UnprocessableContent extends Problem {
  @statusCode statusCode: 422;
}

/** The client sent too many requests. */
@error
@friendlyName("TooManyRequests")
model TooManyRequests extends Problem {
  @statusCode statusCode: 429;

  /** Seconds to wait before the next request. */
  @minValue(0)
  @header("Retry-After")
  retryAfter: int32;
}

/** The server has an internal error. */
@error
@friendlyName("InternalServerError")
model InternalServerError extends Problem {
  @statusCode statusCode: 500;
}

/** The service is not available. */
@error
@friendlyName("ServiceUnavailable")
model ServiceUnavailable extends Problem {
  @statusCode statusCode: 503;
}

/** Errors that most operations can return. */
alias CommonErrors =
  | BadRequest
  | Unauthorized
  | Forbidden
  | InternalServerError;
