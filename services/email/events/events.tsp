using Constellation.Common;

namespace Constellation.Email;

/** The event `email.message.sent`. The `subject` is `messages/<id>`. */
@friendlyName("EmailMessageSentEvent")
model EmailMessageSentEvent is CloudEvent<EmailMessageSentData>;

/** The event `email.message.failed`. The `subject` is `messages/<id>`. */
@friendlyName("EmailMessageFailedEvent")
model EmailMessageFailedEvent is CloudEvent<EmailMessageFailedData>;

/** The event `email.message.suppressed`. The `subject` is `messages/<id>`. */
@friendlyName("EmailMessageSuppressedEvent")
model EmailMessageSuppressedEvent is CloudEvent<EmailMessageSuppressedData>;

/** The event `email.message.delivered`. The `subject` is `messages/<id>`. */
@friendlyName("EmailMessageDeliveredEvent")
model EmailMessageDeliveredEvent is CloudEvent<EmailMessageDeliveredData>;

/** The event `email.message.bounced`. The `subject` is `messages/<id>`. */
@friendlyName("EmailMessageBouncedEvent")
model EmailMessageBouncedEvent is CloudEvent<EmailMessageBouncedData>;

/** The event `email.message.complained`. The `subject` is `messages/<id>`. */
@friendlyName("EmailMessageComplainedEvent")
model EmailMessageComplainedEvent is CloudEvent<EmailMessageComplainedData>;
