using Http;
using OpenAPI;
using Constellation.Common;

namespace Constellation.Audit;

/** Operations on audit entries. */
@route("/v1/audit-entries")
interface AuditEntries {
  /**
   * Search audit entries. The order is `time` descending, then the internal key of the service descending.
   * The order of entries with the same `time` is stable, but a client must not use it.
   * `from` is inclusive and `to` is exclusive. `from` must be before `to`. Else 400 `invalid_parameter`.
   * `targetId` needs `targetType`. Else 400 `invalid_parameter`.
   * A filter value that breaks its rule gives 400 `invalid_parameter`.
   * A bad page token, or a token that was made with other filters, gives 400 `invalid_page_token`.
   * A page ends at 1 MiB of response body, with a minimum of one item.
   * The response has `Cache-Control: no-store` and `Pragma: no-cache`.
   * Error code of `ServiceUnavailable`: `unavailable`. It has `Retry-After` when the database is not available.
   */
  @extension("x-required-scopes", #["audit:log:read"])
  @list
  @get
  list(...CursorPageParams, ...AuditEntryFilters):
    | AuditEntryPageResponse
    | ServiceUnavailable
    | CommonErrors;

  /**
   * Export audit entries with the same filters as the search. `format` is required: `csv` or `json`.
   * The response is one document. `csv` gives `text/csv` (RFC 4180, with a header row). `json` gives `application/json`: one JSON array of `AuditEntry`.
   * The CSV columns, in this order: `id`, `service`, `time`, `receivedAt`, `action`, `result`, `actor`, `actorType`, `act`, `actType`,
   * `targetType`, `targetId`, `summary`, `requestId`, `traceId`, `ipAddress`, `userAgent`, `details` (JSON text).
   * A CSV cell that starts with `=`, `+`, `-`, `@`, a tab, or a carriage return gets a `'` in front.
   * The order of the entries is the order of the search.
   * An export has a maximum count of entries that the operator sets. The default is 100000.
   * More entries give 422 `export_too_large` before the first byte.
   * Each instance runs a maximum of 2 exports at the same time. A third export gives 429 `too_many_exports` with the required `Retry-After`. The 429 body is a `TooManyRequests` problem.
   * `Content-Disposition` is `attachment; filename="audit-entries-<UTC time in the form 20261127T101500Z>.<csv or json>"`.
   * Each export writes an audit entry with the action `audit:log:export`, the format, the filters, and the count.
   * The filter rules and the error codes of the search apply. `invalid_parameter` is the code of 400.
   * The response has `Cache-Control: no-store` and `Pragma: no-cache`.
   * Error code of `ServiceUnavailable`: `unavailable`. It has `Retry-After` when the database is not available.
   */
  @extension("x-required-scopes", #["audit:log:read"])
  @route("/export")
  @get
  export(
    /** Format of the export. */
    @query format: AuditExportFormat,

    ...AuditEntryFilters,
  ):
    | AuditCsvExport
    | AuditJsonExport
    | UnprocessableContent
    | TooManyRequests
    | ServiceUnavailable
    | CommonErrors;

  /**
   * Get one audit entry. `id` is a UUID in text form.
   * A value that is not a UUID, or an unknown ID, gives 404 `audit_entry_not_found`.
   * Two services can use the same ID. `id` with `service` is the unique key.
   * With `service`, the operation returns the entry of that service, or 404.
   * Without `service`, it returns the entry with the oldest `receivedAt`.
   * The response has `Cache-Control: no-store` and `Pragma: no-cache`.
   * Error code of `ServiceUnavailable`: `unavailable`. It has `Retry-After` when the database is not available.
   */
  @extension("x-required-scopes", #["audit:log:read"])
  @route("/{id}")
  @get
  get(
    /** ID of the entry. */
    @path @format("uuid") id: string,

    /** The service of the entry. */
    @query service?: AppKey,
  ): AuditEntryResponse | NotFound | ServiceUnavailable | CommonErrors;
}
