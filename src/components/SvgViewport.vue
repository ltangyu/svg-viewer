<script setup lang="ts">
import { ref, computed, watch, onMounted, onUnmounted, nextTick } from 'vue'
import type { SvgInfo, BackgroundMode } from '../types'
import ViewerToolbar from './ViewerToolbar.vue'
import SvgInfoBadge from './SvgInfoBadge.vue'
import SvgSourceView from './SvgSourceView.vue'

const props = defineProps<{
  svgText: string
  filePath: string
}>()

/* ── Refs ───────────────────────────────────────── */
const hostRef = ref<HTMLDivElement | null>(null)
const stageRef = ref<HTMLDivElement | null>(null)
const svgEl = ref<SVGSVGElement | null>(null)
const info = ref<SvgInfo | null>(null)
const parseError = ref<string>('')

/* ── State ──────────────────────────────────────── */
const zoom = ref(1)
const tx = ref(0)
const ty = ref(0)
const bgMode = ref<BackgroundMode>('checker')
const playing = ref(true)
const sourceOpen = ref(false)

const MIN_ZOOM = 0.05
const MAX_ZOOM = 64
const BG_CYCLE: BackgroundMode[] = ['checker', 'white', 'black', 'none']

const hasAnim = computed(() =>
  !!info.value && (info.value.hasSmilAnimations || info.value.hasCssAnimations)
)

const stageStyle = computed(() => ({
  transform: `translate(${tx.value}px, ${ty.value}px) scale(${zoom.value})`,
  transformOrigin: '0 0',
}))

/* ── SVG Injection ──────────────────────────────── */
function injectSvg(text: string) {
  if (!stageRef.value) return
  stageRef.value.replaceChildren()
  svgEl.value = null
  info.value = null
  parseError.value = ''
  // Reset playing state on each load
  playing.value = true
  hostRef.value?.classList.remove('paused')

  if (!text) return

  const doc = new DOMParser().parseFromString(text, 'image/svg+xml')
  const errorEl = doc.querySelector('parsererror')
  if (errorEl) {
    parseError.value = errorEl.textContent?.slice(0, 200) ?? 'Invalid SVG'
    return
  }

  // Pick the first <svg> root
  const root: Element | null =
    doc.documentElement.tagName.toLowerCase() === 'svg'
      ? doc.documentElement
      : doc.querySelector('svg')
  if (!root) {
    parseError.value = 'No <svg> root element found.'
    return
  }

  const adopted = document.adoptNode(root) as SVGSVGElement

  // Capture intrinsic dimensions from original attributes BEFORE stripping them
  const origWidthAttr = adopted.getAttribute('width')
  const origHeightAttr = adopted.getAttribute('height')
  const parseSvgLen = (v: string | null): number | null => {
    if (!v) return null
    const m = v.trim().match(/^(-?\d+(?:\.\d+)?)/)
    if (!m) return null
    const n = parseFloat(m[1])
    return isNaN(n) ? null : n
  }
  const intrinsicW = parseSvgLen(origWidthAttr)
  const intrinsicH = parseSvgLen(origHeightAttr)

  // Ensure a viewBox exists (synthesize from width/height if needed)
  if (!adopted.getAttribute('viewBox') && intrinsicW && intrinsicH && intrinsicW > 0 && intrinsicH > 0) {
    adopted.setAttribute('viewBox', `0 0 ${intrinsicW} ${intrinsicH}`)
  }

  // Compute the SVG's logical size from viewBox (preferred) or intrinsic attrs.
  // Set the element to exactly this size so the stage's CSS transform math is consistent.
  let logicalW = intrinsicW ?? 0
  let logicalH = intrinsicH ?? 0
  const vbAttr = adopted.getAttribute('viewBox')
  if (vbAttr) {
    const p = vbAttr.trim().split(/[\s,]+/).map(parseFloat)
    if (p.length === 4 && !p.some(isNaN) && p[2] > 0 && p[3] > 0) {
      logicalW = p[2]
      logicalH = p[3]
    }
  }
  if (logicalW <= 0 || logicalH <= 0) {
    // Last-resort default; getBBox() will refine after mount
    logicalW = 300
    logicalH = 150
  }

  adopted.removeAttribute('width')
  adopted.removeAttribute('height')
  adopted.style.width = logicalW + 'px'
  adopted.style.height = logicalH + 'px'
  adopted.style.display = 'block'
  adopted.setAttribute('preserveAspectRatio', 'xMidYMid meet')

  stageRef.value.appendChild(adopted)

  // Rebuild <script> elements so they execute (adopt/innerHTML does NOT run them)
  const oldScripts = Array.from(adopted.querySelectorAll('script'))
  for (const old of oldScripts) {
    const fresh = document.createElement('script') as HTMLScriptElement
    for (const a of Array.from(old.attributes)) {
      fresh.setAttribute(a.name, a.value)
    }
    fresh.textContent = old.textContent
    old.replaceWith(fresh)
  }

  svgEl.value = adopted
  info.value = analyzeSvg(adopted, intrinsicW, intrinsicH)

  // Fit on next frame so getBBox() / layout is ready
  requestAnimationFrame(() => fit())
}

