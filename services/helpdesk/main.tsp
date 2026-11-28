import "@typespec/http";
import "@typespec/openapi";
import "../../lib";
import "./models";
import "./operations";
import "./events";

using Http;

/**
 * The helpdesk service API. Clients manage customers and tickets.
 * The audience of the service is `helpdesk`.
 * The permission manifest of the service is in `services/helpdesk/manifest.json`.
 * The event types of the service are in `services/helpdesk/events/event-types.json`.
 */
@service(#{ title: "Constellation Helpdesk" })
@useAuth(BearerAuth)
namespace Constellation.Helpdesk;
