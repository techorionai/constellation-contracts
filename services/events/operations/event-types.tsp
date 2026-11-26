using Http;
using OpenAPI;
using Constellation.Common;

namespace Constellation.Events;

/** Operations on the event catalog. */
@route("/v1/event-types")
interface EventTypes {
  /**
   * List the event types of the catalog in the order of `type`.
   * `includeRemoved` is `false` by default. `app` filters by app.
   * An `app` value that does not match the `AppKey` pattern gives 400 `invalid_parameter`.
   * A bad page token gives 400 `invalid_page_token`.
   * Error code of `ServiceUnavailable`: `unavailable`. It has `Retry-After` when the database is not available.
   */
  @extension("x-required-scopes", #["events:catalog:read"])
  @list
  @get
  list(
    ...CursorPageParams,

    /** Return only the types of this app. */
    @query app?: AppKey,

    /** Also return the types that have `removedAt`. */
    @query includeRemoved?: boolean = false,
  ): CatalogEventTypePage | ServiceUnavailable | CommonErrors;

  /**
   * Get one event type. This operation also returns a removed type, with `removedAt`.
   * A `{type}` value that does not exist or does not match its pattern gives 404 `event_type_not_found`.
   * Error code of `ServiceUnavailable`: `unavailable`. It has `Retry-After` when the database is not available.
   */
  @extension("x-required-scopes", #["events:catalog:read"])
  @route("/{type}")
  @get
  get(@path type: EventType):
    | CatalogEventType
    | NotFound
    | ServiceUnavailable
    | CommonErrors;
}
