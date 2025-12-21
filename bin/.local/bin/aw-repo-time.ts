#!/usr/bin/env -S npx tsx

/**
 * ActivityWatch Repo Time Tracker
 * Parses terminal window titles (format: org/repo:branch [cmd]) and shows time spent per repo
 */

const AW_HOST = "http://localhost:5600";

const c = {
  reset: "\x1b[0m",
  bold: "\x1b[1m",
  dim: "\x1b[2m",
  cyan: "\x1b[36m",
  yellow: "\x1b[33m",
  green: "\x1b[32m",
  magenta: "\x1b[35m",
};

interface AWEvent {
  timestamp: string;
  duration: number;
  data: {
    app?: string;
    title?: string;
    status?: string;
  };
}

interface RepoTime {
  repo: string;
  branch: string;
  commands: Map<string, number>;
  total: number;
}

async function query(bucketId: string, start: Date, end: Date): Promise<AWEvent[]> {
  const params = new URLSearchParams({
    start: start.toISOString(),
    end: end.toISOString(),
  });
  const res = await fetch(`${AW_HOST}/api/0/buckets/${bucketId}/events?${params}`);
  if (!res.ok) throw new Error(`Failed to fetch ${bucketId}: ${res.statusText}`);
  return res.json();
}

async function findBucket(prefix: string): Promise<string | null> {
  const res = await fetch(`${AW_HOST}/api/0/buckets`);
  const buckets = await res.json();
  const match = Object.keys(buckets).find((name) => name.startsWith(prefix));
  return match || null;
}

function parseTitle(title: string): { repo: string; branch: string; cmd: string } | null {
  // Format: org/repo:branch [cmd] or just repo:branch [cmd] or repo [cmd]
  const match = title.match(/^(.+?)(?::(\S+))?\s+\[(.+)\]$/);
  if (!match) return null;
  return {
    repo: match[1],
    branch: match[2] || "default",
    cmd: match[3],
  };
}

function formatDuration(seconds: number, pad = 8): string {
  const h = Math.floor(seconds / 3600);
  const m = Math.floor((seconds % 3600) / 60);
  const s = Math.floor(seconds % 60);
  let str: string;
  if (h > 0) str = `${h}h ${m}m`;
  else if (m > 0) str = `${m}m ${s}s`;
  else str = `${s}s`;
  return str.padStart(pad);
}

function intersectPeriods(events: AWEvent[], afkEvents: AWEvent[]): AWEvent[] {
  // Filter events to only include time when not-afk
  const notAfk = afkEvents.filter((e) => e.data.status === "not-afk");
  const result: AWEvent[] = [];

  for (const event of events) {
    const eventStart = new Date(event.timestamp).getTime();
    const eventEnd = eventStart + event.duration * 1000;

    for (const afk of notAfk) {
      const afkStart = new Date(afk.timestamp).getTime();
      const afkEnd = afkStart + afk.duration * 1000;

      // Find overlap
      const overlapStart = Math.max(eventStart, afkStart);
      const overlapEnd = Math.min(eventEnd, afkEnd);

      if (overlapStart < overlapEnd) {
        result.push({
          ...event,
          timestamp: new Date(overlapStart).toISOString(),
          duration: (overlapEnd - overlapStart) / 1000,
        });
      }
    }
  }
  return result;
}

function parseArgs(): { start: Date; end: Date; label: string } {
  const args = process.argv.slice(2);
  const now = new Date();
  const today = new Date(now.getFullYear(), now.getMonth(), now.getDate());
  const DAY = 24 * 60 * 60 * 1000;

  if (args.includes("--help") || args.includes("-h")) {
    console.log(`Usage: aw-repo-time.ts [--yesterday | --week]

  --yesterday, -y   Show yesterday's data
  --week, -w        Show last 7 days
  (default)         Show today's data`);
    process.exit(0);
  }

  if (args.includes("--yesterday") || args.includes("-y")) {
    const start = new Date(today.getTime() - DAY);
    return { start, end: today, label: start.toLocaleDateString() };
  }

  if (args.includes("--week") || args.includes("-w")) {
    const start = new Date(today.getTime() - 7 * DAY);
    const end = new Date(today.getTime() + DAY);
    return {
      start,
      end,
      label: `${start.toLocaleDateString()} - ${today.toLocaleDateString()}`,
    };
  }

  // Default: today
  return { start: today, end: new Date(today.getTime() + DAY), label: today.toLocaleDateString() };
}

async function main() {
  const { start, end, label } = parseArgs();

  // Find buckets
  const windowBucket = await findBucket("aw-watcher-window_");
  const afkBucket = await findBucket("aw-watcher-afk_");

  if (!windowBucket || !afkBucket) {
    console.error("Could not find required buckets");
    process.exit(1);
  }

  // Fetch events
  const [windowEvents, afkEvents] = await Promise.all([
    query(windowBucket, start, end),
    query(afkBucket, start, end),
  ]);

  // Filter for terminal (Alacritty) and intersect with not-afk
  const terminalEvents = windowEvents.filter(
    (e) => e.data.app?.toLowerCase() === "alacritty"
  );
  const activeTerminal = intersectPeriods(terminalEvents, afkEvents);

  // Group by day, then by repo:branch
  const dayMap = new Map<string, Map<string, RepoTime>>();

  for (const event of activeTerminal) {
    const parsed = parseTitle(event.data.title || "");
    if (!parsed) continue;

    const day = new Date(event.timestamp).toLocaleDateString();
    if (!dayMap.has(day)) dayMap.set(day, new Map());
    const repoMap = dayMap.get(day)!;

    const key = `${parsed.repo}:${parsed.branch}`;
    let entry = repoMap.get(key);
    if (!entry) {
      entry = { repo: parsed.repo, branch: parsed.branch, commands: new Map(), total: 0 };
      repoMap.set(key, entry);
    }
    entry.total += event.duration;
    entry.commands.set(parsed.cmd, (entry.commands.get(parsed.cmd) || 0) + event.duration);
  }

  // Sort days chronologically (most recent first)
  const sortedDays = [...dayMap.keys()].sort(
    (a, b) => new Date(b).getTime() - new Date(a).getTime()
  );

  // Print results
  console.log();

  if (sortedDays.length === 0) {
    console.log("No terminal activity tracked.");
    return;
  }

  let grandTotal = 0;
  for (const day of sortedDays) {
    const repoMap = dayMap.get(day)!;
    const sorted = [...repoMap.values()].sort((a, b) => b.total - a.total);
    const dayTotal = sorted.reduce((sum, e) => sum + e.total, 0);
    grandTotal += dayTotal;

    console.log(`${c.bold}${c.cyan}${formatDuration(dayTotal)}${c.reset}  ${c.bold}${day}${c.reset}`);
    for (const entry of sorted) {
      const cmdSorted = [...entry.commands.entries()].sort((a, b) => b[1] - a[1]);
      const cmds = cmdSorted.map(([cmd, dur]) => `${c.dim}[${cmd}]${c.reset} ${formatDuration(dur, 0)}`).join(", ");
      console.log(`${c.yellow}${formatDuration(entry.total)}${c.reset}  ${c.green}${entry.repo}${c.reset}:${c.magenta}${entry.branch}${c.reset}  ${cmds}`);
    }
    console.log();
  }

  console.log(`${c.bold}${formatDuration(grandTotal)}  Total${c.reset}`);
}

main().catch((err) => {
  console.error("Error:", err.message);
  process.exit(1);
});
