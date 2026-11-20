import { join } from "node:path";
import { beforeAll, describe, expect, it } from "vitest";
import { compileEntry, root, type Doc } from "./helpers.js";

describe("error model", () => {
  let doc: Doc;
  let diagnostics: string[];

  beforeAll(async () => {
    const result = await compileEntry(
      join(root, "test", "fixtures", "errors", "main.tsp"),
    );
    diagnostics = result.diagnostics;
    doc = result.files["Fixture.Errors.openapi.yaml"];
  });

  it("compiles with no diagnostics", () => {
    expect(diagnostics).toEqual([]);
  });

  // U4
  it("U4: a 404 response is problem+json and NotFound refers to Problem", () => {
    const response = doc.paths["/widgets/not-found"].get.responses["404"];
    expect(Object.keys(response.content)).toEqual(["application/problem+json"]);
    expect(response.content["application/problem+json"].schema).toEqual({
      $ref: "#/components/schemas/NotFound",
    });
    expect(doc.components.schemas.NotFound.allOf).toEqual([
      { $ref: "#/components/schemas/Problem" },
    ]);
    expect(doc.components.schemas.Problem).toBeDefined();
  });

  // U5
  it("U5: CommonErrors gives 400, 401, 403, and 500", () => {
    const codes = Object.keys(doc.paths["/widgets/common"].get.responses);
    expect(codes.sort()).toEqual(["200", "400", "401", "403", "500"]);
  });

  // U6
  it("U6: Forbidden has missingScopes with the PermissionKey pattern", () => {
    const response = doc.paths["/widgets/forbidden"].get.responses["403"];
    expect(response.content["application/problem+json"].schema).toEqual({
      $ref: "#/components/schemas/Forbidden",
    });
    const property = doc.components.schemas.Forbidden.properties.missingScopes;
    expect(property.type).toBe("array");
    expect(property.items).toEqual({
      $ref: "#/components/schemas/PermissionKey",
    });
    expect(doc.components.schemas.PermissionKey.type).toBe("string");
    expect(doc.components.schemas.PermissionKey.pattern).toBe(
      "^(?:[a-z][a-z0-9_]*:[a-z][a-z0-9_]*:[a-z][a-z0-9_]*|identity:admin)$",
    );
  });

  // U7
  it("U7: a 429 response has the Retry-After header", () => {
    const response = doc.paths["/widgets/too-many"].get.responses["429"];
    expect(Object.keys(response.headers)).toContain("Retry-After");
  });

  // R16
  it("R16: the Retry-After header has the minimum 0", () => {
    const response = doc.paths["/widgets/too-many"].get.responses["429"];
    expect(response.headers["Retry-After"].schema.minimum).toBe(0);
  });
});
