import "@typespec/http";
import "@typespec/openapi";
import "../../lib";
import "./models";
import "./operations";

using Http;

/**
 * The events service API. Services register their event types with it.
 * Clients read the central event catalog through it.
 * Events do not go through this service. They go through the outbox and the Valkey streams.
 * The audience of the service is `events`.
 * The permission manifest of the service is in `services/events/manifest.json`.
 */
@service(#{ title: "Constellation Events" })
@useAuth(BearerAuth)
namespace Constellation.Events;
