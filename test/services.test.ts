import { join } from "node:path";
import { describe, expect, it } from "vitest";
import { compileEntry, root } from "./helpers.js";

describe("one OpenAPI file for each service", () => {
  // U17
  it("U17: two services give one file for each service", async () => {
    const result = await compileEntry(
      join(root, "test", "fixtures", "services", "main.tsp"),
    );
    expect(result.diagnostics).toEqual([]);
    expect(Object.keys(result.files).sort()).toEqual([
      "Constellation.Common.openapi.yaml",
      "Fixture.Alpha.openapi.yaml",
      "Fixture.Beta.openapi.yaml",
    ]);

    const alpha = result.files["Fixture.Alpha.openapi.yaml"];
    const beta = result.files["Fixture.Beta.openapi.yaml"];
    expect(Object.keys(alpha.paths)).toEqual(["/v1/alpha-widgets/{id}"]);
    expect(Object.keys(beta.paths)).toEqual(["/v1/beta-gadgets/{id}"]);
    for (const doc of [alpha, beta]) {
      expect(doc.components.schemas.NotFound).toBeDefined();
      expect(doc.components.schemas.Problem).toBeDefined();
    }
  });
});
