import "@typespec/http";

using Http;

namespace Constellation.Helpdesk;

/** A UUID in lowercase text form. The pattern is RE2 syntax. */
@friendlyName("ResourceId")
@pattern("^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$")
@format("uuid")
scalar ResourceId extends string;

/**
 * Response headers for a response that has personal data or text from customers.
 * A cache must not keep the response.
 */
alias HelpdeskNoStoreHeaders = {
  /** Cache rule. */
  @header("Cache-Control") cacheControl: "no-store";

  /** Cache rule for old HTTP/1.0 caches. */
  @header("Pragma") pragma: "no-cache";
};
