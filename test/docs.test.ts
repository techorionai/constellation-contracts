import { cp, mkdir, readFile, rm, writeFile } from "node:fs/promises";
import { join } from "node:path";
import { afterAll, describe, expect, it } from "vitest";
import { compileEntry, root } from "./helpers.js";

const work = join(root, "tsp-output", "docs-examples");

describe("examples in docs/conventions.md", () => {
  afterAll(async () => {
    await rm(work, { recursive: true, force: true });
  });

  // U16
  it("U16: each example block compiles with no diagnostics", async () => {
    const text = await readFile(join(root, "docs", "conventions.md"), "utf8");
    const blocks = [...text.matchAll(/^```tsp example\n([\s\S]*?)^```$/gm)].map(
      (match) => match[1],
    );
    expect(blocks.length).toBeGreaterThan(0);

    for (const [index, block] of blocks.entries()) {
      const dir = join(work, `example-${index}`);
      await rm(dir, { recursive: true, force: true });
      await mkdir(dir, { recursive: true });
      await cp(join(root, "lib"), join(dir, "lib"), { recursive: true });
      await writeFile(join(dir, "main.tsp"), block);
      const result = await compileEntry(join(dir, "main.tsp"), false);
      expect(result.diagnostics, `example block ${index}`).toEqual([]);
    }
  });
});
