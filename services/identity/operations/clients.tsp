using Http;
using OpenAPI;
using Constellation.Common;

namespace Constellation.Identity;

/** Operations on clients. */
@route("/v1/clients")
interface Clients {
  /**
   * Create a client. The token needs `identity:client:write` and `identity:admin`.
   * Error codes of `UnprocessableContent`: `invalid_redirect_uri` and `app_reserved`.
   */
  @extension("x-required-scopes", #["identity:client:write", "identity:admin"])
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
   * Change a client. The token needs `identity:client:write` and `identity:admin`.
   * The `app` of a client cannot change. Error code of `Conflict`: `client_managed_by_config`.
   * Error codes of `UnprocessableContent`: `invalid_redirect_uri`, `client_type_immutable`, and `app_reserved`.
   */
  @extension("x-required-scopes", #["identity:client:write", "identity:admin"])
  @route("/{clientId}")
  @patch
  update(@path clientId: string, @body update: ClientUpdate):
    | Client
    | NotFound
    | Conflict
    | UnprocessableContent
    | CommonErrors;
}
