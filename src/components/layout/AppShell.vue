<script setup lang="ts">
// Floating rounded-card shell — ii Design Language signature layout.
// The outer padding reserves space for the shell's 4-layer soft shadow to fade out.
</script>

<template>
  <div class="shell-padding">
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
