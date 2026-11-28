import "@typespec/http";

using Http;

namespace Constellation.Email;

/** A 200 response with the no-store headers. */
model EmailOk<T> {
  /** Status of the response. */
  @statusCode statusCode: 200;

  ...EmailNoStoreHeaders;

  /** The body. */
  @body body: T;
}

/** A 201 response with the no-store headers. */
model EmailCreated<T> {
  /** Status of the response. */
  @statusCode statusCode: 201;

  ...EmailNoStoreHeaders;

  /** The new resource. */
  @body body: T;
}

/** A 202 response with the no-store headers. */
model EmailAccepted<T> {
  /** Status of the response. */
  @statusCode statusCode: 202;

  ...EmailNoStoreHeaders;

  /** The accepted resource. */
  @body body: T;
}

/** A 204 response with the no-store headers. */
model EmailNoContent {
  /** Status of the response. */
  @statusCode statusCode: 204;

  ...EmailNoStoreHeaders;
}
