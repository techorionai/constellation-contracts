import SwaggerParser from "@apidevtools/swagger-parser";
import Ajv2020 from "ajv/dist/2020.js";
import { readdir, readFile } from "node:fs/promises";
import { join } from "node:path";
import { parse } from "yaml";
import { beforeAll, describe, expect, it } from "vitest";
import { checkSchema } from "../scripts/event-types.mjs";
import {
  compileEntry,
  loadCommon,
  root,
  schemaValidator,
  type Doc,
} from "./helpers.js";

const emailFile = join(root, "generated", "openapi", "Constellation.Email.openapi.yaml");

const json = async (...parts: string[]): Promise<Doc> =>
  JSON.parse(await readFile(join(root, ...parts), "utf8"));

/** Operation ID, method, path, scope, and success status. */
const expected: [string, string, string, string, string][] = [
  ["Messages_send", "post", "/v1/messages", "email:message:send", "202"],
  ["Messages_get", "get", "/v1/messages/{id}", "email:message:read", "200"],
  ["Messages_list", "get", "/v1/messages", "email:message:read", "200"],
  ["Templates_list", "get", "/v1/templates", "email:template:read", "200"],
  ["Templates_get", "get", "/v1/templates/{id}", "email:template:read", "200"],
  ["Templates_create", "post", "/v1/templates", "email:template:write", "201"],
  ["Templates_update", "patch", "/v1/templates/{id}", "email:template:write", "200"],
  ["Templates_delete", "delete", "/v1/templates/{id}", "email:template:write", "204"],
  ["SenderRules_list", "get", "/v1/sender-rules", "email:sender:read", "200"],
  ["SenderRules_create", "post", "/v1/sender-rules", "email:sender:write", "201"],
  ["SenderRules_delete", "delete", "/v1/sender-rules/{id}", "email:sender:write", "204"],
  ["Suppressions_list", "get", "/v1/suppressions", "email:suppression:read", "200"],
  ["Suppressions_lookup", "post", "/v1/suppressions:lookup", "email:suppression:read", "200"],
  ["Suppressions_create", "post", "/v1/suppressions", "email:suppression:write", "201"],
  ["Suppressions_delete", "delete", "/v1/suppressions/{id}", "email:suppression:write", "204"],
];

/** Allowed query parameters of each operation. A path parameter is always `id`. */
const queryAllow: Record<string, string[]> = {
  Messages_list: ["pageSize", "pageToken", "status", "createdFrom", "createdTo"],
  Templates_list: ["pageSize", "pageToken"],
  SenderRules_list: ["pageSize", "pageToken", "app"],
  Suppressions_list: ["pageSize", "pageToken", "reason"],
};

const eventModels = [
  "EmailMessageSentData",
  "EmailMessageFailedData",
  "EmailMessageSuppressedData",
  "EmailMessageDeliveredData",
  "EmailMessageBouncedData",
  "EmailMessageComplainedData",
];

interface Operation {
  id: string;
  method: string;
  path: string;
  op: Doc;
}

