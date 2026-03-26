import { defineStore } from 'pinia';
import { ref } from 'vue';
import { api } from 'src/boot/axios';

interface Document {
  ID: number;
  original_name: string;
  storage_path: string;
  uploaded_at: string;
}

export const useDocumentsStore = defineStore('documents', () => {
  const documents = ref<Document[]>([]);
  const loading = ref(false);

  async function fetchDocuments() {
    loading.value = true;
    try {
      const { data } = await api.get<Document[]>('/documents');
      documents.value = data ?? [];
    } finally {
      loading.value = false;
    }
  }

  async function deleteDocument(id: number) {
    await api.delete(`/documents/${id}`);
    documents.value = documents.value.filter((d) => d.ID !== id);
  }

  async function uploadDocument(file: File) {
    const formData = new FormData();
    formData.append('file', file);
    const { data } = await api.post<Document>('/documents', formData, {
      headers: { 'Content-Type': 'multipart/form-data' },
    });
    documents.value.push(data);
    return data;
  }

  return { documents, loading, fetchDocuments, deleteDocument, uploadDocument };
});
