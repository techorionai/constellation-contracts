import "@typespec/http";
import "../../../lib";

using Http;
using Constellation.Common;

/** Fixture service for the error model tests. */
@service(#{ title: "Fixture Errors" })
namespace Fixture.Errors;

/** A widget. */
model Widget {
  /** ID of the widget. */
  id: string;
}

/** Operations on widgets. */
@route("/widgets")
interface Widgets {
  /** Returns a widget or 404. */
  @route("/not-found")
  @get
  notFound(): Widget | NotFound;

  /** Returns a widget or the common errors. */
  @route("/common")
  @get
  common(): Widget | CommonErrors;

  /** Returns 403. */
  @route("/forbidden")
  @get
  forbidden(): Forbidden;

  /** Returns 429. */
  @route("/too-many")
  @get
  tooMany(): TooManyRequests;
}
