<template>
  <q-page class="q-pa-lg">
    <div class="row items-center q-mb-lg">
      <div class="text-h5 col">Gestor de Políticas</div>
      <q-btn
        icon="refresh"
        flat
        round
        color="primary"
        :loading="documentsStore.loading"
        @click="void documentsStore.fetchDocuments()"
      />
    </div>

    <q-table
      :rows="documentsStore.documents"
      :columns="columns"
      row-key="ID"
      :loading="documentsStore.loading"
      flat
      bordered
      no-data-label="No hay documentos cargados"
    >
      <template v-slot:body-cell-actions="props">
        <q-td :props="props">
          <q-btn
            icon="delete"
            flat
            round
            color="negative"
            size="sm"
            :loading="deletingId === props.row.ID"
            @click="confirmDelete(props.row)"
          >
            <q-tooltip>Eliminar documento</q-tooltip>
          </q-btn>
        </q-td>
      </template>

      <template v-slot:body-cell-uploaded_at="props">
        <q-td :props="props">
          {{ formatDate(props.row.uploaded_at) }}
        </q-td>
      </template>
    </q-table>

    <q-dialog v-model="showConfirm" persistent>
      <q-card>
        <q-card-section class="row items-center">
          <q-avatar icon="warning" color="negative" text-color="white" />
          <span class="q-ml-sm">
            ¿Eliminar <strong>{{ documentToDelete?.original_name }}</strong>?
            Esta acción también eliminará los vectores indexados.
          </span>
        </q-card-section>
        <q-card-actions align="right">
          <q-btn flat label="Cancelar" v-close-popup />
          <q-btn
            flat
            label="Eliminar"
            color="negative"
            @click="void executeDelete()"
            :loading="deletingId !== null"
          />
        </q-card-actions>
      </q-card>
    </q-dialog>
  </q-page>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue';
import { useDocumentsStore } from 'src/stores/documents';

const documentsStore = useDocumentsStore();
const deletingId = ref<number | null>(null);
const showConfirm = ref(false);
const documentToDelete = ref<{ ID: number; original_name: string } | null>(null);

const columns = [
  { name: 'original_name', label: 'Nombre', field: 'original_name', align: 'left' as const, sortable: true },
  { name: 'uploaded_at', label: 'Fecha de subida', field: 'uploaded_at', align: 'left' as const, sortable: true },
  { name: 'actions', label: 'Acciones', field: 'actions', align: 'center' as const },
];

function formatDate(dateStr: string): string {
  return new Date(dateStr).toLocaleString('es-AR');
}

function confirmDelete(doc: { ID: number; original_name: string }) {
  documentToDelete.value = doc;
  showConfirm.value = true;
}

async function executeDelete() {
  if (!documentToDelete.value) return;
  deletingId.value = documentToDelete.value.ID;
  try {
    await documentsStore.deleteDocument(documentToDelete.value.ID);
    showConfirm.value = false;
  } finally {
    deletingId.value = null;
    documentToDelete.value = null;
  }
}

onMounted(() => {
  void documentsStore.fetchDocuments();
});
</script>
