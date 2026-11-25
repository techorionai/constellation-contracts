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
  ["Clients_create", "post", "/v1/clients", "201", ["identity:client:write", "identity:admin"]],
  ["Clients_list", "get", "/v1/clients", "200", ["identity:client:read"]],
  ["Clients_get", "get", "/v1/clients/{clientId}", "200", ["identity:client:read"]],
  ["Clients_update", "patch", "/v1/clients/{clientId}", "200", ["identity:client:write", "identity:admin"]],
  ["ClientKeys_add", "post", "/v1/clients/{clientId}/keys", "201", ["identity:client:write", "identity:admin"]],
  ["ClientKeys_remove", "delete", "/v1/clients/{clientId}/keys/{kid}", "204", ["identity:client:write", "identity:admin"]],
  ["ClientRoles_list", "get", "/v1/clients/{clientId}/roles", "200", ["identity:role:read"]],
  ["ClientRoles_assign", "put", "/v1/clients/{clientId}/roles/{role}", "200", ["identity:role:assign"]],
  ["ClientRoles_remove", "delete", "/v1/clients/{clientId}/roles/{role}", "204", ["identity:role:assign"]],
  ["Sessions_list", "get", "/v1/users/{userId}/sessions", "200", ["identity:session:read"]],
  ["Sessions_revoke", "delete", "/v1/sessions/{sessionId}", "204", ["identity:session:revoke"]],
  ["Sessions_revokeAll", "delete", "/v1/users/{userId}/sessions", "204", ["identity:session:revoke"]],
  ["MeApiTokens_create", "post", "/v1/me/api-tokens", "201", ["identity:api_token:manage_own"]],
  ["MeApiTokens_list", "get", "/v1/me/api-tokens", "200", ["identity:api_token:manage_own"]],
  ["MeApiTokens_revoke", "delete", "/v1/me/api-tokens/{tokenId}", "204", ["identity:api_token:manage_own"]],
  ["UserApiTokens_list", "get", "/v1/users/{userId}/api-tokens", "200", ["identity:api_token:read"]],
  ["ApiTokens_revoke", "delete", "/v1/api-tokens/{tokenId}", "204", ["identity:api_token:revoke"]],
  ["Agents_create", "post", "/v1/agents", "201", ["identity:agent:write", "identity:admin"]],
  ["Agents_list", "get", "/v1/agents", "200", ["identity:agent:read"]],
  ["Agents_get", "get", "/v1/agents/{agentId}", "200", ["identity:agent:read"]],
  ["Agents_update", "patch", "/v1/agents/{agentId}", "200", ["identity:agent:write", "identity:admin"]],
  ["AgentRoles_list", "get", "/v1/agents/{agentId}/roles", "200", ["identity:role:read"]],
  ["AgentRoles_assign", "put", "/v1/agents/{agentId}/roles/{role}", "200", ["identity:role:assign"]],
  ["AgentRoles_remove", "delete", "/v1/agents/{agentId}/roles/{role}", "204", ["identity:role:assign"]],
  ["MeMfa_get", "get", "/v1/me/mfa", "200", ["identity:mfa:manage_own"]],
  ["MeTotp_remove", "delete", "/v1/me/totp", "204", ["identity:mfa:manage_own"]],
  ["UserMfa_get", "get", "/v1/users/{userId}/mfa", "200", ["identity:user:read"]],
  ["UserMfa_reset", "delete", "/v1/users/{userId}/mfa", "204", ["identity:mfa:reset", "identity:admin"]],
];

