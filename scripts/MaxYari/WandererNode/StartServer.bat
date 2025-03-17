start cmd /k gcloud emulators firestore start --host-port=127.0.0.1:8080
cmd /k "set FIRESTORE_EMULATOR_HOST=127.0.0.1:8080&&set GCLOUD_PROJECT=your-project-id&&node WandererServer.js"