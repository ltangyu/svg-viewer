<script setup lang="ts">
import { ref, watch, nextTick } from 'vue'
import type { SvgFileEntry } from '../types'

const props = defineProps<{
  files: SvgFileEntry[]
  allCount: number
  currentIndex: number
  searchQuery: string
}>()

const emit = defineEmits<{
  select: [index: number]
  search: [query: string]
  'change-folder': []
}>()

const searchInputRef = ref<HTMLInputElement | null>(null)
const listRef = ref<HTMLElement | null>(null)
let debounceTimer: ReturnType<typeof setTimeout> | null = null

/* ── Exposed methods for parent keyboard shortcuts ── */
defineExpose({
  focusSearch() {
    searchInputRef.value?.focus()
  },
  blurSearch() {
    searchInputRef.value?.blur()
  },
})

/* ── Search with debounce ───────────────────────── */
function onSearchInput(e: Event) {
  const value = (e.target as HTMLInputElement).value
  if (debounceTimer) clearTimeout(debounceTimer)
  debounceTimer = setTimeout(() => {
    emit('search', value)
  }, 150)
}

/* ── Scroll active item into view ───────────────── */
watch(() => props.currentIndex, async () => {
  await nextTick()
  const active = listRef.value?.querySelector('.file-item.active')
  active?.scrollIntoView({ block: 'nearest', behavior: 'smooth' })
})

/* ── Helpers ────────────────────────────────────── */
function dirPrefix(relativePath: string): string {
  const idx = relativePath.lastIndexOf('/')
  return idx > 0 ? relativePath.substring(0, idx + 1) : ''
}

function formatSize(bytes: number): string {
  if (bytes < 1024) return `${bytes} B`
  if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(1)} KB`
  return `${(bytes / (1024 * 1024)).toFixed(1)} MB`
}
</script>

<template>
  <aside class="sidebar">
    <!-- Header -->
    <div class="sidebar-header">
      <div class="sidebar-title">
        <span class="label-micro">FILES</span>
        <span class="count text-mono">
          {{ files.length }}<template v-if="files.length !== allCount"> / {{ allCount }}</template>
        </span>
      </div>
      <button class="btn-icon has-tooltip" @click="emit('change-folder')">
        <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor"
             stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
          <path d="M22 19a2 2 0 0 1-2 2H4a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h5l2 3h9a2 2 0 0 1 2 2z"/>
        </svg>
        <span class="tooltip-content">Change folder</span>
      </button>
    </div>

    <!-- Search -->
    <div class="sidebar-search">
      <input
        ref="searchInputRef"
        class="input"
        type="text"
        placeholder="Search files... (Ctrl+K)"
        :value="searchQuery"
        @input="onSearchInput"
      />
    </div>

    <!-- File List -->
    <div ref="listRef" class="file-list scroll-y">
      <div
        v-for="(file, idx) in files"
        :key="file.path"
        class="file-item"
        :class="{ active: idx === currentIndex }"
        :title="file.relative_path"
        @click="emit('select', idx)"
      >
        <span class="file-dir" v-if="dirPrefix(file.relative_path)">
          {{ dirPrefix(file.relative_path) }}
        </span>
        <span class="file-name">{{ file.name }}</span>
        <span class="file-size text-mono">{{ formatSize(file.size) }}</span>
      </div>

      <div v-if="files.length === 0" class="empty-state">
        No matching files
      </div>
    </div>
  </aside>
</template>

<style scoped>
.sidebar {
  width: var(--sidebar-w);
  min-width: var(--sidebar-w);
  height: 100%;
  display: flex;
  flex-direction: column;
  border-right: 0.5px solid var(--border-subtle);
  background: var(--bg-sidebar);
}

.sidebar-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: var(--gap-4) var(--gap-4) 0;
}

.sidebar-title {
  display: flex;
  align-items: baseline;
  gap: var(--gap-2);
}

.sidebar-title .count {
  font-size: var(--text-micro);
  color: var(--text-muted);
}

.sidebar-search {
  padding: var(--gap-3) var(--gap-4);
}

.sidebar-search .input {
  width: 100%;
  font-size: var(--text-base);
  padding: 6px 10px;
}

.file-list {
  flex: 1;
  padding: 0 var(--gap-2) var(--gap-4);
}

.file-item {
  display: flex;
  flex-direction: column;
  gap: 1px;
  padding: 7px 10px;
  border-radius: var(--radius);
  cursor: pointer;
  transition: background-color var(--t-fast), border-color var(--t-fast);
  border: 0.5px solid transparent;
  position: relative;
}

.file-item:hover {
  background: var(--bg-hover);
}

.file-item.active {
  background: var(--bg-block);
  border-color: var(--border-medium);
}

.file-dir {
  font-size: var(--text-xs);
  color: var(--text-muted);
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
  line-height: 1.3;
}

.file-name {
  font-size: var(--text-base);
  font-weight: 500;
  color: var(--text-primary);
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
  line-height: 1.4;
}

.file-item.active .file-name {
  font-weight: 600;
}

.file-size {
  font-size: var(--text-micro);
  color: var(--text-muted);
  line-height: 1.3;
}

.empty-state {
  padding: var(--gap-6) var(--gap-4);
  text-align: center;
  font-size: var(--text-base);
  color: var(--text-muted);
}
</style>
