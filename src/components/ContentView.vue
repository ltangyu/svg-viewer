<script setup lang="ts">
import { ref, watch } from 'vue'
import type { SvgFileEntry } from '../types'
import { readTextFile } from '../composables/useFileSystem'
import SvgViewport from './SvgViewport.vue'

const props = defineProps<{
  file: SvgFileEntry | null
  currentIndex: number
  totalFiles: number
  currentDir: string
}>()

const emit = defineEmits<{
  navigate: [delta: number]
}>()

const svgText = ref<string>('')
const isLoading = ref(false)
const errorMsg = ref('')

/* ── Watch file changes ─────────────────────────── */
watch(() => props.file, async (newFile) => {
  errorMsg.value = ''
  if (!newFile) {
    svgText.value = ''
    return
  }

  isLoading.value = true
  try {
    const content = await readTextFile(newFile.path)

    // Soft cap to avoid pathological DOM trees
    const MAX = 20 * 1024 * 1024 // 20 MB SVG text
    if (content.length > MAX) {
      svgText.value = ''
      errorMsg.value = `File too large (${(content.length / 1024 / 1024).toFixed(1)} MB). 20 MB limit.`
    } else if (!content.trim()) {
      svgText.value = ''
      errorMsg.value = 'This file is empty.'
    } else {
      svgText.value = content
    }
  } catch (err) {
    errorMsg.value = `Failed to read file: ${err}`
    svgText.value = ''
  } finally {
    isLoading.value = false
  }
}, { immediate: true })

/* ── Helpers ────────────────────────────────────── */
function displayName(file: SvgFileEntry): string {
  return file.relative_path || file.name
}
</script>

<template>
  <main class="content">
    <!-- Navigation Header -->
    <header class="content-header">
      <div class="nav-controls">
        <button
          class="btn-icon has-tooltip"
          :disabled="currentIndex <= 0"
          @click="emit('navigate', -1)"
        >
          <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor"
               stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
            <polyline points="15 18 9 12 15 6"/>
          </svg>
          <span class="tooltip-content">Previous (Alt+↑)</span>
        </button>

        <span class="nav-counter text-mono" v-if="totalFiles > 0">
          {{ currentIndex + 1 }} / {{ totalFiles }}
        </span>

        <button
          class="btn-icon has-tooltip"
          :disabled="currentIndex >= totalFiles - 1"
          @click="emit('navigate', 1)"
        >
          <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor"
               stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
            <polyline points="9 18 15 12 9 6"/>
          </svg>
          <span class="tooltip-content">Next (Alt+↓)</span>
        </button>
      </div>

      <span class="file-path text-mono" v-if="file" :title="file.path">
        {{ displayName(file) }}
      </span>
    </header>

    <!-- Viewport / States -->
    <div class="content-body">
      <SvgViewport
        v-if="svgText && !errorMsg"
        :svg-text="svgText"
        :file-path="file?.path ?? ''"
      />

      <div v-else-if="errorMsg" class="state-overlay">
        <div class="state-card">
          <span class="status-dot err"></span>
          <span class="state-msg">{{ errorMsg }}</span>
        </div>
      </div>

      <div v-else-if="!file && !isLoading" class="state-overlay">
        <p class="state-hint">Select a file from the sidebar</p>
      </div>
    </div>

    <!-- Loading Overlay -->
    <div v-if="isLoading" class="loading-overlay">
      <span class="status-dot warn"></span>
    </div>
  </main>
</template>

<style scoped>
.content {
  flex: 1;
  display: flex;
  flex-direction: column;
  height: 100%;
  overflow: hidden;
  position: relative;
  background: var(--bg-block);
}

/* ── Header ─────────────────────────────────────── */
.content-header {
  display: flex;
  align-items: center;
  gap: var(--gap-4);
  padding: 8px 16px;
  border-bottom: 0.5px solid var(--border-subtle);
  background: var(--bg-titlebar);
  flex-shrink: 0;
  min-height: var(--titlebar-h);
}

.nav-controls {
  display: flex;
  align-items: center;
  gap: var(--gap-1);
  flex-shrink: 0;
}

.nav-counter {
  font-size: var(--text-xs);
  color: var(--text-muted);
  min-width: 56px;
  text-align: center;
  user-select: none;
}

.file-path {
  font-size: var(--text-xs);
  color: var(--text-secondary);
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
  flex: 1;
}

/* ── Body ───────────────────────────────────────── */
.content-body {
  flex: 1;
  position: relative;
  overflow: hidden;
}

/* ── State Overlays ─────────────────────────────── */
.state-overlay {
  position: absolute;
  inset: 0;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: var(--gap-4);
}

.state-card {
  display: inline-flex;
  align-items: center;
  gap: var(--gap-2);
  padding: 10px 16px;
  border-radius: var(--radius);
  border: 0.5px solid var(--border-medium);
  background: var(--bg-block);
  box-shadow: var(--shadow-card);
}

.state-msg {
  font-size: var(--text-base);
  color: var(--text-primary);
}

.state-hint {
  font-size: var(--text-md);
  color: var(--text-muted);
}

.loading-overlay {
  position: absolute;
  top: calc(var(--titlebar-h) + 12px);
  right: 16px;
  z-index: 10;
}
</style>
