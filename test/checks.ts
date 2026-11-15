import { readFile, readdir } from "node:fs/promises";
import { basename, join, relative } from "node:path";

export const maxLines = 250;

/**
 * A declaration at the start of a statement. A statement starts at the start of
 * the text, after a line break, after a semicolon, or after a brace.
 * Decorators can come before the keyword, on the same line or on other lines.
 */
const declaration =
  /(?:^|[\n;{}])\s*(?:@[\w.]+(?:\([^)]*\))?\s*)*(?:extern\s+)?(model|op|interface|enum|union|scalar|alias)\b/;

/** Remove block comments (also doc comments) and line comments. */
function stripComments(text: string): string {
  return text.replace(/\/\*[\s\S]*?\*\//g, "").replace(/^\s*\/\/.*$/gm, "");
}

/** Find all .tsp files under the given paths. A path is a file or a folder. */
export async function findTspFiles(paths: string[]): Promise<string[]> {
  const found: string[] = [];
  async function walk(path: string): Promise<void> {
    let entries;
    try {
      entries = await readdir(path, { withFileTypes: true });
    } catch {
      if (path.endsWith(".tsp")) found.push(path);
      return;
    }
    for (const entry of entries) {
      if (entry.name === "node_modules") continue;
      const full = join(path, entry.name);
      if (entry.isDirectory()) await walk(full);
      else if (entry.name.endsWith(".tsp")) found.push(full);
    }
  }
  for (const path of paths) await walk(path);
  return found.sort();
}

/** Report each file that has more than the maximum number of lines. */
export async function checkLineLimit(
  files: string[],
  base: string,
): Promise<string[]> {
  const problems: string[] = [];
  for (const file of files) {
    const text = await readFile(file, "utf8");
    const lines = text.replace(/\n$/, "").split("\n").length;
    if (lines > maxLines) {
      problems.push(
        `${relative(base, file)}: ${lines} lines, the maximum is ${maxLines}`,
      );
    }
  }
  return problems;
}

/** Report each main.tsp file that has a declaration statement. */
export async function checkMainFiles(
  files: string[],
  base: string,
): Promise<string[]> {
  const problems: string[] = [];
  for (const file of files) {
    if (basename(file) !== "main.tsp") continue;
    const text = stripComments(await readFile(file, "utf8"));
    const match = declaration.exec(text);
    if (match) {
      problems.push(`${relative(base, file)}: has a '${match[1]}' statement`);
    }
  }
  return problems;
}
