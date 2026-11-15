import { mkdtemp, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { describe, expect, it } from "vitest";
import {
  checkLineLimit,
  checkMainFiles,
  findTspFiles,
  maxLines,
} from "./checks.js";
import { root } from "./helpers.js";

async function repositoryFiles(): Promise<string[]> {
  return findTspFiles([
    join(root, "main.tsp"),
    join(root, "lib"),
    join(root, "services"),
  ]);
}

describe("file organization rules", () => {
  // U18
  it("U18: each .tsp file has the allowed number of lines or fewer", async () => {
    const files = await repositoryFiles();
    expect(files.length).toBeGreaterThan(0);
    expect(await checkLineLimit(files, root)).toEqual([]);
  });

  // U18
  it("U18: the check reports a file with 251 lines", async () => {
    const dir = await mkdtemp(join(tmpdir(), "contracts-lines-"));
    try {
      const file = join(dir, "long.tsp");
      await writeFile(file, "// line\n".repeat(maxLines + 1));
      const problems = await checkLineLimit([file], dir);
      expect(problems).toEqual(["long.tsp: 251 lines, the maximum is 250"]);
      const ok = join(dir, "short.tsp");
      await writeFile(ok, "// line\n".repeat(maxLines));
      expect(await checkLineLimit([ok], dir)).toEqual([]);
    } finally {
      await rm(dir, { recursive: true, force: true });
    }
  });

  // U19
  it("U19: no main.tsp file has a declaration", async () => {
    const files = await repositoryFiles();
    expect(files.some((f) => f.endsWith("main.tsp"))).toBe(true);
    expect(await checkMainFiles(files, root)).toEqual([]);
  });

  // U19
  it("U19: the check reports a main.tsp file that has a model", async () => {
    const dir = await mkdtemp(join(tmpdir(), "contracts-main-"));
    try {
      const file = join(dir, "main.tsp");
      await writeFile(
        file,
        '/** A model in a comment is fine. */\nimport "./a.tsp";\n\nmodel Bad {\n  id: string;\n}\n',
      );
      expect(await checkMainFiles([file], dir)).toEqual([
        "main.tsp: has a 'model' statement",
      ]);
      const ok = join(dir, "sub");
      await writeFile(join(dir, "other.tsp"), "model Fine {}\n");
      expect(await checkMainFiles([join(dir, "other.tsp")], ok)).toEqual([]);
    } finally {
      await rm(dir, { recursive: true, force: true });
    }
  });

  // R18
  it("R18: the check finds a declaration after a decorator or a semicolon", async () => {
    const dir = await mkdtemp(join(tmpdir(), "contracts-main-"));
    try {
      const file = join(dir, "main.tsp");
      const cases: [string, string][] = [
        ['@doc("x") model Bad {}', "model"],
        ['@doc("x")\n@friendlyName("Bad")\nscalar Bad extends string;', "scalar"],
        ['import "./a.tsp"; model Bad {}', "model"],
        ["namespace A { model Bad {} }", "model"],
        ["alias Bad = string;", "alias"],
      ];
      for (const [text, statement] of cases) {
        await writeFile(file, `${text}\n`);
        expect(await checkMainFiles([file], dir), text).toEqual([
          `main.tsp: has a '${statement}' statement`,
        ]);
      }
      await writeFile(
        file,
        '// model in a line comment\nimport "./a.tsp";\nusing Models;\n',
      );
      expect(await checkMainFiles([file], dir)).toEqual([]);
    } finally {
      await rm(dir, { recursive: true, force: true });
    }
  });

  // R18
  it("R18: the check ignores a file with a name that ends in main.tsp", async () => {
    const dir = await mkdtemp(join(tmpdir(), "contracts-main-"));
    try {
      const file = join(dir, "xmain.tsp");
      await writeFile(file, "model Fine {}\n");
      expect(await checkMainFiles([file], dir)).toEqual([]);
    } finally {
      await rm(dir, { recursive: true, force: true });
    }
  });
});
