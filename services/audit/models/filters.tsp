import "@typespec/http";

using Http;
using Constellation.Common;

namespace Constellation.Audit;

/** Query filters of the search and the export. All are optional. They combine with AND. */
@friendlyName("AuditEntryFilters")
model AuditEntryFilters {
  /** Start of the time range. Inclusive. */
  @query from?: utcDateTime;

  /** End of the time range. Exclusive. `from` must be before `to`. */
  @query to?: utcDateTime;

  /** Return only the entries of this service. */
  @query service?: AppKey;

  /** Return only this action. */
  @query action?: PermissionKey;

  /** Return only this result. */
  @query result?: AuditResult;

  /** Return only the entries of this actor. */
  @query
  @minLength(1)
  @maxLength(128)
  actor?: string;

  /** Return only the entries of this actor type. */
  @query actorType?: PrincipalType;

  /** Return only the entries with this `act`. */
  @query
  @minLength(1)
  @maxLength(128)
  act?: string;

  /** Return only the entries with this target type. */
  @query targetType?: AuditTargetType;

  /** Return only the entries with this target ID. It needs `targetType`. */
  @query
  @minLength(1)
  @maxLength(256)
  targetId?: string;

  /** Return only the entries with this request ID. */
  @query
  @minLength(1)
  @maxLength(128)
  requestId?: string;

  /** Return only the entries with this trace ID. 32 lowercase hex characters. */
  @query
  @pattern("^[0-9a-f]{32}$")
  traceId?: string;
}
