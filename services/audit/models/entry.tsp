import "@typespec/http";

using Constellation.Common;

namespace Constellation.Audit;

/** One audit entry in the audit service. The service and `id` together are the unique key. */
@friendlyName("AuditEntry")
model AuditEntry {
  /** ID of the entry: the CloudEvent `id`. A UUID in lowercase text form. */
  @format("uuid")
  id: string;

  /** Key of the app that wrote the entry. It comes from `source`. */
  service: AppKey;

  /** Time of the action. */
  time: utcDateTime;

  /** Time at which the audit service stored the entry. */
  receivedAt: utcDateTime;

  /** The action. */
  action: PermissionKey;

  /** Result of the action. */
  result: AuditResult;

  /** The ID of the principal that did the action. */
  actor: string;

  /** Type of the principal in `actor`. */
  actorType: PrincipalType;

  /** The agent that acted for the user, or the proposer of an action that a user approved. */
  act?: string;

  /** Type of the principal in `act`. */
  actType?: PrincipalType;

  /** The resource that the action acted on. */
  target?: AuditTarget;

  /** Short text for a person. */
  summary?: string;

  /** Details of the action. */
  details?: Record<unknown>;

  /** The `X-Request-ID` of the request. */
  requestId?: string;

  /** ID of the trace, from `traceparent`. 32 lowercase hex characters. */
  @pattern("^[0-9a-f]{32}$")
  traceId?: string;

  /** IP address of the client. */
  @maxLength(45)
  ipAddress?: string;

  /** The `User-Agent` of the request. */
  @maxLength(512)
  userAgent?: string;
}

/** One page of audit entries. */
model AuditEntryPage is CursorPage<AuditEntry>;
