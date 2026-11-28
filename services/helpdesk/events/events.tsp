using Constellation.Common;

namespace Constellation.Helpdesk;

/** The event `helpdesk.ticket.created`. The `subject` is `tickets/<id>`. */
@friendlyName("TicketCreatedEvent")
model TicketCreatedEvent is CloudEvent<TicketCreatedData>;

/** The event `helpdesk.ticket.updated`. The `subject` is `tickets/<id>`. */
@friendlyName("TicketUpdatedEvent")
model TicketUpdatedEvent is CloudEvent<TicketUpdatedData>;

/** The event `helpdesk.ticket.status_changed`. The `subject` is `tickets/<id>`. */
@friendlyName("TicketStatusChangedEvent")
model TicketStatusChangedEvent is CloudEvent<TicketStatusChangedData>;

/** The event `helpdesk.customer.created`. The `subject` is `customers/<id>`. */
@friendlyName("CustomerCreatedEvent")
model CustomerCreatedEvent is CloudEvent<CustomerCreatedData>;

/** The event `helpdesk.customer.updated`. The `subject` is `customers/<id>`. */
@friendlyName("CustomerUpdatedEvent")
model CustomerUpdatedEvent is CloudEvent<CustomerUpdatedData>;
