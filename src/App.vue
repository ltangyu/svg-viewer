<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { invoke } from '@tauri-apps/api/core'
import { listen } from '@tauri-apps/api/event'
import type { SvgFileEntry, ViewState } from './types'
import { scanSvgFiles, saveLastDir } from './composables/useFileSystem'
import LandingPage from './components/LandingPage.vue'
import FileBrowser from './components/FileBrowser.vue'
import AppShell from './components/layout/AppShell.vue'
import WindowControls from './components/layout/WindowControls.vue'

const view = ref<ViewState>('landing')
const files = ref<SvgFileEntry[]>([])
const currentDir = ref('')
const initialFilePath = ref<string | null>(null)

function handleFolderOpened(dir: string, svgFiles: SvgFileEntry[]) {
  currentDir.value = dir
  files.value = svgFiles
  view.value = 'browser'
}

function handleChangeFolder() {
  initialFilePath.value = null
  view.value = 'landing'
}

/**
 * Open a .svg file directly: scan its parent directory,
 * switch to browser view, and navigate to the target file.
 */
async function openFileDirectly(filePath: string) {
  const normalized = filePath.replace(/\\/g, '/')
  const dir = normalized.substring(0, normalized.lastIndexOf('/'))
  if (!dir) return

  try {
    const svgFiles = await scanSvgFiles(dir)
    if (svgFiles.length === 0) return

    saveLastDir(dir)
    currentDir.value = dir
    files.value = svgFiles
    initialFilePath.value = filePath
    view.value = 'browser'
  } catch {
    // silently ignore — user can still open manually
  }
}

onMounted(async () => {
  // 1) Check if launched with a .svg file argument (double-click / Open With)
  try {
    const launchFile = await invoke<string | null>('get_launch_file')
    if (launchFile) {
      await openFileDirectly(launchFile)
    }
  } catch {
    // command not available or failed
  }

  // 2) Listen for files opened while the app is already running
  //    (single-instance plugin forwards the path via event)
  await listen<string>('open-file', async (event) => {
    await openFileDirectly(event.payload)
  })
})
</script>

<template>
  <AppShell>
    <WindowControls />
    <LandingPage
      v-if="view === 'landing'"
      @folder-opened="handleFolderOpened"
    />
    <FileBrowser
      v-else
      :files="files"
      :current-dir="currentDir"
      :initial-file-path="initialFilePath"
      @change-folder="handleChangeFolder"
      @folder-opened="handleFolderOpened"
    />
  </AppShell>
</template>