function analyzeSvg(svg: SVGSVGElement, intrinsicW: number | null, intrinsicH: number | null): SvgInfo {
  const vb = svg.getAttribute('viewBox')
  // Prefer captured original intrinsic dims; fall back to viewBox when available
  let iw = intrinsicW
  let ih = intrinsicH
  if ((iw === null || ih === null) && vb) {
    const parts = vb.trim().split(/[\s,]+/).map(parseFloat)
    if (parts.length === 4 && !parts.some(isNaN)) {
      if (iw === null) iw = parts[2]
      if (ih === null) ih = parts[3]
    }
  }
  const hasSmil = !!svg.querySelector('animate, animateTransform, animateMotion, set')
  const hasScripts = !!svg.querySelector('script')

  // CSS animation detection — bounded walk (max 5000 nodes)
  let hasCss = false
  const all = svg.querySelectorAll('*')
  const cap = Math.min(all.length, 5000)
  for (let i = 0; i < cap; i++) {
    const name = getComputedStyle(all[i]).animationName
    if (name && name !== 'none') {
      hasCss = true
      break
    }
  }

  return {
    viewBox: vb,
    intrinsicWidth: iw,
    intrinsicHeight: ih,
    hasSmilAnimations: hasSmil,
    hasCssAnimations: hasCss,
    hasScripts,
  }
}

/* ── Zoom / Pan ─────────────────────────────────── */
function zoomAtPoint(factor: number, clientX: number, clientY: number) {
  if (!hostRef.value) return
  const rect = hostRef.value.getBoundingClientRect()
  const px = clientX - rect.left
  const py = clientY - rect.top
  const newZoom = Math.min(MAX_ZOOM, Math.max(MIN_ZOOM, zoom.value * factor))
  const ratio = newZoom / zoom.value
  // Pin the world point under the cursor
  tx.value = px - (px - tx.value) * ratio
  ty.value = py - (py - ty.value) * ratio
  zoom.value = newZoom
}

function onWheel(e: WheelEvent) {
  if ((e.target as HTMLElement)?.closest('.toolbar, .source-panel, .info-badge')) return
  e.preventDefault()
  const factor = e.deltaY < 0 ? 1.15 : 1 / 1.15
  zoomAtPoint(factor, e.clientX, e.clientY)
}

let dragging = false
let lastX = 0
let lastY = 0

function onMouseDown(e: MouseEvent) {
  if (e.button !== 0) return
  if ((e.target as HTMLElement)?.closest('.toolbar, .source-panel, .info-badge')) return
  dragging = true
  lastX = e.clientX
  lastY = e.clientY
  hostRef.value?.classList.add('dragging')
}
function onMouseMove(e: MouseEvent) {
  if (!dragging) return
  tx.value += e.clientX - lastX
  ty.value += e.clientY - lastY
  lastX = e.clientX
  lastY = e.clientY
}
function onMouseUp() {
  dragging = false
  hostRef.value?.classList.remove('dragging')
}

function getContentSize(): { w: number; h: number } {
  if (!svgEl.value) return { w: 100, h: 100 }
  const vb = svgEl.value.viewBox?.baseVal
  if (vb && vb.width > 0 && vb.height > 0) {
    return { w: vb.width, h: vb.height }
  }
  // Fallback to bounding box
  try {
    const bb = svgEl.value.getBBox()
    return { w: bb.width || 100, h: bb.height || 100 }
  } catch {
    return { w: 100, h: 100 }
  }
}

