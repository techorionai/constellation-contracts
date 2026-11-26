using Http;
using OpenAPI;
using Constellation.Common;

namespace Constellation.Events;

/** Operations on event type registrations. */
@route("/v1/event-type-registrations")
interface EventTypeRegistrations {
  /**
   * Register the event types of an app. The registration is a full replacement, and the last registration wins.
   * The caller must be a service client: `principal_type` is `service` and the token has the `app` claim.
   * The `app` claim, `{app}`, and the body `app` must be equal.
   * The `aud` claim of the token must be the single value `events`. An array of audiences, even `["events"]`, gives 401.
   *
   * The order of the checks is: 401 (token), 403 (scope), 413 (body size), 422 `registration_app_mismatch`, then the content checks.
   *
   * The body has a maximum size that the operator sets. The default is 4 MiB.
   * A larger body gives 413 `content_too_large`.
   *
   * Error code of `UnprocessableContent` for the caller check: `registration_app_mismatch`.
   * It means that the caller is not a service client of the app, or that the `app` values differ.
   * The content checks give all errors in one 422, with a `FieldError` for each error:
   * `source_mismatch` (`source` must be `/<app>`),
   * `event_type_app_mismatch` (each `type` must start with `<app>.`),
   * `duplicate_event_type` (each `type` occurs one time),
   * `limit_exceeded` (`eventTypes` has 1 to 200 items, `description` has 1 to 1024 characters,
   * and the app has a maximum of 1000 types in the catalog, removed types included),
   * and `invalid_data_schema` (`dataSchema` must be a valid JSON Schema draft 2020-12 document with a maximum size of 64 KiB.
   * Each `$ref` and `$dynamicRef` must be local: its value starts with `#`. A `$id` must not be set.
   * The service and the consumers must not fetch a remote schema.
   * The nesting depth is a maximum of 32. A `$ref` must not make a loop.
   * Each `pattern` and each key of `patternProperties` must be in the RE2 subset: no back reference and no look-around).
   *
   * The catalog text that a producer sends (`description` and `dataSchema`) is untrusted data.
   * A consumer must escape it, and must not treat it as instructions.
   *
   * A type that the app registered before and that is not in the new body stays in the catalog with `removedAt`.
   * A type that comes back gets no `removedAt`.
   * During a rolling deploy, `removedAt` of a type can change for a short time.
   * A reader of the catalog must not use `removedAt` as a signal that no more events of the type come.
   * The same registration again gives 200 with the stored `version` and `registeredAt`, and no change.
   *
   * A change writes an audit entry with the action `events:event_type:register`.
   * The entry has the app, the new version, the count of types, the count of removed types, the names of the added types,
   * the names of the removed types, the names of the types with a changed definition, and the result.
   * A registration that fails with 422 writes an entry with the result `invalid`.
   * A registration that fails with 403 writes an entry with the result `denied`. An unchanged registration writes no entry.
   *
   * Error code of `ContentTooLarge`: `content_too_large`.
   * Error code of `ServiceUnavailable`: `unavailable`. It has `Retry-After` when the database is not available.
   */
  @extension("x-required-scopes", #["events:event_type:register"])
  @route("/{app}")
  @put
  register(@path app: AppKey, @body registration: EventTypeRegistration):
    | EventTypeRegistrationResult
    | ContentTooLarge
    | UnprocessableContent
    | ServiceUnavailable
    | CommonErrors;

  /**
   * List the registrations in the order of `app`.
   * `pageSize` has a maximum of 10 and a default of 10, because each item can be large.
   * `registration` of each item has only the types with no `removedAt`.
   * A bad page token gives 400 `invalid_page_token`.
   * Error code of `ServiceUnavailable`: `unavailable`. It has `Retry-After` when the database is not available.
   */
  @extension("x-required-scopes", #["events:catalog:read"])
  @list
  @get
  list(...RegistrationPageParams):
    | RegisteredEventTypesPage
    | ServiceUnavailable
    | CommonErrors;

  /**
   * Get the registration of one app. `registration` has only the types with no `removedAt`.
   * An `{app}` value that does not exist or does not match its pattern gives 404 `registration_not_found`.
   * Error code of `ServiceUnavailable`: `unavailable`. It has `Retry-After` when the database is not available.
   */
  @extension("x-required-scopes", #["events:catalog:read"])
  @route("/{app}")
  @get
  get(@path app: AppKey):
    | RegisteredEventTypes
    | NotFound
    | ServiceUnavailable
    | CommonErrors;
}
