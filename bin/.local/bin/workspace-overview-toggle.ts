#!/usr/bin/env node
import { $ } from "./zx-polyfill.ts";

// Hard-coded workspace order from hyprland.conf
const ORDER = [
  "work",
  "edit",
  "read",
  "talk",
  "youtube",
  "spotify",
  "meet",
  "incognito",
  "presentation",
];

const ICON_CAP = 6;

interface HyprMonitor {
  id: number;
  name: string;
  focused: boolean;
}
interface HyprWorkspace {
  id: number;
  name: string;
  monitor: string;
  windows: number;
}
interface HyprClient {
  address: string;
  workspace: { id: number; name: string };
  class: string;
  title: string;
  focusHistoryID: number;
}
interface HyprActiveWorkspace {
  id: number;
  name: string;
}
interface HyprActiveWindow {
  address?: string;
}

interface SnapshotWindow {
  address: string;
  class: string;
  title: string;
  icon: string;
  focused: boolean;
}
interface SnapshotWorkspace {
  name: string;
  monitor: string;
  windows: SnapshotWindow[];
  focused: boolean;
  isSpecial: boolean;
  iconStrip: string[];
  overflowLabel: string;
}
interface Snapshot {
  groups: { monitor: string; workspaces: SnapshotWorkspace[] }[];
  specials: SnapshotWorkspace[];
  defaultHovered: string;
  byName: Record<string, SnapshotWorkspace>;
}

async function hyprctlJson<T>(cmd: string): Promise<T> {
  const result = await $`hyprctl -j ${cmd}`;
  return JSON.parse(result.stdout) as T;
}

async function isOpen(): Promise<boolean> {
  const result = await $({ nothrow: true })`eww active-windows`;
  if (result.exitCode !== 0) return false;
  return /^workspace-overview\b/m.test(result.stdout);
}

function iconNameFor(cls: string): string {
  if (!cls) return "application-x-executable";
  return cls.toLowerCase();
}

function orderIndex(name: string): number {
  const i = ORDER.indexOf(name);
  return i >= 0 ? i : ORDER.length + name.charCodeAt(0);
}

async function buildSnapshot(): Promise<{
  snapshot: Snapshot;
  focusedMonitorId: number;
}> {
  const [monitors, workspaces, clients, activeWs, activeWin] =
    await Promise.all([
      hyprctlJson<HyprMonitor[]>("monitors"),
      hyprctlJson<HyprWorkspace[]>("workspaces"),
      hyprctlJson<HyprClient[]>("clients"),
      hyprctlJson<HyprActiveWorkspace>("activeworkspace"),
      hyprctlJson<HyprActiveWindow>("activewindow"),
    ]);

  const focusedMonitor =
    monitors.find((m) => m.focused) ?? monitors[0];
  if (!focusedMonitor) {
    throw new Error("no monitors returned by hyprctl");
  }

  const clientsByWs = new Map<string, HyprClient[]>();
  for (const c of clients) {
    if (!c.workspace?.name) continue;
    const arr = clientsByWs.get(c.workspace.name);
    if (arr) arr.push(c);
    else clientsByWs.set(c.workspace.name, [c]);
  }

  function buildWorkspace(
    ws: HyprWorkspace,
    isSpecial: boolean
  ): SnapshotWorkspace {
    const raw = clientsByWs.get(ws.name) ?? [];
    raw.sort((a, b) => a.focusHistoryID - b.focusHistoryID);
    const wins: SnapshotWindow[] = raw.map((c) => ({
      address: c.address,
      class: c.class,
      title: c.title || c.class || "(untitled)",
      icon: iconNameFor(c.class),
      focused: !!activeWin?.address && c.address === activeWin.address,
    }));
    const iconStrip = wins.slice(0, ICON_CAP).map((w) => w.icon);
    const overflow = wins.length - ICON_CAP;
    return {
      name: ws.name,
      monitor: ws.monitor,
      windows: wins,
      focused: ws.name === activeWs.name,
      isSpecial,
      iconStrip,
      overflowLabel: overflow > 0 ? `+${overflow}` : "",
    };
  }

  const active = workspaces.filter((w) => w.windows > 0);
  const normalWs = active
    .filter((w) => !w.name.startsWith("special:"))
    .map((w) => buildWorkspace(w, false));
  const specialWs = active
    .filter((w) => w.name.startsWith("special:"))
    .map((w) => buildWorkspace(w, true));

  const monitorOrder = [
    focusedMonitor.name,
    ...monitors.filter((m) => !m.focused).map((m) => m.name),
  ];
  const groups = monitorOrder
    .map((mon) => ({
      monitor: mon,
      workspaces: normalWs
        .filter((ws) => ws.monitor === mon)
        .sort((a, b) => orderIndex(a.name) - orderIndex(b.name)),
    }))
    .filter((g) => g.workspaces.length > 0);

  const byName: Record<string, SnapshotWorkspace> = {};
  for (const ws of [...normalWs, ...specialWs]) byName[ws.name] = ws;

  // If the focused workspace is empty (no windows), fall back to the
  // first active workspace so the side panel has something to show.
  let defaultHovered = activeWs.name;
  if (!byName[defaultHovered]) {
    const first = normalWs[0] ?? specialWs[0];
    if (first) defaultHovered = first.name;
  }

  return {
    snapshot: { groups, specials: specialWs, defaultHovered, byName },
    focusedMonitorId: focusedMonitor.id,
  };
}

async function main(): Promise<void> {
  const dryRun = process.argv.includes("--dry-run");

  if (!dryRun && (await isOpen())) {
    await $({ nothrow: true })`eww close workspace-overview workspace-overview-backdrop`;
    return;
  }

  const { snapshot, focusedMonitorId } = await buildSnapshot();
  const json = JSON.stringify(snapshot);

  if (dryRun) {
    process.stdout.write(json + "\n");
    return;
  }

  await $`eww update ${`workspace_data=${json}`}`;
  await $`eww update ${`hovered_ws=${snapshot.defaultHovered}`}`;
  const screen = String(focusedMonitorId);
  await $`eww open workspace-overview-backdrop --screen ${screen}`;
  await $`eww open workspace-overview --screen ${screen}`;
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
