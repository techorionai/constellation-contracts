using Http;
using OpenAPI;
using Constellation.Common;

namespace Constellation.Identity;

/** Operations on roles. Roles come from manifests. */
@route("/v1/roles")
interface Roles {
  /** List the roles. Use `app` to list the roles of one app. */
  @extension("x-required-scopes", #["identity:role:read"])
  @list
  @get
  list(@query app?: AppKey, ...CursorPageParams): RolePage | CommonErrors;

  /** Get one role. */
  @extension("x-required-scopes", #["identity:role:read"])
  @route("/{role}")
  @get
  get(@path role: RoleRef): Role | NotFound | CommonErrors;
}
