<template>
  <q-layout view="lHh Lpr lFf">
    <q-header elevated class="bg-primary text-white">
      <q-toolbar>
        <q-btn flat dense round icon="menu" @click="toggleLeftDrawer" />
        <q-toolbar-title>grcSmart</q-toolbar-title>
      </q-toolbar>
    </q-header>

    <q-drawer v-model="leftDrawerOpen" show-if-above bordered>
      <q-list>
        <q-item-label header>Menú</q-item-label>

        <q-item clickable v-ripple :to="'/chat'" active-class="bg-primary text-white">
          <q-item-section avatar>
            <q-icon name="chat" />
          </q-item-section>
          <q-item-section>Chat RAG</q-item-section>
        </q-item>

        <q-item clickable v-ripple :to="'/upload'" active-class="bg-primary text-white">
          <q-item-section avatar>
            <q-icon name="upload_file" />
          </q-item-section>
          <q-item-section>Subir Archivos</q-item-section>
        </q-item>

        <q-item clickable v-ripple :to="'/documents'" active-class="bg-primary text-white">
          <q-item-section avatar>
            <q-icon name="description" />
          </q-item-section>
          <q-item-section>Políticas</q-item-section>
        </q-item>

        <q-item clickable v-ripple :to="'/settings'" active-class="bg-primary text-white">
          <q-item-section avatar>
            <q-icon name="settings" />
          </q-item-section>
          <q-item-section>Configuración</q-item-section>
        </q-item>
      </q-list>
    </q-drawer>

    <q-page-container>
      <router-view />
    </q-page-container>
  </q-layout>
</template>

<script setup lang="ts">
import { ref } from 'vue';

const leftDrawerOpen = ref(false);

function toggleLeftDrawer() {
  leftDrawerOpen.value = !leftDrawerOpen.value;
}
</script>
