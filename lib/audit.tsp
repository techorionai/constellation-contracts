namespace Constellation.Common;

/** Result of an audited action. */
@friendlyName("AuditResult")
union AuditResult {
  "success",
  "denied",
  "invalid",
  "failure",
}

/** Type of the target of an audited action, for example `ticket`. */
@pattern("^[a-z][a-z0-9_]{0,63}$")
@friendlyName("AuditTargetType")
scalar AuditTargetType extends string;

/** The resource that an audited action acted on. */
@friendlyName("AuditTarget")
model AuditTarget {
  /** Type of the resource. */
  type: AuditTargetType;

  /** ID of the resource. */
  @minLength(1)
  @maxLength(256)
  id: string;
}

/**
 * Data of an audit entry. The time, the actor, `act`, the service, and the trace ID are in the envelope of the event.
 * `action` is an action key in the form of a `PermissionKey`. It starts with `<app>:` of the producer.
 * It does not have to be a key of the manifest of the producer.
 * `summary` and `details` contain no secret, no token, and no password.
 */
@friendlyName("AuditEntryData")
model AuditEntryData {
  /** The action, for example `identity:mfa:passkey_rename`. */
  action: PermissionKey;

  /** Result of the action. */
  result: AuditResult;

  /** The resource that the action acted on. */
  target?: AuditTarget;

  /** Short text for a person. It has no secret, no token, and no password. */
  @minLength(1)
  @maxLength(1024)
  summary?: string;

  /** Details of the action as a JSON object. It has a maximum of 16 KiB in JSON. It has no secret, no token, and no password. */
  details?: Record<unknown>;

  /** The `X-Request-ID` of the request. */
  @minLength(1)
  @maxLength(128)
  requestId?: string;

  /** IP address of the client. A valid IPv4 or IPv6 address in text form, with no port and no zone. A reader refuses another value. */
  @minLength(1)
  @maxLength(45)
  ipAddress?: string;

  /** The `User-Agent` of the request. */
  @minLength(1)
  @maxLength(512)
  userAgent?: string;
}

/**
 * An audit entry as a CloudEvent. The audit transport rules are:
 *
 * 1. A service writes the audit entry in the same database transaction as the change. The audit outbox of `constellation-platform-go` does this.
 * 2. The relay adds the entry to the Valkey stream `audit.stream:<app>`. Each stream entry has one field `event` with the CloudEvent in JSON.
 * 3. `source` is `/<app>`. `type` is `<app>.audit.recorded`. `id` is a UUID in lowercase text form (UUIDv7 recommended) and is unique for the app.
 *    The audit service removes duplicates by `source` and `id`. The schema of the shared `CloudEvent` does not express the UUID rule.
 * 4. `actor`, `actortype`, `act`, and `acttype` come from the verified principal of the request, never from request data.
 *    An entry with no request principal has the client ID of the producer as `actor` and `service` as `actortype`.
 *    `act` is the agent for an action of an agent for a user. It is the proposer for an action that a user approved.
 * 5. `time` is the time of the action.
 * 6. Only the audit service reads audit streams. A service writes only to its own audit stream.
 * 7. The full CloudEvent has a maximum of 64 KiB.
 * 8. A reader ignores an unknown member of `data` and of the envelope. It does not refuse the entry for this reason.
 */
@friendlyName("AuditRecordedEvent")
model AuditRecordedEvent is CloudEvent<AuditEntryData>;
