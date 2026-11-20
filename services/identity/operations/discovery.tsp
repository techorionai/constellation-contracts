using Http;

namespace Constellation.Identity;

/** Discovery documents. They have no authentication and no `/v1` prefix. */
@route("/.well-known")
interface Discovery {
  /** Get the OIDC discovery document. */
  @useAuth(NoAuth)
  @route("/openid-configuration")
  @get
  openidConfiguration(): DiscoveryDocument;

  /** Get the public keys that verify the tokens of the service. */
  @useAuth(NoAuth)
  @route("/jwks.json")
  @get
  jwks(): JsonWebKeySet;
}
