# Conventions

This file gives the rules for the TypeSpec files in this repository. Read `docs/usage.md` for the steps to change a contract and to use a generated file. Read `docs/typespec-guide.md` for the TypeSpec language.

## Layout

```txt
constellation-contracts/
|---- .github/workflows/ci.yml
|---- docs/
|---- generated/openapi/        Generated OpenAPI files. Do not edit by hand.
|---- lib/                      Shared models for all services
|---- services/                 One folder for each service
|---- test/                     Tests, fixtures, and example documents
|---- main.tsp                  Imports ./lib and each services/<name>/main.tsp
|---- tspconfig.yaml
|---- package.json
```

All library files use the blockless namespace `namespace Constellation.Common;`. A service file uses `using Constellation.Common;`.

## Commands

| Command | Use |
| ------- | --- |
| `npm ci` | Install the exact package versions. |
| `npm run format` | Format all `.tsp` files. |
| `npm run build` | Compile with warnings as errors. Write the files in `generated/openapi/`. |
| `npm run lint` | Compile with no output. Check the format. |
| `npm test` | Run the tests. |

## Naming rules

- Service namespace: `Constellation.<Service>`, for example `Constellation.Identity`. Folder: `services/<service>/`.
- A service namespace does not change after its first release. A new name changes the file name and breaks the URL of each consumer.
- Route prefix: `/v1` on each service namespace. A service that has OAuth endpoints puts `@route("/v1/<resource>")` on each interface in place of the namespace prefix. Read the "OAuth endpoints" section.
- Models and enums: PascalCase. Properties and query parameters: camelCase. String literal values: lower snake case. File names: kebab case.
- Each model, property, and operation has a doc comment (`/** */`).
- Each operation returns its success type or types, plus the error union that applies.
- A list operation uses the shared pagination models and `@list`.
- A page model is a named model, for example `model TicketPage is CursorPage<Ticket>;`. The emitter gives a generic name to an unnamed template instance.
- A CloudEvent model is a named model, for example `model TicketCreatedEvent is CloudEvent<TicketCreated>;`.
- Each shared model in `lib/` has the decorator `@friendlyName`. Then the OpenAPI schema name does not have the prefix `Constellation.Common.` in the file of a service.

## File organization rules

The specs must stay short and easy to read. One file has one topic. These rules apply to `lib/` and to `services/`.

Layout of one service:

```txt
services/<service>/
|---- main.tsp                 The service entry point. Imports and the service namespace only.
|---- models/
|------- main.tsp              Imports each model file
|------- <resource>.tsp        The models, enums, and unions of one resource
|---- operations/
|------- main.tsp              Imports each operation file
|------- <resource>.tsp        One interface with the operations of one resource
|---- events/                  Only if the service publishes events
|------- main.tsp
|------- <resource>.tsp        The event data models of one resource, and the named CloudEvent models
|---- permissions.tsp          Only if the service has permissions. The permission keys and the default roles.
```

Example of a service entry point:

```tsp
import "@typespec/http";
import "../../lib";
import "./models";
import "./operations";

using Http;

/** The identity service API. */
@service(#{ title: "Constellation Identity" })
@route("/v1")
namespace Constellation.Identity;
```

Example of an operation file:

```tsp
namespace Constellation.Identity;

/** Operations on users. */
@route("/users")
interface Users {
  /** List the users. */
  @list @get list(...CursorPageParams): UserPage | CommonErrors;

  /** Get one user. */
  @get get(@path id: string): User | NotFound | CommonErrors;
}
```

Rules:

1. The `main.tsp` file of a service or a folder has only `import`, `using`, decorators, doc comments, and the namespace statement. It has no `model`, `op`, `interface`, `enum`, `union`, `scalar`, or `alias`.
2. One `<resource>.tsp` file has one resource. The file name is the resource name in kebab case, for example `api-token.tsp`.
3. All operations of one resource are in one `interface`. The interface has the `@route` of the resource. The operation IDs then have the form `<Interface>_<operation>`, for example `Users_list`.
4. All files of one service use the blockless namespace `namespace Constellation.<Service>;`. A service does not use sub-namespaces. Then the schema names and the operation IDs stay short.
5. A `.tsp` file has a maximum of 250 lines. If a resource file has more lines, divide it by subtopic, for example `ticket.tsp` and `ticket-sla.tsp`. Do not make one file for each model.
6. A model that two or more resources use goes in `models/shared.tsp` of the service. A model that two or more services use goes in `lib/`.
7. The files in `lib/` follow the same rules. `lib/main.tsp` has only imports, and each other file has one topic.
8. A service namespace must not import another service namespace. Shared types go in `lib/`.

