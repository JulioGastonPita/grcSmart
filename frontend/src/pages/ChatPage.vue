<template>
  <q-page class="column" style="height: calc(100vh - 50px);">
    <div class="col q-pa-md overflow-auto" ref="messagesContainer">
      <div v-if="chatStore.messages.length === 0" class="text-center text-grey q-mt-xl">
        <q-icon name="chat_bubble_outline" size="64px" color="grey-4" />
        <p class="text-h6 text-grey-5 q-mt-md">Haz una pregunta sobre las políticas</p>
      </div>

      <div
        v-for="(msg, idx) in chatStore.messages"
        :key="idx"
        class="q-mb-md"
        :class="msg.role === 'user' ? 'flex justify-end' : 'flex justify-start'"
      >
        <q-chat-message
          :name="msg.role === 'user' ? 'Tú' : 'grcSmart'"
          :text="[msg.content]"
          :sent="msg.role === 'user'"
          :bg-color="msg.role === 'user' ? 'primary' : 'grey-2'"
          :text-color="msg.role === 'user' ? 'white' : 'black'"
        />
      </div>

      <div v-if="chatStore.loading" class="flex justify-start q-mb-md">
        <q-chat-message name="grcSmart" bg-color="grey-2">
          <q-spinner-dots size="2rem" color="primary" />
        </q-chat-message>
      </div>
    </div>

    <div class="q-pa-md bg-white shadow-up-2">
      <q-input
        v-model="inputMessage"
        outlined
        placeholder="Escribe tu pregunta..."
        :disable="chatStore.loading"
        @keyup.enter="handleSend"
        autogrow
        :maxlength="2000"
      >
        <template v-slot:append>
          <q-btn
            round
            flat
            icon="send"
            color="primary"
            :disable="!inputMessage.trim() || chatStore.loading"
            @click="handleSend"
          />
        </template>
      </q-input>
    </div>
  </q-page>
</template>

<script setup lang="ts">
import { ref, watch, nextTick } from 'vue';
import { useChatStore } from 'src/stores/chat';

const chatStore = useChatStore();
const inputMessage = ref('');
const messagesContainer = ref<HTMLElement | null>(null);

async function handleSend() {
  const msg = inputMessage.value.trim();
  if (!msg) return;
  inputMessage.value = '';
  await chatStore.sendMessage(msg);
  await nextTick();
  scrollToBottom();
}

function scrollToBottom() {
  if (messagesContainer.value) {
    messagesContainer.value.scrollTop = messagesContainer.value.scrollHeight;
  }
}

watch(() => chatStore.messages.length, () => {
  nextTick(scrollToBottom);
});
</script>
