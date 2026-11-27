import "@typespec/http";

using Http;

namespace Constellation.Audit;

/**
 * Response headers for a response that has personal data, for example an IP address or a user agent.
 * A cache must not keep the response.
 */
alias AuditNoStoreHeaders = {
  /** Cache rule. */
  @header("Cache-Control") cacheControl: "no-store";

  /** Cache rule for old HTTP/1.0 caches. */
  @header("Pragma") pragma: "no-cache";
};

/** The export limit of the principal or of the instance is reached. The code is `too_many_exports`. */
@error
@friendlyName("TooManyExports")
model TooManyExports {
  ...Constellation.Common.Problem;

  /** Status of the response. */
  @statusCode statusCode: 429;

  /** Seconds to wait before the next export. */
  @minValue(0)
  @header("Retry-After")
  retryAfter: int32;
}

/** An export of audit entries as CSV or JSON. CSV follows RFC 4180, with a header row. JSON is one array. */
@friendlyName("AuditCsvExport")
model AuditCsvExport {
  /** Media type of the response. */
  @header contentType: "text/csv";

  /** Status of the response. */
  @statusCode statusCode: 200;

  /** Name of the file. The value is `attachment; filename="audit-entries-<UTC time>.<csv or json>"`. */
  @header("Content-Disposition") contentDisposition: string;

  /** The browser must not guess the media type. */
  @header("X-Content-Type-Options") contentTypeOptions: "nosniff";

  ...AuditNoStoreHeaders;

  /** The CSV text. */
  @body body: string;
}

/** An export of audit entries as CSV or JSON. CSV follows RFC 4180, with a header row. JSON is one array. */
@friendlyName("AuditJsonExport")
model AuditJsonExport {
  /** Media type of the response. */
  @header contentType: "application/json";

  /** Status of the response. */
  @statusCode statusCode: 200;

  /** Name of the file. The value is `attachment; filename="audit-entries-<UTC time>.<csv or json>"`. */
  @header("Content-Disposition") contentDisposition: string;

  /** The browser must not guess the media type. */
  @header("X-Content-Type-Options") contentTypeOptions: "nosniff";

  ...AuditNoStoreHeaders;

  /** The audit entries. */
  @body body: AuditEntry[];
}

/** An audit entry response with the no-store headers. */
@friendlyName("AuditEntryResponse")
model AuditEntryResponse {
  /** Status of the response. */
  @statusCode statusCode: 200;

  ...AuditNoStoreHeaders;

  /** The audit entry. */
  @body body: AuditEntry;
}

/** A page response with the no-store headers. */
@friendlyName("AuditEntryPageResponse")
model AuditEntryPageResponse {
  /** Status of the response. */
  @statusCode statusCode: 200;

  ...AuditNoStoreHeaders;

  /** The page. */
  @body body: AuditEntryPage;
}

/** The export format. */
@friendlyName("AuditExportFormat")
union AuditExportFormat {
  "csv",
  "json",
}
