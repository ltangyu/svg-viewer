/** Mirrors the Rust `SvgFileEntry` struct returned by `scan_svg_files`. */
export interface SvgFileEntry {
  /** File name only, e.g. "icon.svg" */
  name: string
  /** Absolute path on disk */
  path: string
  /** Path relative to chosen root, forward-slash separated */
  relative_path: string
  /** File size in bytes */
  size: number
}

/** View state for the root App component. */
export type ViewState = 'landing' | 'browser'

/** Metadata extracted from a successfully parsed <svg> root. */
export interface SvgInfo {
  /** e.g. "0 0 100 100"; null when absent */
  viewBox: string | null
  /** numeric width from svg.width.baseVal.value; null when %/auto */
  intrinsicWidth: number | null
  /** numeric height; null when %/auto */
  intrinsicHeight: number | null
  /** True if any animate/animateTransform/animateMotion/set elements found */
  hasSmilAnimations: boolean
  /** True if any descendant has CSS animation-name */
  hasCssAnimations: boolean
  /** True if any <script> element is present */
  hasScripts: boolean
}

/** Cycle states for transparency background. */
export type BackgroundMode = 'checker' | 'white' | 'black' | 'none'
