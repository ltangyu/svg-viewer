<script setup lang="ts">
import { ref, computed } from 'vue'
import type { SvgInfo } from '../types'

const props = defineProps<{
  info: SvgInfo
}>()

const expanded = ref(true)

const sizeLabel = computed(() => {
  const w = props.info.intrinsicWidth
  const h = props.info.intrinsicHeight
  if (w === null || h === null) return '—'
  const round = (n: number) => Number.isInteger(n) ? n : n.toFixed(1)
  return `${round(w)} × ${round(h)}`
})

const viewBoxLabel = computed(() => props.info.viewBox ?? '—')

type DotKind = 'ok' | 'warn' | 'err' | 'idle'
const animTypes = computed(() => {
  const tags: { dot: DotKind; label: string }[] = []
  if (props.info.hasSmilAnimations) tags.push({ dot: 'ok', label: 'SMIL' })
  if (props.info.hasCssAnimations) tags.push({ dot: 'warn', label: 'CSS' })
  if (props.info.hasScripts) tags.push({ dot: 'err', label: 'JS' })
  return tags
})

function toggle() {
  expanded.value = !expanded.value
}
</script>

<template>
  <div class="info-badge glass-box" :class="{ collapsed: !expanded }" @click="toggle">
    <template v-if="expanded">
      <div class="row">
        <span class="label-micro">VIEWBOX</span>
        <span class="value text-mono">{{ viewBoxLabel }}</span>
      </div>
      <div class="row">
        <span class="label-micro">SIZE</span>
        <span class="value text-mono">{{ sizeLabel }}</span>
      </div>
      <div class="row anim-row" v-if="animTypes.length">
        <span class="label-micro">ANIM</span>
        <span class="anim-tags">
          <span v-for="t in animTypes" :key="t.label" class="anim-tag">
            <span class="status-dot" :class="t.dot"></span>
            <span class="anim-label text-mono">{{ t.label }}</span>
          </span>
        </span>
      </div>
    </template>
    <template v-else>
      <span class="label-micro">SVG</span>
      <span v-if="animTypes.length" class="dot-row">
        <span v-for="t in animTypes" :key="t.label" class="status-dot" :class="t.dot"></span>
      </span>
    </template>
  </div>
</template>

<style scoped>
.info-badge {
  position: absolute;
  bottom: 12px;
  left: 12px;
  display: flex;
  flex-direction: column;
  gap: 4px;
  padding: 8px 12px;
  border-radius: var(--radius);
  box-shadow: var(--shadow-card);
  cursor: pointer;
  z-index: 20;
  min-width: 160px;
  transition: all var(--t-fast);
}
.info-badge.collapsed {
  flex-direction: row;
  align-items: center;
  gap: var(--gap-2);
  min-width: 0;
  padding: 6px 10px;
}

.row {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: var(--gap-3);
}

.value {
  font-size: var(--text-xs);
  color: var(--text-primary);
  font-weight: 600;
  white-space: nowrap;
}

.anim-row {
  align-items: center;
}

.anim-tags {
  display: inline-flex;
  align-items: center;
  gap: 6px;
}
.anim-tag {
  display: inline-flex;
  align-items: center;
  gap: 4px;
}
.anim-label {
  font-size: var(--text-xs);
  font-weight: 600;
  color: var(--text-primary);
}

.dot-row {
  display: inline-flex;
  align-items: center;
  gap: 3px;
}
</style>
