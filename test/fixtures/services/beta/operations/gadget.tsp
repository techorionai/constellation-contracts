import "@typespec/http";

using Http;
using Constellation.Common;

namespace Fixture.Beta;

/** Operations on beta gadgets. */
@route("/beta-gadgets")
interface Gadgets {
  /** Get one gadget. */
  @get
  get(@path id: string): Gadget | NotFound | CommonErrors;
}
