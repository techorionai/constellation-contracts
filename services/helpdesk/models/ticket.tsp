import "@typespec/http";

using Http;
using Constellation.Common;

namespace Constellation.Helpdesk;

/** Status of a ticket. */
@friendlyName("TicketStatus")
union TicketStatus {
  "open",
  "pending",
  "resolved",
  "closed",
}

/** Priority of a ticket. */
@friendlyName("TicketPriority")
union TicketPriority {
  "low",
  "normal",
  "high",
  "urgent",
}

/** A ticket of the helpdesk. */
@friendlyName("Ticket")
model Ticket {
  /** ID of the ticket. A UUID in lowercase text form. */
  id: ResourceId;

  /** Number of the ticket. The service sets it. A person can read it more easily than the ID. */
  @minValue(1)
  number: int64;

  /** Subject of the ticket. */
  @minLength(1)
  @maxLength(200)
  subject: string;

  /** Description of the ticket. */
  @minLength(1)
  @maxLength(10000)
  description?: string;

  /** Status of the ticket. */
  status: TicketStatus;

  /** Priority of the ticket. */
  priority: TicketPriority;

  /** ID of the customer of the ticket. */
  customerId: ResourceId;

  /** Time when the ticket was created. */
  createdAt: utcDateTime;

  /** Time when the ticket was changed. */
  updatedAt: utcDateTime;
}

/** Request to create a ticket. The status of a new ticket is `open`. */
@friendlyName("TicketCreate")
model TicketCreate {
  /** Subject of the ticket. */
  @minLength(1)
  @maxLength(200)
  subject: string;

  /** Description of the ticket. */
  @minLength(1)
  @maxLength(10000)
  description?: string;

  /** Priority of the ticket. The default is `normal`. */
  priority?: TicketPriority;

  /** ID of the customer of the ticket. */
  customerId: ResourceId;
}

/** Request to change a ticket. A field that is not present does not change. The request needs at least one field. */
@friendlyName("TicketUpdate")
model TicketUpdate {
  /** Subject of the ticket. */
  @minLength(1)
  @maxLength(200)
  subject?: string;

  /** Description of the ticket. */
  @minLength(1)
  @maxLength(10000)
  description?: string;

  /** Priority of the ticket. */
  priority?: TicketPriority;

  /** Status of the ticket. */
  status?: TicketStatus;
}

/** Query filters of the ticket list. All are optional. They combine with AND. */
@friendlyName("TicketFilters")
model TicketFilters {
  /** Return only the tickets with this status. */
  @query status?: TicketStatus;

  /** Return only the tickets with this priority. */
  @query priority?: TicketPriority;

  /** Return only the tickets of this customer. */
  @query customerId?: ResourceId;
}

/** One page of tickets. */
model TicketPage is CursorPage<Ticket>;
