import "@typespec/http";
import "@typespec/openapi";
import "../../lib";
import "./models";
import "./operations";
import "./events";

using Http;

/**
 * The email service API. Clients send messages and manage templates, sender rules, and suppressions.
 * The audience of the service is `email`.
 * The permission manifest of the service is in `services/email/manifest.json`.
 * The event types of the service are in `services/email/events/event-types.json`.
 */
@service(#{ title: "Constellation Email" })
@useAuth(BearerAuth)
namespace Constellation.Email;
