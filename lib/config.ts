import { join } from "path";

// Centralized configuration for sprite-mobile.
// Mirrors the environment variables from claude-hub's internal/config/config.go
// so both services share a consistent view of directories.

/** User's home directory. */
export const HOME_DIR = process.env.HOME || "/home/sprite";

/**
 * Working directory where Claude processes are spawned.
 * Defaults to HOME if CLAUDE_WORK_DIR is not set.
 */
export const WORK_DIR = process.env.CLAUDE_WORK_DIR || HOME_DIR;

/**
 * Encode a filesystem path the way Claude does for its projects directory names.
 * Each "/" is replaced with "-".
 * e.g. "/home/sprite" becomes "-home-sprite"
 */
function encodePath(path: string): string {
  return path.replace(/\//g, "-");
}

/**
 * Directory where Claude stores session .jsonl files.
 * Computed from WORK_DIR unless explicitly overridden via CLAUDE_PROJECTS_DIR.
 */
export const CLAUDE_PROJECTS_DIR =
  process.env.CLAUDE_PROJECTS_DIR ||
  join(HOME_DIR, ".claude", "projects", encodePath(WORK_DIR));
