import { beforeAll, describe, expect, it } from "vitest";
import { loadPagingFixture, resolveRef, type Doc } from "./helpers.js";

describe("cursor pagination", () => {
  let doc: Doc;
  let diagnostics: string[];

  beforeAll(async () => {
    ({ doc, diagnostics } = await loadPagingFixture());
  });

  // U8
  it("U8: the list operation has the pageToken and pageSize parameters", () => {
    expect(diagnostics).toEqual([]);
    const parameters = doc.paths["/widgets"].get.parameters.map((p: Doc) =>
      resolveRef(doc, p),
    );
    const byName = Object.fromEntries(parameters.map((p: Doc) => [p.name, p]));
    expect(Object.keys(byName).sort()).toEqual(["pageSize", "pageToken"]);
    expect(byName.pageToken.in).toBe("query");
    expect(byName.pageToken.schema.type).toBe("string");
    expect(byName.pageSize.in).toBe("query");
    expect(byName.pageSize.schema).toMatchObject({
      type: "integer",
      format: "int32",
      minimum: 1,
      maximum: 200,
      default: 50,
    });
  });

  // U9
  it("U9: the page has required items and an optional nextPageToken", () => {
    const schema = resolveRef(
      doc,
      doc.paths["/widgets"].get.responses["200"].content["application/json"]
        .schema,
    );
    expect(schema.required).toContain("items");
    expect(schema.required).not.toContain("nextPageToken");
    expect(schema.properties.items.type).toBe("array");
    expect(schema.properties.items.items).toEqual({
      $ref: "#/components/schemas/Widget",
    });
    expect(schema.properties.nextPageToken.type).toBe("string");
  });
});