function fit() {
  if (!hostRef.value || !svgEl.value) return
  const host = hostRef.value.getBoundingClientRect()
  const { w, h } = getContentSize()
  const pad = 0.92
  const fitZoom = Math.min(host.width / w, host.height / h) * pad
  zoom.value = Math.min(MAX_ZOOM, Math.max(MIN_ZOOM, fitZoom))
  tx.value = (host.width - w * zoom.value) / 2
  ty.value = (host.height - h * zoom.value) / 2
}

function actualSize() {
  if (!hostRef.value || !svgEl.value) return
  const host = hostRef.value.getBoundingClientRect()
  const { w, h } = getContentSize()
  zoom.value = 1
  tx.value = (host.width - w) / 2
  ty.value = (host.height - h) / 2
}

function zoomIn() {
  if (!hostRef.value) return
  const r = hostRef.value.getBoundingClientRect()
  zoomAtPoint(1.25, r.left + r.width / 2, r.top + r.height / 2)
}
function zoomOut() {
  if (!hostRef.value) return
  const r = hostRef.value.getBoundingClientRect()
  zoomAtPoint(1 / 1.25, r.left + r.width / 2, r.top + r.height / 2)
}
function reset() {
  zoom.value = 1
  tx.value = 0
  ty.value = 0
}

/* ── Animation Control ──────────────────────────── */
function togglePlay() {
  if (!svgEl.value || !info.value) return
  if (playing.value) {
    if (info.value.hasSmilAnimations) {
      try {
        svgEl.value.pauseAnimations()
      } catch {
        /* SMIL may be unsupported on rare configs */
      }
    }
    if (info.value.hasCssAnimations) {
      hostRef.value?.classList.add('paused')
    }
    playing.value = false
  } else {
    if (info.value.hasSmilAnimations) {
      try {
        svgEl.value.unpauseAnimations()
      } catch { /* noop */ }
    }
    hostRef.value?.classList.remove('paused')
    playing.value = true
  }
}

function restart() {
  if (!svgEl.value || !info.value) return
  // SMIL restart
  if (info.value.hasSmilAnimations) {
    try {
      svgEl.value.setCurrentTime(0)
      if (playing.value) svgEl.value.unpauseAnimations()
    } catch { /* noop */ }
  }
  // For CSS + JS animations, the most reliable cross-browser restart is to re-inject
  if (info.value.hasCssAnimations || info.value.hasScripts) {
    injectSvg(props.svgText)
  }
}

/* ── Background ─────────────────────────────────── */
function cycleBg() {
  const idx = BG_CYCLE.indexOf(bgMode.value)
  bgMode.value = BG_CYCLE[(idx + 1) % BG_CYCLE.length]
}

/* ── Source Panel ───────────────────────────────── */
function toggleSource() {
  sourceOpen.value = !sourceOpen.value
  nextTick(() => fit())
}

/* ── Keyboard Shortcuts ─────────────────────────── */
function handleKey(e: KeyboardEvent) {
  const tag = (e.target as HTMLElement)?.tagName
  if (tag === 'INPUT' || tag === 'TEXTAREA') return
  // Skip if Alt/Ctrl/Meta combos (those belong to FileBrowser/global)
  if (e.altKey || e.ctrlKey || e.metaKey) return

  switch (e.key) {
    case '+':
    case '=':
      e.preventDefault()
      zoomIn()
      break
    case '-':
    case '_':
      e.preventDefault()
      zoomOut()
      break
    case '0':
      e.preventDefault()
      actualSize()
      break
    case 'f':
    case 'F':
      e.preventDefault()
      fit()
      break
    case 'r':
      e.preventDefault()
      reset()
      break
    case 'R':
      e.preventDefault()
      restart()
      break
    case ' ':
      if (hasAnim.value) {
        e.preventDefault()
        togglePlay()
      }
      break
    case 'b':
    case 'B':
      e.preventDefault()
      cycleBg()
      break
    case 's':
    case 'S':
      e.preventDefault()
      toggleSource()
      break
  }
}

