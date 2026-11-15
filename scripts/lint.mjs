// Run the compile check and the format check. Run both, even if the first one fails,
// so that the CI log shows all failures. Exit with a non-zero code if one failed.
import { spawnSync } from "node:child_process";
import { fileURLToPath } from "node:url";

const tsp = fileURLToPath(
  new URL("../node_modules/@typespec/compiler/cmd/tsp.js", import.meta.url),
);
const files = ["main.tsp", "lib/**/*.tsp", "services/**/*.tsp", "test/**/*.tsp"];

const steps = [
  ["compile", [tsp, "compile", ".", "--no-emit", "--warn-as-error"]],
  ["format check", [tsp, "format", "--check", ...files]],
];

let failed = false;
for (const [name, args] of steps) {
  const result = spawnSync(process.execPath, args, { stdio: "inherit" });
  if (result.status !== 0) {
    console.error(`lint: the ${name} failed`);
    failed = true;
  }
}
process.exit(failed ? 1 : 0);
