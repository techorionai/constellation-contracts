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
   * The first page of each search (a request with no `pageToken`) writes an audit entry with the action `audit:log:search` and the filters. Later pages write no entry.
   * The response has `Cache-Control: no-store` and `Pragma: no-cache`.
   * A limited request gives 429 `rate_limited` with the required `Retry-After`.
   * Error code of `ServiceUnavailable`: `unavailable`. It has `Retry-After` when the database is not available.
   */
  @extension("x-required-scopes", #["audit:log:read"])
  @list
  @get
  list(...CursorPageParams, ...AuditEntryFilters):
    | AuditEntryPageResponse
    | TooManyRequests
    | ServiceUnavailable
    | CommonErrors;

  /**
   * Export audit entries with the same filters as the search. `format` is required: `csv` or `json`.
   * The response is one document. `csv` gives `text/csv` (RFC 4180, with a header row). `json` gives `application/json`: one JSON array of `AuditEntry`.
   * The CSV columns, in this order: `id`, `service`, `time`, `receivedAt`, `action`, `result`, `actor`, `actorType`, `act`, `actType`,
   * `targetType`, `targetId`, `summary`, `requestId`, `traceId`, `ipAddress`, `userAgent`, `details` (JSON text).
   * Each CSV field is in double quotes, and a `"` in a field becomes `""`. A field that starts with `=`, `+`, `-`, `@`, a tab, a carriage return, or a line feed gets a `'` in front. This rule applies to all columns.
   * Producers must remove or escape control characters and bidirectional control characters in free text, for example `summary`, `requestId`, and `userAgent`.
   * The order of the entries is the order of the search.
   * An export has a maximum count of entries that the operator sets. The default is 100000.
   * An export also has a maximum size in bytes that the operator sets. The default is 256 MiB. The service must stream the body and must not keep the full export in memory.
   * More entries than the count limit give 422 `export_too_large` before the first byte. An export that reaches the byte limit while the service streams stops, and the service closes the connection with an error. The client must not use a partial export.
   * Each instance runs a maximum of 2 exports at the same time, and each principal runs a maximum of 1 export at the same time. An export above a limit gives 429 `too_many_exports` with the required `Retry-After`. The 429 body is a `TooManyExports` problem.
   * `Content-Disposition` is `attachment; filename="audit-entries-<UTC time in the form 20261127T101500Z>.<csv or json>"`. `X-Content-Type-Options` is `nosniff`.
   * The route `/v1/audit-entries/export` has precedence over `/v1/audit-entries/{id}`. The value `export` is never an entry ID.
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
    | TooManyExports
    | ServiceUnavailable
    | CommonErrors;

  /**
   * Get one audit entry. `id` is a UUID in text form.
   * A value that is not a UUID gives 400 `invalid_parameter`. An unknown ID gives 404 `audit_entry_not_found`.
   * The value `export` is not an ID. The route `/v1/audit-entries/export` has precedence over this route.
   * Two services can use the same ID. `id` with `service` is the unique key.
   * With `service`, the operation returns the entry of that service, or 404.
   * Without `service`, it returns the entry with the oldest `receivedAt`.
   * The response has `Cache-Control: no-store` and `Pragma: no-cache`.
   * A limited request gives 429 `rate_limited` with the required `Retry-After`.
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
  ):
    | AuditEntryResponse
    | NotFound
    | TooManyRequests
    | ServiceUnavailable
    | CommonErrors;
}
