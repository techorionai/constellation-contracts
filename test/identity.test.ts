import SwaggerParser from "@apidevtools/swagger-parser";
import { readFile } from "node:fs/promises";
import { join } from "node:path";
import { parse } from "yaml";
import { beforeAll, describe, expect, it } from "vitest";
import {
  loadCommon,
  resolveRef,
  root,
  schemaValidator,
  type Doc,
} from "./helpers.js";

const identityFile = join(
  root,
  "generated",
  "openapi",
  "Constellation.Identity.openapi.yaml",
);

async function examples(name: string): Promise<{
  valid: unknown[];
  invalid: unknown[];
}> {
  return JSON.parse(
    await readFile(join(root, "test", "examples", name), "utf8"),
  );
}

/** Operation ID, method, path, success status, and scope of each /v1 operation. */
const rest: [string, string, string, string, string[]][] = [
  ["PermissionManifests_publish", "put", "/v1/permission-manifests/{app}", "200", ["identity:manifest:publish"]],
  ["PermissionManifests_list", "get", "/v1/permission-manifests", "200", ["identity:role:read"]],
  ["PermissionManifests_get", "get", "/v1/permission-manifests/{app}", "200", ["identity:role:read"]],
  ["Roles_list", "get", "/v1/roles", "200", ["identity:role:read"]],
  ["Roles_get", "get", "/v1/roles/{role}", "200", ["identity:role:read"]],
  ["Users_create", "post", "/v1/users", "201", ["identity:user:write"]],
  ["Users_list", "get", "/v1/users", "200", ["identity:user:read"]],
  ["Users_get", "get", "/v1/users/{userId}", "200", ["identity:user:read"]],
  ["Users_update", "patch", "/v1/users/{userId}", "200", ["identity:user:write"]],
  ["Me_get", "get", "/v1/me", "200", []],
  ["Invites_create", "post", "/v1/users/{userId}/invites", "201", ["identity:user:write"]],
  ["UserRoles_list", "get", "/v1/users/{userId}/roles", "200", ["identity:role:read"]],
  ["UserRoles_assign", "put", "/v1/users/{userId}/roles/{role}", "200", ["identity:role:assign"]],
  ["UserRoles_remove", "delete", "/v1/users/{userId}/roles/{role}", "204", ["identity:role:assign"]],
  ["Clients_create", "post", "/v1/clients", "201", ["identity:client:write"]],
  ["Clients_list", "get", "/v1/clients", "200", ["identity:client:read"]],
  ["Clients_get", "get", "/v1/clients/{clientId}", "200", ["identity:client:read"]],
  ["Clients_update", "patch", "/v1/clients/{clientId}", "200", ["identity:client:write"]],
  ["ClientKeys_add", "post", "/v1/clients/{clientId}/keys", "201", ["identity:client:write"]],
  ["ClientKeys_remove", "delete", "/v1/clients/{clientId}/keys/{kid}", "204", ["identity:client:write"]],
  ["ClientRoles_list", "get", "/v1/clients/{clientId}/roles", "200", ["identity:role:read"]],
  ["ClientRoles_assign", "put", "/v1/clients/{clientId}/roles/{role}", "200", ["identity:role:assign"]],
  ["ClientRoles_remove", "delete", "/v1/clients/{clientId}/roles/{role}", "204", ["identity:role:assign"]],
  ["Sessions_list", "get", "/v1/users/{userId}/sessions", "200", ["identity:session:read"]],
  ["Sessions_revoke", "delete", "/v1/sessions/{sessionId}", "204", ["identity:session:revoke"]],
  ["Sessions_revokeAll", "delete", "/v1/users/{userId}/sessions", "204", ["identity:session:revoke"]],
];

