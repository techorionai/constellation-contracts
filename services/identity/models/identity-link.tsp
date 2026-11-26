using Constellation.Common;

namespace Constellation.Identity;

/** Upstream identity provider for login and link. The union is open, so a later release can add a provider. */
@friendlyName("UpstreamProvider")
union UpstreamProvider {
  "google",
  "microsoft",
  string,
}

/**
 * A link between a user and an account at an upstream identity provider.
 * The model has no upstream subject. The subject is an internal key of the service.
 * A user has a maximum of one link for each provider.
 */
@friendlyName("IdentityLink")
model IdentityLink {
  /** The upstream provider. It identifies the link of the user. */
  provider: UpstreamProvider;

  /** The email from the upstream account at the last login. Only for show to people. Absent when the service has no email. */
  email?: string;

  /** The time of the link. */
  createdAt: utcDateTime;

  /** The time of the last login with the link. Absent when the link was never used for a login. */
  lastUsedAt?: utcDateTime;
}

/** One page of identity links. */
model IdentityLinkPage is CursorPage<IdentityLink>;
