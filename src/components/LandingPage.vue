<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import {
  selectFolder,
  scanSvgFiles,
  saveLastDir,
  loadLastDir,
} from '../composables/useFileSystem'
import type { SvgFileEntry } from '../types'

const emit = defineEmits<{
  'folder-opened': [dir: string, files: SvgFileEntry[]]
}>()

const lastDir = ref<string | null>(null)
const isLoading = ref(false)
const errorMsg = ref('')

const lastDirName = computed(() => {
  if (!lastDir.value) return ''
  const parts = lastDir.value.replace(/\\/g, '/').split('/')
  return parts[parts.length - 1] || parts[parts.length - 2] || lastDir.value
})

onMounted(() => {
  lastDir.value = loadLastDir()
})

async function handleOpen() {
  errorMsg.value = ''
  const dir = await selectFolder()
  if (!dir) return
  await openDirectory(dir)
}

async function handleOpenLast() {
  if (!lastDir.value) return
  errorMsg.value = ''
  await openDirectory(lastDir.value)
}

async function openDirectory(dir: string) {
  isLoading.value = true
  try {
    const svgFiles = await scanSvgFiles(dir)
    if (svgFiles.length === 0) {
      errorMsg.value = 'No .svg files found in this directory.'
      return
    }
    saveLastDir(dir)
    emit('folder-opened', dir, svgFiles)
  } catch (err) {
    errorMsg.value = `Failed to scan: ${err}`
  } finally {
    isLoading.value = false
  }
}
</script>

<template>
  <div class="landing">
    <div class="landing-card glass-box">
      <div class="landing-icon">
        <!-- Phosphor file-svg brand glyph (matches app icon) -->
        <svg width="56" height="56" viewBox="0 0 256 256" fill="none" stroke="currentColor"
             stroke-width="14" stroke-linecap="round" stroke-linejoin="round">
          <path d="M75.9,153.6s-29.43-7.78-31.8,11,38.43,10.12,35.78,30.72c-2.47,19.16-31.78,11-31.78,11"/>
          <path d="M48,112V40a8,8,0,0,1,8-8h96l56,56v24"/>
          <polyline points="152 32 152 88 208 88"/>
          <polyline points="104 152 124 208 144 152"/>
          <path d="M200,184h8v16.87A22.12,22.12,0,0,1,192,208c-13.25,0-24-12.54-24-28s10.75-28,24-28a21.28,21.28,0,0,1,12,3.75"/>
        </svg>
      </div>

      <h1 class="landing-title">SVG Viewer</h1>
      <p class="landing-subtitle">Lightweight SVG viewer with animation support</p>

      <button class="btn btn-primary landing-cta" :disabled="isLoading" @click="handleOpen">
        <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor"
             stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
          <path d="M22 19a2 2 0 0 1-2 2H4a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h5l2 3h9a2 2 0 0 1 2 2z"/>
        </svg>
        {{ isLoading ? 'Scanning...' : 'Open Folder' }}
      </button>

      <button
        v-if="lastDir && !isLoading"
        class="btn btn-ghost landing-reopen"
        @click="handleOpenLast"
      >
        Reopen: {{ lastDirName }}
      </button>

      <p v-if="errorMsg" class="error-msg">
        <span class="status-dot err"></span>
        <span>{{ errorMsg }}</span>
      </p>
    </div>
  </div>
</template>

<style scoped>
.landing {
  display: flex;
  align-items: center;
  justify-content: center;
  width: 100%;
  height: 100%;
  background: var(--bg-shell);
}

.landing-card {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: var(--gap-3);
  padding: 48px 56px;
  border-radius: var(--radius-lg);
  box-shadow: var(--shadow-modal);
  text-align: center;
  max-width: 380px;
}

.landing-icon {
  color: var(--text-secondary);
  margin-bottom: var(--gap-1);
}

.landing-title {
  margin: 0;
  font-family: var(--font-sans);
  font-size: 24px;
  font-weight: 600;
  letter-spacing: -0.02em;
  color: var(--text-primary);
}

.landing-subtitle {
  margin: 0 0 var(--gap-3);
  font-size: var(--text-base);
  color: var(--text-secondary);
}

.landing-cta {
  display: inline-flex;
  align-items: center;
  gap: var(--gap-2);
  padding: 10px 24px;
}

.landing-reopen {
  max-width: 260px;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
  font-size: var(--text-base);
  color: var(--text-secondary);
}
.landing-reopen:hover:not(:disabled) {
  color: var(--text-primary);
}

.error-msg {
  display: inline-flex;
  align-items: center;
  gap: var(--gap-2);
  margin: 0;
  font-size: var(--text-base);
  color: var(--bg-danger-btn);
}
</style>
