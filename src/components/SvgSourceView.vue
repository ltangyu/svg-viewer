<script setup lang="ts">
import { ref, computed } from 'vue'
import hljs from 'highlight.js/lib/core'
import xml from 'highlight.js/lib/languages/xml'

hljs.registerLanguage('xml', xml)

const props = defineProps<{
  svgText: string
}>()

defineEmits<{
  close: []
}>()

const highlighted = computed(() => {
  try {
    return hljs.highlight(props.svgText, { language: 'xml' }).value
  } catch {
    // Fallback: plain escaped text
    return props.svgText
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
  }
})

const byteSize = computed(() => {
  const bytes = new Blob([props.svgText]).size
  if (bytes < 1024) return `${bytes} B`
  if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(1)} KB`
  return `${(bytes / 1024 / 1024).toFixed(1)} MB`
})

const copied = ref(false)
async function copyAll() {
  try {
    await navigator.clipboard.writeText(props.svgText)
    copied.value = true
    setTimeout(() => (copied.value = false), 1200)
  } catch {
    copied.value = false
  }
}
</script>

<template>
  <aside class="source-panel" @wheel.stop @mousedown.stop @dblclick.stop>
    <header class="source-header">
      <div class="source-title">
        <span class="label-micro">SOURCE</span>
        <span class="source-size text-mono">{{ byteSize }}</span>
      </div>
      <div class="source-actions">
        <button class="btn-icon has-tooltip" @click="copyAll">
          <svg v-if="!copied" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor"
               stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
            <rect x="9" y="9" width="13" height="13" rx="2" ry="2"/>
            <path d="M5 15H4a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2h9a2 2 0 0 1 2 2v1"/>
          </svg>
          <svg v-else width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor"
               stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
            <polyline points="20 6 9 17 4 12"/>
          </svg>
          <span class="tooltip-content">{{ copied ? 'Copied!' : 'Copy XML' }}</span>
        </button>
        <button class="btn-icon has-tooltip" @click="$emit('close')">
          <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor"
               stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
            <line x1="18" y1="6" x2="6" y2="18"/>
            <line x1="6" y1="6" x2="18" y2="18"/>
          </svg>
          <span class="tooltip-content">Close (S)</span>
        </button>
      </div>
    </header>

    <div class="source-body scroll-y">
      <pre><code class="language-xml" v-html="highlighted"></code></pre>
    </div>
  </aside>
</template>

<style scoped>
.source-panel {
  width: 40%;
  min-width: 320px;
  max-width: 560px;
  height: 100%;
  display: flex;
  flex-direction: column;
  background: var(--bg-block);
  border-left: 0.5px solid var(--border-subtle);
  animation: slide-in var(--t-base) ease;
}

@keyframes slide-in {
  from { transform: translateX(100%); opacity: 0; }
  to   { transform: translateX(0);    opacity: 1; }
}

.source-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 8px 12px;
  border-bottom: 0.5px solid var(--border-subtle);
  background: var(--bg-titlebar);
  flex-shrink: 0;
  min-height: var(--titlebar-h);
}

.source-title {
  display: inline-flex;
  align-items: baseline;
  gap: var(--gap-2);
}

.source-size {
  font-size: var(--text-micro);
  color: var(--text-muted);
}

.source-actions {
  display: inline-flex;
  align-items: center;
  gap: var(--gap-1);
}

.source-body {
  flex: 1;
  overflow: auto;
  background: var(--bg-block);
}

.source-body pre {
  margin: 0;
  padding: 12px 14px;
  font-family: var(--font-mono);
  font-size: var(--text-xs);
  line-height: 1.55;
  color: var(--text-primary);
  white-space: pre;
}

.source-body code {
  font-family: inherit;
  background: transparent;
  padding: 0;
}

/* Tone-down highlight.js github colors to match monochrome palette */
.source-body :deep(.hljs-tag),
.source-body :deep(.hljs-name) {
  color: var(--text-primary);
  font-weight: 600;
}
.source-body :deep(.hljs-attr) {
  color: var(--text-secondary);
}
.source-body :deep(.hljs-string) {
  color: var(--text-primary);
  font-weight: 500;
}
.source-body :deep(.hljs-comment) {
  color: var(--text-muted);
  font-style: italic;
}
</style>
