import "@typespec/http";
import "../../../lib";

using Http;
using Constellation.Common;

/** Fixture service for the pagination tests. */
@service(#{ title: "Fixture Paging" })
namespace Fixture.Paging;

/** A widget. */
model Widget {
  /** ID of the widget. */
  id: string;
}

/** One page of widgets. */
model WidgetPage is CursorPage<Widget>;

/** Operations on widgets. */
@route("/widgets")
interface Widgets {
  /** Lists the widgets. */
  @list
  @get
  list(...CursorPageParams): WidgetPage | CommonErrors;
}
