# E.D.I.T.H. for Emiliano — Ollama update

Download **[EDITH-Ollama.zip](EDITH-Ollama.zip)**. It extracts into **EDITH-Ollama**, beside your existing EDITH-Emiliano folder. Fresh installations now default to Ollama on your Mac and the qwen2.5:3b model. The Integrations screen has a **Use Ollama on this Mac** button. Local AI needs no cloud API key; keep Ollama running and download the selected model.

## Update your existing Mac installation

Unzip EDITH-Ollama.zip into Downloads. Stop the running E.D.I.T.H. app and scheduler with Control+C in their terminals. Open Ollama and run in Terminal:

```sh
ollama pull qwen2.5:3b
node ~/Downloads/EDITH-Ollama/scripts/update-existing.mjs ~/Downloads/EDITH-Emiliano
cd ~/Downloads/EDITH-Emiliano
bash scripts/setup-cloud.sh
npm run ai:ollama -- qwen2.5:3b
npm run dev
```

In a second Terminal:

```sh
cd ~/Downloads/EDITH-Emiliano
npm run scheduler
```

Open http://localhost:3000 in your Mac's browser. Use Integrations → Test model connection.

The updater preserves your existing .env, database, private document storage, password and unrelated files. The ai:ollama command changes only local AI settings and the saved provider choice, fixing older installations that stay in demo or cloud mode. Adjust paths if you installed elsewhere. Keep your existing installation folder; replacing it wholesale does not migrate your data.

## Fresh installation

Install Node.js **24**, open Ollama and run `ollama pull qwen2.5:3b`. From the new folder:

```sh
cd ~/Downloads/EDITH-Ollama
bash scripts/setup-cloud.sh
npm run dev
```

Run `npm run scheduler` in a second Terminal in the same folder. First opening asks you to create a private password of at least 12 characters.

## Voice and cloud alternatives

ElevenLabs remains optional and separate. Create your own API key with Text-to-Speech access, copy your selected voice's ID, and put them in .env as ELEVENLABS_API_KEY and ELEVENLABS_VOICE_ID. Restart the app and scheduler, then preview the voice. Never paste keys in chat.

Groq's free developer API remains available, with usage limits. Create your own key at https://console.groq.com/keys, set GROQ_API_KEY in .env, restart both processes, choose Use Groq cloud AI in Integrations, and test it. The included README explains this and other integrations.

The original EDITH-Emiliano.zip link also contains the updated code and Ollama defaults, under its original folder name. EDITH-Ollama.zip gives the update a distinct folder name.

## Validation

33 backend tests and 10 browser tests passed; build, type checking and lint passed in the cloud Linux environment. The upgrade test verifies preservation of existing keys, password, task, database and original document, and repeated Ollama configuration. The browser test uses a mock local HTTP model and exercises provider selection, the connection test and streamed conversation. Real model inference, ElevenLabs speech and native macOS execution require your Mac/provider and have not been claimed as verified. The archives exclude private .env files, databases, uploaded originals, node_modules and generated builds.
