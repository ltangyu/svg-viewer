<script setup lang="ts">
import { computed } from 'vue'
import type { BackgroundMode } from '../types'

const props = defineProps<{
  zoom: number
  playing: boolean
  bgMode: BackgroundMode
  hasAnim: boolean
  sourceOpen: boolean
}>()

defineEmits<{
  'zoom-in': []
  'zoom-out': []
  'fit': []
  'actual-size': []
  'reset': []
  'toggle-play': []
  'restart': []
  'cycle-bg': []
  'toggle-source': []
}>()

const zoomPct = computed(() => `${Math.round(props.zoom * 100)}%`)

const bgLabel = computed(() => {
  switch (props.bgMode) {
    case 'checker': return 'Checker'
    case 'white': return 'White'
    case 'black': return 'Black'
    case 'none': return 'None'
  }
})
</script>

<template>
  <div class="toolbar glass-box" @wheel.stop @mousedown.stop @dblclick.stop>
    <!-- Zoom group -->
    <div class="group">
      <button class="btn-icon has-tooltip" @click="$emit('zoom-out')">
        <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor"
             stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
          <line x1="5" y1="12" x2="19" y2="12"/>
        </svg>
        <span class="tooltip-content">Zoom out (−)</span>
      </button>

      <span class="zoom-pct text-mono" :title="`${props.zoom.toFixed(3)}x`">{{ zoomPct }}</span>

      <button class="btn-icon has-tooltip" @click="$emit('zoom-in')">
        <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor"
             stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
          <line x1="12" y1="5" x2="12" y2="19"/>
          <line x1="5" y1="12" x2="19" y2="12"/>
        </svg>
        <span class="tooltip-content">Zoom in (+)</span>
      </button>
    </div>

    <div class="divider"></div>

    <!-- View group -->
    <div class="group">
      <button class="btn-icon has-tooltip" @click="$emit('fit')">
        <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor"
             stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
          <polyline points="4 14 4 20 10 20"/>
          <polyline points="20 10 20 4 14 4"/>
          <line x1="14" y1="10" x2="21" y2="3"/>
          <line x1="3" y1="21" x2="10" y2="14"/>
        </svg>
        <span class="tooltip-content">Fit to screen (F)</span>
      </button>

      <button class="btn-icon has-tooltip" @click="$emit('actual-size')">
        <span class="actual-glyph text-mono">1:1</span>
        <span class="tooltip-content">Actual size (0)</span>
      </button>

      <button class="btn-icon has-tooltip" @click="$emit('reset')">
        <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor"
             stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
          <polyline points="23 4 23 10 17 10"/>
          <path d="M20.49 15a9 9 0 1 1-2.12-9.36L23 10"/>
        </svg>
        <span class="tooltip-content">Reset (R)</span>
      </button>
    </div>

    <div class="divider" v-if="hasAnim"></div>

    <!-- Animation group -->
    <div class="group" v-if="hasAnim">
      <button class="btn-icon has-tooltip" @click="$emit('toggle-play')">
        <svg v-if="playing" width="14" height="14" viewBox="0 0 24 24" fill="currentColor">
          <rect x="6" y="4" width="4" height="16" rx="1"/>
          <rect x="14" y="4" width="4" height="16" rx="1"/>
        </svg>
        <svg v-else width="14" height="14" viewBox="0 0 24 24" fill="currentColor">
          <polygon points="6 4 20 12 6 20 6 4"/>
        </svg>
        <span class="tooltip-content">{{ playing ? 'Pause (Space)' : 'Play (Space)' }}</span>
      </button>

      <button class="btn-icon has-tooltip" @click="$emit('restart')">
        <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor"
             stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
          <polyline points="1 4 1 10 7 10"/>
          <path d="M3.51 15a9 9 0 1 0 2.13-9.36L1 10"/>
        </svg>
        <span class="tooltip-content">Restart (Shift+R)</span>
      </button>
    </div>

    <div class="divider"></div>

    <!-- Display group -->
    <div class="group">
      <button class="btn-icon has-tooltip" @click="$emit('cycle-bg')">
        <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor"
             stroke-width="1.5" stroke-linejoin="round">
          <rect x="3" y="3" width="18" height="18" rx="1.5"/>
          <rect x="3" y="3" width="9" height="9" fill="currentColor" opacity="0.3"/>
          <rect x="12" y="12" width="9" height="9" fill="currentColor" opacity="0.3"/>
        </svg>
        <span class="tooltip-content">Background: {{ bgLabel }} (B)</span>
      </button>

      <button class="btn-icon has-tooltip" :class="{ active: sourceOpen }" @click="$emit('toggle-source')">
        <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor"
             stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
          <polyline points="16 18 22 12 16 6"/>
          <polyline points="8 6 2 12 8 18"/>
        </svg>
        <span class="tooltip-content">Source (S)</span>
      </button>
    </div>
  </div>
</template>

<style scoped>
.toolbar {
  position: absolute;
  top: 12px;
  right: 12px;
  display: inline-flex;
  align-items: center;
  gap: var(--gap-1);
  padding: 4px 6px;
  border-radius: var(--radius);
  box-shadow: var(--shadow-card);
  z-index: 20;
}

.group {
  display: inline-flex;
  align-items: center;
  gap: 2px;
}

.divider {
  width: 1px;
  height: 16px;
  background: var(--border-subtle);
  margin: 0 2px;
}

.zoom-pct {
  font-size: var(--text-xs);
  font-weight: 600;
  color: var(--text-secondary);
  min-width: 42px;
  text-align: center;
  user-select: none;
}

.actual-glyph {
  font-size: var(--text-micro);
  font-weight: 700;
  letter-spacing: 0;
  line-height: 1;
}
</style>
