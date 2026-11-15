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
- Route prefix: `/v1` on each service namespace.
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
| `UnprocessableContent` | 422 |
| `TooManyRequests` | 429 |
| `InternalServerError` | 500 |
| `ServiceUnavailable` | 503 |

- `Problem.code` is a stable code that a machine can read, in lower snake case, with a maximum of 64 characters. Example: `ticket_not_found`.
- `Problem.errors` has the `FieldError` items of a validation error. `FieldError.field` is a JSON Pointer to the incorrect value.
- `Forbidden.missingScopes` has the permission keys that the principal lacks. An agent uses it to ask the user for approval.
- `TooManyRequests` has the `Retry-After` header.
- A server can reject an expired or incorrect page token with `BadRequest` and the code `invalid_page_token`.

Rules for the content of an error:

- `title` and `detail` contain no internal data. Examples of internal data: stack traces, SQL text, file paths, host names, and tokens.
- `instance` contains no personal data and no secret.
- A 500 or 503 response gives only a general `detail`, plus `requestId` and `traceId`. An operator uses these IDs to find the full error in the logs and traces.

## Pagination

- The pagination is cursor based. Offset pagination is not allowed.
- `pageToken` is an opaque token with a maximum of 1024 characters. A client must not parse it.
- `pageSize` is from 1 to 200. The default is 50.
- `nextPageToken` has no value on the last page.

## Keys and limits

| Type | Pattern | Maximum length | Example |
| ---- | ------- | -------------- | ------- |
| `AppKey` | `^[a-z][a-z0-9_]*$` | 32 | `customer_portal` |
| `PermissionKey` | `<app>:<resource>:<action>`, each segment `[a-z][a-z0-9_]*` | 128 | `helpdesk:ticket:write` |
| `RoleKey` | `^[a-z][a-z0-9_]*$` | 64 | `agent_admin` |
| `ResourceType` | `^[a-z][a-z0-9_]*$` | 64 | `ticket` |
| `EventType` | Three or more segments, each `[a-z][a-z0-9_]*`, with a dot between the segments | 128 | `helpdesk.ticket.created` |

All key segments use lower snake case. Thus each `AppKey` is a valid first segment of a `PermissionKey` and of an `EventType`. The identity service and the events service do the semantic checks. Example: each permission key starts with the `app` of its manifest.

## CloudEvents attributes

The event envelope follows CloudEvents 1.0 in JSON format.

| Attribute | Required | Rule |
| --------- | -------- | ---- |
| `specversion` | Yes | Always `1.0`. |
| `id` | Yes | Unique for each `source`. Maximum 128 characters. |
| `source` | Yes | URI reference, for example `/helpdesk`. Maximum 256 characters. |
| `type` | Yes | An `EventType`. |
| `time` | Yes | Date and time in UTC. |
| `subject` | No | ID of the resource, for example the ticket ID. |
| `datacontenttype` | Yes | Always `application/json`. |
| `dataschema` | No | URI of the schema of `data`. |
| `data` | Yes | The data of the event. |
| `actor` | Yes | The `sub` of the token: the ID of the principal. |
| `actortype` | Yes | `user`, `agent`, `service`, or `workflow`. |
| `act` | No | The `act` of the token: the agent that acts for the user. |
| `acttype` | No | The type of the principal in `act`. |
| `traceparent` | No | W3C trace context. |

A CloudEvents extension name has only lowercase letters and digits, with a maximum of 20 characters.

## Versions and compatible changes

- The release tag has the form `vMAJOR.MINOR.PATCH`. All files have the same version.
- MAJOR: a breaking change. Examples: remove or rename a field, an operation, or a union or enum value. Change the type of a field. Add a required request field. Make an optional request field required. Make a pattern or a limit stricter.
- MINOR: a compatible addition. Examples: a new service, a new operation, a new optional request field, a new response field.
- PATCH: a change to doc comments only. The generated files change only in their descriptions.
- A change in `lib/` follows the same rules. It changes the files of all services.
- A service must work with the previous version. Thus an author does a breaking change in two steps. First, the author adds the new form as a compatible change (MINOR). In a later MAJOR release, the author removes the old form.
- The PR description of a contract change gives the type of change: MAJOR, MINOR, or PATCH. The `release-module` skill uses it to select the next version.
