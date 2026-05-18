<script setup lang="ts">
import { getCurrentWindow } from '@tauri-apps/api/window'

const win = getCurrentWindow()

async function onMinimize() { await win.minimize() }
async function onMaximize() { await win.toggleMaximize() }
async function onClose() { await win.close() }
</script>

<template>
  <header class="titlebar" data-tauri-drag-region>
    <div class="title-group" data-tauri-drag-region>
      <svg class="brand-glyph" width="14" height="14" viewBox="0 0 256 256" fill="none"
           stroke="currentColor" stroke-width="20" stroke-linecap="round" stroke-linejoin="round"
           data-tauri-drag-region>
        <path d="M75.9,153.6s-29.43-7.78-31.8,11,38.43,10.12,35.78,30.72c-2.47,19.16-31.78,11-31.78,11"/>
        <path d="M48,112V40a8,8,0,0,1,8-8h96l56,56v24"/>
        <polyline points="152 32 152 88 208 88"/>
        <polyline points="104 152 124 208 144 152"/>
        <path d="M200,184h8v16.87A22.12,22.12,0,0,1,192,208c-13.25,0-24-12.54-24-28s10.75-28,24-28a21.28,21.28,0,0,1,12,3.75"/>
      </svg>
      <span class="title-en label-micro" data-tauri-drag-region>SVG VIEWER</span>
    </div>

    <div class="controls">
      <button class="ctrl" type="button" title="Minimize" @click="onMinimize">
        <svg width="10" height="10" viewBox="0 0 10 10" fill="none" stroke="currentColor" stroke-width="1">
          <line x1="1" y1="5" x2="9" y2="5"/>
        </svg>
      </button>
      <button class="ctrl" type="button" title="Maximize" @click="onMaximize">
        <svg width="10" height="10" viewBox="0 0 10 10" fill="none" stroke="currentColor" stroke-width="1">
          <rect x="1" y="1" width="8" height="8"/>
        </svg>
      </button>
      <button class="ctrl close" type="button" title="Close" @click="onClose">
        <svg width="10" height="10" viewBox="0 0 10 10" fill="none" stroke="currentColor" stroke-width="1">
          <line x1="1.5" y1="1.5" x2="8.5" y2="8.5"/>
          <line x1="8.5" y1="1.5" x2="1.5" y2="8.5"/>
        </svg>
      </button>
    </div>
  </header>
</template>

<style scoped>
.titlebar {
  height: var(--titlebar-h);
  background: var(--bg-titlebar);
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 0 4px 0 14px;
  border-bottom: 0.5px solid var(--border-subtle);
  border-radius: var(--radius-lg) var(--radius-lg) 0 0;
  flex-shrink: 0;
  gap: 12px;
}

.title-group {
  display: flex;
  align-items: center;
  gap: 8px;
  pointer-events: none;
  flex: 1;
  min-width: 0;
}

.brand-glyph {
  color: var(--text-primary);
  flex-shrink: 0;
}

.title-en {
  color: var(--text-secondary);
  letter-spacing: 0.1em;
}

.controls {
  display: flex;
  gap: 2px;
}

.ctrl {
  width: 28px;
  height: 24px;
  border-radius: var(--radius-sm);
  color: var(--text-secondary);
  background: transparent;
  border: none;
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  transition: background-color var(--t-fast), color var(--t-fast);
}
.ctrl:hover {
  background: var(--bg-hover);
  color: var(--text-primary);
}
.ctrl.close:hover {
  background: var(--bg-danger-btn);
  color: var(--text-on-dark);
}
</style>
