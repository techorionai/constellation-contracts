// Make the event type registration file of each service that publishes typed events.
//
// Input:  services/<svc>/events/event-types.json (a list of type, description, data)
//         tsp-output/json-schema/<Model>.json (output of @typespec/json-schema)
// Output: generated/event-types/<svc>.event-types.json (EventTypeRegistration format)
//
// The rules are the rules of the events service (docs/conventions.md, "Typed event data").
// The walk rule (which keywords the checks go into, and the depth) must be equal to the
// schema depth rule of constellation-platform-go and constellation-events.
//
// Options: --services <dir>, --schemas <dir>, --out <dir>. The defaults are the folders of this repository.
import Ajv2020 from "ajv/dist/2020.js";
import { mkdir, readdir, readFile, writeFile } from "node:fs/promises";
import { basename, dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const root = resolve(dirname(fileURLToPath(import.meta.url)), "..");
const draft = "https://json-schema.org/draft/2020-12/schema";
const maxSchemaBytes = 64 * 1024;
const maxDepth = 32;

/** Keywords with one schema as value. */
const schemaKeywords = [
  "items",
  "additionalItems",
  "additionalProperties",
  "unevaluatedItems",
  "unevaluatedProperties",
  "contains",
  "propertyNames",
  "not",
  "if",
  "then",
  "else",
  "contentSchema",
];
/** Keywords with a list of schemas as value. */
const schemaListKeywords = ["allOf", "anyOf", "oneOf", "prefixItems", "items"];
/** Keywords with a map of schemas as value. */
const schemaMapKeywords = [
  "properties",
  "patternProperties",
  "$defs",
  "definitions",
  "dependentSchemas",
];

const isObject = (value) =>
  value !== null && typeof value === "object" && !Array.isArray(value);

/**
 * Call visit(schema, depth) for the schema and for each subschema.
 * The root has depth 1. Each step into a member of a keyword adds 1.
 * The walk does not go into const, enum, default, examples, or unknown keywords.
 */
function walk(schema, visit, depth = 1) {
  if (!isObject(schema)) return;
  visit(schema, depth);
  for (const key of schemaKeywords) {
    if (isObject(schema[key])) walk(schema[key], visit, depth + 1);
  }
  for (const key of schemaListKeywords) {
    if (Array.isArray(schema[key])) {
      for (const item of schema[key]) walk(item, visit, depth + 1);
    }
  }
  for (const key of schemaMapKeywords) {
    if (isObject(schema[key])) {
      for (const item of Object.values(schema[key])) walk(item, visit, depth + 1);
    }
  }
}

/** Sort the keys of all objects. Arrays keep their order. */
function sortKeys(value) {
  if (Array.isArray(value)) return value.map(sortKeys);
  if (isObject(value)) {
    return Object.fromEntries(
      Object.keys(value)
        .sort()
        .map((key) => [key, sortKeys(value[key])]),
    );
  }
  return value;
}

const stable = (value) => `${JSON.stringify(sortKeys(value), null, 2)}\n`;

const same = (a, b) => JSON.stringify(sortKeys(a)) === JSON.stringify(sortKeys(b));

/** Read one emitter output file. */
async function loadModel(schemaDir, file) {
  return JSON.parse(await readFile(join(schemaDir, file), "utf8"));
}

/**
 * Make one self-contained schema. Put each referenced schema into $defs.
 * Change each $ref to a local #/$defs/<name>. Delete each $id. Set $schema.
 * A problem throws an Error with the rule.
 */
async function bundle(schemaDir, modelName) {
  const file = `${modelName}.json`;
  let top;
  try {
    top = await loadModel(schemaDir, file);
  } catch {
    throw new Error(`the data model ${modelName} has no emitter output (add @jsonSchema)`);
  }
  const defs = {};

  const addDef = (name, schema) => {
    if (name in defs && !same(defs[name], schema)) {
      throw new Error(`two different schemas have the name ${name} in $defs`);
    }
    defs[name] = schema;
  };

  const loaded = new Map();
  /** Hoist a schema file into $defs and return its local $ref. */
  const include = async (target, fragment) => {
    if (!loaded.has(target)) {
      let other;
      try {
        other = await loadModel(schemaDir, target);
      } catch {
        throw new Error(`the $ref target ${target} has no emitter output`);
      }
      loaded.set(target, other);
      const { $defs = {}, ...body } = other;
      delete body.$schema;
      for (const [name, def] of Object.entries($defs)) addDef(name, def);
      addDef(basename(target, ".json"), body);
      await fix(body);
      for (const def of Object.values($defs)) await fix(def);
    }
    if (fragment) return `#${fragment}`;
    return `#/$defs/${basename(target, ".json")}`;
  };

  /** Fix the $ref values and delete the $id values of one schema tree. */
  const fix = async (schema) => {
    const nodes = [];
    walk(schema, (node) => nodes.push(node));
    for (const node of nodes) {
      delete node.$id;
      if (typeof node.$ref === "string" && !node.$ref.startsWith("#")) {
        const [target, fragment = ""] = node.$ref.split("#");
        node.$ref = await include(target, fragment);
      }
    }
  };

  const { $defs = {}, ...body } = top;
  delete body.$schema;
  for (const [name, def] of Object.entries($defs)) addDef(name, def);
  await fix(body);
  for (const def of Object.values($defs)) await fix(def);
  const result = { $schema: draft, ...body };
  if (Object.keys(defs).length > 0) result.$defs = defs;
  return result;
}

/** Resolve a local JSON pointer ref against the root schema. */
function resolveLocal(schema, ref) {
  if (ref === "#") return schema;
  if (!ref.startsWith("#/")) return undefined;
  let node = schema;
  for (const raw of ref.slice(2).split("/")) {
    const part = decodeURIComponent(raw).replaceAll("~1", "/").replaceAll("~0", "~");
    if (node === null || typeof node !== "object" || !(part in node)) return undefined;
    node = node[part];
  }
  return node;
}

const lookaround = /\(\?(=|!|<=|<!)/;
const backReference = /\\[1-9]|\\k</;

/** Return the list of rule violations of one dataSchema. */
function checkSchema(schema) {
  const errors = [];
  if (!isObject(schema)) return ["the schema must be an object"];
  const bytes = Buffer.byteLength(JSON.stringify(schema));
  if (bytes > maxSchemaBytes) {
    errors.push(`the schema is ${bytes} bytes, the maximum is ${maxSchemaBytes}`);
  }
  let deepest = 0;
  walk(schema, (node, depth) => {
    deepest = Math.max(deepest, depth);
    if ("$id" in node) errors.push("the schema has $id");
    for (const key of ["$ref", "$dynamicRef"]) {
      if (key in node) {
        if (typeof node[key] !== "string" || !node[key].startsWith("#")) {
          errors.push(`${key} is not local: ${node[key]}`);
        } else if (key === "$ref" && resolveLocal(schema, node[key]) === undefined) {
          errors.push(`${key} does not resolve: ${node[key]}`);
        }
      }
    }
    const patterns = [];
    if (typeof node.pattern === "string") patterns.push(node.pattern);
    if (isObject(node.patternProperties)) patterns.push(...Object.keys(node.patternProperties));
    for (const pattern of patterns) {
      if (lookaround.test(pattern)) errors.push(`the pattern has look-around: ${pattern}`);
      if (backReference.test(pattern)) errors.push(`the pattern has a back reference: ${pattern}`);
    }
    const objectType =
      node.type === "object" || (Array.isArray(node.type) && node.type.includes("object"));
    if (objectType || isObject(node.properties)) {
      const closed = ["unevaluatedProperties", "additionalProperties"].some(
        (key) => node[key] === false || (isObject(node[key]) && same(node[key], { not: {} })),
      );
      if (!closed) errors.push("an object schema is not closed (unevaluatedProperties)");
    }
  });
  if (deepest > maxDepth) {
    errors.push(`the depth is ${deepest}, the maximum is ${maxDepth}`);
  }
  if (errors.length === 0) {
    try {
      new Ajv2020({ strict: true, validateFormats: false }).compile(schema);
    } catch (error) {
      errors.push(`the schema does not compile: ${error.message}`);
    }
  }
  return [...new Set(errors)];
}

/** Return the list of rule violations of one event type list. */
function checkList(service, list) {
  const errors = [];
  if (!Array.isArray(list) || list.length < 1 || list.length > 200) {
    errors.push(["(list)", "eventTypes must have 1 to 200 items"]);
    return errors;
  }
  const seen = new Set();
  for (const item of list) {
    const type = String(item?.type);
    if (!type.startsWith(`${service}.`)) {
      errors.push([type, `the type must start with ${service}.`]);
    }
    if (seen.has(type)) errors.push([type, "the type occurs more than one time"]);
    seen.add(type);
    const description = item?.description;
    if (typeof description !== "string" || [...description].length < 1 || [...description].length > 1024) {
      errors.push([type, "the description must have 1 to 1024 characters"]);
    }
    if (typeof item?.data !== "string" || item.data === "") {
      errors.push([type, "the data model name is missing"]);
    }
  }
  return errors;
}

function parseArgs(argv) {
  const options = {
    services: join(root, "services"),
    schemas: join(root, "tsp-output", "json-schema"),
    out: join(root, "generated", "event-types"),
  };
  for (let i = 0; i < argv.length; i += 2) {
    const name = argv[i]?.replace(/^--/, "");
    if (!(name in options) || argv[i + 1] === undefined) {
      throw new Error(`unknown option: ${argv[i]}`);
    }
    options[name] = resolve(argv[i + 1]);
  }
  return options;
}

async function main() {
  const options = parseArgs(process.argv.slice(2));
  const failures = [];
  const outputs = [];
  const services = (await readdir(options.services, { withFileTypes: true }))
    .filter((entry) => entry.isDirectory())
    .map((entry) => entry.name)
    .sort();
  for (const service of services) {
    let list;
    try {
      list = JSON.parse(
        await readFile(join(options.services, service, "events", "event-types.json"), "utf8"),
      );
    } catch (error) {
      if (error.code === "ENOENT") continue;
      throw error;
    }
    const listErrors = checkList(service, list);
    for (const [type, rule] of listErrors) failures.push(`${service}: ${type}: ${rule}`);
    if (listErrors.length > 0) continue;
    const eventTypes = [];
    for (const item of list) {
      let dataSchema;
      try {
        dataSchema = await bundle(options.schemas, item.data);
      } catch (error) {
        failures.push(`${service}: ${item.type}: ${error.message}`);
        continue;
      }
      const errors = checkSchema(dataSchema);
      for (const rule of errors) failures.push(`${service}: ${item.type}: ${rule}`);
      eventTypes.push({ type: item.type, description: item.description, dataSchema });
    }
    outputs.push([service, { source: `/${service}`, app: service, eventTypes }]);
  }
  if (failures.length > 0) {
    for (const line of failures) console.error(`event-types: ${line}`);
    process.exit(1);
  }
  await mkdir(options.out, { recursive: true });
  for (const [service, registration] of outputs) {
    await writeFile(join(options.out, `${service}.event-types.json`), stable(registration));
  }
}

main().catch((error) => {
  console.error(`event-types: ${error.message}`);
  process.exit(1);
});