/** The OAuth and discovery operations. */
const oauth: [string, string, string, string][] = [
  ["Discovery_openidConfiguration", "get", "/.well-known/openid-configuration", "200"],
  ["Discovery_jwks", "get", "/.well-known/jwks.json", "200"],
  ["OAuth_token", "post", "/oauth/token", "200"],
  ["OAuth_revoke", "post", "/oauth/revoke", "200"],
  ["OAuth_introspect", "post", "/oauth/introspect", "200"],
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

/** The operations that declare 429, by body family. */
const oauthLimited = ["OAuth_token", "OAuth_introspect", "OAuth_revoke", "OAuth_userinfo"];
const htmlLimited = ["OAuth_authorize", "OAuth_endSession"];
const jsonLimited = [
  "Discovery_jwks",
  "Discovery_openidConfiguration",
  "MeApiTokens_create",
  "PermissionManifests_publish",
];
const limited = [...oauthLimited, ...htmlLimited, ...jsonLimited];

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
          $ref:
            status === "429"
              ? "#/components/schemas/OAuthTooManyRequests"
              : "#/components/schemas/OAuthError",
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
      "OAuth_introspect",
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
    expect(lists.length).toBe(11);
    for (const id of ["MeApiTokens_list", "UserApiTokens_list", "Agents_list", "AgentRoles_list"]) {
      expect(lists.map((o) => o.id), id).toContain(id);
    }
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
        "admin",
        "session:read",
        "session:revoke",
        "manifest:publish",
        "api_token:manage_own",
        "api_token:read",
        "api_token:revoke",
        "mfa:manage_own",
        "mfa:reset",
        "agent:read",
        "agent:write",
        "token:exchange",
      ]
        .map((k) => `identity:${k}`)
        .sort(),
    );
    const admin = manifest.defaultRoles.find((r: Doc) => r.key === "admin");
    expect([...admin.permissions].sort()).toEqual([...keys].sort());
    const service = manifest.defaultRoles.find((r: Doc) => r.key === "service");
    expect(service.permissions).toEqual(["identity:manifest:publish"]);
    // U50
    const user = manifest.defaultRoles.find((r: Doc) => r.key === "user");
    expect(user.permissions).toEqual([
      "identity:api_token:manage_own",
      "identity:mfa:manage_own",
    ]);
    expect(
      manifest.permissions.find((p: Doc) => p.key === "identity:mfa:reset").description,
    ).toContain("also needs identity:admin");
    const exchangers = manifest.defaultRoles
      .filter((r: Doc) => r.permissions.includes("identity:token:exchange"))
      .map((r: Doc) => r.key);
    expect(exchangers).toEqual(["admin"]);
  });

  // U25b
  it("U25b: only the role admin has identity:admin", async () => {
    const manifest = JSON.parse(
      await readFile(join(root, "services", "identity", "manifest.json"), "utf8"),
    );
    expect(manifest.permissions.map((p: Doc) => p.key)).toContain("identity:admin");
    const holders = manifest.defaultRoles
      .filter((r: Doc) => r.permissions.includes("identity:admin"))
      .map((r: Doc) => r.key);
    expect(holders).toEqual(["admin"]);
  });

  // U25c
  it("U25c: ClientUpdate has no app, and Invites_create has the invite codes", () => {
    expect(doc.components.schemas.ClientUpdate.properties.app).toBeUndefined();
    expect(doc.components.schemas.ClientCreate.properties.app).toBeDefined();
    const conflict = byId["Invites_create"].op.responses["409"];
    expect(conflict).toBeDefined();
    const text = JSON.stringify(byId["Invites_create"].op.description);
    expect(text).toContain("user_not_invited");
    expect(text).toContain("user_disabled");
    expect(byId["Users_create"].op.description).toContain("invalid_user");
  });

  // R23
  it("R23: token, userinfo, invite, and user-created responses are not cached", () => {
    const cases: [string, string][] = [
      ["OAuth_token", "200"],
      ["OAuth_userinfo", "200"],
      ["Invites_create", "201"],
      ["Users_create", "201"],
      ["OAuth_introspect", "200"],
      ["MeApiTokens_create", "201"],
    ];
    for (const [id, status] of cases) {
      const headers = byId[id].op.responses[status].headers;
      expect(headers["Cache-Control"].schema.enum, id).toEqual(["no-store"]);
      expect(headers["Pragma"].schema.enum, id).toEqual(["no-cache"]);
    }
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
    expect(discovery.properties.introspection_endpoint).toBeDefined();
    expect(discovery.required).not.toContain("introspection_endpoint");
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

  const newOps: [string, string[]][] = [
    ["MeApiTokens_create", ["422"]],
    ["MeApiTokens_list", []],
    ["MeApiTokens_revoke", ["404"]],
    ["UserApiTokens_list", ["404"]],
    ["ApiTokens_revoke", ["404"]],
    ["Agents_create", ["409", "422"]],
    ["Agents_list", []],
    ["Agents_get", ["404"]],
    ["Agents_update", ["404", "409"]],
    ["AgentRoles_list", ["404"]],
    ["AgentRoles_assign", ["404", "422"]],
    ["AgentRoles_remove", ["404"]],
  ];

  // U40
  it("U40: error models of the new operations and the scopes of AgentRoles", () => {
    for (const [id, statuses] of newOps) {
      const found = Object.keys(byId[id].op.responses)
        .filter((s) => ["404", "409", "422"].includes(s))
        .sort();
      expect(found, id).toEqual(statuses);
      for (const s of ["400", "401", "403", "500"]) {
        expect(byId[id].op.responses[s], `${id} ${s}`).toBeDefined();
      }
    }
    const tokenText: string = byId["OAuth_token"].op.description;
    for (const code of [
      "invalid_client",
      "unauthorized_client",
      "invalid_request",
      "unsupported_token_type",
      "invalid_grant",
      "invalid_target",
      "invalid_scope",
    ]) {
      expect(tokenText, code).toContain(code);
    }
    expect(tokenText).toContain("`aud` of the subject token");
    expect(tokenText).toContain("no `refresh_token`");
    const assign = byId["AgentRoles_assign"].op;
    expect(
      assign.responses["200"].content["application/json"].schema,
    ).toEqual({ $ref: "#/components/schemas/RoleAssignment" });
    for (const name of ["list", "assign", "remove"]) {
      expect(byId[`AgentRoles_${name}`].op["x-required-scopes"]).toEqual(
        byId[`ClientRoles_${name}`].op["x-required-scopes"],
      );
    }
    for (const id of ["AgentRoles_assign", "AgentRoles_remove"]) {
      const role = (byId[id].op.parameters as Doc[])
        .map((p) => resolveRef(doc, p))
        .find((p) => p.name === "role");
      expect(role.in, id).toBe("path");
      expect(role.schema, id).toEqual({ $ref: "#/components/schemas/RoleRef" });
    }
  });

  // U41
  it("U41: OAuth_introspect has a form body, OAuthError, and no security", () => {
    const found = byId["OAuth_introspect"];
    expect(Object.keys(found.op.requestBody.content)).toEqual([
      "application/x-www-form-urlencoded",
    ]);
    for (const [status, response] of Object.entries<Doc>(found.op.responses)) {
      if (status === "200") continue;
      expect(Object.keys(response.content), status).toEqual(["application/json"]);
      expect(response.content["application/json"].schema).toEqual({
        $ref:
          status === "429"
            ? "#/components/schemas/OAuthTooManyRequests"
            : "#/components/schemas/OAuthError",
      });
    }
    expect(effectiveSecurity(doc, found.op)).toEqual([{}]);
  });

  // U42
  it("U42: IntrospectRequest and IntrospectResponse", () => {
    const request = doc.components.schemas.IntrospectRequest;
    expect(request.required).toEqual(["token"]);
    expect(request.properties.token.maxLength).toBe(512);
    expect(doc.components.schemas.IntrospectResponse.required).toEqual(["active"]);
    const headers = byId["OAuth_introspect"].op.responses["200"].headers;
    expect(headers["Cache-Control"].schema.enum).toEqual(["no-store"]);
    expect(headers["Pragma"].schema.enum).toEqual(["no-cache"]);
  });

  // U43
  it("U43: token exchange examples and the rules in the doc comment", async () => {
    const validate = check("TokenRequest");
    const { valid, invalid } = await examples("token-exchange-request.json");
    for (const value of valid) expect(validate(value)).toBe(true);
    invalid.forEach((value, i) =>
      expect(validate(value), `invalid example ${i}`).toBe(false),
    );
    const text: string = byId["OAuth_token"].op.description;
    for (const code of [
      "invalid_client",
      "unauthorized_client",
      "invalid_request",
      "unsupported_token_type",
      "invalid_grant",
      "invalid_target",
      "invalid_scope",
    ]) {
      expect(text, code).toContain(code);
    }
  });

  // U44
  it("U44: TokenResponse with issued_token_type", () => {
    const validate = check("TokenResponse");
    expect(
      validate({
        access_token: "a.b.c",
        token_type: "Bearer",
        expires_in: 300,
        scope: "helpdesk:ticket:read",
        issued_token_type: "urn:ietf:params:oauth:token-type:access_token",
      }),
    ).toBe(true);
  });

  // U45
  it("U45: IntrospectResponse examples", async () => {
    const validate = check("IntrospectResponse");
    const { valid, invalid } = await examples("introspect-response.json");
    for (const value of valid) expect(validate(value)).toBe(true);
    invalid.forEach((value, i) =>
      expect(validate(value), `invalid example ${i}`).toBe(false),
    );
    const props = doc.components.schemas.IntrospectResponse.properties;
    expect(props.exp.format).toBe("int64");
    expect(props.iat.format).toBe("int64");
    expect(JSON.stringify(props.aud)).toContain("AppKey");
    const text: string = byId["OAuth_introspect"].op.description;
    expect(text).toContain("invalid_client");
    expect(text).toContain("<caller app>:");
  });

  // U46
  it("U46: ApiTokenCreate examples", async () => {
    const validate = check("ApiTokenCreate");
    const { valid, invalid } = await examples("api-token-create.json");
    for (const value of valid) expect(validate(value)).toBe(true);
    invalid.forEach((value, i) =>
      expect(validate(value), `invalid example ${i}`).toBe(false),
    );
    expect(doc.components.schemas.ApiTokenCreate.additionalProperties).not.toBe(false);
    expect(JSON.stringify(doc.components.schemas.ApiTokenCreate.properties.scope)).toContain(
      "ScopeString",
    );
  });

  // U47
  it("U47: ApiTokenCreated is a secret and the response is not cached", () => {
    expect(doc.components.schemas.ApiTokenCreated.properties.token.format).toBe(
      "password",
    );
    const headers = byId["MeApiTokens_create"].op.responses["201"].headers;
    expect(headers["Cache-Control"].schema.enum).toEqual(["no-store"]);
    expect(headers["Pragma"].schema.enum).toEqual(["no-cache"]);
  });

  // U51
  it("U51: Agent models", async () => {
    const { valid, invalid } = await examples("agent.json");
    for (const group of valid as Doc[]) {
      expect(check(group.schema)(group.value), group.schema).toBe(true);
    }
    for (const group of invalid as Doc[]) {
      expect(check(group.schema)(group.value), JSON.stringify(group)).toBe(false);
    }
    for (const name of ["Agent", "AgentCreate", "AgentUpdate"]) {
      expect(doc.components.schemas[name].additionalProperties, name).not.toBe(false);
    }
  });

  // U53
  it("U53: grant type and token type unions", () => {
    expect(check("TokenRequest")({ grant_type: "urn:ietf:params:oauth:grant-type:token-exchange" })).toBe(true);
    const tokenType = check("TokenType");
    for (const value of [
      "urn:ietf:params:oauth:token-type:access_token",
      "urn:constellation:params:oauth:token-type:agent-id",
      "urn:example:other",
    ]) {
      expect(tokenType(value), value).toBe(true);
    }
    const hint = check("IntrospectTokenTypeHint");
    for (const value of ["api_token", "access_token", "refresh_token", "other"]) {
      expect(hint(value), value).toBe(true);
    }
    const revokeHint = doc.components.schemas.RevokeRequest.properties.token_type_hint;
    expect(JSON.stringify(revokeHint)).toContain("TokenTypeHint");
    expect(JSON.stringify(doc.components.schemas.TokenTypeHint)).not.toContain("api_token");
  });

  // U57
  it("U57: the act claim is set by token exchange", async () => {
    const common = await loadCommon();
    const text: string = common.components.schemas.AccessTokenClaims.properties.act.description;
    expect(text).toContain("token exchange");
    expect(text).toContain("agent");
    expect(text).not.toContain("Reserved");
    expect(common.components.schemas.ActorClaim.description).toContain("one level");
  });

  // R4
  it("R4: subject_token has a length limit and actor_token is a uuid", () => {
    const validate = check("TokenRequest");
    const base = { grant_type: "urn:ietf:params:oauth:grant-type:token-exchange" };
    expect(validate({ ...base, subject_token: "a".repeat(4097) })).toBe(false);
    expect(validate({ ...base, subject_token: "a".repeat(4096) })).toBe(true);
    expect(validate({ ...base, actor_token: "x".repeat(1000) })).toBe(false);
  });

  // U56
  it("U56: implicit role text and AssignmentSource", () => {
    expect(byId["UserRoles_list"].op.description).toContain("identity:user");
    expect(byId["UserRoles_list"].op.description).toContain("config");
    const source = doc.components.schemas.AssignmentSource;
    expect(source.enum ?? source.anyOf?.flatMap((s: Doc) => s.enum)).toEqual(["config", "api"]);
  });

  // U58
  it("U58: exactly ten operations declare 429", () => {
    const with429 = ops.filter((o) => o.op.responses["429"]).map((o) => o.id);
    expect(with429.sort()).toEqual(limited.slice().sort());
    // Each public operation (no security) declares 429 with a required Retry-After.
    const publicOps = ops.filter((o) => {
      const security = effectiveSecurity(doc, o.op);
      return security.every((requirement) => Object.keys(requirement).length === 0);
    });
    expect(publicOps.length).toBeGreaterThan(0);
    for (const o of publicOps) {
      expect(o.op.responses["429"], o.id).toBeDefined();
      expect(o.op.responses["429"].headers?.["Retry-After"]?.required, o.id).toBe(true);
    }
  });

  // U59
  it("U59: Retry-After of each 429 response", () => {
    for (const id of limited) {
      const header = byId[id].op.responses["429"].headers["Retry-After"];
      expect(header.required, id).toBe(true);
      expect(header.schema.type, id).toBe("integer");
      expect(header.schema.format, id).toBe("int32");
      expect(header.schema.minimum, id).toBe(jsonLimited.includes(id) ? 0 : 1);
    }
  });

  // U60
  it("U60: the OAuth 429 response", () => {
    for (const id of oauthLimited) {
      const response = byId[id].op.responses["429"];
      expect(Object.keys(response.content), id).toEqual(["application/json"]);
      expect(response.content["application/json"].schema, id).toEqual({
        $ref: "#/components/schemas/OAuthTooManyRequests",
      });
      expect(response.headers["Cache-Control"], id).toBeDefined();
      expect(response.headers["Pragma"], id).toBeDefined();
    }
  });

  // U61
  it("U61: OAuth rate limit schemas have the fields of OAuthError", () => {
    const error = doc.components.schemas.OAuthError;
    for (const name of ["OAuthTooManyRequests", "OAuthServiceUnavailable"]) {
      const schema = doc.components.schemas[name];
      expect(Object.keys(schema.properties).sort(), name).toEqual(
        Object.keys(error.properties).sort(),
      );
      expect(schema.required, name).toEqual(error.required);
    }
  });

  // U62
  it("U62: the HTML 429 response", () => {
    for (const id of htmlLimited) {
      const response = byId[id].op.responses["429"];
      expect(Object.keys(response.content), id).toEqual(["text/html"]);
      // The HTML body is a string, as in HtmlPage. The emitter inlines it.
      expect(response.content["text/html"].schema, id).toEqual({ type: "string" });
      // The 429 and the 503 responses are different.
      const other = byId[id].op.responses["503"];
      expect(response.description, id).not.toEqual(other.description);
      expect(response.headers["Retry-After"].required, id).toBe(true);
      expect(other.headers["Retry-After"].required ?? false, id).toBe(false);
    }
  });

  // U63
  it("U63: the problem 429 response", () => {
    for (const id of jsonLimited) {
      const response = byId[id].op.responses["429"];
      expect(Object.keys(response.content), id).toEqual([
        "application/problem+json",
      ]);
      const schema = response.content["application/problem+json"].schema;
      expect(schema, id).toEqual({ $ref: "#/components/schemas/TooManyRequests" });
      const resolved = resolveRef(doc, schema);
      expect(resolved.allOf, id).toEqual([{ $ref: "#/components/schemas/Problem" }]);
      expect(resolveRef(doc, resolved.allOf[0]).required, id).toContain("code");
    }
    for (const id of ["Discovery_jwks", "Discovery_openidConfiguration"]) {
      expect(byId[id].op.description, id).toContain("`rate_limited`");
    }
  });

  // U64
  it("U64: 503 of MeApiTokens_create and PermissionManifests_publish", () => {
    for (const id of ["MeApiTokens_create", "PermissionManifests_publish"]) {
      const response = byId[id].op.responses["503"];
      expect(response, id).toBeDefined();
      const schema = response.content["application/problem+json"].schema;
      expect(schema, id).toEqual({ $ref: "#/components/schemas/ServiceUnavailable" });
      const resolved = resolveRef(doc, schema);
      expect(resolveRef(doc, resolved.allOf[0]).required, id).toContain("code");
      expect(byId[id].op.description, id).toContain("`TooManyRequests`: `rate_limited`");
      expect(byId[id].op.description, id).toContain("`ServiceUnavailable`: `unavailable`");
    }
  });

  // U65
  it("U65: 503 of OAuth_userinfo", () => {
    const response = byId["OAuth_userinfo"].op.responses["503"];
    expect(Object.keys(response.content)).toEqual(["application/json"]);
    expect(response.content["application/json"].schema).toEqual({
      $ref: "#/components/schemas/OAuthServiceUnavailable",
    });
    const header = response.headers["Retry-After"];
    expect(header.required ?? false).toBe(false);
    expect(header.schema.format).toBe("int32");
    expect(header.schema.minimum).toBe(1);
    expect(response.headers["Cache-Control"]).toBeDefined();
    expect(response.headers["Pragma"]).toBeDefined();
  });

  // U66
  it("U66: 503 of OAuth_authorize and OAuth_endSession", () => {
    for (const id of htmlLimited) {
      const response = byId[id].op.responses["503"];
      expect(Object.keys(response.content), id).toEqual(["text/html"]);
      // The HTML body is a string, as in HtmlPage. The emitter inlines it.
      expect(response.content["text/html"].schema, id).toEqual({ type: "string" });
      const header = response.headers["Retry-After"];
      expect(header.required ?? false, id).toBe(false);
      expect(header.schema.format, id).toBe("int32");
      expect(header.schema.minimum, id).toBe(1);
      // The 429 and the 503 responses are different.
      expect(response.description, id).not.toEqual(byId[id].op.responses["429"].description);
    }
  });

  // U67
  it("U67: the existing 503 responses do not change", () => {
    for (const id of ["OAuth_token", "OAuth_revoke", "OAuth_introspect"]) {
      const response = byId[id].op.responses["503"];
      expect(response.content["application/json"].schema, id).toEqual({
        $ref: "#/components/schemas/OAuthError",
      });
      expect(response.headers?.["Retry-After"], id).toBeUndefined();
    }
    for (const id of ["MeApiTokens_create", "PermissionManifests_publish"]) {
      const response = byId[id].op.responses["503"];
      expect(response.headers?.["Retry-After"], id).toBeUndefined();
    }
    expect(doc.components.schemas.ServiceUnavailable.allOf).toEqual([
      { $ref: "#/components/schemas/Problem" },
    ]);
  });

  // U68
  it("U68: rate limit examples", async () => {
    const data: any = await examples("rate-limit.json");
    const oauthCheck = check("OAuthTooManyRequests");
    for (const value of data.valid) expect(oauthCheck(value)).toBe(true);
    data.invalid.forEach((value: unknown, i: number) =>
      expect(oauthCheck(value), `invalid example ${i}`).toBe(false),
    );
    const problemCheck = check("TooManyRequests");
    for (const value of data.validProblem) expect(problemCheck(value)).toBe(true);
    data.invalidProblem.forEach((value: unknown, i: number) =>
      expect(problemCheck(value), `invalid problem ${i}`).toBe(false),
    );
  });

  // U69
  it("U69: OAuthError stays the schema of the other non-200 statuses", () => {
    for (const id of ["OAuth_token", "OAuth_revoke", "OAuth_introspect"]) {
      for (const [status, response] of Object.entries<Doc>(byId[id].op.responses)) {
        if (status === "200" || status === "429") continue;
        expect(
          response.content["application/json"].schema,
          `${id} ${status}`,
        ).toEqual({ $ref: "#/components/schemas/OAuthError" });
      }
    }
  });
  const mfaOps = ["MeMfa_get", "MeTotp_remove", "UserMfa_get", "UserMfa_reset"];

  // U70
  it("U70: x-required-scopes of the MFA operations", async () => {
    const manifest = JSON.parse(
      await readFile(join(root, "services", "identity", "manifest.json"), "utf8"),
    );
    const keys: string[] = manifest.permissions.map((p: Doc) => p.key);
    const expected: Record<string, string[]> = {
      MeMfa_get: ["identity:mfa:manage_own"],
      MeTotp_remove: ["identity:mfa:manage_own"],
      UserMfa_get: ["identity:user:read"],
      UserMfa_reset: ["identity:mfa:reset", "identity:admin"],
    };
    for (const id of mfaOps) {
      const scopes = byId[id].op["x-required-scopes"];
      expect(scopes, id).toEqual(expected[id]);
      for (const key of scopes) expect(keys, id).toContain(key);
    }
  });

  // U71
  it("U71: amr and auth_time in AccessTokenClaims", async () => {
    const common = await loadCommon();
    const claims = common.components.schemas.AccessTokenClaims;
    expect(claims.properties.amr).toBeDefined();
    expect(claims.properties.auth_time).toBeDefined();
    expect(claims.required ?? []).not.toContain("amr");
    expect(claims.required ?? []).not.toContain("auth_time");
    expect(claims.properties.amr.items).toEqual({
      $ref: "#/components/schemas/AuthenticationMethod",
    });
  });

  // U72
  it("U72: IdTokenClaims required claims", () => {
    const schema = doc.components.schemas.IdTokenClaims;
    expect([...schema.required].sort()).toEqual(
      ["aud", "auth_time", "exp", "iat", "iss", "sub"].sort(),
    );
    for (const name of ["nonce", "sid", "amr", "email", "email_verified", "name"]) {
      expect(schema.properties[name], name).toBeDefined();
      expect(schema.required, name).not.toContain(name);
    }
  });

  // U73
  it("U73: ID token claims examples", async () => {
    const validate = check("IdTokenClaims");
    const { valid, invalid } = await examples("id-token-claims.json");
    for (const value of valid) expect(validate(value)).toBe(true);
    invalid.forEach((value, i) =>
      expect(validate(value), `invalid example ${i}`).toBe(false),
    );
  });

  // U74
  it("U74: MFA status examples", async () => {
    const validate = check("MfaStatus");
    const { valid, invalid } = await examples("mfa-status.json");
    for (const value of valid) expect(validate(value)).toBe(true);
    invalid.forEach((value, i) =>
      expect(validate(value), `invalid example ${i}`).toBe(false),
    );
  });

  // U75
  it("U75: the MFA status responses", () => {
    for (const id of ["MeMfa_get", "UserMfa_get"]) {
      const schema = byId[id].op.responses["200"].content["application/json"].schema;
      expect(schema, id).toEqual({ $ref: "#/components/schemas/MfaStatus" });
    }
  });

  // U76
  it("U76: ReauthenticationRequired in the common file", async () => {
    const common = await loadCommon();
    const schema = common.components.schemas.ReauthenticationRequired;
    expect(schema.allOf).toEqual([{ $ref: "#/components/schemas/Problem" }]);
    const check401 = byId["MeTotp_remove"].op.responses["401"];
    const header = check401.headers["WWW-Authenticate"];
    expect(header.required).toBe(false);
  });

  // U77
  it("U77: the 401 response of the step-up operations", () => {
    for (const id of ["MeTotp_remove", "UserMfa_reset"]) {
      const response = byId[id].op.responses["401"];
      expect(JSON.stringify(response.content), id).toContain("ReauthenticationRequired");
      expect(response.headers?.["WWW-Authenticate"], id).toBeDefined();
    }
  });

  // U78
  it("U78: the doc comment of MeMfa_get", () => {
    expect(byId["MeMfa_get"].op.description).toContain("user_token_required");
  });

  // U79
  it("U79: MeTotp_remove", () => {
    const { op } = byId["MeTotp_remove"];
    for (const status of ["204", "401", "403", "404", "409"]) {
      expect(op.responses[status], status).toBeDefined();
    }
    for (const text of [
      "reauthentication_required",
      "insufficient_user_authentication",
      'max_age="300"',
      "user_token_required",
      "totp_not_found",
      "mfa_required",
      "recovery codes",
    ]) {
      expect(op.description, text).toContain(text);
    }
  });

  // U80
  it("U80: UserMfa_get", () => {
    const { op } = byId["UserMfa_get"];
    for (const status of ["200", "401", "403", "404"]) {
      expect(op.responses[status], status).toBeDefined();
    }
    expect(op.description).toContain("user_not_found");
  });

  // U81
  it("U81: UserMfa_reset", () => {
    const { op } = byId["UserMfa_reset"];
    for (const status of ["204", "401", "403", "404"]) {
      expect(op.responses[status], status).toBeDefined();
    }
    for (const text of ["user_not_found", "reauthentication_required", "revokes all sessions"]) {
      expect(op.description, text).toContain(text);
    }
  });

  // U83
  it("U83: the MFA operations do not declare 429 or 503", () => {
    for (const id of mfaOps) {
      expect(byId[id].op.responses["429"], id).toBeUndefined();
      expect(byId[id].op.responses["503"], id).toBeUndefined();
    }
    expect(ops.filter((o) => o.op.responses["429"])).toHaveLength(limited.length);
  });
  // U84
  it("U84: the step-up rule in docs/conventions.md", async () => {
    const text = await readFile(join(root, "docs", "conventions.md"), "utf8");
    expect(text).toContain("insufficient_user_authentication");
    expect(text).toContain("max_age");
    expect(text).toContain("the client does not refresh the token");
  });
});
