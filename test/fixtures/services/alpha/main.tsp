import "@typespec/http";
import "../../../../lib";
import "./models";
import "./operations";

using Http;

/** The alpha fixture service. */
@service(#{ title: "Fixture Alpha" })
@route("/v1")
namespace Fixture.Alpha;
