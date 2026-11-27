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

const auditFile = join(
  root,
  "generated",
  "openapi",
  "Constellation.Audit.openapi.yaml",
);

async function examples(name: string): Promise<{
  valid: unknown[];
  invalid: unknown[];
}> {
  return JSON.parse(
    await readFile(join(root, "test", "examples", name), "utf8"),
  );
}

const filters: [string, string][] = [
  ["from", "date-time"],
  ["to", "date-time"],
  ["service", "AppKey"],
  ["action", "PermissionKey"],
  ["result", "AuditResult"],
  ["actor", "string"],
  ["actorType", "PrincipalType"],
  ["act", "string"],
  ["targetType", "AuditTargetType"],
  ["targetId", "string"],
  ["requestId", "string"],
  ["traceId", "string"],
];

/** Operation ID, method, path, success statuses, and error statuses. */
const expected: [string, string, string, number[]][] = [
  ["AuditEntries_list", "get", "/v1/audit-entries", []],
  ["AuditEntries_get", "get", "/v1/audit-entries/{id}", [404]],
  ["AuditEntries_export", "get", "/v1/audit-entries/export", [422, 429]],
];

const commonErrors = [400, 401, 403, 500, 503];

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

describe("audit service contract", () => {
  let doc: Doc;
  let common: Doc;
  let ops: Operation[];
  let byId: Record<string, Operation>;
  let manifest: Doc;
  let check: (name: string) => (value: unknown) => boolean;
  let checkCommon: (name: string) => (value: unknown) => boolean;

  const params = (id: string): Doc[] =>
    (byId[id].op.parameters as Doc[]).map((p) => resolveRef(doc, p));

  beforeAll(async () => {
    doc = parse(await readFile(auditFile, "utf8"));
    common = await loadCommon();
    ops = operations(doc);
    byId = Object.fromEntries(ops.map((o) => [o.id, o]));
    manifest = JSON.parse(
      await readFile(join(root, "services", "audit", "manifest.json"), "utf8"),
    );
    check = schemaValidator(doc, "audit.openapi");
    checkCommon = schemaValidator(common, "common.openapi");
  });

  // U129
  it("U129: the common file has the shared audit models", () => {
    const names = Object.keys(common.components.schemas);
    for (const name of [
      "AuditEntryData",
      "AuditTarget",
      "AuditResult",
      "AuditTargetType",
      "AuditRecordedEvent",
    ]) {
      expect(names).toContain(name);
    }
  });

  // U130
  it("U130: AuditEntryData rules", () => {
    const data = common.components.schemas.AuditEntryData;
    expect(data.required.sort()).toEqual(["action", "result"]);
    expect(data.properties.summary.maxLength).toBe(1024);
    expect(data.properties.userAgent.maxLength).toBe(512);
    expect(data.properties.requestId.maxLength).toBe(128);
    expect(data.properties.ipAddress.maxLength).toBe(45);
    expect(common.components.schemas.AuditResult.enum).toEqual([
      "success",
      "denied",
      "invalid",
      "failure",
    ]);
  });

  // U131
  it("U131: the root compiles with warnings as errors", async () => {
    const result = await compileEntry(join(root, "main.tsp"), false);
    expect(result.diagnostics).toEqual([]);
  });

  // U132
  it("U132: the OpenAPI file is valid", async () => {
    await SwaggerParser.validate(auditFile);
  });

  // U133
  it("U133: operations, methods, paths, and content types", () => {
    expect(ops.map((o) => o.id).sort()).toEqual(
      expected.map((e) => e[0]).sort(),
    );
    for (const [id, method, path] of expected) {
      expect(byId[id].method, id).toBe(method);
      expect(byId[id].path, id).toBe(path);
      expect(byId[id].op["x-required-scopes"], id).toEqual(["audit:log:read"]);
    }
    const ok = (id: string): Doc => byId[id].op.responses["200"].content;
    expect(ok("AuditEntries_list")["application/json"].schema).toEqual({
      $ref: "#/components/schemas/AuditEntryPage",
    });
    expect(ok("AuditEntries_get")["application/json"].schema).toEqual({
      $ref: "#/components/schemas/AuditEntry",
    });
    const exported = ok("AuditEntries_export");
    expect(Object.keys(exported).sort()).toEqual([
      "application/json",
      "text/csv",
    ]);
    expect(exported["text/csv"].schema).toEqual({ type: "string" });
    expect(exported["application/json"].schema).toEqual({
      type: "array",
      items: { $ref: "#/components/schemas/AuditEntry" },
    });
  });

  // U134
  it("U134: security, problem errors, 503, scopes, and no-store headers", () => {
    const keys = new Set(manifest.permissions.map((p: Doc) => p.key));
    for (const o of ops) {
      expect(o.op.security ?? doc.security, o.id).toEqual([{ BearerAuth: [] }]);
      const header503 = o.op.responses["503"].headers["Retry-After"];
      expect(header503.required ?? false, o.id).toBe(false);
      for (const [status, response] of Object.entries<Doc>(o.op.responses)) {
        if (Number(status) < 400) continue;
        expect(Object.keys(response.content), `${o.id} ${status}`).toEqual([
          "application/problem+json",
        ]);
      }
      for (const scope of o.op["x-required-scopes"]) {
        expect(keys.has(scope), scope).toBe(true);
      }
      const headers = o.op.responses["200"].headers;
      expect(headers["Cache-Control"].schema.enum, o.id).toEqual(["no-store"]);
      expect(headers["Pragma"].schema.enum, o.id).toEqual(["no-cache"]);
    }
  });

  // U135
  it("U135: query and path parameters", () => {
    for (const id of ["AuditEntries_list", "AuditEntries_export"]) {
      const found = params(id);
      for (const [name, type] of filters) {
        const p = found.find((x) => x.name === name);
        expect(p, `${id} ${name}`).toBeDefined();
        expect(p.in).toBe("query");
        if (type === "date-time") expect(p.schema.format).toBe("date-time");
        else if (type === "string") expect(p.schema.type).toBe("string");
        else
          expect(p.schema, `${id} ${name}`).toEqual({
            $ref: `#/components/schemas/${type}`,
          });
      }
    }
    const list = params("AuditEntries_list").map((p) => p.name);
    expect(list).toContain("pageToken");
    expect(list).toContain("pageSize");
    const format = params("AuditEntries_export").find((p) => p.name === "format");
    expect(format.required).toBe(true);
    expect(resolveRef(doc, format.schema).enum).toEqual(["csv", "json"]);
    const service = params("AuditEntries_get").find((p) => p.name === "service");
    expect(service.in).toBe("query");
    expect(service.required ?? false).toBe(false);
    expect(service.schema).toEqual({ $ref: "#/components/schemas/AppKey" });
    const id = params("AuditEntries_get").find((p) => p.name === "id");
    expect(id.in).toBe("path");
    expect(id.schema.format).toBe("uuid");
    expect(doc.components.schemas.AuditEntry.properties.id.format).toBe("uuid");
  });

  // U136
  it("U136: doc comments", () => {
    const text = ops.map((o) => o.op.description).join("\n");
    for (const word of [
      "invalid_parameter",
      "invalid_page_token",
      "audit_entry_not_found",
      "export_too_large",
      "too_many_exports",
      "unavailable",
      "`id`, `service`, `time`, `receivedAt`, `action`, `result`, `actor`, `actorType`, `act`, `actType`",
      "`targetType`, `targetId`, `summary`, `requestId`, `traceId`, `ipAddress`, `userAgent`, `details`",
      "starts with `=`, `+`, `-`, `@`, a tab, or a carriage return gets a `'` in front",
      "audit:log:export",
    ]) {
      expect(text, word).toContain(word);
    }
    const event: string =
      common.components.schemas.AuditRecordedEvent.description;
    for (const word of [
      ".audit.recorded",
      "`/<app>`",
      "UUID in lowercase text form",
      "A reader ignores an unknown member",
    ]) {
      expect(event, word).toContain(word);
    }
  });

  const cases: [string, "common" | "audit", string, string][] = [
    ["U137", "common", "AuditRecordedEvent", "audit-recorded-event.json"],
    ["U138", "audit", "AuditEntry", "audit-entry.json"],
  ];
  for (const [id, where, schema, file] of cases) {
    // U137, U138
    it(`${id}: examples for ${schema}`, async () => {
      const validate = (where === "common" ? checkCommon : check)(schema);
      const { valid, invalid } = await examples(file);
      expect(valid.length).toBeGreaterThan(0);
      expect(invalid.length).toBeGreaterThan(0);
      for (const value of valid) expect(validate(value)).toBe(true);
      invalid.forEach((value, index) => {
        expect(validate(value), `invalid example ${index}`).toBe(false);
      });
    });
  }

  // U139
  it("U139: the manifest", () => {
    expect(checkCommon("PermissionManifest")(manifest)).toBe(true);
    expect(manifest.app).toBe("audit");
    expect(manifest.defaultRoles).toHaveLength(1);
    expect(manifest.defaultRoles[0].key).toBe("reader");
    expect(manifest.defaultRoles[0].permissions).toEqual(["audit:log:read"]);
  });

  // U140
  it("U140: error statuses of each operation", () => {
    for (const [id, , , extra] of expected) {
      const statuses = Object.keys(byId[id].op.responses)
        .map(Number)
        .filter((s) => s >= 400)
        .sort();
      expect(statuses, id).toEqual([...commonErrors, ...extra].sort());
    }
    const header = byId["AuditEntries_export"].op.responses["429"].headers[
      "Retry-After"
    ];
    expect(header.required).toBe(true);
    expect(header.schema.type).toBe("integer");
  });
});