The tests enforce rules 1 and 5.

## Add a service

1. Make the folder `services/<service>/` with the files of the layout above.
2. Add `import "./services/<service>/main.tsp";` to the root `main.tsp`.
3. Run `npm run format`, `npm run build`, `npm run lint`, and `npm test`.
4. Commit the `.tsp` files and the new file in `generated/openapi/` in the same commit.

The build writes one OpenAPI file for each `@service` namespace. The file name is `<namespace>.openapi.yaml`, for example `Constellation.Identity.openapi.yaml`. Each service file is complete. It has a copy of each shared model that the service uses. A consumer needs only the file of its service.

This is a complete example of a small service. The tests compile it.

```tsp example
import "@typespec/http";
import "./lib";

using Http;
using Constellation.Common;

/** The tickets service API. */
@service(#{ title: "Constellation Tickets" })
@route("/v1")
namespace Constellation.Tickets;

/** A ticket. */
model Ticket {
  /** ID of the ticket. */
  id: string;

  /** Title of the ticket. */
  title: string;
}

/** One page of tickets. */
model TicketPage is CursorPage<Ticket>;

/** Operations on tickets. */
@route("/tickets")
interface Tickets {
  /** List the tickets. */
  @list
  @get
  list(...CursorPageParams): TicketPage | CommonErrors;

  /** Get one ticket. */
  @get
  get(@path id: string): Ticket | NotFound | CommonErrors;
}
```

## Security

- An API with authentication declares the scheme `BearerAuth` with `@useAuth(BearerAuth)` on the service namespace. All operations then need a bearer access token.
- An operation with no authentication has `@useAuth(NoAuth)`. Examples: discovery documents and the OAuth token endpoint.
- A protected operation lists the permissions that it needs in the extension `x-required-scopes`. The value is an array of `PermissionKey` values. OpenAPI scope lists are static, but permission keys are dynamic, so the extension carries them. An operation that needs no permission has an empty array. A list with more than one key means that the token must have all of them. The call fails with 403 if the token lacks one key.
- A response that has a token, a secret, or personal data has the headers `Cache-Control: no-store` and `Pragma: no-cache`.
- The access token claim `app` is the key of the app of a service client. It is not the audience. Only tokens from the client credentials grant have it, with `principal_type` `service`. Exchange tokens, user tokens, and API tokens do not have it. A verifier uses `app` only when `principal_type` is `service`.
- The access token `scope` claim has permission keys only. The type `ScopeString` holds them. OIDC scopes (`openid`, `profile`, `email`, `offline_access`) go only in the request `scope` of an authorize or token operation. The type `RequestScopeString` holds them.

This is a complete example. The tests compile it.

```tsp example
import "@typespec/http";
import "@typespec/openapi";
import "./lib";

using Http;
using OpenAPI;
using Constellation.Common;

/** The notes service API. */
@service(#{ title: "Constellation Notes" })
@useAuth(BearerAuth)
namespace Constellation.Notes;

/** A note. */
model Note {
  /** ID of the note. */
  id: string;
}

/** Operations on notes. */
@route("/v1/notes")
interface Notes {
  /** Get one note. */
  @extension("x-required-scopes", #["notes:note:read"])
  @route("/{id}")
  @get
  get(@path id: string): Note | NotFound | CommonErrors;
}
```

## OAuth endpoints

OAuth 2.0 and OIDC clients expect standard paths and standard errors. Thus the OAuth endpoints are an exception to the rules for paths and errors.

