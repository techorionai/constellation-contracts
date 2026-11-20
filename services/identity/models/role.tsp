using Constellation.Common;

namespace Constellation.Identity;

/** A role from a manifest. */
@friendlyName("Role")
model Role {
  /** Reference of the role in the form `<app>:<role>`. */
  ref: RoleRef;

  /** Application that owns the role. */
  app: AppKey;

  /** Key of the role in the application. */
  key: RoleKey;

  /** Display name of the role. */
  name: string;

  /** Description of the role. */
  description: string;

  /** Permissions that the role grants. */
  permissions: PermissionKey[];
}

/** One page of roles. */
model RolePage is CursorPage<Role>;

/** Where a role assignment comes from. */
@friendlyName("AssignmentSource")
union AssignmentSource {
  "config",
  "api",
}

/** A role that a user or a client has. */
@friendlyName("RoleAssignment")
model RoleAssignment {
  /** The role. */
  role: RoleRef;

  /** `config` if the assignment is from a configuration file. `api` if it is from the API. */
  source: AssignmentSource;

  /** True if the role is not in the current manifest of its app. */
  pending: boolean;
}

/** One page of role assignments. */
model RoleAssignmentPage is CursorPage<RoleAssignment>;
