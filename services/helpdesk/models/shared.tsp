import "@typespec/http";

using Http;

namespace Constellation.Helpdesk;

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
