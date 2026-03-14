import { execSync } from "child_process";

interface ScreenInfo {
  width: number;
  height: number;
}

function getScreenInfo(): ScreenInfo {
  const raw = execSync("hyprctl monitors -j", { encoding: "utf-8" });
  const monitors = JSON.parse(raw);
  return { width: monitors[0].width, height: monitors[0].height };
}

const WAYBAR_HEIGHT = 20;
const SMALL_GRAPH_COUNT = 5;
const SMALL_GRAPH_HEIGHT = 120;

const screen = getScreenInfo();
const sidebarHeight = screen.height - WAYBAR_HEIGHT;
const bigGraphHeight = sidebarHeight - SMALL_GRAPH_COUNT * SMALL_GRAPH_HEIGHT;

export { screen, sidebarHeight, bigGraphHeight, SMALL_GRAPH_HEIGHT };
