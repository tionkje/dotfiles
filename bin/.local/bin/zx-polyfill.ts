import { execFile } from "node:child_process";

interface RunResult {
  stdout: string;
  exitCode: number;
}

interface RunOptions {
  nothrow?: boolean;
  input?: string;
}

function shellEscape(s: string): string {
  return "'" + s.replace(/'/g, "'\\''") + "'";
}

function exec(
  strings: TemplateStringsArray,
  values: (string | string[])[],
  options: RunOptions
): Promise<RunResult> {
  const parts: string[] = [];
  strings.forEach((str, i) => {
    parts.push(str);
    if (i < values.length) {
      const val = values[i];
      if (Array.isArray(val)) {
        parts.push(val.map(shellEscape).join(" "));
      } else {
        parts.push(shellEscape(val));
      }
    }
  });
  const cmd = parts.join("").trim();

  return new Promise((resolve, reject) => {
    const child = execFile("sh", ["-c", cmd], (error, stdout) => {
      const result: RunResult = {
        stdout: stdout ?? "",
        exitCode: error ? (error as any).code ?? 1 : 0,
      };
      if (error && !options.nothrow) reject(error);
      else resolve(result);
    });
    if (options.input) {
      child.stdin?.write(options.input);
      child.stdin?.end();
    }
  });
}

export function $(
  options: RunOptions
): (
  strings: TemplateStringsArray,
  ...values: (string | string[])[]
) => Promise<RunResult>;
export function $(
  strings: TemplateStringsArray,
  ...values: (string | string[])[]
): Promise<RunResult>;
export function $(
  stringsOrOptions: TemplateStringsArray | RunOptions,
  ...values: (string | string[])[]
): any {
  if (!Array.isArray(stringsOrOptions) && !("raw" in stringsOrOptions)) {
    const options = stringsOrOptions as RunOptions;
    return (strings: TemplateStringsArray, ...vals: (string | string[])[]) =>
      exec(strings, vals, options);
  }
  return exec(stringsOrOptions as TemplateStringsArray, values, {});
}
