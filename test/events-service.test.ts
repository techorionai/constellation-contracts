import SwaggerParser from "@apidevtools/swagger-parser";
import { readFile } from "node:fs/promises";
import { join } from "node:path";
import { parse } from "yaml";
import { beforeAll, describe, expect, it } from "vitest";
import {
  compileEntry,
  loadCommon,
  resolveRef,
  root,
  schemaValidator,
  type Doc,
} from "./helpers.js";

const eventsFile = join(
  root,
  "generated",
  "openapi",
  "Constellation.Events.openapi.yaml",
);

async function examples(name: string): Promise<{
  valid: unknown[];
  invalid: unknown[];
}> {
  return JSON.parse(
    await readFile(join(root, "test", "examples", name), "utf8"),
  );
}

/** Operation ID, method, path, success schema, and scope of each operation. */
const expected: [string, string, string, string, string][] = [
  ["EventTypeRegistrations_register", "put", "/v1/event-type-registrations/{app}", "EventTypeRegistrationResult", "events:event_type:register"],
  ["EventTypeRegistrations_list", "get", "/v1/event-type-registrations", "RegisteredEventTypesPage", "events:catalog:read"],
  ["EventTypeRegistrations_get", "get", "/v1/event-type-registrations/{app}", "RegisteredEventTypes", "events:catalog:read"],
  ["EventTypes_list", "get", "/v1/event-types", "CatalogEventTypePage", "events:catalog:read"],
  ["EventTypes_get", "get", "/v1/event-types/{type}", "CatalogEventType", "events:catalog:read"],
];

interface Operation {
  id: string;
  method: string;
  path: string;
  op: Doc;
}

function operations(doc: Doc): Operation[] {
  const found: Operation[] = [];
  for (const [path, item] of Object.entries<Doc>(doc.paths)) {
    for (const [method, op] of Object.entries<Doc>(item)) {
      found.push({ id: op.operationId, method, path, op });
    }
  }
  return found;
}

