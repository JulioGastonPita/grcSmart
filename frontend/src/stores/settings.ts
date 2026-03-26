import { defineStore } from 'pinia';
import { ref } from 'vue';
import { api } from 'src/boot/axios';

interface Settings {
  id?: number;
  gemini_api_key: string;
  llm_model: string;
  embedding_provider: string;
}

export const useSettingsStore = defineStore('settings', () => {
  const settings = ref<Settings>({
    gemini_api_key: '',
    llm_model: 'gemini-1.5-flash',
    embedding_provider: 'gemini',
  });
  const loading = ref(false);

  async function fetchSettings() {
    loading.value = true;
    try {
      const { data } = await api.get<Settings>('/settings');
      settings.value = data;
    } finally {
      loading.value = false;
    }
  }

  async function saveSettings(payload: Settings) {
    loading.value = true;
    try {
      const { data } = await api.put<Settings>('/settings', payload);
      settings.value = data;
    } finally {
      loading.value = false;
    }
  }

  return { settings, loading, fetchSettings, saveSettings };
});
