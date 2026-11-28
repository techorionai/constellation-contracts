using Http;
using OpenAPI;
using Constellation.Common;

namespace Constellation.Email;

/** Operations on templates. */
@route("/v1/templates")
interface Templates {
  /**
   * List the templates. The order is `createdAt` descending, then `id` descending.
   * The page token is opaque. A token of another operation gives 400 `invalid_page_token`.
   * Each response, also an error response, has `Cache-Control: no-store` and `Pragma: no-cache`.
   * Error code of `ServiceUnavailable`: `unavailable`. It has `Retry-After` when the database is not available.
   */
  @extension("x-required-scopes", #["email:template:read"])
  @list
  @get
  list(...CursorPageParams): EmailOk<TemplatePage> | EmailCommonErrors;

  /**
   * Get one template. Error code of `NotFound`: `template_not_found`.
   * Each response, also an error response, has `Cache-Control: no-store` and `Pragma: no-cache`.
   * Error code of `ServiceUnavailable`: `unavailable`. It has `Retry-After` when the database is not available.
   */
  @extension("x-required-scopes", #["email:template:read"])
  @route("/{id}")
  @get
  get(
    /** ID of the template. */
    @path id: ResourceId,
  ): EmailOk<Template> | EmailNotFound | EmailCommonErrors;

  /**
   * Create a template. The subject, the text, and the HTML use Go template syntax.
   * The operation writes an audit entry with the action `email:template:create`, the key of the template, and the result.
   * Error code of `Conflict`: `template_key_taken`. Error code of `UnprocessableContent`: `template_syntax_invalid` for a bad template, or `validation_failed`.
   * Each response, also an error response, has `Cache-Control: no-store` and `Pragma: no-cache`.
   * Error code of `ServiceUnavailable`: `unavailable`. It has `Retry-After` when the database is not available.
   */
  @extension("x-required-scopes", #["email:template:write"])
  @post
  create(@body template: TemplateCreate):
    | EmailCreated<Template>
    | EmailConflict
    | EmailUnprocessableContent
    | EmailTooManyRequests
    | EmailCommonErrors;

  /**
   * Change a template. A field that is not in the body does not change. The key does not change.
   * A body with no field gives 400 `empty_update`. An empty string for `html` removes the HTML template.
   * The operation writes an audit entry with the action `email:template:update`, the ID of the template, and the result.
   * Error code of `NotFound`: `template_not_found`. Error code of `UnprocessableContent`: `template_syntax_invalid` or `validation_failed`.
   * Each response, also an error response, has `Cache-Control: no-store` and `Pragma: no-cache`.
   * Error code of `ServiceUnavailable`: `unavailable`. It has `Retry-After` when the database is not available.
   */
  @extension("x-required-scopes", #["email:template:write"])
  @route("/{id}")
  @patch
  update(
    /** ID of the template. */
    @path id: ResourceId,

    @body update: TemplateUpdate,
  ):
    | EmailOk<Template>
    | EmailNotFound
    | EmailUnprocessableContent
    | EmailTooManyRequests
    | EmailCommonErrors;

  /**
   * Delete a template. Error code of `NotFound`: `template_not_found`.
   * The operation writes an audit entry with the action `email:template:delete`, the ID and the key of the template, and the result.
   * Each response, also an error response, has `Cache-Control: no-store` and `Pragma: no-cache`.
   * Error code of `ServiceUnavailable`: `unavailable`. It has `Retry-After` when the database is not available.
   */
  @extension("x-required-scopes", #["email:template:write"])
  @route("/{id}")
  @delete
  delete(
    /** ID of the template. */
    @path id: ResourceId,
  ): EmailNoContent | EmailNotFound | EmailTooManyRequests | EmailCommonErrors;
}
