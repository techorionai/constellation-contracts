using Http;
using OpenAPI;
using Constellation.Common;

namespace Constellation.Identity;

/** Operations on the user of the access token. */
@route("/v1/me")
interface Me {
  /** Get the user of the access token. It needs no permission. */
  @extension("x-required-scopes", #[])
  @get
  get(): User | CommonErrors;
}
