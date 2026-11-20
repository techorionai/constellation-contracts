using Http;
using OpenAPI;
using Constellation.Common;

namespace Constellation.Identity;

/** Operations on users. */
@route("/v1/users")
interface Users {
  /** Create a user and an invite. Error code of `Conflict`: `email_taken`. */
  @extension("x-required-scopes", #["identity:user:write"])
  @post
  create(@body user: UserCreate):
    | {
        @statusCode _: 201;
        @body body: UserCreated;
      }
    | Conflict
    | UnprocessableContent
    | CommonErrors;

  /** List the users. */
  @extension("x-required-scopes", #["identity:user:read"])
  @list
  @get
  list(...CursorPageParams): UserPage | CommonErrors;

  /** Get one user. */
  @extension("x-required-scopes", #["identity:user:read"])
  @route("/{userId}")
  @get
  get(@path userId: string): User | NotFound | CommonErrors;

  /** Change the name or the disabled state of a user. Error code of `Conflict`: `last_admin`. */
  @extension("x-required-scopes", #["identity:user:write"])
  @route("/{userId}")
  @patch
  update(@path userId: string, @body update: UserUpdate):
    | User
    | NotFound
    | Conflict
    | CommonErrors;
}