/* ── Lifecycle ──────────────────────────────────── */
watch(() => props.svgText, (text) => injectSvg(text), { immediate: false })

let resizeObserver: ResizeObserver | null = null
let resizeTimer: ReturnType<typeof setTimeout> | null = null

onMounted(() => {
  injectSvg(props.svgText)
  window.addEventListener('keydown', handleKey)

  if (hostRef.value && 'ResizeObserver' in window) {
    resizeObserver = new ResizeObserver(() => {
      if (resizeTimer) clearTimeout(resizeTimer)
      resizeTimer = setTimeout(() => {
        if (svgEl.value) fit()
      }, 100)
    })
    resizeObserver.observe(hostRef.value)
  }
})

onUnmounted(() => {
  window.removeEventListener('keydown', handleKey)
  resizeObserver?.disconnect()
  if (resizeTimer) clearTimeout(resizeTimer)
})
</script>

<template>
  <div class="viewport-wrap">
    <div
      ref="hostRef"
      class="viewport"
      :class="['bg-' + bgMode]"
      @wheel="onWheel"
      @mousedown="onMouseDown"
      @mousemove="onMouseMove"
      @mouseup="onMouseUp"
      @mouseleave="onMouseUp"
      @dblclick="fit"
    >
      <div ref="stageRef" class="stage" :style="stageStyle">
        <!-- live <svg> appended here by injectSvg() -->
      </div>

      <ViewerToolbar
        :zoom="zoom"
        :playing="playing"
        :bg-mode="bgMode"
        :has-anim="hasAnim"
        :source-open="sourceOpen"
        @zoom-in="zoomIn"
        @zoom-out="zoomOut"
        @fit="fit"
        @actual-size="actualSize"
        @reset="reset"
        @toggle-play="togglePlay"
        @restart="restart"
        @cycle-bg="cycleBg"
        @toggle-source="toggleSource"
      />

      <SvgInfoBadge v-if="info" :info="info" />

      <div v-if="parseError" class="parse-error">
        <span class="status-dot err"></span>
        <span class="parse-error-text">{{ parseError }}</span>
      </div>
    </div>

    <SvgSourceView
      v-if="sourceOpen"
      :svg-text="svgText"
      @close="toggleSource"
    />
  </div>
</template>

<style scoped>
.viewport-wrap {
  position: relative;
  width: 100%;
  height: 100%;
  display: flex;
}

.viewport {
  position: relative;
  flex: 1;
  overflow: hidden;
  cursor: grab;
  user-select: none;
  -webkit-user-select: none;
}
.viewport.dragging {
  cursor: grabbing;
}

/* ── CSS animation pause class ── */
.viewport.paused,
.viewport.paused :deep(*) {
  animation-play-state: paused !important;
}

/* ── Background modes ── */
.viewport.bg-checker {
  background-color: var(--bg-shell);
  background-image:
    linear-gradient(45deg, var(--bg-surface-2) 25%, transparent 25%),
    linear-gradient(-45deg, var(--bg-surface-2) 25%, transparent 25%),
    linear-gradient(45deg, transparent 75%, var(--bg-surface-2) 75%),
    linear-gradient(-45deg, transparent 75%, var(--bg-surface-2) 75%);
  background-size: 16px 16px;
  background-position: 0 0, 0 8px, 8px -8px, -8px 0;
}
.viewport.bg-white { background: #ffffff; }
.viewport.bg-black { background: #000000; }
.viewport.bg-none  { background: transparent; }

.stage {
  position: absolute;
  inset: 0;
  width: 100%;
  height: 100%;
  will-change: transform;
  pointer-events: none;
}
.stage :deep(svg) {
  pointer-events: auto;
}

.parse-error {
  position: absolute;
  top: 50%;
  left: 50%;
  transform: translate(-50%, -50%);
  display: inline-flex;
  align-items: center;
  gap: var(--gap-2);
  padding: 10px 16px;
  border-radius: var(--radius);
  border: 0.5px solid var(--border-medium);
  background: var(--bg-block);
  box-shadow: var(--shadow-card);
  max-width: 80%;
}
.parse-error-text {
  font-family: var(--font-mono);
  font-size: var(--text-xs);
  color: var(--text-primary);
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}
</style>
