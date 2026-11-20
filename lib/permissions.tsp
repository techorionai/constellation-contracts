namespace Constellation.Common;

/** Key of an application, for example `helpdesk` or `customer_portal`. */
@pattern("^[a-z][a-z0-9_]*$")
@maxLength(32)
@friendlyName("AppKey")
scalar AppKey extends string;

/**
 * Key of a permission in the form `<app>:<resource>:<action>`, for example `helpdesk:ticket:write`.
 * The only exception is `identity:admin`, the permission of full administration of the identity service.
 */
@pattern("^(?:[a-z][a-z0-9_]*:[a-z][a-z0-9_]*:[a-z][a-z0-9_]*|identity:admin)$")
@maxLength(128)
@friendlyName("PermissionKey")
scalar PermissionKey extends string;

/** Key of a role, for example `agent_admin`. */
@pattern("^[a-z][a-z0-9_]*$")
@maxLength(64)
@friendlyName("RoleKey")
scalar RoleKey extends string;

/** One permission that a service defines. */
@friendlyName("PermissionDefinition")
model PermissionDefinition {
  /** Key of the permission. */
  key: PermissionKey;

  /** Description of what the permission allows. */
  description: string;
}

/** A default role of a service, with its permissions. */
@friendlyName("RoleDefinition")
model RoleDefinition {
  /** Key of the role. */
  key: RoleKey;

  /** Display name of the role. */
  name: string;

  /** Description of the role. */
  description: string;

  /** Permissions that the role grants. */
  permissions: PermissionKey[];
}

/** The permissions and default roles that a service publishes. */
@friendlyName("PermissionManifest")
model PermissionManifest {
  /** Key of the application that owns the permissions. */
  app: AppKey;

  /** Permissions that the application defines. */
  permissions: PermissionDefinition[];

  /** Default roles of the application. */
  defaultRoles: RoleDefinition[];
}
