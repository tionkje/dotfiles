#!/usr/bin/env node
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

async function main(): Promise<void> {
  const sessions = await getSessions();
  const lines = formatLines(sessions);

  if (process.argv.includes("--list")) {
    process.stdout.write(lines.join("\n") + "\n");
    return;
  }

  const input = lines.join("\n");
  // 2>/dev/null: capture-pane may fail transiently as user navigates fzf
  const previewCmd =
    'tmux capture-pane -t {1} -p -e 2>/dev/null | tr -d "\\r" | tail -n 50';
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
  await $`tmux switch-client -t ${target}`;
}

main();
