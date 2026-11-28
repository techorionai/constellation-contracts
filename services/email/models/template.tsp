using Constellation.Common;

namespace Constellation.Email;

/** One variable of a template. */
@friendlyName("TemplateVariable")
model TemplateVariable {
  /** Name of the variable. */
  @pattern("^[A-Za-z][A-Za-z0-9_]{0,63}$")
  name: string;

  /** If true, a send must give a value. */
  required: boolean;
}

/** An email template. The subject, the text, and the HTML use Go template syntax. */
@friendlyName("Template")
model Template {
  /** ID of the template. */
  id: ResourceId;

  /** Unique key of the template. */
  @pattern("^[a-z][a-z0-9_.-]{0,63}$")
  key: string;

  /** Description. */
  @maxLength(500)
  description?: string;

  /** Subject template. It has no control character. The service checks the rendered subject too. */
  subject: HeaderText;

  /** Text template. */
  @minLength(1)
  @maxLength(1048576)
  text: string;

  /** HTML template. */
  @minLength(1)
  @maxLength(1048576)
  html?: string;

  /** Variables of the template. */
  @maxItems(50)
  variables: TemplateVariable[];

  /** Time when the template was created. */
  createdAt: utcDateTime;

  /** Time when the template was changed. */
  updatedAt: utcDateTime;
}

/** Request to create a template. */
@friendlyName("TemplateCreate")
model TemplateCreate {
  /** Unique key of the template. */
  @pattern("^[a-z][a-z0-9_.-]{0,63}$")
  key: string;

  /** Description. */
  @maxLength(500)
  description?: string;

  /** Subject template. It has no control character. The service checks the rendered subject too. */
  subject: HeaderText;

  /** Text template. */
  @minLength(1)
  @maxLength(1048576)
  text: string;

  /** HTML template. */
  @minLength(1)
  @maxLength(1048576)
  html?: string;

  /** Variables of the template. */
  @maxItems(50)
  variables?: TemplateVariable[];
}

/** Request to change a template. A field that is not present does not change. An empty string for `html` removes the HTML template. The request needs at least one field. The key does not change. */
@friendlyName("TemplateUpdate")
model TemplateUpdate {
  /** Description. */
  @maxLength(500)
  description?: string;

  /** Subject template. It has no control character. The service checks the rendered subject too. */
  subject?: HeaderText;

  /** Text template. */
  @minLength(1)
  @maxLength(1048576)
  text?: string;

  /** HTML template. An empty string removes the HTML template. */
  @maxLength(1048576)
  html?: string;

  /** Variables of the template. */
  @maxItems(50)
  variables?: TemplateVariable[];
}

/** One page of templates. */
model TemplatePage is CursorPage<Template>;
