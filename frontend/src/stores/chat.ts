import { defineStore } from 'pinia';
import { ref } from 'vue';
import { api } from 'src/boot/axios';

interface Message {
  role: 'user' | 'assistant';
  content: string;
  timestamp: Date;
}

export const useChatStore = defineStore('chat', () => {
  const messages = ref<Message[]>([]);
  const loading = ref(false);

  async function sendMessage(userMessage: string) {
    messages.value.push({
      role: 'user',
      content: userMessage,
      timestamp: new Date(),
    });

    loading.value = true;
    try {
      const { data } = await api.post<{ answer: string }>('/chat', {
        message: userMessage,
      });
      messages.value.push({
        role: 'assistant',
        content: data.answer,
        timestamp: new Date(),
      });
    } catch {
      messages.value.push({
        role: 'assistant',
        content: 'Error al procesar tu consulta. Intenta de nuevo.',
        timestamp: new Date(),
      });
    } finally {
      loading.value = false;
    }
  }

  function clearHistory() {
    messages.value = [];
  }

  return { messages, loading, sendMessage, clearHistory };
});
