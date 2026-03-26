<template>
  <q-page class="q-pa-lg">
    <div class="text-h5 q-mb-lg">Configuración</div>

    <q-card class="q-pa-md" style="max-width: 600px;">
      <q-form @submit="void handleSave()" class="q-gutter-md">
        <q-input
          v-model="form.gemini_api_key"
          label="API Key de Gemini"
          :type="showKey ? 'text' : 'password'"
          outlined
          :loading="settingsStore.loading"
          hint="Obtén tu API Key en Google AI Studio"
        >
          <template v-slot:append>
            <q-icon
              :name="showKey ? 'visibility_off' : 'visibility'"
              class="cursor-pointer"
              @click="showKey = !showKey"
            />
          </template>
        </q-input>

        <q-select
          v-model="form.llm_model"
          :options="llmModels"
          label="Modelo LLM"
          outlined
          emit-value
          map-options
        />

        <q-select
          v-model="form.embedding_provider"
          :options="embeddingProviders"
          label="Proveedor de Embeddings"
          outlined
          emit-value
          map-options
        />

        <div class="row justify-end q-gutter-sm">
          <q-btn
            label="Guardar"
            type="submit"
            color="primary"
            :loading="settingsStore.loading"
            icon="save"
          />
        </div>
      </q-form>
    </q-card>

    <q-banner v-if="saveSuccess" class="q-mt-md bg-positive text-white" rounded style="max-width: 600px;">
      <template v-slot:avatar>
        <q-icon name="check_circle" />
      </template>
      Configuración guardada correctamente.
    </q-banner>
  </q-page>
</template>

<script setup lang="ts">
import { ref, reactive, onMounted } from 'vue';
import { useSettingsStore } from 'src/stores/settings';

const settingsStore = useSettingsStore();
const showKey = ref(false);
const saveSuccess = ref(false);

const form = reactive({
  gemini_api_key: '',
  llm_model: 'gemini-1.5-flash',
  embedding_provider: 'gemini',
});

const llmModels = [
  { label: 'Gemini 1.5 Flash (rápido)', value: 'gemini-1.5-flash' },
  { label: 'Gemini 1.5 Pro (avanzado)', value: 'gemini-1.5-pro' },
  { label: 'Gemini 2.0 Flash', value: 'gemini-2.0-flash' },
];

const embeddingProviders = [
  { label: 'Gemini (text-embedding-004)', value: 'gemini' },
];

async function handleSave() {
  await settingsStore.saveSettings({ ...form });
  saveSuccess.value = true;
  setTimeout(() => { saveSuccess.value = false; }, 3000);
}

onMounted(async () => {
  await settingsStore.fetchSettings();
  Object.assign(form, settingsStore.settings);
});
</script>
