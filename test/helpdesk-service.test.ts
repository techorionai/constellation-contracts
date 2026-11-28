import SwaggerParser from "@apidevtools/swagger-parser";
import Ajv2020 from "ajv/dist/2020.js";
import { readdir, readFile } from "node:fs/promises";
import { join } from "node:path";
import { parse } from "yaml";
import { beforeAll, describe, expect, it } from "vitest";
import {
  compileEntry,
  loadCommon,
  makeAjv,
  root,
  schemaValidator,
  type Doc,
} from "./helpers.js";

const helpdeskFile = join(
  root,
  "generated",
  "openapi",
  "Constellation.Helpdesk.openapi.yaml",
);

const json = async (...parts: string[]): Promise<Doc> =>
  JSON.parse(await readFile(join(root, ...parts), "utf8"));

/** Replace the placeholders of the bad examples with long values. */
const fill = (value: unknown): unknown =>
  JSON.parse(
    JSON.stringify(value)
      .replace("SUBJECT201", "s".repeat(201))
      .replace("EMAIL255", `${"e".repeat(243)}@example.com`),
  );

/** Operation ID, method, path, scope, and success status. */
const expected: [string, string, string, string, string][] = [
  ["Customers_list", "get", "/v1/customers", "helpdesk:customer:read", "200"],
  ["Customers_get", "get", "/v1/customers/{customerId}", "helpdesk:customer:read", "200"],
  ["Customers_lookup", "post", "/v1/customers:lookup", "helpdesk:customer:read", "200"],
  ["Customers_create", "post", "/v1/customers", "helpdesk:customer:write", "201"],
  ["Customers_update", "patch", "/v1/customers/{customerId}", "helpdesk:customer:write", "200"],
  ["Tickets_list", "get", "/v1/tickets", "helpdesk:ticket:read", "200"],
  ["Tickets_get", "get", "/v1/tickets/{ticketId}", "helpdesk:ticket:read", "200"],
  ["Tickets_create", "post", "/v1/tickets", "helpdesk:ticket:write", "201"],
  ["Tickets_update", "patch", "/v1/tickets/{ticketId}", "helpdesk:ticket:write", "200"],
];

const eventModels = [
  "TicketCreatedData",
  "TicketUpdatedData",
  "TicketStatusChangedData",
  "CustomerCreatedData",
  "CustomerUpdatedData",
];

interface Operation {
  id: string;
  method: string;
  path: string;
  op: Doc;
}

