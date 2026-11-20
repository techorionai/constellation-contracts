import "@typespec/http";
import "@typespec/openapi";
import "../../lib";
import "./models";
import "./operations";

using Http;

/**
 * The identity service API. The OAuth and OIDC endpoints use standard paths and RFC 6749 errors.
 * The other operations use the prefix `/v1` and RFC 9457 errors.
 * The permission manifest of the service is in `services/identity/manifest.json`.
 */
@service(#{ title: "Constellation Identity" })
@useAuth(BearerAuth)
namespace Constellation.Identity;
