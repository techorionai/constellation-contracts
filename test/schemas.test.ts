import { readFile } from "node:fs/promises";
import { join } from "node:path";
import { beforeAll, describe, expect, it } from "vitest";
import {
  loadCommon,
  loadPagingFixture,
  resolveRef,
  root,
  schemaValidator,
  type Doc,
} from "./helpers.js";

async function examples(name: string): Promise<{
  valid: unknown[];
  invalid: unknown[];
}> {
  return JSON.parse(
    await readFile(join(root, "test", "examples", name), "utf8"),
  );
}

describe("shared schemas", () => {
  let check: (name: string) => (value: unknown) => boolean;

  beforeAll(async () => {
    check = schemaValidator(await loadCommon(), "common.openapi");
  });

  const cases: [string, string, string][] = [
    ["U13", "LinkTemplateSet", "link-template-set.json"],
    ["U14", "PermissionManifest", "permission-manifest.json"],
    ["U15", "EventTypeRegistration", "event-type-registration.json"],
  ];

  for (const [id, schema, file] of cases) {
    // U13, U14, U15
    it(`${id}: example documents for ${schema}`, async () => {
      const validate = check(schema);
      const { valid, invalid } = await examples(file);
      expect(valid.length).toBeGreaterThan(0);
      expect(invalid.length).toBeGreaterThan(0);
      for (const value of valid) expect(validate(value)).toBe(true);
      invalid.forEach((value, index) => {
        expect(validate(value), `invalid example ${index}`).toBe(false);
      });
    });
  }
});

describe("limit values", () => {
  let check: (name: string) => (value: unknown) => boolean;
  let paging: Doc;

  beforeAll(async () => {
    check = schemaValidator(await loadCommon(), "common.openapi");
    ({ doc: paging } = await loadPagingFixture());
  });

  function parameterSchema(name: string): Doc {
    const parameters = paging.paths["/widgets"].get.parameters.map((p: Doc) =>
      resolveRef(paging, p),
    );
    return parameters.find((p: Doc) => p.name === name).schema;
  }

  // U20
  it("U20: pageSize limits", async () => {
    const schema = parameterSchema("pageSize");
    expect(schema.minimum).toBe(1);
    expect(schema.maximum).toBe(200);
    const doc = {
      components: { schemas: { PageSize: schema } },
    };
    const validate = schemaValidator(doc, "page-size")("PageSize");
    expect(validate(1)).toBe(true);
    expect(validate(200)).toBe(true);
    expect(validate(0)).toBe(false);
    expect(validate(201)).toBe(false);
  });

  // U20
  it("U20: pageToken limit", () => {
    const schema = parameterSchema("pageToken");
    const doc = { components: { schemas: { PageToken: schema } } };
    const validate = schemaValidator(doc, "page-token")("PageToken");
    expect(validate("a".repeat(1024))).toBe(true);
    expect(validate("a".repeat(1025))).toBe(false);
  });

  // U20
  it("U20: string limits of the key scalars", () => {
    const cases: [string, (n: number) => string, number][] = [
      ["AppKey", (n) => "a".repeat(n), 32],
      ["PermissionKey", (n) => `a:b:${"c".repeat(n - 4)}`, 128],
      ["EventType", (n) => `a.b.${"c".repeat(n - 4)}`, 128],
      ["RoleKey", (n) => "a".repeat(n), 64],
      ["ResourceType", (n) => "a".repeat(n), 64],
    ];
    for (const [name, make, max] of cases) {
      const validate = check(name);
      expect(validate(make(max)), `${name} at ${max}`).toBe(true);
      expect(validate(make(max + 1)), `${name} at ${max + 1}`).toBe(false);
    }
  });

  // U20
  it("U20: Problem.code and CloudEvent id and source limits", () => {
    const problem = (code: string) => ({
      type: "about:blank",
      title: "Title",
      status: 404,
      code,
    });
    const validateProblem = check("Problem");
    expect(validateProblem(problem("a".repeat(64)))).toBe(true);
    expect(validateProblem(problem("a".repeat(65)))).toBe(false);

    const event = (id: string, source: string) => ({
      specversion: "1.0",
      id,
      source,
      type: "helpdesk.ticket.created",
      time: "2026-11-15T10:00:00Z",
      datacontenttype: "application/json",
      data: {},
      actor: "usr_1",
      actortype: "user",
    });
    const validateEvent = check("CloudEventEnvelope");
    expect(validateEvent(event("a".repeat(128), "s".repeat(256)))).toBe(true);
    expect(validateEvent(event("a".repeat(129), "s"))).toBe(false);
    expect(validateEvent(event("a", "s".repeat(257)))).toBe(false);
  });
});
