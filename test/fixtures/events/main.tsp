import "@typespec/http";
import "../../../lib";

using Http;
using Constellation.Common;

/** Fixture service for the CloudEvents tests. */
@service(#{ title: "Fixture Events" })
namespace Fixture.Events;

/** Data of the ticket created event. */
model TicketCreated {
  /** ID of the ticket. */
  ticketId: string;
}

/** The ticket created event. */
model TicketCreatedEvent is CloudEvent<TicketCreated>;

/** Operations on events. */
@route("/events")
interface Events {
  /** Returns an event. */
  @get
  get(): TicketCreatedEvent;
}
