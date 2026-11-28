import "@typespec/json-schema";

using TypeSpec.JsonSchema;

namespace Constellation.Email;

/** A UUID in lowercase text form. The pattern is RE2 syntax. */
@friendlyName("EventResourceId")
@pattern("^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$")
@format("uuid")
scalar EventResourceId extends string;

/** Key of the app that sent the message. */
@friendlyName("EventAppKey")
@pattern("^[a-z][a-z0-9_]*$")
@maxLength(32)
scalar EventAppKey extends string;

/**
 * Data of the event `email.message.sent`. The service sent the message to the mail system.
 * It has no address, no subject, and no content.
 */
@jsonSchema
@friendlyName("EmailMessageSentData")
model EmailMessageSentData {
  /** ID of the message. */
  messageId: EventResourceId;

  /** Key of the app that sent the message. */
  senderApp: EventAppKey;

  /** Number of recipients that this event is about. */
  @minValue(1)
  @maxValue(50)
  recipientCount: int32;

  /** Number of the send attempt. */
  @minValue(1)
  attempt: int32;
}

/** Data of the event `email.message.failed`. The service did not send the message and does not try again. */
@jsonSchema
@friendlyName("EmailMessageFailedData")
model EmailMessageFailedData {
  /** ID of the message. */
  messageId: EventResourceId;

  /** Key of the app that sent the message. */
  senderApp: EventAppKey;

  /** Number of recipients that this event is about. */
  @minValue(1)
  @maxValue(50)
  recipientCount: int32;

  /** Number of the last send attempt. */
  @minValue(1)
  attempt: int32;

  /** Reason of the failure. */
  failureCode: EmailFailureCode;
}

/** Data of the event `email.message.suppressed`. The service did not send to the recipients because they are on the suppression list. */
@jsonSchema
@friendlyName("EmailMessageSuppressedData")
model EmailMessageSuppressedData {
  /** ID of the message. */
  messageId: EventResourceId;

  /** Key of the app that sent the message. */
  senderApp: EventAppKey;

  /** Number of recipients that this event is about. */
  @minValue(1)
  @maxValue(50)
  recipientCount: int32;
}

/**
 * Data of the event `email.message.delivered`. The mail system delivered the message.
 * `recipientCount` is the number of recipients that this one event is about.
 * A notification can be about only some recipients of a message.
 */
@jsonSchema
@friendlyName("EmailMessageDeliveredData")
model EmailMessageDeliveredData {
  /** ID of the message. */
  messageId: EventResourceId;

  /** Key of the app that sent the message. */
  senderApp: EventAppKey;

  /** Number of recipients that this event is about. */
  @minValue(1)
  @maxValue(50)
  recipientCount: int32;
}

/**
 * Data of the event `email.message.bounced`. The mail system rejected the message.
 * `bounceType` is `permanent` for a rejection of the 5xx class, `transient` for the 4xx class,
 * and `undetermined` for a rejection with no known class.
 */
@jsonSchema
@friendlyName("EmailMessageBouncedData")
model EmailMessageBouncedData {
  /** ID of the message. */
  messageId: EventResourceId;

  /** Key of the app that sent the message. */
  senderApp: EventAppKey;

  /** Number of recipients that this event is about. */
  @minValue(1)
  @maxValue(50)
  recipientCount: int32;

  /** Type of the bounce. */
  bounceType: EmailBounceType;
}

/** Data of the event `email.message.complained`. A recipient marked the message as unwanted. */
@jsonSchema
@friendlyName("EmailMessageComplainedData")
model EmailMessageComplainedData {
  /** ID of the message. */
  messageId: EventResourceId;

  /** Key of the app that sent the message. */
  senderApp: EventAppKey;

  /** Number of recipients that this event is about. */
  @minValue(1)
  @maxValue(50)
  recipientCount: int32;
}
