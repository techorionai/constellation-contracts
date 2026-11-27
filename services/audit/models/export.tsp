import "@typespec/http";

using Http;

namespace Constellation.Audit;

/**
 * Response headers for a response that has personal data, for example an IP address or a user agent.
 * A cache must not keep the response.
 */
@friendlyName("AuditNoStoreHeaders")
model AuditNoStoreHeaders {
  /** Cache rule. */
  @header("Cache-Control") cacheControl: "no-store";

  /** Cache rule for old HTTP/1.0 caches. */
  @header("Pragma") pragma: "no-cache";
}

/** An export of audit entries as CSV (RFC 4180, with a header row). */
@friendlyName("AuditCsvExport")
model AuditCsvExport {
  /** Media type of the response. */
  @header contentType: "text/csv";

  /** Status of the response. */
  @statusCode statusCode: 200;

  ...AuditNoStoreHeaders;

  /** The CSV text. */
  @body body: string;
}

/** An export of audit entries as one JSON array. */
@friendlyName("AuditJsonExport")
model AuditJsonExport {
  /** Media type of the response. */
  @header contentType: "application/json";

  /** Status of the response. */
  @statusCode statusCode: 200;

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
