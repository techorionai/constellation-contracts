using Http;
using OpenAPI;
using Constellation.Common;

namespace Constellation.Identity;

/** Operations on sign-in sessions. */
@route("/v1")
interface Sessions {
  /** List the sessions of a user. */
  @extension("x-required-scopes", #["identity:session:read"])
  @route("/users/{userId}/sessions")
  @list
  @get
  list(@path userId: string, ...CursorPageParams):
    | SessionPage
    | NotFound
    | CommonErrors;

  /** Revoke one session. */
  @extension("x-required-scopes", #["identity:session:revoke"])
  @route("/sessions/{sessionId}")
  @delete
  revoke(@path sessionId: string):
    | {
        @statusCode _: 204;
      }
    | NotFound
    | CommonErrors;

  /** Revoke all sessions of a user. */
  @extension("x-required-scopes", #["identity:session:revoke"])
  @route("/users/{userId}/sessions")
  @delete
  revokeAll(@path userId: string):
    | {
        @statusCode _: 204;
      }
    | NotFound
    | CommonErrors;
}
