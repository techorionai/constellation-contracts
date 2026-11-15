# How to use this repository

This repository makes OpenAPI files only. It does not make Go code. Each consumer repository copies the OpenAPI file that it needs from a release tag, and generates its own code from the copy.

## Generated files

`npm run build` writes one OpenAPI 3.0.0 file for each `@service` namespace in `generated/openapi/`.

| File | Content |
| ---- | ------- |
| `Constellation.Common.openapi.yaml` | The shared models only. It has no paths. |
| `Constellation.<Service>.openapi.yaml` | The routes of the service, and the shared models that the service uses. |

Each service file is complete. A consumer needs only the file of its service. It does not need `Constellation.Common.openapi.yaml`.

All files have one version: the release tag of this repository. A change to one service makes a new tag for all services. Read the version rules in `docs/conventions.md`.

## For an author

An author is a person who changes a contract.

1. Add or change the `.tsp` files in `services/<service>/` or in `lib/`. For a new service, add the import to the root `main.tsp`. Follow `docs/conventions.md`.
2. Run `npm run format`, then `npm run build`. The build writes the files in `generated/openapi/`.
3. Run `npm run lint` and `npm test`.
4. Commit the `.tsp` files and the generated files in the same commit. Open a PR. CI fails if the generated files are not current. In the PR description, give the type of change: MAJOR, MINOR, or PATCH.
5. After the merge, the `release-module` skill makes a new tag `vX.Y.Z`.

## For a consumer

The role of each consumer:

| Consumer | Files that it copies | Code that it generates |
| -------- | -------------------- | ---------------------- |
| `constellation-platform-go` | The file of each platform service, and `Constellation.Common.openapi.yaml` | The Go clients of all platform services, and the common Go types |
| A platform service, for example `constellation-identity` | The file of its own service | Its Go server stubs and types |
| An application, for example `constellation-helpdesk` | The file of its own API, when its API is in this repository | Its Go server stubs. It does not generate a client for a platform service. It uses the clients of `constellation-platform-go`. |

Steps:

1. Select a release tag, for example `v0.1.0`. Do not use `main` or a branch name. The tag ruleset and immutable releases make sure that a tag does not change.
2. Get the file of the service with one of these two methods:
   - Raw URL at the tag:

     ```sh
     curl -fsSL -o api/openapi/Constellation.Identity.openapi.yaml \
       https://raw.githubusercontent.com/techorionai/constellation-contracts/v0.1.0/generated/openapi/Constellation.Identity.openapi.yaml
     ```

   - Manual copy: open the file at the tag on GitHub, and copy it into the consumer repository.
3. Commit the copy in the consumer repository, for example in `api/openapi/`. Also record the tag, for example in `api/openapi/CONTRACTS_VERSION`. Then a reviewer can see the version.
4. Generate the Go code from the copy, for example with oapi-codegen and `go generate`. The consumer repository owns the generator configuration.
5. To update, repeat steps 1 to 4 with the new tag. The `bump-dependency` skill does this.

A consumer must not change the copy by hand. A change goes into this repository first.

Each service repository generates its own Go type for each shared model, for example `identity.Problem` and `audit.Problem`. oapi-codegen cannot share these types, because TypeSpec does not make external `$ref` values. `constellation-platform-go` can generate common Go types from `Constellation.Common.openapi.yaml` for code that is not specific to one service, for example the event relay.
