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
import { basename, dirname, isAbsolute, join, relative, resolve } from "node:path";
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
/**
 * Keywords with a list of schemas as value.
 * `items` is in this list and in the list above on purpose. A value of `items` can be one schema
 * (2020-12) or a list of schemas (older drafts). The Go services (constellation-events and
 * constellation-platform-go) have the same two entries. Keep the three lists equal to them.
 */
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

const escapePointer = (name) => name.replaceAll("~", "~0").replaceAll("/", "~1");

/**
 * Call visit(schema, depth, pointer) for the schema and for each subschema.
 * The pointer is the JSON Pointer of the subschema. The root pointer is the empty string.
 * The root has depth 1. Each step into a member of a keyword adds 1.
 * The walk does not go into const, enum, default, examples, or unknown keywords.
 */
function walk(schema, visit, depth = 1, pointer = "") {
  if (!isObject(schema)) return;
  visit(schema, depth, pointer);
  for (const key of schemaKeywords) {
    if (isObject(schema[key])) walk(schema[key], visit, depth + 1, `${pointer}/${key}`);
  }
  for (const key of schemaListKeywords) {
    if (Array.isArray(schema[key])) {
      schema[key].forEach((item, index) =>
        walk(item, visit, depth + 1, `${pointer}/${key}/${index}`),
      );
    }
  }
  for (const key of schemaMapKeywords) {
    if (isObject(schema[key])) {
      for (const [name, item] of Object.entries(schema[key])) {
        walk(item, visit, depth + 1, `${pointer}/${key}/${escapePointer(name)}`);
      }
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

const modelNamePattern = /^[A-Za-z_][A-Za-z0-9_]*$/;
const modelFilePattern = /^[A-Za-z_][A-Za-z0-9_]*\.json$/;

/** Read one emitter output file. The file must be in the schema folder. */
async function loadModel(schemaDir, file) {
  const path = resolve(schemaDir, file);
  const inside = relative(resolve(schemaDir), path);
  if (inside === "" || inside.startsWith("..") || isAbsolute(inside)) {
    throw new Error(`the model file ${file} is not in the schema folder`);
  }
  return JSON.parse(await readFile(path, "utf8"));
}

/** Read one model file. A missing file gives the message. Any other error goes up. */
async function readModel(schemaDir, file, message) {
  try {
    return await loadModel(schemaDir, file);
  } catch (error) {
    if (error.code === "ENOENT") throw new Error(message);
    throw error;
  }
}

/**
 * Make one self-contained schema. Put each referenced schema into $defs.
 * Change each $ref to a local #/$defs/<name>. Delete each $id. Set $schema.
 * A problem throws an Error with the rule.
 */
async function bundle(schemaDir, dataModel) {
  const top = await readModel(
    schemaDir,
    `${dataModel}.json`,
    `the data model ${dataModel} has no emitter output (add @jsonSchema)`,
  );
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
    if (!modelFilePattern.test(target)) {
      throw new Error(`the $ref target ${target} is not a model file of the emitter output`);
    }
    if (!loaded.has(target)) {
      const other = await readModel(
        schemaDir,
        target,
        `the $ref target ${target} has no emitter output`,
      );
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

/**
 * Find look-around and back references in a pattern. The scan skips escaped characters
 * and the inside of character classes, because they are text and not syntax.
 */
function scanPattern(pattern) {
  const found = new Set();
  let inClass = false;
  for (let i = 0; i < pattern.length; i++) {
    const c = pattern[i];
    if (c === "\\") {
      const next = pattern[i + 1] ?? "";
      if (!inClass && (/[1-9]/.test(next) || (next === "k" && pattern[i + 2] === "<"))) {
        found.add("a back reference");
      }
      i++;
    } else if (inClass) {
      if (c === "]") inClass = false;
    } else if (c === "[") {
      inClass = true;
      if (pattern[i + 1] === "^") i++;
      if (pattern[i + 1] === "]") i++;
    } else if (c === "(" && pattern[i + 1] === "?") {
      const rest = pattern.slice(i + 2, i + 4);
      if (rest[0] === "=" || rest[0] === "!" || rest === "<=" || rest === "<!") {
        found.add("look-around");
      }
    }
  }
  return found;
}

/**
 * Equal to checkRef of the events service. A reference must point to an examined subschema
 * (by JSON Pointer) or to the name of an $anchor or $dynamicAnchor of an examined subschema.
 */
function refTargetExists(ref, pointers, anchors) {
  let fragment;
  try {
    fragment = decodeURIComponent(ref.slice(1));
  } catch {
    return false;
  }
  if (fragment !== "" && !fragment.startsWith("/")) return anchors.has(fragment);
  return pointers.has(fragment);
}

/** Return the list of rule violations of one dataSchema. Ajv compiles the schema after the rules. */
export function checkSchema(schema) {
  const errors = checkRules(schema);
  if (errors.length === 0) {
    try {
      new Ajv2020({ strict: true, validateFormats: false }).compile(schema);
    } catch (error) {
      errors.push(`the schema does not compile: ${error.message}`);
    }
  }
  return errors;
}

/** Return the list of rule violations of the events service for one dataSchema. */
export function checkRules(schema) {
  const errors = [];
  if (!isObject(schema)) return ["the schema must be an object"];
  const bytes = Buffer.byteLength(JSON.stringify(schema));
  if (bytes > maxSchemaBytes) {
    errors.push(`the schema is ${bytes} bytes, the maximum is ${maxSchemaBytes}`);
  }
  let deepest = 0;
  const pointers = new Set();
  const anchors = new Set();
  const refs = [];
  walk(schema, (node, depth, pointer) => {
    deepest = Math.max(deepest, depth);
    pointers.add(pointer);
    if ("$id" in node) errors.push("the schema has $id");
    for (const key of ["$anchor", "$dynamicAnchor"]) {
      if (typeof node[key] === "string") anchors.add(node[key]);
    }
    for (const key of ["$ref", "$dynamicRef"]) {
      if (key in node) {
        if (typeof node[key] !== "string" || !node[key].startsWith("#")) {
          errors.push(`${key} is not local: ${node[key]}`);
        } else {
          refs.push([key, node[key]]);
        }
      }
    }
    const patterns = [];
    if (typeof node.pattern === "string") patterns.push(node.pattern);
    if (isObject(node.patternProperties)) patterns.push(...Object.keys(node.patternProperties));
    for (const pattern of patterns) {
      for (const problem of scanPattern(pattern)) {
        errors.push(`the pattern has ${problem}: ${pattern}`);
      }
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
  for (const [key, ref] of refs) {
    if (!refTargetExists(ref, pointers, anchors)) {
      errors.push(`${key} does not point to an examined subschema or an anchor: ${ref}`);
    }
  }
  if (deepest > maxDepth) {
    errors.push(`the depth is ${deepest}, the maximum is ${maxDepth}`);
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
    if (typeof item?.data !== "string" || !modelNamePattern.test(item.data)) {
      errors.push([type, "the data model name is missing or has characters that are not allowed"]);
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

// Run main only when node starts this file. A test can import the check functions.
if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  main().catch((error) => {
    console.error(`event-types: ${error.message}`);
    process.exit(1);
  });
}
