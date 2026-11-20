using Http;
using OpenAPI;
using Constellation.Common;

namespace Constellation.Identity;

/** Operations on clients. */
@route("/v1/clients")
interface Clients {
  /**
   * Create a client. Error codes of `UnprocessableContent`: `invalid_redirect_uri` and `app_reserved`.
   */
  @extension("x-required-scopes", #["identity:client:write"])
  @post
  create(@body client: ClientCreate):
    | {
        @statusCode _: 201;
        @body body: Client;
      }
    | UnprocessableContent
    | CommonErrors;

  /** List the clients. */
  @extension("x-required-scopes", #["identity:client:read"])
  @list
  @get
  list(...CursorPageParams): ClientPage | CommonErrors;

  /** Get one client. */
  @extension("x-required-scopes", #["identity:client:read"])
  @route("/{clientId}")
  @get
  get(@path clientId: string): Client | NotFound | CommonErrors;

  /**
   * Change a client. Error code of `Conflict`: `client_managed_by_config`.
   * Error codes of `UnprocessableContent`: `invalid_redirect_uri`, `client_type_immutable`, and `app_reserved`.
   */
  @extension("x-required-scopes", #["identity:client:write"])
  @route("/{clientId}")
  @patch
  update(@path clientId: string, @body update: ClientUpdate):
    | Client
    | NotFound
    | Conflict
    | UnprocessableContent
    | CommonErrors;
}