- An OAuth or discovery endpoint has the standard path with no `/v1` prefix. Examples: `/oauth/token` and `/.well-known/jwks.json`.
- The error body of an OAuth endpoint is the RFC 6749 form `{error, error_description}` with the content type `application/json`. It is not a `Problem`. A discovery endpoint is an exception for 429 (see below).
- A protected resource endpoint of OAuth, for example `userinfo`, gives a `WWW-Authenticate` header on 401 and 403 (RFC 6750) and no body. It uses the OAuth error body on 429 and 503.
- A discovery endpoint uses the `Problem` body with the code `rate_limited` for 429.
- The field names of an OAuth model are in snake case, as the RFCs require.
- TypeSpec cannot remove a namespace prefix. Thus a service with OAuth endpoints has no `@route` on its namespace. Each interface has its own `@route`. A `/v1` interface uses `@route("/v1/<resource>")`. An OAuth interface uses its standard path.
- All other operations of the service follow the normal rules: `/v1` and `Problem`.

### Authentication methods and step-up

- A user access token and an ID token can have the optional claims `amr` and `auth_time`. `amr` lists the methods of the login of the session. The values are `pwd`, `otp`, `rec`, `hwk`, `user`, `fed`, and `mfa`. A service that needs MFA checks that `amr` contains `mfa`. It does not check the other values. A token with `act` does not satisfy MFA, even if it has `amr`. A service rejects `amr` and `auth_time` of a token with `act`.
- An operation that needs a fresh MFA login gives 401 `ReauthenticationRequired` with the code `reauthentication_required`. The response has the RFC 9470 challenge in the header `WWW-Authenticate`, for example `Bearer error="insufficient_user_authentication", error_description="A fresh MFA login is necessary", max_age="300"`. The parameter `error_description` is optional. The status is 401 as in RFC 9470. It is not 403 as for `insufficient_scope` (RFC 6750).
- A fresh login rule is weaker than the fresh MFA rule. The token needs `auth_time` at most 5 minutes old and the operation does not check `amr` for `mfa`. An operation with this rule also gives 401 `ReauthenticationRequired` with the code `reauthentication_required`. The `error_description` is "A fresh login is necessary". A token with no `auth_time` or with `act` does not satisfy the rule.
- A client reads the `error` parameter of `WWW-Authenticate`. For `insufficient_user_authentication`, the client does not refresh the token, because a refresh keeps the old `auth_time` and `amr`. The client starts a new authorization request with `max_age` and `prompt=login`.
- A browser ceremony, for example the TOTP enrollment, the passkey registration, the passkey login, the upstream login, the upstream link flow, the upstream invite flow, or the display of recovery codes, is a hosted page of the service. It is outside the contract, like `/login` and `/setup`.

### Token exchange

The token endpoint accepts the grant `urn:ietf:params:oauth:grant-type:token-exchange` (RFC 8693). The request has the fields `subject_token`, `subject_token_type`, `audience`, and `scope`. It can also have `actor_token`, `actor_token_type`, and `requested_token_type`. `actor_token` and `actor_token_type` go together. The response has `issued_token_type`.

| Rule | Error code |
| ---- | ---------- |
| Only a service client with `private_key_jwt` can use the grant. | `invalid_client` (401) |
| The client needs the permission `identity:token:exchange`. | `unauthorized_client` |
| A repeated parameter, a missing required parameter, or only one of `actor_token` and `actor_token_type`. | `invalid_request` |
| A token type that is not the access token URI (or the agent ID URI for the actor). | `unsupported_token_type` |
| The subject token is not a valid user access token. It has `act`, it is expired, or its user is disabled. Its `aud` is not the `app` of the authenticated client. The agent does not exist, is disabled, or belongs to another client. | `invalid_grant` |
| `audience` is not one app key, or it is `identity`. | `invalid_target` |
| A requested scope is not in the permissions of the user, intersected with the permissions of the agent if there is an actor. An OIDC scope (`openid`, `profile`, `email`, `offline_access`). A scope that does not start with `<audience>:`. | `invalid_scope` |

The new token has `sub` of the user. If there is an actor, it has `act` with `principal_type` `agent`. Its `exp` is not later than the `exp` of the subject token. The new token has no `amr` and no `auth_time`. The response has no `refresh_token` and no `id_token`. The actor token is the ID of an agent, not a signed token. The security comes from the client authentication and the binding of the agent to its client.

A custom token type URI has the form `urn:constellation:params:oauth:token-type:<name>`.

### Introspection

`POST /oauth/introspect` (RFC 7662) is only for a service client with `private_key_jwt`. Any other caller gets 401 `invalid_client` and learns nothing about the token. The response is `{active:false}` for an unknown, expired, or revoked token, for a token of a disabled user, and for a token with no scope for the caller app. For an active token, `scope` is the stored scope, intersected with the current permissions of the user, and then limited to the scopes that start with `<caller app>:`. If the result is empty, the response is `{active:false}`.

