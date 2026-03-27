<template>
  <q-page class="q-pa-lg">
    <div class="text-h5 q-mb-lg">Subir Archivos PDF</div>

    <q-card class="q-pa-md">
      <q-uploader
        label="Arrastra PDFs aquí o haz clic para seleccionar"
        accept=".pdf"
        multiple
        :factory="uploadFactory"
        style="width: 100%; min-height: 200px;"
        color="primary"
        flat
        bordered
        @uploaded="onUploaded"
        @failed="onFailed"
      >
        <template v-slot:header="scope">
          <div class="row no-wrap items-center q-pa-sm q-gutter-xs">
            <q-btn
              icon="add_box"
              round
              dense
              flat
              @click="scope.pickFiles"
            >
              <q-tooltip>Seleccionar archivos</q-tooltip>
            </q-btn>
            <q-btn
              v-if="scope.queuedFiles.length > 0"
              icon="clear_all"
              round
              dense
              flat
              @click="scope.removeQueuedFiles"
            >
              <q-tooltip>Limpiar cola</q-tooltip>
            </q-btn>
            <div class="col">
              <div class="q-uploader__title">{{ scope.queuedFiles.length }} archivo(s) en cola</div>
            </div>
            <q-btn
              v-if="scope.queuedFiles.length > 0"
              icon="cloud_upload"
              round
              dense
              flat
              @click="scope.upload"
            >
              <q-tooltip>Subir todo</q-tooltip>
            </q-btn>
          </div>
        </template>
      </q-uploader>
    </q-card>

    <q-banner v-if="uploadSuccess" class="q-mt-md bg-positive text-white" rounded>
      <template v-slot:avatar>
        <q-icon name="check_circle" />
      </template>
      Archivo subido e indexado correctamente.
    </q-banner>

    <q-banner v-if="uploadError" class="q-mt-md bg-negative text-white" rounded>
      <template v-slot:avatar>
        <q-icon name="error" />
      </template>
      {{ uploadError }}
    </q-banner>
  </q-page>
</template>

<script setup lang="ts">
import { ref } from 'vue';
import { useDocumentsStore } from 'src/stores/documents';

const documentsStore = useDocumentsStore();
const uploadSuccess = ref(false);
const uploadError = ref('');

function uploadFactory(files: readonly File[]) {
  return files.map(() => ({
    url: (import.meta.env.VITE_API_BASE_URL as string) + '/api/documents',
    method: 'POST',
    fieldName: 'file',
    formFields: [],
  }));
}

function onUploaded() {
  uploadSuccess.value = true;
  uploadError.value = '';
  void documentsStore.fetchDocuments();
  setTimeout(() => { uploadSuccess.value = false; }, 3000);
}

function onFailed(info: { files: readonly File[]; xhr: XMLHttpRequest }) {
  uploadError.value = `Error al subir: ${info.xhr?.statusText || 'Error desconocido'}`;
  uploadSuccess.value = false;
}
</script>
