import "@typespec/http";

using Http;
using Constellation.Common;

namespace Fixture.Alpha;

/** Operations on alpha widgets. */
@route("/alpha-widgets")
interface Widgets {
  /** Get one widget. */
  @get
  get(@path id: string): Widget | NotFound | CommonErrors;
}
