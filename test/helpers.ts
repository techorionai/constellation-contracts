import { compile, NodeHost, resolveCompilerOptions } from "@typespec/compiler";
import Ajv from "ajv";
import addFormats from "ajv-formats";
import { mkdtemp, readdir, readFile, rm } from "node:fs/promises";
import { tmpdir } from "node:os";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { parse } from "yaml";

export const root = resolve(dirname(fileURLToPath(import.meta.url)), "..");
export const commonFile = join(
  root,
  "generated",
  "openapi",
  "Constellation.Common.openapi.yaml",
);

/** A JSON value from a parsed OpenAPI file. */
export type Doc = any;

export interface CompileResult {
  diagnostics: string[];
  files: Record<string, Doc>;
}

/**
 * Compile a TypeSpec entry point with the options of tspconfig.yaml.
 * The OpenAPI files and the JSON Schema files go to a temporary folder. Warnings are errors.
 */
export async function compileEntry(
  entrypoint: string,
  emit = true,
): Promise<CompileResult> {
  const [options] = await resolveCompilerOptions(NodeHost, {
    cwd: root,
    entrypoint,
    configPath: join(root, "tspconfig.yaml"),
  });
  const outDir = await mkdtemp(join(tmpdir(), "contracts-"));
  try {
    const emitter = options.options?.["@typespec/openapi3"] ?? {};
    emitter["emitter-output-dir"] = outDir;
    const jsonSchema = options.options?.["@typespec/json-schema"] ?? {};
    jsonSchema["emitter-output-dir"] = join(outDir, "json-schema");
    options.options = {
      ...options.options,
      "@typespec/openapi3": emitter,
      "@typespec/json-schema": jsonSchema,
    };
    options.noEmit = !emit;
    options.warningAsError = true;
    const program = await compile(NodeHost, entrypoint, options);
    const diagnostics = program.diagnostics.map(
      (d) => `${d.severity} ${d.code}: ${d.message}`,
    );
    const files: Record<string, Doc> = {};
    if (emit) {
      for (const name of await readdir(outDir)) {
        if (name === "json-schema") continue;
        files[name] = parse(await readFile(join(outDir, name), "utf8"));
      }
    }
    return { diagnostics, files };
  } finally {
    await rm(outDir, { recursive: true, force: true });
  }
}

export async function loadCommon(): Promise<Doc> {
  return parse(await readFile(commonFile, "utf8"));
}

/** Make an Ajv instance that can check the schemas of an OpenAPI 3.0 document. */
export function makeAjv(): Ajv {
  const ajv = new Ajv({ strict: true, allErrors: true });
  addFormats(ajv);
  ajv.addFormat("int32", true);
  ajv.addFormat("int64", true);
  for (const keyword of ["openapi", "info", "tags", "paths", "components", "security"]) {
    ajv.addKeyword(keyword);
  }
  return ajv;
}

/** A function that checks a value against a schema of an OpenAPI document. */
export function schemaValidator(
  doc: Doc,
  id: string,
): (name: string) => (value: unknown) => boolean {
  const ajv = makeAjv();
  ajv.addSchema(doc, id);
  return (name) => {
    const validate = ajv.getSchema(`${id}#/components/schemas/${name}`);
    if (!validate) throw new Error(`Schema not found: ${name}`);
    return (value) => validate(value) as boolean;
  };
}

/** Resolve a local $ref of the document. */
export function resolveRef(doc: Doc, node: Doc): Doc {
  if (node && typeof node.$ref === "string") {
    let target = doc;
    for (const part of node.$ref.replace(/^#\//, "").split("/")) {
      target = target[part];
    }
    return target;
  }
  return node;
}

/** Compile the pagination fixture. */
export async function loadPagingFixture(): Promise<{
  diagnostics: string[];
  doc: Doc;
}> {
  const result = await compileEntry(
    join(root, "test", "fixtures", "paging", "main.tsp"),
  );
  return {
    diagnostics: result.diagnostics,
    doc: result.files["Fixture.Paging.openapi.yaml"],
  };
}