describe("events service contract", () => {
  let doc: Doc;
  let common: Doc;
  let ops: Operation[];
  let byId: Record<string, Operation>;
  let manifest: Doc;
  let check: (name: string) => (value: unknown) => boolean;
  let checkCommon: (name: string) => (value: unknown) => boolean;

  beforeAll(async () => {
    doc = parse(await readFile(eventsFile, "utf8"));
    common = await loadCommon();
    ops = operations(doc);
    byId = Object.fromEntries(ops.map((o) => [o.id, o]));
    manifest = JSON.parse(
      await readFile(join(root, "services", "events", "manifest.json"), "utf8"),
    );
    check = schemaValidator(doc, "events.openapi");
    checkCommon = schemaValidator(common, "common.openapi");
  });

  // U115
  it("U115: the root compiles with warnings as errors", async () => {
    const result = await compileEntry(join(root, "main.tsp"), false);
    expect(result.diagnostics).toEqual([]);
  });

  // U116
  it("U116: the OpenAPI file is valid", async () => {
    await SwaggerParser.validate(eventsFile);
  });

  // U117
  it("U117: operations, methods, paths, success schemas, and scopes", () => {
    expect(ops.map((o) => o.id).sort()).toEqual(
      expected.map((e) => e[0]).sort(),
    );
    for (const [id, method, path, schema, scope] of expected) {
      const found = byId[id];
      expect(found.method, id).toBe(method);
      expect(found.path, id).toBe(path);
      expect(found.op["x-required-scopes"], id).toEqual([scope]);
      const ok = found.op.responses["200"].content["application/json"].schema;
      expect(ok, id).toEqual({ $ref: `#/components/schemas/${schema}` });
    }
  });

  // U118
  it("U118: security, problem errors, 503, and scopes in the manifest", () => {
    const keys = new Set(manifest.permissions.map((p: Doc) => p.key));
    expect(doc.components.securitySchemes.BearerAuth).toMatchObject({
      type: "http",
      scheme: "Bearer",
    });
    for (const o of ops) {
      expect(o.op.security ?? doc.security, o.id).toEqual([{ BearerAuth: [] }]);
      expect(o.op.responses["503"], o.id).toBeDefined();
      for (const [status, response] of Object.entries<Doc>(o.op.responses)) {
        if (Number(status) < 400) continue;
        expect(Object.keys(response.content), `${o.id} ${status}`).toEqual([
          "application/problem+json",
        ]);
      }
      for (const scope of o.op["x-required-scopes"]) {
        expect(keys.has(scope), scope).toBe(true);
      }
    }
  });

  // U119
  it("U119: list operations have page parameters and a page result", () => {
    for (const id of ["EventTypeRegistrations_list", "EventTypes_list"]) {
      const names = (byId[id].op.parameters as Doc[]).map(
        (p) => resolveRef(doc, p).name,
      );
      expect(names, id).toContain("pageToken");
      expect(names, id).toContain("pageSize");
      const page = resolveRef(
        doc,
        byId[id].op.responses["200"].content["application/json"].schema,
      );
      expect(page.required, id).toContain("items");
      expect(page.properties.nextPageToken, id).toBeDefined();
    }
  });

  // U120
  it("U120: query parameters of EventTypes_list", () => {
    const params = (byId["EventTypes_list"].op.parameters as Doc[]).map((p) =>
      resolveRef(doc, p),
    );
    const app = params.find((p) => p.name === "app");
    const includeRemoved = params.find((p) => p.name === "includeRemoved");
    expect(app.in).toBe("query");
    expect(app.schema).toEqual({ $ref: "#/components/schemas/AppKey" });
    expect(resolveRef(doc, app.schema).pattern).toBe("^[a-z][a-z0-9_]*$");
    expect(includeRemoved.schema.type).toBe("boolean");
    expect(includeRemoved.schema.default).toBe(false);
    expect(doc.components.schemas.AppKey.pattern).toBe("^[a-z][a-z0-9_]*$");
  });

  // U121
  it("U121: the doc comment of EventTypeRegistrations_register", () => {
    const text: string = byId["EventTypeRegistrations_register"].op.description;
    for (const code of [
      "registration_app_mismatch",
      "source_mismatch",
      "event_type_app_mismatch",
      "duplicate_event_type",
      "limit_exceeded",
      "invalid_data_schema",
      "content_too_large",
      "unavailable",
      "principal_type",
      "last registration wins",
      "events:event_type:register",
      "401 (token), 403 (scope), 413 (body size), 422 `registration_app_mismatch`, then the content checks",
    ]) {
      expect(text, code).toContain(code);
    }
  });

  // R6
  it("R6: the register operation has the 422 response with problem+json", () => {
    const response =
      byId["EventTypeRegistrations_register"].op.responses["422"];
    expect(response).toBeDefined();
    expect(Object.keys(response.content)).toEqual(["application/problem+json"]);
    expect(response.content["application/problem+json"].schema).toEqual({
      $ref: "#/components/schemas/UnprocessableContent",
    });
  });

  // R7, R9, R10, R12, R13: the security rules of the register operation
  it("R7: the register doc comment and the conventions give the security rules", async () => {
    const text: string = byId["EventTypeRegistrations_register"].op.description;
    const conventions = await readFile(
      join(root, "docs", "conventions.md"),
      "utf8",
    );
    for (const source of [text, conventions]) {
      for (const rule of [
        "Each `$ref` and `$dynamicRef`",
        "must not fetch a remote schema",
        "maximum of 1000 types",
        "RE2 subset",
        "untrusted",
        "single value `events`",
      ]) {
        expect(source, rule).toContain(rule);
      }
    }
    expect(text).toContain("`$ref` must not make a loop");
    expect(text).toContain("The nesting depth is a maximum of 32");
    expect(conventions).toContain("maximum nesting depth of 32");
    expect(conventions).toContain("`denied`");
    expect(text).toContain("`denied`");
    expect(text).toContain("the names of the added types");
    expect(conventions).toContain("untrusted data");
  });

  // R8
  it("R8: the list of registrations has a maximum pageSize of 10", () => {
    const params = (byId["EventTypeRegistrations_list"].op.parameters as Doc[])
      .map((p) => resolveRef(doc, p));
    const size = params.find((p) => p.name === "pageSize");
    expect(size.schema.maximum).toBe(10);
    expect(size.schema.minimum).toBe(1);
    expect(size.schema.default).toBe(10);
    const catalog = (byId["EventTypes_list"].op.parameters as Doc[])
      .map((p) => resolveRef(doc, p))
      .find((p) => p.name === "pageSize");
    expect(catalog.schema.maximum).toBe(200);
  });

  // R12
  it("R12: the catalog text fields are marked as untrusted", () => {
    for (const name of ["CatalogEventType"]) {
      const props = doc.components.schemas[name].properties;
      expect(props.description.description, name).toContain("untrusted");
      expect(props.dataSchema.description, name).toContain("untrusted");
    }
    const def = common.components.schemas.EventTypeDefinition.properties;
    expect(def.description.description).toContain("untrusted");
    expect(def.dataSchema.description).toContain("untrusted");
  });

  // U122
  it("U122: the doc comments of the read operations", () => {
    const text = [
      "EventTypeRegistrations_list",
      "EventTypeRegistrations_get",
      "EventTypes_list",
      "EventTypes_get",
    ]
      .map((id) => byId[id].op.description)
      .join("\n");
    for (const code of [
      "registration_not_found",
      "event_type_not_found",
      "invalid_parameter",
      "invalid_page_token",
    ]) {
      expect(text, code).toContain(code);
    }
    expect(byId["EventTypes_get"].op.description).toContain(
      "also returns a removed type, with `removedAt`",
    );
  });

  // U123
  it("U123: path parameters", () => {
    const path = (id: string, name: string): Doc =>
      (byId[id].op.parameters as Doc[])
        .map((p) => resolveRef(doc, p))
        .find((p) => p.name === name && p.in === "path");
    const app = path("EventTypeRegistrations_get", "app");
    expect(app.schema).toEqual({ $ref: "#/components/schemas/AppKey" });
    expect(resolveRef(doc, app.schema).pattern).toBe("^[a-z][a-z0-9_]*$");
    const type = path("EventTypes_get", "type");
    const schema = resolveRef(doc, type.schema);
    expect(schema.pattern).toBe(
      doc.components.schemas.EventType.pattern,
    );
    expect(schema.maxLength).toBe(128);
  });

  // U124
  it("U124: the manifest", () => {
    expect(checkCommon("PermissionManifest")(manifest)).toBe(true);
    expect(manifest.app).toBe("events");
    const keys = new Set(manifest.permissions.map((p: Doc) => p.key));
    expect(manifest.defaultRoles.map((r: Doc) => r.key).sort()).toEqual([
      "producer",
      "reader",
    ]);
    for (const role of manifest.defaultRoles) {
      for (const permission of role.permissions) {
        expect(keys.has(permission), permission).toBe(true);
      }
    }
  });

  // U125
  it("U125: the app claim of AccessTokenClaims", () => {
    const claims = common.components.schemas.AccessTokenClaims;
    expect(JSON.stringify(claims.properties.app)).toContain("AppKey");
    expect(claims.required).not.toContain("app");
    expect(claims.properties.app.description).toContain("principal_type");
    expect(common.components.schemas.AppKey.pattern).toBe(
      "^[a-z][a-z0-9_]*$",
    );
  });

  // U126
  it("U126: ContentTooLarge and the Retry-After header of ServiceUnavailable", () => {
    for (const d of [common, doc]) {
      const tooLarge = d.components.schemas.ContentTooLarge;
      expect(JSON.stringify(tooLarge)).toContain("Problem");
      expect(JSON.stringify(d.components.schemas.ServiceUnavailable)).toContain(
        "Problem",
      );
      expect(tooLarge.description).toContain("content_too_large");
    }
    const response =
      byId["EventTypeRegistrations_register"].op.responses["413"];
    expect(Object.keys(response.content)).toEqual(["application/problem+json"]);
    expect(response.content["application/problem+json"].schema).toEqual({
      $ref: "#/components/schemas/ContentTooLarge",
    });
    for (const o of ops) {
      const header = o.op.responses["503"].headers["Retry-After"];
      expect(header.required ?? false, o.id).toBe(false);
      expect(header.schema.type, o.id).toBe("integer");
      expect(header.schema.minimum, o.id).toBe(0);
    }
  });

  const cases: [string, string, string][] = [
    ["U127", "CatalogEventType", "catalog-event-type.json"],
    ["U128", "EventTypeRegistrationResult", "event-type-registration-result.json"],
    ["U128", "RegisteredEventTypes", "registered-event-types.json"],
  ];
  for (const [id, schema, file] of cases) {
    // U127, U128
    it(`${id}: examples for ${schema}`, async () => {
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
