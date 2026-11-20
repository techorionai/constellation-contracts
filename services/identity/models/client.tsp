using Constellation.Common;

namespace Constellation.Identity;

/** Type of a client. */
@friendlyName("ClientType")
union ClientType {
  "service",
  "public",
}

/** Where a client comes from. */
@friendlyName("ClientSource")
union ClientSource {
  "config",
  "api",
}

/** A public key of a service client. */
@friendlyName("ClientKey")
model ClientKey {
  /** ID of the key. */
  kid: string;

  /** The public key. */
  jwk: JsonWebKey;

  /** Time when the key was added. */
  createdAt: utcDateTime;
}

/**
 * An OAuth client.
 * `app` is the audience of its tokens. A service client has the `app` of its service.
 * A public client has the `app` of the application that it signs users in to.
 */
@friendlyName("Client")
model Client {
  /** ID of the client. */
  id: string;

  /** Type of the client. */
  type: ClientType;

  /** Application of the client. */
  app: AppKey;

  /** Where the client comes from. */
  source: ClientSource;

  /** Display name of the client. */
  name: string;

  /** Allowed redirect URIs. Public clients only. */
  redirectUris?: string[];

  /** Allowed post logout redirect URIs. Public clients only. */
  postLogoutRedirectUris?: string[];

  /** True if the client is disabled. */
  disabled: boolean;

  /** Public keys. Service clients only. */
  keys?: ClientKey[];
}

/** Request to create a client. */
@friendlyName("ClientCreate")
model ClientCreate {
  /** Type of the client. */
  type: ClientType;

  /** Application of the client. */
  app: AppKey;

  /** Display name of the client. */
  name: string;

  /** Allowed redirect URIs. Public clients only. */
  redirectUris?: string[];

  /** Allowed post logout redirect URIs. Public clients only. */
  postLogoutRedirectUris?: string[];

  /** Public key. Service clients only. */
  jwk?: JsonWebKey;
}

/** Request to change a client. A field that is not present does not change. It has no `app`, because the `app` of a client cannot change. */
@friendlyName("ClientUpdate")
model ClientUpdate {
  /** The type cannot change. A different value gives `client_type_immutable`. */
  type?: ClientType;

  /** Display name of the client. */
  name?: string;

  /** Allowed redirect URIs. Public clients only. */
  redirectUris?: string[];

  /** Allowed post logout redirect URIs. Public clients only. */
  postLogoutRedirectUris?: string[];

  /** True to disable the client. */
  disabled?: boolean;
}

/** One page of clients. */
model ClientPage is CursorPage<Client>;
