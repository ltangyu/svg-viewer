<script setup lang="ts">
// Floating rounded-card shell — ii Design Language signature layout.
// The outer padding reserves space for the shell's 4-layer soft shadow to fade out.
import { getCurrentWindow } from '@tauri-apps/api/window'

const win = getCurrentWindow()

/** Drag the window from the transparent outer padding ring. */
async function onPaddingMouseDown(e: MouseEvent) {
  if (e.button !== 0) return
  // Only drag when the user actually clicked the padding itself,
  // not when the event bubbled up from inner content.
  if (e.target !== e.currentTarget) return
  await win.startDragging()
}
</script>

<template>
  <div class="shell-padding" @mousedown="onPaddingMouseDown" data-tauri-drag-region>
    <div class="shell">
      <slot />
    </div>
  </div>
</template>

<style scoped>
.shell-padding {
  height: 100%;
  padding: var(--shell-padding);
  background: transparent;
  overflow: hidden;
}

.shell {
  height: 100%;
  background: var(--bg-shell);
  border-radius: var(--radius-lg);
  box-shadow: var(--shadow-shell);
  display: flex;
  flex-direction: column;
  overflow: hidden;
}
</style>