### API tokens and self-service operations

- A personal API token has the format `cpat_` followed by 43 base64url characters. A service finds an API token by this prefix. The scope of an API token is a `ScopeString`. It has no OIDC scope.
- An operation under `/v1/me/` that changes self-service data needs a user access token with no `act`. Other tokens get 403 with the code `user_token_required`.
- The error `scope_not_granted` lists each key in an entry of `errors`. Each entry has `field` `/scope`, `code` `scope_not_granted`, and a `message` that names the key.
- An implicit role (`service` and `user` in the identity manifest) is in the manifest and has no database row. An API shows it with the source `config`.

## Form bodies

A request body of type `application/x-www-form-urlencoded` uses `@header contentType: "application/x-www-form-urlencoded"` and `@body` with a model. The OAuth token, revoke, and introspect operations are examples. Keep the form models open, so that a later release can add a field.

## Manifest files

A consumer copies files from a release tag. A TypeSpec constant is not in the generated OpenAPI file. Thus a service with a fixed permission manifest keeps it in `services/<service>/manifest.json`. The file must be valid against `PermissionManifest`. The service embeds a copy of the file. The identity service uses `services/identity/manifest.json`.

## Shared models

| Model | File | Use it when |
| ----- | ---- | ----------- |
| `Problem` and the status models | `lib/errors.tsp` | An operation returns an error. |
| `CommonErrors` | `lib/errors.tsp` | An operation returns 400, 401, 403, and 500. Add the other status models that apply. |
| `CursorPageParams` and `CursorPage<T>` | `lib/pagination.tsp` | An operation lists resources. |
| `CloudEvent<T>`, `CloudEventEnvelope`, `EventType`, `PrincipalType` | `lib/events.tsp` | A service publishes an event, or an event relay handles an event of unknown type. |
| `LinkTemplate`, `LinkTemplateSet`, `ResourceType` | `lib/links.tsp` | An application maps resource types to URLs. |
| `PermissionManifest`, `PermissionDefinition`, `RoleDefinition`, `AppKey`, `PermissionKey`, `RoleKey` | `lib/permissions.tsp` | A service publishes its permissions and default roles. |
| `EventTypeRegistration`, `EventTypeDefinition` | `lib/event-types.tsp` | A service registers its event types with the events service. |
| `AccessTokenClaims`, `ActorClaim`, `ScopeString`, `RequestScopeString`, `RoleRef`, `AppKeyList` | `lib/auth.tsp` | A service or a client reads or checks an access token, a scope list, or a role reference. |

Do not use visibility decorators in the shared models. Then each model has one schema name.

This is a complete example of a named event model. The tests compile it.

```tsp example
import "./lib";

using Constellation.Common;

namespace Constellation.Tickets;

/** Data of the ticket created event. */
model TicketCreated {
  /** ID of the ticket. */
  ticketId: string;
}

/** The ticket created event. */
model TicketCreatedEvent is CloudEvent<TicketCreated>;
```

## Errors (RFC 9457)

An error response has the content type `application/problem+json`. The body is a `Problem`.

| Model | Status |
| ----- | ------ |
| `BadRequest` | 400 |
| `Unauthorized` | 401 |
| `Forbidden` | 403 |
| `NotFound` | 404 |
| `Conflict` | 409 |
| `ContentTooLarge` | 413 |
| `UnprocessableContent` | 422 |
| `TooManyRequests` | 429 |
| `InternalServerError` | 500 |
| `ServiceUnavailable` | 503 |

- `Problem.code` is a stable code that a machine can read, in lower snake case, with a maximum of 64 characters. Example: `ticket_not_found`.
- `Problem.errors` has the `FieldError` items of a validation error. `FieldError.field` is a JSON Pointer to the incorrect value.
- `Forbidden.missingScopes` has the permission keys that the principal lacks. An agent uses it to ask the user for approval.
- `TooManyRequests` has the `Retry-After` header.
- `ServiceUnavailable` can have the optional `Retry-After` header.
- `ContentTooLarge` has the code `content_too_large`. The operator of the service sets the body limit.
- A server can reject an expired or incorrect page token with `BadRequest` and the code `invalid_page_token`.

