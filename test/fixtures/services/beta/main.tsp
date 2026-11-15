import "@typespec/http";
import "../../../../lib";
import "./models";
import "./operations";

using Http;

/** The beta fixture service. */
@service(#{ title: "Fixture Beta" })
@route("/v1")
namespace Fixture.Beta;
