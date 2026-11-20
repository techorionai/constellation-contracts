using Constellation.Common;

namespace Constellation.Identity;

/** A permission manifest that the identity service stores. */
@friendlyName("PublishedManifest")
model PublishedManifest {
  /** The manifest. */
  manifest: PermissionManifest;

  /** Version of the stored manifest. It increases with each change. */
  version: int32;

  /** Time of the last publish. */
  publishedAt: utcDateTime;
}

/** One page of manifests. */
model PublishedManifestPage is CursorPage<PublishedManifest>;