Rules for the content of an error:

- `title` and `detail` contain no internal data. Examples of internal data: stack traces, SQL text, file paths, host names, and tokens.
- `instance` contains no personal data and no secret.
- A 500 or 503 response gives only a general `detail`, plus `requestId` and `traceId`. An operator uses these IDs to find the full error in the logs and traces.

## Rate limits

- An operation that the service limits declares 429 with the required header `Retry-After`.
- The body follows the family of the operation. An `/oauth/*` JSON operation uses the OAuth error body. A browser page uses `HtmlPage` content. A `/v1` or discovery operation uses `Problem` with the code `rate_limited`.
- `Retry-After` is an integer number of seconds (RFC 9110 delay-seconds). The identity service sends a value of 1 or more. A client accepts 0 and treats it as 1.
- A client must not try again before `Retry-After`.
- A new public operation must declare 429.
- The 429 or 503 status, the body (`detail`, `error_description`), and `Retry-After` do not change when a `client_id` or a user exists or does not exist. The response does not give the limit key, the limit value, or the remaining requests.

## Pagination

- The pagination is cursor based. Offset pagination is not allowed.
- `pageToken` is an opaque token with a maximum of 1024 characters. A client must not parse it.
- `pageSize` is from 1 to 200. The default is 50. The list of registrations is an exception: its `pageSize` is from 1 to 10, and the default is 10.
- `nextPageToken` has no value on the last page.

## Keys and limits

| Type | Pattern | Maximum length | Example |
| ---- | ------- | -------------- | ------- |
| `AppKey` | `^[a-z][a-z0-9_]*$` | 32 | `customer_portal` |
| `PermissionKey` | `<app>:<resource>:<action>`, each segment `[a-z][a-z0-9_]*`. The one exception is `identity:admin`. | 128 | `helpdesk:ticket:write` |
| `RoleKey` | `^[a-z][a-z0-9_]*$` | 64 | `agent_admin` |
| `ResourceType` | `^[a-z][a-z0-9_]*$` | 64 | `ticket` |
| `EventType` | Three or more segments, each `[a-z][a-z0-9_]*`, with a dot between the segments | 128 | `helpdesk.ticket.created` |

All key segments use lower snake case. Thus each `AppKey` is a valid first segment of a `PermissionKey` and of an `EventType`. The identity service and the events service do the semantic checks. Example: each permission key starts with the `app` of its manifest.

## CloudEvents attributes

The event envelope follows CloudEvents 1.0 in JSON format.

| Attribute | Required | Rule |
| --------- | -------- | ---- |
| `specversion` | Yes | Always `1.0`. |
| `id` | Yes | Unique for each `source`. From 1 to 128 characters. |
| `source` | Yes | URI reference, for example `/helpdesk`. From 1 to 256 characters. |
| `type` | Yes | An `EventType`. |
| `time` | Yes | Date and time in UTC. |
| `subject` | No | ID of the resource, for example the ticket ID. From 1 to 256 characters. |
| `datacontenttype` | Yes | Always `application/json`. |
| `dataschema` | No | URI of the schema of `data`. |
| `data` | Yes | The data of the event. |
| `actor` | Yes | The `sub` of the token: the ID of the principal. From 1 to 128 characters. |
| `actortype` | Yes | `user`, `agent`, `service`, or `workflow`. |
| `act` | No | The `act` of the token: the agent that acts for the user. From 1 to 128 characters. Set it together with `acttype`. |
| `acttype` | No | The type of the principal in `act`. Set it together with `act`. |
| `traceparent` | No | W3C trace context, in the form `00-<32 hex>-<16 hex>-<2 hex>` with lowercase hex digits. |

`act` and `acttype` go together. A producer sets both or neither. The schema cannot express this rule. The producer sets `actor`, `actortype`, `act`, and `acttype` from the verified principal of the request. It never sets them from request data. The outbox of `constellation-platform-go` does this. The outbox writer refuses an event that has only one of `act` and `acttype`.

An event can have no request principal. Examples are an event of a timer, or an event of a consumer that reacts to another event. Then the producer sets `actor` to the client ID of the producer service and `actortype` to `service`. A consumer does not copy `actor` from the event that it reacts to.

A CloudEvents extension name has only lowercase letters and digits, with a maximum of 20 characters.

