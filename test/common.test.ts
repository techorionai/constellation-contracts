import SwaggerParser from "@apidevtools/swagger-parser";
import { join } from "node:path";
import { beforeAll, describe, expect, it } from "vitest";
import {
  commonFile,
  compileEntry,
  loadCommon,
  root,
  type CompileResult,
  type Doc,
} from "./helpers.js";

describe("root project", () => {
  let result: CompileResult;
  let common: Doc;

  beforeAll(async () => {
    result = await compileEntry(join(root, "main.tsp"), false);
    common = await loadCommon();
  });

  // U1
  it("U1: compiles with warnings as errors and has no diagnostics", () => {
    expect(result.diagnostics).toEqual([]);
  });

  // U2
  it("U2: the common file is a valid OpenAPI 3.0.0 document with no paths", async () => {
    const api = await SwaggerParser.validate(commonFile);
    expect(api.openapi).toBe("3.0.0");
    expect(Object.keys(api.paths ?? {})).toEqual([]);
  });

  // U3
  it("U3: the common file has the shared schemas", () => {
    const names = Object.keys(common.components.schemas);
    for (const name of [
      "Problem",
      "FieldError",
      "CloudEventEnvelope",
      "LinkTemplate",
      "LinkTemplateSet",
      "PermissionManifest",
      "PermissionDefinition",
      "RoleDefinition",
      "EventTypeRegistration",
      "EventTypeDefinition",
      "AuditEntryData",
      "AuditTarget",
      "AuditResult",
      "AuditTargetType",
      "AuditRecordedEvent",
    ]) {
      expect(names).toContain(name);
    }
  });
});