/** The OAuth and discovery operations. */
const oauth: [string, string, string, string][] = [
  ["Discovery_openidConfiguration", "get", "/.well-known/openid-configuration", "200"],
  ["Discovery_jwks", "get", "/.well-known/jwks.json", "200"],
  ["OAuth_token", "post", "/oauth/token", "200"],
  ["OAuth_revoke", "post", "/oauth/revoke", "200"],
  ["OAuth_userinfo", "get", "/oauth/userinfo", "200"],
  ["OAuth_authorize", "get", "/oauth/authorize", "200"],
  ["OAuth_endSession", "get", "/oauth/end_session", "200"],
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

/** The security requirements of an operation. An operation overrides the global list. */
function effectiveSecurity(doc: Doc, op: Doc): Doc[] {
  return op.security ?? doc.security ?? [];
}

describe("identity contract", () => {
  let doc: Doc;
  let ops: Operation[];
  let byId: Record<string, Operation>;
  let check: (name: string) => (value: unknown) => boolean;
  let checkCommon: (name: string) => (value: unknown) => boolean;

  beforeAll(async () => {
    doc = parse(await readFile(identityFile, "utf8"));
    ops = operations(doc);
    byId = Object.fromEntries(ops.map((o) => [o.id, o]));
    check = schemaValidator(doc, "identity.openapi");
    checkCommon = schemaValidator(await loadCommon(), "common.openapi");
  });

  // U21
  it("U21: the OpenAPI file is valid", async () => {
    await SwaggerParser.validate(identityFile);
  });

  // U22
  it("U22: paths, operation IDs, and success statuses", () => {
    const expected = [
      ...oauth.map(([id, method, path, status]) => ({ id, method, path, status })),
      ...rest.map(([id, method, path, status]) => ({ id, method, path, status })),
    ];
    expect(ops.map((o) => o.id).sort()).toEqual(
      expected.map((e) => e.id).sort(),
    );
    for (const e of expected) {
      const found = byId[e.id];
      expect(found.method, e.id).toBe(e.method);
      expect(found.path, e.id).toBe(e.path);
      expect(found.op.responses[e.status], e.id).toBeDefined();
    }
    expect(byId["Me_get"].path).toBe("/v1/me");
  });

  // U23
  it("U23: the token and revoke bodies are form bodies and errors are OAuthError", () => {
    for (const id of ["OAuth_token", "OAuth_revoke"]) {
      const content = byId[id].op.requestBody.content;
      expect(Object.keys(content), id).toEqual([
        "application/x-www-form-urlencoded",
      ]);
      for (const [status, response] of Object.entries<Doc>(
        byId[id].op.responses,
      )) {
        if (status === "200") continue;
        expect(Object.keys(response.content), `${id} ${status}`).toEqual([
          "application/json",
        ]);
        expect(response.content["application/json"].schema).toEqual({
          $ref: "#/components/schemas/OAuthError",
        });
      }
    }
    const revoke = resolveRef(
      doc,
      byId["OAuth_revoke"].op.requestBody.content[
        "application/x-www-form-urlencoded"
      ].schema,
    );
    expect(revoke.required).toEqual(["token"]);
    expect(revoke.properties.token_type_hint).toBeDefined();
  });

  // U24
  it("U24: discovery and OAuth operations have no security and no /v1 prefix", () => {
    for (const id of [
      "Discovery_openidConfiguration",
      "Discovery_jwks",
      "OAuth_token",
      "OAuth_revoke",
      "OAuth_authorize",
      "OAuth_endSession",
    ]) {
      const found = byId[id];
      expect(found.path.startsWith("/v1"), id).toBe(false);
      const security: Doc[] = effectiveSecurity(doc, found.op);
      for (const requirement of security) {
        expect(Object.keys(requirement), id).toEqual([]);
      }
    }
  });

  // U24a
  it("U24a: userinfo uses BearerAuth with no scopes", () => {
    const found = byId["OAuth_userinfo"];
    expect(found.path.startsWith("/v1")).toBe(false);
    expect(effectiveSecurity(doc, found.op)).toEqual([{ BearerAuth: [] }]);
    expect(found.op["x-required-scopes"]).toBeUndefined();
    const header = found.op.responses["401"].headers["WWW-Authenticate"];
    expect(header).toBeDefined();
    expect(found.op.responses["401"].content).toBeUndefined();
  });

  // U25
  it("U25: /v1 operations use BearerAuth and Problem errors", () => {
    const v1 = ops.filter((o) => o.path.startsWith("/v1"));
    expect(v1.length).toBe(rest.length);
    expect(doc.components.securitySchemes.BearerAuth).toMatchObject({
      type: "http",
      scheme: "Bearer",
    });
    for (const o of v1) {
      expect(effectiveSecurity(doc, o.op), o.id).toEqual([{ BearerAuth: [] }]);
      for (const [status, response] of Object.entries<Doc>(o.op.responses)) {
        if (Number(status) < 400) continue;
        expect(Object.keys(response.content), `${o.id} ${status}`).toEqual([
          "application/problem+json",
        ]);
      }
    }
  });

  // U25a
  it("U25a: x-required-scopes of each /v1 operation", async () => {
    const manifest = JSON.parse(
      await readFile(join(root, "services", "identity", "manifest.json"), "utf8"),
    );
    const keys = new Set(manifest.permissions.map((p: Doc) => p.key));
    for (const [id, , , , scopes] of rest) {
      const value = byId[id].op["x-required-scopes"];
      expect(value, id).toEqual(scopes);
      for (const scope of value) expect(keys.has(scope), scope).toBe(true);
    }
    expect(byId["Me_get"].op["x-required-scopes"]).toEqual([]);
  });

  // U26
  it("U26: list operations have page parameters and a page result", () => {
    const lists = ops.filter((o) => o.id.endsWith("_list"));
    expect(lists.length).toBe(7);
    for (const o of lists) {
      const names = (o.op.parameters as Doc[]).map(
        (p) => resolveRef(doc, p).name,
      );
      expect(names, o.id).toContain("pageToken");
      expect(names, o.id).toContain("pageSize");
      const page = resolveRef(
        doc,
        o.op.responses["200"].content["application/json"].schema,
      );
      expect(page.required, o.id).toContain("items");
      expect(page.properties.nextPageToken, o.id).toBeDefined();
    }
  });

  // U27
  it("U27: token request examples", async () => {
    const validate = check("TokenRequest");
    const { valid, invalid } = await examples("token-request.json");
    for (const value of valid) expect(validate(value)).toBe(true);
    invalid.forEach((value, i) =>
      expect(validate(value), `invalid example ${i}`).toBe(false),
    );
  });

  // U28
  it("U28: key set examples and private fields", async () => {
    const validate = check("JsonWebKeySet");
    const { valid, invalid } = await examples("jwks.json");
    for (const value of valid) expect(validate(value)).toBe(true);
    invalid.forEach((value, i) =>
      expect(validate(value), `invalid example ${i}`).toBe(false),
    );
    const key = (valid[0] as Doc).keys[0];
    for (const field of ["d", "p", "q", "dp", "dq", "qi", "k"]) {
      expect(validate({ keys: [{ ...key, [field]: "x" }] }), field).toBe(false);
    }
  });

  // U29
  it("U29: access token claims examples", async () => {
    const validate = checkCommon("AccessTokenClaims");
    const { valid, invalid } = await examples("access-token-claims.json");
    for (const value of valid) expect(validate(value)).toBe(true);
    invalid.forEach((value, i) =>
      expect(validate(value), `invalid example ${i}`).toBe(false),
    );
  });

  // U30
  it("U30: RoleRef pattern", () => {
    const validate = checkCommon("RoleRef");
    expect(validate("helpdesk:agent")).toBe(true);
    for (const bad of ["helpdesk", "Helpdesk:agent", "a:b:c"]) {
      expect(validate(bad), bad).toBe(false);
    }
  });

  // U32
  it("U32: Invite.url is a password and ClientKey.jwk shares the key schema", () => {
    expect(doc.components.schemas.Invite.properties.url.format).toBe("password");
    expect(
      doc.components.schemas.ClientKey.properties.jwk.allOf,
    ).toEqual([{ $ref: "#/components/schemas/JsonWebKey" }]);
    expect(doc.components.schemas.JsonWebKeySet.properties.keys.items).toEqual({
      $ref: "#/components/schemas/JsonWebKey",
    });
  });

  // U33
  it("U33: OAuthError.error is an open union", () => {
    const validate = check("OAuthError");
    expect(validate({ error: "invalid_grant" })).toBe(true);
    expect(validate({ error: "slow_down" })).toBe(true);
    expect(validate({ error_description: "No error." })).toBe(false);
  });

  // U34
  it("U34: error unions of the 409 and 422 table", () => {
    const conflict: string[] = [
      "Users_create",
      "Users_update",
      "UserRoles_remove",
      "Clients_update",
      "ClientKeys_add",
      "ClientKeys_remove",
      "ClientRoles_assign",
      "ClientRoles_remove",
      "Invites_create",
    ];
    const unprocessable: string[] = [
      "PermissionManifests_publish",
      "UserRoles_assign",
      "ClientRoles_assign",
      "Clients_create",
      "Clients_update",
      "ClientKeys_add",
      "ClientRoles_list",
      "ClientRoles_remove",
    ];
    for (const id of conflict) {
      expect(byId[id].op.responses["409"], id).toBeDefined();
    }
    for (const id of unprocessable) {
      expect(byId[id].op.responses["422"], id).toBeDefined();
    }
  });

  // U35
  it("U35: the manifest file", async () => {
    const manifest = JSON.parse(
      await readFile(join(root, "services", "identity", "manifest.json"), "utf8"),
    );
    expect(checkCommon("PermissionManifest")(manifest)).toBe(true);
    expect(manifest.app).toBe("identity");
    const keys: string[] = manifest.permissions.map((p: Doc) => p.key);
    for (const key of keys) expect(key.startsWith("identity:")).toBe(true);
    expect(new Set(keys).size).toBe(keys.length);
    const roleKeys: string[] = manifest.defaultRoles.map((r: Doc) => r.key);
    expect(new Set(roleKeys).size).toBe(roleKeys.length);
    for (const role of manifest.defaultRoles) {
      for (const key of role.permissions) expect(keys).toContain(key);
    }
    expect(keys.sort()).toEqual(
      [
        "user:read",
        "user:write",
        "role:read",
        "role:assign",
        "client:read",
        "client:write",
        "session:read",
        "session:revoke",
        "manifest:publish",
      ]
        .map((k) => `identity:${k}`)
        .sort(),
    );
    const admin = manifest.defaultRoles.find((r: Doc) => r.key === "admin");
    expect([...admin.permissions].sort()).toEqual([...keys].sort());
    const service = manifest.defaultRoles.find((r: Doc) => r.key === "service");
    expect(service.permissions).toEqual(["identity:manifest:publish"]);
  });

  // U36
  it("U36: DiscoveryDocument and UserInfo", async () => {
    const discovery = doc.components.schemas.DiscoveryDocument;
    for (const field of [
      "issuer",
      "authorization_endpoint",
      "token_endpoint",
      "jwks_uri",
      "userinfo_endpoint",
      "revocation_endpoint",
      "end_session_endpoint",
      "response_types_supported",
      "grant_types_supported",
      "subject_types_supported",
      "id_token_signing_alg_values_supported",
      "scopes_supported",
      "token_endpoint_auth_methods_supported",
      "token_endpoint_auth_signing_alg_values_supported",
      "code_challenge_methods_supported",
    ]) {
      expect(discovery.properties[field], field).toBeDefined();
    }
    const userinfo = doc.components.schemas.UserInfo;
    for (const field of ["sub", "email", "email_verified", "name"]) {
      expect(userinfo.properties[field], field).toBeDefined();
    }
    const validate = check("DiscoveryDocument");
    const { valid, invalid } = await examples("discovery.json");
    for (const value of valid) expect(validate(value)).toBe(true);
    for (const value of invalid) expect(validate(value)).toBe(false);
  });

  // U37
  it("U37: RoleAssignment and Client", () => {
    const assignment = doc.components.schemas.RoleAssignment;
    for (const field of ["role", "source", "pending"]) {
      expect(assignment.properties[field], field).toBeDefined();
    }
    const client = doc.components.schemas.Client;
    expect(client.properties.source).toBeDefined();
    expect(client.properties.app).toBeDefined();
    expect(client.required).toContain("app");
  });
});
