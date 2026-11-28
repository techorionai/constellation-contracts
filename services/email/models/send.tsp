import "@typespec/openapi3";

using TypeSpec.OpenAPI;

namespace Constellation.Email;

/** Fields that all send requests have. */
@friendlyName("SendMessageFields")
model SendMessageFields {
  /** Address of the sender. A sender rule of the caller app must allow it. */
  from: EmailAddress;

  /** Display name of the sender. */
  @minLength(1)
  @maxLength(100)
  fromName?: string;

  /** Recipients. */
  @minItems(1)
  @maxItems(50)
  to: EmailAddress[];

  /** Copy recipients. */
  @maxItems(50)
  cc?: EmailAddress[];

  /** Blind copy recipients. */
  @maxItems(50)
  bcc?: EmailAddress[];

  /** Address for replies. */
  replyTo?: EmailAddress;

  /** Fields to put the message in a thread. */
  threading?: MessageThreading;

  /** Send time. A maximum of 7 days after the request. The default is now. */
  sendAt?: utcDateTime;
}

/** Message IDs for a thread. */
@friendlyName("MessageThreading")
model MessageThreading {
  /** Message ID of the message that this message answers. */
  @minLength(1)
  @maxLength(998)
  inReplyTo?: string;

  /** Message IDs of the thread. */
  @maxItems(100)
  references?: string[];
}

/** A template and its variables for a send request. */
@friendlyName("TemplateReference")
model TemplateReference {
  /** Key of the template. */
  @pattern("^[a-z][a-z0-9_.-]{0,63}$")
  key: string;

  /** Values of the variables. The key is a variable name. A maximum of 50 variables. Each value has a maximum of 10000 characters. */
  variables: Record<string>;
}

/** Message content that the caller gives. */
@friendlyName("MessageContent")
model MessageContent {
  /** Subject. */
  @minLength(1)
  @maxLength(998)
  subject: string;

  /** Text body. A maximum of 1 MiB. */
  @minLength(1)
  @maxLength(1048576)
  text: string;

  /** HTML body. A maximum of 1 MiB. */
  @minLength(1)
  @maxLength(1048576)
  html?: string;
}

/** Send request that uses a template. */
@friendlyName("TemplateSendRequest")
model TemplateSendRequest {
  ...SendMessageFields;

  /** The template. */
  template: TemplateReference;
}

/** Send request with content. */
@friendlyName("ContentSendRequest")
model ContentSendRequest {
  ...SendMessageFields;

  /** The content. */
  content: MessageContent;
}

/** Request to send a message. The body has `template` or `content`. A body with both is not valid. */
@oneOf
@friendlyName("SendMessageRequest")
union SendMessageRequest {
  template: TemplateSendRequest,
  content: ContentSendRequest,
}
