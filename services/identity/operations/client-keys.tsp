using Http;
using OpenAPI;
using Constellation.Common;

namespace Constellation.Identity;

/** Operations on the keys of a service client. */
@route("/v1/clients/{clientId}/keys")
interface ClientKeys {
  /**
   * Add a public key to a service client. The token needs `identity:client:write` and `identity:admin`.
   * Error code of `Conflict`: `client_managed_by_config`.
   * Error codes of `UnprocessableContent`: `client_type_unsupported` and `invalid_jwk`.
   */
  @extension("x-required-scopes", #["identity:client:write", "identity:admin"])
  @post
  add(@path clientId: string, @body jwk: JsonWebKey):
    | {
        @statusCode _: 201;
        @body body: ClientKey;
      }
    | NotFound
    | Conflict
    | UnprocessableContent
    | CommonErrors;

  /**
   * Remove a key from a service client. The token needs `identity:client:write` and `identity:admin`.
   * Error code of `Conflict`: `client_managed_by_config`.
   */
  @extension("x-required-scopes", #["identity:client:write", "identity:admin"])
  @route("/{kid}")
  @delete
  remove(@path clientId: string, @path kid: string):
    | {
        @statusCode _: 204;
      }
    | NotFound
    | Conflict
    | CommonErrors;
}
