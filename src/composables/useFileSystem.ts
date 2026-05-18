import { invoke } from '@tauri-apps/api/core'
import { open } from '@tauri-apps/plugin-dialog'
import type { SvgFileEntry } from '../types'

const STORAGE_KEY = 'svg-viewer-last-dir'

/** Open a native folder-picker dialog. Returns the chosen path or `null`. */
export async function selectFolder(): Promise<string | null> {
  const selected = await open({
    directory: true,
    multiple: false,
    title: 'Select SVG Folder',
  })
  return selected as string | null
}

/** Recursively scan `dirPath` for .svg files (sorted by relative path). */
export async function scanSvgFiles(dirPath: string): Promise<SvgFileEntry[]> {
  return invoke<SvgFileEntry[]>('scan_svg_files', { dirPath })
}

/** Read a text file and return its content. */
export async function readTextFile(filePath: string): Promise<string> {
  return invoke<string>('read_text_file', { filePath })
}

/** Persist the last-opened directory path to localStorage. */
export function saveLastDir(dirPath: string): void {
  try {
    localStorage.setItem(STORAGE_KEY, dirPath)
  } catch {
    // localStorage may be unavailable in some contexts
  }
}

/** Retrieve the last-opened directory path from localStorage. */
export function loadLastDir(): string | null {
  try {
    return localStorage.getItem(STORAGE_KEY)
  } catch {
    return null
  }
}
