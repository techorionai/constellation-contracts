import "@typespec/http";
import "@typespec/openapi";
import "../../lib";
import "./models";
import "./operations";

using Http;

/**
 * The audit service API. Clients search, read, and export audit entries.
 * Services write audit entries through their audit outbox and the Valkey streams `audit.stream:<app>`. They do not call this API.
 * The audience of the service is `audit`.
 * The permission manifest of the service is in `services/audit/manifest.json`.
 */
@service(#{ title: "Constellation Audit" })
@useAuth(BearerAuth)
namespace Constellation.Audit;
