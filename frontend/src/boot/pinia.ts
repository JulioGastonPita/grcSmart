import { createPinia } from 'pinia';

export default ({ app }: { app: { use: (plugin: ReturnType<typeof createPinia>) => void } }) => {
  app.use(createPinia());
};
