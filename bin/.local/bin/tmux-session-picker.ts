#!/usr/bin/env node
import { spawnSync } from "node:child_process";
import { $ } from "./zx-polyfill.ts";

// --- ANSI colors ---

const C = {
  reset: "\x1b[0m",
  bold: "\x1b[1m",
  dim: "\x1b[2m",
  green: "\x1b[32m",
  yellow: "\x1b[33m",
  cyan: "\x1b[36m",
} as const;

// --- Types ---

interface SessionInfo {
  name: string;
  attached: boolean;
  lastAttached: number;
  activity: number;
  panePath: string;
  windows: number;
  branch: string;
  repo: string;
}

interface SesEntry {
  type: "ssh" | "dir";
  raw: string; // full line from ses-entries.sh, passed to ses.sh as $1
  display: string; // shown in fzf (~ substituted, no colors)
  atime?: number; // unix seconds, dirs only
}

// --- Git info with caching ---

const gitCache = new Map<string, { branch: string; repo: string } | null>();

async function getGitInfo(
  path: string
): Promise<{ branch: string; repo: string } | null> {
  const result =
    await $({ nothrow: true })`git -C ${path} rev-parse --show-toplevel --abbrev-ref HEAD`;
  if (result.exitCode !== 0) return null;

  const lines = result.stdout.trim().split("\n");
  const toplevel = lines[0];
  const branch = lines[1] ?? "";

  if (gitCache.has(toplevel)) return gitCache.get(toplevel)!;

  let url = "";
  const urlResult =
    await $({ nothrow: true })`git -C ${toplevel} config --get remote.origin.url`;
  url = urlResult.stdout.trim();

  if (!url) {
    const remoteResult =
      await $({ nothrow: true })`git -C ${toplevel} remote`;
    const remote = remoteResult.stdout.trim().split("\n")[0];
    if (remote) {
      const altResult =
        await $({ nothrow: true })`git -C ${toplevel} config --get remote.${remote}.url`;
      url = altResult.stdout.trim();
    }
  }

  let repo = "";
  if (url) {
    url = url.replace(/\.git$/, "");
    const match = url.match(/[/:]([^/:]+\/[^/:]+)$/);
    if (match) repo = match[1];
  }

  if (!branch && !repo) {
    gitCache.set(toplevel, null);
    return null;
  }

  const info = { branch, repo };
  gitCache.set(toplevel, info);
  return info;
}

// --- Helpers ---

function formatAge(seconds: number): string {
  if (seconds < 60) return `${seconds}s`;
  if (seconds < 3600) return `${Math.floor(seconds / 60)}m`;
  if (seconds < 86400) return `${Math.floor(seconds / 3600)}h`;
  return `${Math.floor(seconds / 86400)}d`;
}

function formatRelativeTime(ts: number): string {
  if (!ts || ts <= 0) return "never";
  const now = new Date();
  const then = new Date(ts * 1000);
  const diffSec = Math.floor((now.getTime() - then.getTime()) / 1000);

  if (diffSec < 0) return "in the future";
  if (diffSec < 60) return `${diffSec}s ago`;
  if (diffSec < 3600) return `${Math.floor(diffSec / 60)}m ago`;
  if (diffSec < 6 * 3600) return `${Math.floor(diffSec / 3600)}h ago`;

  const hh = String(then.getHours()).padStart(2, "0");
  const mm = String(then.getMinutes()).padStart(2, "0");
  const time = `${hh}:${mm}`;

  const startOfDay = (d: Date): number =>
    new Date(d.getFullYear(), d.getMonth(), d.getDate()).getTime();
  const daysAgo = Math.round(
    (startOfDay(now) - startOfDay(then)) / 86400000
  );

  if (daysAgo === 0) {
    const h = then.getHours();
    if (h < 12) return `this morning ${time}`;
    if (h < 18) return `this afternoon ${time}`;
    return `this evening ${time}`;
  }

  if (daysAgo === 1) {
    const h = then.getHours();
    if (h >= 18 && now.getHours() < 12) return `last night ${time}`;
    return `yesterday ${time}`;
  }

  if (daysAgo < 7) {
    const weekday = then.toLocaleDateString("en-US", { weekday: "long" });
    return `last ${weekday} ${time}`;
  }

  const dayMonth = then.toLocaleDateString("en-GB", {
    day: "numeric",
    month: "short",
  });
  if (then.getFullYear() !== now.getFullYear()) {
    return `${dayMonth} '${String(then.getFullYear()).slice(2)}`;
  }
  return dayMonth;
}

// --- Ses entries (directories + SSH hosts from ses-entries.sh) ---

function toSessionName(entry: SesEntry): string {
  if (entry.type === "ssh") {
    const afterSsh = entry.raw.slice(4); // remove "ssh " prefix
    const firstAlias = afterSsh.split(/[,| ]/)[0].trim();
    return `ssh_${firstAlias.replace(/\./g, "_")}`;
  }
  const basename = entry.raw.split("/").pop() ?? "";
  return basename.replace(/\./g, "_");
}

async function getSesEntries(
  existingNames: Set<string>
): Promise<SesEntry[]> {
  const result = await $({ nothrow: true })`ses-entries.sh`;
  if (result.exitCode !== 0) return [];

  const home = process.env.HOME ?? "";
  const lines = result.stdout.trim().split("\n").filter(Boolean);
  const entries: SesEntry[] = [];

  for (const line of lines) {
    if (line.startsWith("ssh ")) {
      const display = home ? line.replace(home, "~") : line;
      const entry: SesEntry = { type: "ssh", raw: line, display };
      if (existingNames.has(toSessionName(entry))) continue;
      entries.push(entry);
      continue;
    }

    const tabIdx = line.indexOf("\t");
    if (tabIdx === -1) continue;
    const atime = parseFloat(line.slice(0, tabIdx));
    const path = line.slice(tabIdx + 1);
    const display = home ? path.replace(home, "~") : path;
    const entry: SesEntry = {
      type: "dir",
      raw: path,
      display,
      atime: Number.isFinite(atime) && atime > 0 ? atime : undefined,
    };
    if (existingNames.has(toSessionName(entry))) continue;
    entries.push(entry);
  }

  return entries;
}

