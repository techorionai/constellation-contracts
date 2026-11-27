# constellation-contracts

TypeSpec contracts for the Constellation platform. This repository holds the TypeSpec sources of the platform service APIs, the shared models, and the generated OpenAPI files. It does not make Go code.

Shared models: errors (RFC 9457), cursor pagination, the CloudEvents envelope, link templates, the permission manifest, the event type registration, and the access token claims.

Services: identity (`Constellation.Identity`) events (`Constellation.Events`), and audit (`Constellation.Audit`). The permission manifests are in `services/identity/manifest.json`, `services/events/manifest.json`, and `services/audit/manifest.json`.

## Layout

```txt
lib/                 Shared models
services/            One folder for each service, with an optional manifest.json
generated/openapi/   Generated OpenAPI 3.0.0 files, one for each service
docs/                Conventions, usage, and the TypeSpec guide
test/                Tests, fixtures, and example documents
```

## Commands

| Command | Use |
| ------- | --- |
| `npm ci` | Install the exact package versions. |
| `npm run format` | Format all `.tsp` files. |
| `npm run build` | Write the files in `generated/openapi/`. |
| `npm run lint` | Compile with no output. Check the format. |
| `npm test` | Run the tests. |

## Use

- Author: change the `.tsp` files, run `npm run format` and `npm run build`, and commit the generated files with the source. CI fails if the generated files are not current.
- Consumer: copy the OpenAPI file of your service from a release tag. For example, use the raw URL `https://raw.githubusercontent.com/techorionai/constellation-contracts/<tag>/generated/openapi/<file>`. Generate your code from the copy.

Read [docs/usage.md](docs/usage.md) for the steps and [docs/conventions.md](docs/conventions.md) for the rules.

## License

MIT. See [LICENSE](LICENSE).
