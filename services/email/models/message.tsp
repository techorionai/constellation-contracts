using Http;
using Constellation.Common;

namespace Constellation.Email;

/** Status of a message. */
@friendlyName("MessageStatus")
union MessageStatus {
  "queued",
  "sending",
  "sent",
  "partially_sent",
  "failed",
  "suppressed",
}

/** Kind of a recipient. */
@friendlyName("RecipientKind")
union RecipientKind {
  "to",
  "cc",
  "bcc",
}

/**
 * Status of a recipient. A delivery notification changes only the status of the recipient.
 * The status of the message stays `sent` or `partially_sent`.
 */
@friendlyName("RecipientStatus")
union RecipientStatus {
  "pending",
  "sent",
  "delivered",
  "bounced",
  "complained",
  "suppressed",
  "failed",
}

/** One recipient of a message. */
@friendlyName("MessageRecipient")
model MessageRecipient {
  /** Email address of the recipient. */
  address: EmailAddress;

  /** Kind of the recipient. */
  kind: RecipientKind;

  /** Status of the recipient. */
  status: RecipientStatus;

  /** Type of the bounce. Only for the status `bounced`. */
  bounceType?: EmailBounceType;
}

/**
 * A message in the queue or sent. It has the metadata and the status for each recipient.
 * It does not have the subject, the text, the HTML, or the template variables.
 * The service deletes a message 24 hours after `sendAt`. After this time, a read gives 404 `message_not_found`.
 */
@friendlyName("Message")
model Message {
  /** ID of the message. */
  id: ResourceId;

  /** Key of the app that sent the message. */
  senderApp: AppKey;

  /** Status of the message. */
  status: MessageStatus;

  /** Address of the sender. */
  from: EmailAddress;

  /** Recipients of the message. */
  recipients: MessageRecipient[];

  /** Key of the template. Only if the message used a template. */
  templateKey?: string;

  /** Number of send attempts. */
  @minValue(0)
  attempts: int32;

  /** Time when the service starts to send the message. */
  sendAt: utcDateTime;

  /** Time when the message was accepted. */
  createdAt: utcDateTime;

  /** Time when the message was changed. */
  updatedAt: utcDateTime;

  /** Time when the service sent the message. */
  sentAt?: utcDateTime;

  /** Reason of the failure. Only for the status `failed`. */
  failureCode?: EmailFailureCode;
}

/** One page of messages. */
model MessagePage is CursorPage<Message>;

/** Filters of the list of messages. */
@friendlyName("MessageFilters")
model MessageFilters {
  /** Show only messages with this status. */
  @query status?: MessageStatus;

  /** Show only messages with `createdAt` at or after this time. */
  @query createdFrom?: utcDateTime;

  /** Show only messages with `createdAt` before this time. */
  @query createdTo?: utcDateTime;
}