function formatSesEntries(entries: SesEntry[]): string[] {
  const rows = entries.map((e) => ({
    e,
    age: e.atime !== undefined ? formatRelativeTime(e.atime) : "",
  }));
  const maxDisplay = Math.max(0, ...rows.map((r) => r.e.display.length));
  return rows.map(({ e, age }) => {
    const padded = e.display.padEnd(maxDisplay);
    const ageCol = age ? `  ${C.dim}${age}${C.reset}` : "";
    return `${e.raw}\t  ${padded}${ageCol}`;
  });
}

// --- Session data ---

async function getSessions(): Promise<SessionInfo[]> {
  const FS = "\x1f";
  const format = [
    "#{session_name}",
    "#{session_attached}",
    "#{session_last_attached}",
    "#{session_activity}",
    "#{pane_current_path}",
    "#{session_windows}",
  ].join(FS);

  const result = await $`tmux list-sessions -F ${format}`;
  const lines = result.stdout.trim().split("\n").filter(Boolean);

  return Promise.all(
    lines.map(async (line) => {
      const [name, attached, lastAttached, activity, panePath, windows] =
        line.split(FS);
      const gitInfo = await getGitInfo(panePath);
      return {
        name,
        attached: attached !== "0",
        lastAttached: parseInt(lastAttached, 10),
        activity: parseInt(activity, 10),
        panePath,
        windows: parseInt(windows, 10),
        branch: gitInfo?.branch ?? "",
        repo: gitInfo?.repo ?? "",
      };
    })
  );
}

// --- Aligned formatting ---

function formatLines(sessions: SessionInfo[]): string[] {
  const now = Math.floor(Date.now() / 1000);

  const rows = sessions.map((s) => ({
    s,
    marker: s.attached ? "*" : " ",
    age: formatAge(now - s.activity),
    win: `${s.windows}w`,
  }));

  const maxName = Math.max(0, ...rows.map((r) => r.s.name.length));
  const maxBranch = Math.max(0, ...rows.map((r) => r.s.branch.length));
  const maxRepo = Math.max(0, ...rows.map((r) => r.s.repo.length));
  const maxAge = Math.max(0, ...rows.map((r) => r.age.length));
  const maxWin = Math.max(0, ...rows.map((r) => r.win.length));

  rows.sort((a, b) => b.s.lastAttached - a.s.lastAttached);

  return rows.map((r) => {
    let display = "";
    display += `${C.green}${r.marker}${C.reset} `;
    display += `${C.bold}${r.s.name.padEnd(maxName)}${C.reset}  `;

    if (maxBranch > 0) {
      display += `${C.yellow}${r.s.branch.padEnd(maxBranch)}${C.reset}  `;
    }
    if (maxRepo > 0) {
      display += `${C.cyan}${r.s.repo.padEnd(maxRepo)}${C.reset}  `;
    }

    display += `${C.dim}${r.age.padStart(maxAge)}${C.reset} `;
    display += `${C.dim}${r.win.padStart(maxWin)}${C.reset}`;

    return `${r.s.name}\t${display}`;
  });
}

// --- Main ---

const SEPARATOR_KEY = "__separator__";

async function main(): Promise<void> {
  const sessions = await getSessions();
  const sessionLines = formatLines(sessions);

  if (process.argv.includes("--list")) {
    process.stdout.write(sessionLines.join("\n") + "\n");
    return;
  }

  const existingNames = new Set(sessions.map((s) => s.name));
  const sesEntries = await getSesEntries(existingNames);
  const sesLines = formatSesEntries(sesEntries);

  const allLines = [...sessionLines];
  if (sesLines.length > 0) {
    allLines.push(
      `${SEPARATOR_KEY}\t  ${C.dim}─── new sessions ───${C.reset}`
    );
    allLines.push(...sesLines);
  }

  const input = allLines.join("\n");

  const previewCmd = [
    "if tmux has-session -t {1} 2>/dev/null; then",
    '  tmux capture-pane -t {1} -p -e 2>/dev/null | tr -d "\\r" | tail -n 50;',
    "elif [ -d {1} ]; then",
    "  ls -la --color=always {1};",
    'elif echo {1} | grep -q "^ssh "; then',
    "  a=$(echo {1} | sed 's/^ssh //' | cut -d'|' -f1 | cut -d',' -f1 | tr -d ' ');",
    '  ssh -G "$a" 2>/dev/null | grep -iE "^(hostname|user|port|identityfile|proxyjump) ";',
    "fi",
  ].join(" ");

  const fzfArgs = [
    "--ansi",
    "--no-sort",
    `--delimiter=\t`,
    "--with-nth=2",
    "--header-lines=1",
    `--preview=${previewCmd}`,
    "--preview-window=right:50%",
    "--prompt=session > ",
    "--no-info",
  ];

  const result = await $({ input, nothrow: true })`fzf ${fzfArgs}`;
  if (result.exitCode !== 0) return;

  const target = result.stdout.trim().split("\t")[0];
  if (target === SEPARATOR_KEY) return;

  if (target.startsWith("/") || target.startsWith("ssh ")) {
    const sesScript = `${process.env.HOME}/.local/bin/ses.sh`;
    spawnSync(sesScript, [target], { stdio: "inherit" });
  } else {
    await $`tmux switch-client -t ${target}`;
  }
}

main();