## Event transport

- A service writes its events to its outbox in the business transaction. Events do not go through the events service.
- The relay of `constellation-platform-go` adds the events to the Valkey stream `events.stream:<app>`. Each stream entry has one field `event`. Its value is the CloudEvent in JSON.
- The name of a consumer group is the app key of the consumer, or `<app>.<name>`.
- Delivery is at least once. The order is not guaranteed. A consumer removes duplicates by `source` and `id`.

## Event type registration

A service registers its event types with the events service (`PUT /v1/event-type-registrations/{app}`). The events service keeps the central event catalog. A client reads it with `GET /v1/event-types`.

- The caller must be a service client. The token has `principal_type` `service` and the `app` claim. The `app` claim, `{app}`, and the body `app` must be equal. Else the events service gives 422 `registration_app_mismatch`.
- The `aud` claim of the token must be the single value `events`. An array of audiences, even `["events"]`, gives 401. This stops the replay of a token that was issued for more than one audience.
- The order of the checks is: 401, 403, 413, 422 `registration_app_mismatch`, then the content checks. The content checks give all errors in one 422.
- `source` must be `/<app>`. Each `type` must start with `<app>.` and occur one time. `eventTypes` has 1 to 200 items. `description` has 1 to 1024 characters. `dataSchema` is a valid JSON Schema draft 2020-12 document with a maximum size of 64 KiB.
- An app has a maximum of 1000 types in the catalog, removed types included. A registration above it gives 422 `limit_exceeded`.
- Each `$ref` and `$dynamicRef` in `dataSchema` is local: its value starts with `#`. A `$id` is not set. The events service and the consumers must not fetch a remote schema. Else the events service gives 422 `invalid_data_schema`.
- `dataSchema` has a maximum nesting depth of 32. A `$ref` must not make a loop. Each `pattern` and each key of `patternProperties` is in the RE2 subset, with no back reference and no look-around. Else the events service gives 422 `invalid_data_schema`.
- The catalog text that a producer sends (`description` and `dataSchema`) is untrusted data. A consumer must escape it before it shows it. An agent or a UI must not treat it as instructions.
- The body has a maximum size that the operator sets. The default is 4 MiB. A larger body gives 413 `content_too_large`.
- The registration is a full replacement, and the last registration wins. A type that is not in the new body stays in the catalog with `removedAt`. A reader of the catalog must not use `removedAt` as a signal that no more events of the type come.
- The same registration again changes nothing.
- The outbox writer of a service refuses a type that is not in the registration of the service. It uses its own registration, not the catalog.
- A change writes an audit entry with the action `events:event_type:register`. The entry has the names of the added, removed, and changed types. A request that fails with 403 writes an entry with the result `denied`.

## Link templates

An application gives a `LinkTemplateSet`. A client builds a link from `baseUrl` and a template.

- `baseUrl` is `https://` and a host, or `http://localhost` for development. It can have a port. It can have a path prefix, for example `https://example.com/helpdesk`. A path segment is not `.` or `..`. It has no `/` at the end, no user info, no query, and no fragment.
- A `template` starts with `{base_url}/`. It is an RFC 6570 level 1 path template. It has no `..`, no `@`, no `?`, no `#`, and no reserved expansion such as `{+id}`.
- A consumer MUST percent-encode each variable value before it puts the value in the template.
- A consumer MUST compare the host of the final URL with the host of `baseUrl`. If the hosts are not equal, the consumer MUST NOT use the link.

## Versions and compatible changes

- The release tag has the form `vMAJOR.MINOR.PATCH`. All files have the same version.
- MAJOR: a breaking change. Examples: remove or rename a field, an operation, or a union or enum value. Change the type of a field. Add a required request field. Make an optional request field required. Make a pattern or a limit stricter.
- MINOR: a compatible addition. Examples: a new service, a new operation, a new optional request field, a new response field.
- PATCH: a change to doc comments only. The generated files change only in their descriptions.
- A change in `lib/` follows the same rules. It changes the files of all services.
- A service must work with the previous version. Thus an author does a breaking change in two steps. First, the author adds the new form as a compatible change (MINOR). In a later MAJOR release, the author removes the old form.
- The PR description of a contract change gives the type of change: MAJOR, MINOR, or PATCH. The `release-module` skill uses it to select the next version.
