import { spawnSync } from "node:child_process";
import { mkdir, mkdtemp, readFile, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { root, type Doc } from "./helpers.js";

const script = join(root, "scripts", "event-types.mjs");
const closed = { additionalProperties: false };

interface Item {
  type: string;
  description: string;
  data: string;
}

/** A schema with `steps` nested `properties` steps below the root. */
function nested(steps: number): Doc {
  let schema: Doc = { type: "string" };
  for (let i = 0; i < steps; i++) {
    schema = { type: "object", properties: { a: schema }, ...closed };
  }
  return schema;
}

describe("event type script", () => {
  let work: string;
  let count = 0;

  beforeAll(async () => {
    work = await mkdtemp(join(tmpdir(), "event-types-"));
  });

  afterAll(async () => {
    await rm(work, { recursive: true, force: true });
  });

  /** Make a fixture folder, run the script, and return the result. */
  async function run(
    list: Item[],
    schemas: Record<string, Doc>,
    service = "fx",
  ): Promise<{ status: number | null; stderr: string; out: string }> {
    const dir = join(work, `case-${count++}`);
    await mkdir(join(dir, "services", service, "events"), { recursive: true });
    await mkdir(join(dir, "schemas"), { recursive: true });
    await writeFile(
      join(dir, "services", service, "events", "event-types.json"),
      JSON.stringify(list),
    );
    for (const [name, schema] of Object.entries(schemas)) {
      await writeFile(join(dir, "schemas", `${name}.json`), JSON.stringify(schema));
    }
    const out = join(dir, "out");
    const result = spawnSync(
      process.execPath,
      [script, "--services", join(dir, "services"), "--schemas", join(dir, "schemas"), "--out", out],
      { encoding: "utf8" },
    );
    return { status: result.status, stderr: result.stderr, out };
  }

  const item = (type = "fx.thing.created", data = "A"): Item => ({
    type,
    description: "A thing.",
    data,
  });

  const simple = (extra: Doc = {}): Doc => ({
    $schema: "https://json-schema.org/draft/2020-12/schema",
    $id: "A.json",
    type: "object",
    properties: { x: { type: "string" } },
    ...closed,
    ...extra,
  });

  // U150
  it("U150: a reference to another model goes into $defs", async () => {
    const result = await run([item()], {
      A: simple({ properties: { b: { $ref: "B.json" } } }),
      B: {
        $schema: "https://json-schema.org/draft/2020-12/schema",
        $id: "B.json",
        type: "object",
        properties: { y: { type: "string" } },
        ...closed,
      },
    });
    expect(result.stderr).toBe("");
    expect(result.status).toBe(0);
    const file = JSON.parse(await readFile(join(result.out, "fx.event-types.json"), "utf8"));
    const schema = file.eventTypes[0].dataSchema;
    expect(schema.properties.b).toEqual({ $ref: "#/$defs/B" });
    expect(schema.$defs.B.properties.y.type).toBe("string");
    expect(JSON.stringify(schema)).not.toContain("$id");
    expect(schema.$schema).toBe("https://json-schema.org/draft/2020-12/schema");
    expect(file.source).toBe("/fx");
    expect(file.app).toBe("fx");
  });

  // U151
  it("U151: a pattern with look-ahead fails", async () => {
    const result = await run([item()], {
      A: simple({ properties: { x: { type: "string", pattern: "^(?=a)b$" } } }),
    });
    expect(result.status).toBe(1);
    expect(result.stderr).toContain("fx.thing.created");
    expect(result.stderr).toContain("look-around");
  });

  // U152
  it("U152: a schema over 64 KiB fails, and a depth over 32 fails", async () => {
    const large = await run([item()], {
      A: simple({ description: "d".repeat(70000) }),
    });
    expect(large.status).toBe(1);
    expect(large.stderr).toContain("fx.thing.created");
    expect(large.stderr).toContain("maximum is 65536");

    const deep = await run([item()], { A: nested(32) });
    expect(deep.status).toBe(1);
    expect(deep.stderr).toContain("fx.thing.created");
    expect(deep.stderr).toContain("depth is 33");

    const fits = await run([item()], { A: nested(31) });
    expect(fits.stderr).toBe("");
    expect(fits.status).toBe(0);
  });

  // U152, the walk rule: values of const, enum, and default are not schemas
  it("U152: the depth check does not go into const, enum, or default", async () => {
    const hidden = nested(40);
    const result = await run([item()], {
      A: simple({
        properties: { x: { enum: [hidden], default: hidden, const: hidden } },
      }),
    });
    expect(result.stderr).toBe("");
    expect(result.status).toBe(0);
  });

  // U153
  it("U153: two runs make the same bytes", async () => {
    const schemas = { A: simple(), B: simple() };
    const list = [item(), item("fx.thing.updated", "B")];
    const first = await run(list, schemas);
    const second = await run(list, schemas);
    expect(first.status).toBe(0);
    const a = await readFile(join(first.out, "fx.event-types.json"));
    const b = await readFile(join(second.out, "fx.event-types.json"));
    expect(a.equals(b)).toBe(true);
    expect(a.includes("\r")).toBe(false);
  });

  // U154
  it("U154: bad lists fail with the type and the rule", async () => {
    const schemas = { A: simple() };
    const cases: [string, Item[], Record<string, Doc>, string, string][] = [
      ["duplicate type", [item(), item()], schemas, "fx.thing.created", "more than one time"],
      ["wrong prefix", [item("other.thing.created")], schemas, "other.thing.created", "must start with fx."],
      [
        "empty description",
        [{ ...item(), description: "" }],
        schemas,
        "fx.thing.created",
        "1 to 1024 characters",
      ],
      ["no emitter output", [item("fx.thing.created", "Missing")], schemas, "fx.thing.created", "no emitter output"],
      [
        "open schema",
        [item()],
        { A: { type: "object", properties: { x: { type: "string" } } } },
        "fx.thing.created",
        "not closed",
      ],
      [
        "remote ref",
        [item()],
        { A: simple({ properties: { x: { $ref: "https://example.com/x.json" } } }) },
        "fx.thing.created",
        "no emitter output",
      ],
    ];
    for (const [name, list, files, type, rule] of cases) {
      const result = await run(list, files);
      expect(result.status, name).toBe(1);
      expect(result.stderr, name).toContain(type);
      expect(result.stderr, name).toContain(rule);
    }
  });
});
