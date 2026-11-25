using Http;
using Constellation.Common;

namespace Constellation.Identity;

/** Discovery documents. They have no authentication and no `/v1` prefix. */
@route("/.well-known")
interface Discovery {
  /**
   * Get the OIDC discovery document.
   * Error code of `TooManyRequests`: `rate_limited`.
   */
  @useAuth(NoAuth)
  @route("/openid-configuration")
  @get
  openidConfiguration(): DiscoveryDocument | TooManyRequests;

  /**
   * Get the public keys that verify the tokens of the service.
   * Error code of `TooManyRequests`: `rate_limited`.
   */
  @useAuth(NoAuth)
  @route("/jwks.json")
  @get
  jwks(): JsonWebKeySet | TooManyRequests;
}