describe("helpdesk service contract", () => {
  let doc: Doc;
  let ops: Operation[];
  let byId: Record<string, Operation>;
  let manifest: Doc;
  let registration: Doc;
  let check: (name: string) => (value: unknown) => boolean;
  let checkCommon: (name: string) => (value: unknown) => boolean;

  beforeAll(async () => {
    doc = parse(await readFile(helpdeskFile, "utf8"));
    ops = [];
    for (const [path, item] of Object.entries<Doc>(doc.paths)) {
      for (const [method, op] of Object.entries<Doc>(item)) {
        ops.push({ id: op.operationId, method, path, op });
      }
    }
    byId = Object.fromEntries(ops.map((o) => [o.id, o]));
    manifest = await json("services", "helpdesk", "manifest.json");
    registration = await json(
      "generated",
      "event-types",
      "helpdesk.event-types.json",
    );
    check = schemaValidator(doc, "helpdesk.openapi");
    checkCommon = schemaValidator(await loadCommon(), "common.openapi");
  });

  // U141
  it("U141: both emitters compile and write no file in the repository", async () => {
    const snapshot = async (folder: string) =>
      Object.fromEntries(
        await Promise.all(
          (await readdir(folder)).map(
            async (name) =>
              [name, await readFile(join(folder, name), "utf8")] as const,
          ),
        ),
      );
    const folders = [
      join(root, "generated", "event-types"),
      join(root, "generated", "openapi"),
    ];
    const before = await Promise.all(folders.map(snapshot));
    const result = await compileEntry(join(root, "main.tsp"));
    expect(result.diagnostics).toEqual([]);
    expect(Object.keys(result.files)).toContain(
      "Constellation.Helpdesk.openapi.yaml",
    );
    for (const model of eventModels) {
      expect(result.schemaFiles, model).toContain(`${model}.json`);
    }
    expect(await Promise.all(folders.map(snapshot))).toEqual(before);
    await SwaggerParser.validate(helpdeskFile);
  });

  // U142
  it("U142: operation IDs, methods, and paths", () => {
    expect(ops.map((o) => o.id).sort()).toEqual(expected.map((e) => e[0]).sort());
    for (const [id, method, path] of expected) {
      expect(byId[id].method, id).toBe(method);
      expect(byId[id].path, id).toBe(path);
    }
  });

  // U143
  it("U143: scopes of the operations are in the manifest", () => {
    const keys = new Set(manifest.permissions.map((p: Doc) => p.key));
    for (const [id, , , scope] of expected) {
      expect(byId[id].op["x-required-scopes"], id).toEqual([scope]);
      expect(keys.has(scope), scope).toBe(true);
    }
  });

  // U144
  it("U144: error responses and doc comments", () => {
    for (const o of ops) {
      expect(o.op.security ?? doc.security, o.id).toEqual([{ BearerAuth: [] }]);
      const retry = o.op.responses["503"].headers["Retry-After"];
      expect(retry.required ?? false, o.id).toBe(false);
      for (const [status, response] of Object.entries<Doc>(o.op.responses)) {
        if (Number(status) < 400) continue;
        expect(Object.keys(response.content), `${o.id} ${status}`).toEqual([
          "application/problem+json",
        ]);
      }
    }
    const codes: Record<string, string[]> = {
      Customers_list: ["invalid_page_token"],
      Customers_lookup: ["customer_not_found"],
      Customers_get: ["customer_not_found"],
      Customers_create: ["customer_email_taken", "validation_failed"],
      Customers_update: ["empty_update", "customer_not_found", "customer_email_taken"],
      Tickets_list: ["invalid_page_token", "invalid_parameter"],
      Tickets_get: ["ticket_not_found"],
      Tickets_create: ["customer_unknown", "validation_failed"],
      Tickets_update: ["empty_update", "ticket_not_found"],
    };
    for (const [id, words] of Object.entries(codes)) {
      for (const word of words) {
        expect(byId[id].op.description, `${id} ${word}`).toContain(word);
      }
      expect(byId[id].op.description, id).toContain("unavailable");
    }
    for (const id of ["Customers_update", "Tickets_update"]) {
      expect(byId[id].op.description, id).toContain("no real change");
      expect(byId[id].op.description, id).toContain(
        "writes no event and no audit entry",
      );
    }
    expect(byId["Tickets_create"].op.responses["422"]).toBeDefined();
  });

  // U145
  it("U145: no-store headers on each response, also the error responses", () => {
    for (const [id] of expected) {
      const responses = Object.entries<Doc>(byId[id].op.responses);
      expect(responses.length, id).toBeGreaterThan(4);
      for (const [status, response] of responses) {
        const headers = response.headers ?? {};
        expect(headers["Cache-Control"]?.schema.enum, `${id} ${status}`).toEqual(["no-store"]);
        expect(headers["Pragma"]?.schema.enum, `${id} ${status}`).toEqual(["no-cache"]);
      }
    }
    for (const status of ["400", "401", "403", "404", "500", "503"]) {
      expect(byId["Customers_get"].op.responses[status], status).toBeDefined();
    }
    expect(Object.keys(doc.components.schemas)).not.toContain(
      "HelpdeskNoStoreHeaders",
    );
  });

  // U155
  it("U155: the email lookup is a POST with the email in the body", () => {
    const list = byId["Customers_list"].op;
    const names = (list.parameters ?? []).map((p: Doc) => p.name ?? p.$ref);
    expect(names.join(" ")).not.toContain("email");
    const lookup = byId["Customers_lookup"].op;
    expect(lookup.parameters ?? []).toEqual([]);
    expect(Object.keys(doc.paths).join(" ")).not.toContain("email");
    const body = lookup.requestBody.content["application/json"].schema;
    expect(body.$ref).toBe("#/components/schemas/CustomerLookup");
    const validate = check("CustomerLookup");
    expect(validate({ email: "ada@example.com" })).toBe(true);
    expect(validate({})).toBe(false);
    expect(validate({ email: "" })).toBe(false);
    expect(validate({ email: `${"e".repeat(243)}@example.com` })).toBe(false);
    expect(Object.keys(lookup.responses).sort()).toEqual(
      ["200", "400", "401", "403", "404", "500", "503"],
    );
  });

  // U146
  it("U146: the manifest", () => {
    expect(checkCommon("PermissionManifest")(manifest)).toBe(true);
    expect(manifest.app).toBe("helpdesk");
    const keys: string[] = manifest.permissions.map((p: Doc) => p.key);
    expect([...keys].sort()).toEqual([
      "helpdesk:customer:read",
      "helpdesk:customer:write",
      "helpdesk:ticket:read",
      "helpdesk:ticket:write",
    ]);
    const roles = Object.fromEntries(
      manifest.defaultRoles.map((r: Doc) => [r.key, r.permissions]),
    );
    expect(Object.keys(roles).sort()).toEqual(["support_agent", "viewer"]);
    for (const list of Object.values<string[]>(roles)) {
      for (const key of list) expect(keys).toContain(key);
    }
    expect([...roles.support_agent].sort()).toEqual([...keys].sort());
    expect([...roles.viewer].sort()).toEqual([
      "helpdesk:customer:read",
      "helpdesk:ticket:read",
    ]);
  });

  // U147
  for (const [schema, file] of [
    ["Ticket", "helpdesk-ticket.json"],
    ["Customer", "helpdesk-customer.json"],
  ] as const) {
    it(`U147: examples for ${schema}`, async () => {
      const validate = check(schema);
      const { valid, invalid } = await json("test", "examples", file);
      expect(valid.length).toBeGreaterThan(0);
      for (const value of valid) expect(validate(value)).toBe(true);
      const ajv = makeAjv();
      ajv.addSchema(doc, "h.openapi");
      const fn = ajv.getSchema(`h.openapi#/components/schemas/${schema}`)!;
      for (const { field, value } of invalid) {
        expect(fn(fill(value)), field).toBe(false);
        const paths = (fn.errors ?? []).map((e) => e.instancePath);
        expect(paths, field).toContain(`/${field}`);
      }
    });
  }

  // U148
  it("U148: event data examples and the named CloudEvent models", async () => {
    const examples = await json("test", "examples", "helpdesk-events.json");
    const list = await json("services", "helpdesk", "events", "event-types.json");
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
      expect(doc.components.schemas[event].properties.data.allOf, event).toEqual([{
        $ref: `#/components/schemas/${item.data}`,
      }]);
    }
    expect(check("TicketStatus")("open")).toBe(true);
    expect(check("TicketStatus")("done")).toBe(false);
  });

  // U149
  it("U149: the generated registration file", async () => {
    expect(registration.eventTypes.map((t: Doc) => t.type)).toEqual([
      "helpdesk.ticket.created",
      "helpdesk.ticket.updated",
      "helpdesk.ticket.status_changed",
      "helpdesk.customer.created",
      "helpdesk.customer.updated",
    ]);
    expect(registration.source).toBe("/helpdesk");
    expect(registration.app).toBe("helpdesk");
    expect(checkCommon("EventTypeRegistration")(registration)).toBe(true);
    const examples = await json("test", "examples", "helpdesk-events.json");
    const list = await json("services", "helpdesk", "events", "event-types.json");
    for (const item of list) {
      const entry = registration.eventTypes.find((t: Doc) => t.type === item.type);
      const text = JSON.stringify(entry.dataSchema);
      expect(text, item.type).not.toContain('"$id"');
      const refs = [...text.matchAll(/"\$(?:dynamicRef|ref)":"([^"]*)"/g)].map(
        (m) => m[1],
      );
      for (const ref of refs) {
        expect(ref.startsWith("#/"), `${item.type} ${ref}`).toBe(true);
      }
      expect(entry.dataSchema.$schema).toBe(
        "https://json-schema.org/draft/2020-12/schema",
      );
      const validate = new Ajv2020({ strict: true, validateFormats: false }).compile(
        entry.dataSchema,
      );
      const good = examples[item.data].valid[0];
      expect(validate(good), item.type).toBe(true);
      expect(validate({ ...good, extra: 1 }), `${item.type} extra`).toBe(false);
      expect(Buffer.byteLength(text)).toBeLessThan(64 * 1024);
    }
    expect(registration.eventTypes[0].dataSchema.properties.number.type).toBe(
      "integer",
    );
    // Decision D7: no free text and no personal data in the event data.
    const all = JSON.stringify(registration);
    for (const word of ['"subject":{', '"email":{', '"phone":{', '"name":{']) {
      expect(all, word).not.toContain(word);
    }
  });
});
