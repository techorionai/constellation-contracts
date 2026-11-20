using Http;
using OpenAPI;
using Constellation.Common;

namespace Constellation.Identity;

/** Operations on permission manifests. */
@route("/v1/permission-manifests")
interface PermissionManifests {
  /**
   * Publish the manifest of an app. The `{app}` in the path must be the `app` of the manifest.
   * The caller must be a service client of that app. The app `identity` is not allowed.
   * Error codes of `UnprocessableContent`: `manifest_app_mismatch`, `permission_app_mismatch`,
   * `role_permission_unknown`, and `duplicate_key`.
   */
  @extension("x-required-scopes", #["identity:manifest:publish"])
  @route("/{app}")
  @put
  publish(@path app: AppKey, @body manifest: PermissionManifest):
    | PublishedManifest
    | UnprocessableContent
    | CommonErrors;

  /** List the stored manifests. */
  @extension("x-required-scopes", #["identity:role:read"])
  @list
  @get
  list(...CursorPageParams): PublishedManifestPage | CommonErrors;

  /** Get the stored manifest of one app. */
  @extension("x-required-scopes", #["identity:role:read"])
  @route("/{app}")
  @get
  get(@path app: AppKey): PublishedManifest | NotFound | CommonErrors;
}