describe("email service contract", () => {
  let doc: Doc;
  let ops: Operation[];
  let byId: Record<string, Operation>;
  let manifest: Doc;
  let registration: Doc;
  let check: (name: string) => (value: unknown) => boolean;
  let checkCommon: (name: string) => (value: unknown) => boolean;
  const resolveParam = (p: Doc): Doc =>
    p.$ref ? doc.components.parameters[p.$ref.split("/").pop()!] : p;

  beforeAll(async () => {
    doc = parse(await readFile(emailFile, "utf8"));
    ops = [];
    for (const [path, item] of Object.entries<Doc>(doc.paths)) {
      for (const [method, op] of Object.entries<Doc>(item)) {
        ops.push({ id: op.operationId, method, path, op });
      }
    }
    byId = Object.fromEntries(ops.map((o) => [o.id, o]));
    manifest = await json("services", "email", "manifest.json");
    registration = await json("generated", "event-types", "email.event-types.json");
    check = schemaValidator(doc, "email.openapi");
    checkCommon = schemaValidator(await loadCommon(), "common.openapi");
  });

  // U1
  it("U1: both emitters compile and write no file in the repository", async () => {
    const snapshot = async (folder: string) =>
      Object.fromEntries(
        await Promise.all(
          (await readdir(folder)).map(
            async (name) => [name, await readFile(join(folder, name), "utf8")] as const,
          ),
        ),
      );
    const folders = [join(root, "generated", "event-types"), join(root, "generated", "openapi")];
    const before = await Promise.all(folders.map(snapshot));
    const result = await compileEntry(join(root, "main.tsp"));
    expect(result.diagnostics).toEqual([]);
    expect(Object.keys(result.files)).toContain("Constellation.Email.openapi.yaml");
    for (const model of eventModels) expect(result.schemaFiles, model).toContain(`${model}.json`);
    expect(await Promise.all(folders.map(snapshot))).toEqual(before);
    await SwaggerParser.validate(emailFile);
  });

  // U2
  it("U2: operation IDs, methods, and paths", () => {
    expect(ops.map((o) => o.id).sort()).toEqual(expected.map((e) => e[0]).sort());
    for (const [id, method, path, , success] of expected) {
      expect(byId[id].method, id).toBe(method);
      expect(byId[id].path, id).toBe(path);
      expect(byId[id].op.responses[success], id).toBeDefined();
    }
  });

  // U3
  it("U3: scopes of the operations are in the manifest", () => {
    const keys = new Set(manifest.permissions.map((p: Doc) => p.key));
    for (const [id, , , scope] of expected) {
      expect(byId[id].op["x-required-scopes"], id).toEqual([scope]);
      expect(keys.has(scope), scope).toBe(true);
    }
  });

  // U4
  it("U4: no-store headers on each response, also the error responses", () => {
    for (const [id] of expected) {
      for (const [status, response] of Object.entries<Doc>(byId[id].op.responses)) {
        const headers = response.headers ?? {};
        expect(headers["Cache-Control"]?.schema.enum, `${id} ${status}`).toEqual(["no-store"]);
        expect(headers["Pragma"]?.schema.enum, `${id} ${status}`).toEqual(["no-cache"]);
      }
    }
  });

  // U5
  it("U5: path and query parameters against an allow list", () => {
    for (const o of ops) {
      const names = (o.op.parameters ?? [])
        .map(resolveParam)
        .filter((p: Doc) => p.in !== "header")
        .map((p: Doc) => `${p.in}:${p.name}`)
        .sort();
      const want = [
        ...(o.path.includes("{id}") ? ["path:id"] : []),
        ...(queryAllow[o.id] ?? []).map((q) => `query:${q}`),
      ].sort();
      expect(names, o.id).toEqual(want);
    }
    expect(Object.keys(doc.paths).join(" ")).not.toContain("address");
  });

  // U6
  it("U6: the manifest", () => {
    expect(checkCommon("PermissionManifest")(manifest)).toBe(true);
    expect(manifest.app).toBe("email");
    const keys: string[] = manifest.permissions.map((p: Doc) => p.key);
    expect(keys).toHaveLength(9);
    for (const key of keys) expect(key.startsWith("email:"), key).toBe(true);
    const roles = Object.fromEntries(
      manifest.defaultRoles.map((r: Doc) => [r.key, r.permissions]),
    );
    expect(Object.keys(roles).sort()).toEqual(["admin", "sender", "viewer"]);
    for (const list of Object.values<string[]>(roles)) {
      for (const key of list) expect(keys).toContain(key);
    }
    expect(roles.sender).not.toContain("email:message:read_all");
    expect([...roles.sender].sort()).toEqual([
      "email:message:read",
      "email:message:send",
      "email:template:read",
    ]);
    expect([...roles.admin].sort()).toEqual([...keys].sort());
    expect(roles.viewer).toContain("email:message:read_all");
    expect(roles.viewer).toHaveLength(5);
  });

  // U7
  it("U7: send request examples", async () => {
    const validate = check("SendMessageRequest");
    const base = { from: "noreply@example.com", to: ["a@example.com"] };
    const tpl = { key: "welcome", variables: { name: "Ada" } };
    const content = { subject: "Hello", text: "Hello" };
    const addr = (n: number) => `${"e".repeat(n - 12)}@example.com`;
    const many = Array.from({ length: 51 }, (_, i) => `u${i}@example.com`);
    const cases: [number, unknown, boolean][] = [
      [1, { ...base, template: tpl }, true],
      [2, { ...base, content }, true],
      [3, { ...base, template: tpl, content }, false],
      [4, { ...base }, false],
      [5, { ...base, content, to: many }, false],
      [6, { ...base, content: { ...content, subject: "s".repeat(999) } }, false],
      [7, { ...base, content, to: [addr(255)] }, false],
      [8, { ...base, content, to: many.slice(0, 50) }, true],
      [9, { ...base, content: { ...content, subject: "s".repeat(998) } }, true],
      [10, { ...base, content, to: [addr(254)] }, true],
      [11, { ...base, content: { subject: "Hello" } }, false],
      [12, { ...base, content, to: [] }, false],
      [13, { ...base, template: { key: "welcome", variables: { n: 1 } } }, false],
    ];
    for (const [n, value, ok] of cases) expect(validate(value), `case ${n}`).toBe(ok);
    const examples = await json("test", "examples", "email-send.json");
    for (const value of Object.values(examples)) expect(validate(value)).toBe(true);
  });

  // U8
  it("U8: the registration file", () => {
    expect(registration.eventTypes.map((t: Doc) => t.type)).toEqual([
      "email.message.sent",
      "email.message.failed",
      "email.message.suppressed",
      "email.message.delivered",
      "email.message.bounced",
      "email.message.complained",
    ]);
    expect(registration.source).toBe("/email");
    expect(registration.app).toBe("email");
    expect(checkCommon("EventTypeRegistration")(registration)).toBe(true);
    for (const entry of registration.eventTypes) {
      const text = JSON.stringify(entry.dataSchema);
      expect(text, entry.type).not.toContain('"$id"');
      expect(entry.dataSchema.unevaluatedProperties, entry.type).toEqual({ not: {} });
      const refs = [...text.matchAll(/"\$(?:dynamicRef|ref)":"([^"]*)"/g)].map((m) => m[1]);
      for (const ref of refs) expect(ref.startsWith("#/"), `${entry.type} ${ref}`).toBe(true);
      expect(checkSchema(entry.dataSchema), entry.type).toEqual([]);
      expect(Buffer.byteLength(text)).toBeLessThan(64 * 1024);
    }
  });

  // U9
  it("U9: event data examples and the named CloudEvent models", async () => {
    const examples = await json("test", "examples", "email-events.json");
    const list = await json("services", "email", "events", "event-types.json");
    expect(list.map((item: Doc) => item.data)).toEqual(eventModels);
    for (const item of list) {
      const entry = registration.eventTypes.find((t: Doc) => t.type === item.type);
      const validate = new Ajv2020({ strict: true, validateFormats: false }).compile(
        entry.dataSchema,
      );
      const { valid, invalid } = examples[item.data];
      expect(valid.length, item.data).toBeGreaterThan(0);
      for (const value of valid) expect(validate(value), item.data).toBe(true);
      for (const { rule, value } of invalid) {
        expect(validate(value), `${item.data}: ${rule}`).toBe(false);
      }
      const event = item.data.replace("Data", "Event");
      expect(doc.components.schemas[event].properties.data.allOf, event).toEqual([
        { $ref: `#/components/schemas/${item.data}` },
      ]);
    }
    const all = JSON.stringify(registration);
    for (const word of ['"address":{', '"subject":{', '"text":{', '"html":{']) {
      expect(all, word).not.toContain(word);
    }
  });

  // U10
  it("U10: the idempotency header and its responses", () => {
    const op = byId["Messages_send"].op;
    const header = (op.parameters ?? []).map(resolveParam).find((p: Doc) => p.in === "header");
    expect(header.name).toBe("Idempotency-Key");
    expect(header.required ?? false).toBe(false);
    expect(header.schema.minLength).toBe(1);
    expect(header.schema.maxLength).toBe(255);
    expect(op.responses["409"].headers["Retry-After"]).toBeDefined();
    expect(op.responses["422"]).toBeDefined();
    expect(op.description).toContain("idempotency_key_reused");
    expect(op.description).toContain("idempotency_request_in_progress");
  });

  // U12
  it("U12: no email provider in the contract", () => {
    const words = /\b(ses|sns|smtp|aws|amazon|x-amz[a-z-]*)\b/i;
    const hits: string[] = [];
    const walk = (node: unknown, path: string): void => {
      if (Array.isArray(node)) {
        node.forEach((v, i) => {
          if (typeof v === "string" && words.test(v)) hits.push(`${path}[${i}]`);
          walk(v, `${path}[${i}]`);
        });
      } else if (node && typeof node === "object") {
        for (const [key, value] of Object.entries(node)) {
          if (words.test(key)) hits.push(`${path}.${key}`);
          if (typeof value === "string" && words.test(value)) hits.push(`${path}.${key}`);
          walk(value, `${path}.${key}`);
        }
      }
    };
    walk(doc, "openapi");
    walk(registration, "registration");
    expect(hits).toEqual([]);
  });

  // U13
  it("U13: the send request body is a oneOf of two models", () => {
    const body = byId["Messages_send"].op.requestBody.content["application/json"].schema;
    expect(body.$ref).toBe("#/components/schemas/SendMessageRequest");
    const union = doc.components.schemas.SendMessageRequest;
    expect(union.oneOf).toHaveLength(2);
    const required = union.oneOf.map(
      (m: Doc) => doc.components.schemas[m.$ref.split("/").pop()!].required,
    );
    expect(required[0]).toContain("template");
    expect(required[0]).not.toContain("content");
    expect(required[1]).toContain("content");
    expect(required[1]).not.toContain("template");
  });

  // U14
  it("U14: data names are valid model names with output files", async () => {
    const list = await json("services", "email", "events", "event-types.json");
    const result = await compileEntry(join(root, "main.tsp"));
    for (const item of list) {
      expect(item.data).toMatch(/^[A-Za-z_][A-Za-z0-9_]*$/);
      expect(result.schemaFiles).toContain(`${item.data}.json`);
    }
  });

  // U15
  it("U15: Retry-After on 429 and 503", () => {
    for (const o of ops) {
      const r503 = o.op.responses["503"].headers["Retry-After"];
      expect(r503.required ?? false, o.id).toBe(false);
      const r429 = o.op.responses["429"];
      if (r429) expect(r429.headers["Retry-After"].required, o.id).toBe(true);
    }
    expect(byId["Messages_send"].op.responses["429"]).toBeDefined();
  });

  // U16
  it("U16: doc comments of the message operations", () => {
    const send = byId["Messages_send"].op.description;
    expect(send).toContain("total of `to`, `cc`, and `bcc` is a maximum of 50");
    expect(send).toContain("no `app` claim gives 422 `sender_not_allowed`");
    for (const id of ["Messages_get", "Messages_list"]) {
      const text = byId[id].op.description;
      expect(text, id).toContain("`app` claim");
      expect(text, id).toContain("email:message:read_all");
      expect(text, id).toContain("24 hours");
    }
  });
});
