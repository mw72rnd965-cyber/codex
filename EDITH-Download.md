# E.D.I.T.H. — real clock and web sources

Download **[EDITH-Ollama.zip](EDITH-Ollama.zip)**. It extracts into **EDITH-Ollama**, beside your existing **EDITH-Emiliano** folder.

This update answers time/date questions directly from your Mac's clock in your saved timezone. Web search retrieves actual excerpts with clickable source links and retrieval time. Tavily's public keyless search is enabled by default; it needs internet access and has usage limits. A failed search reports that it could not verify the answer. Your selected Ollama model continues handling ordinary conversation.

## Update your existing Mac installation

Unzip EDITH-Ollama.zip into Downloads. Stop the running E.D.I.T.H. app and scheduler with Control+C in their terminals. Keep Ollama running, then run:

```sh
node ~/Downloads/EDITH-Ollama/scripts/update-existing.mjs ~/Downloads/EDITH-Emiliano
cd ~/Downloads/EDITH-Emiliano
bash scripts/setup-cloud.sh
npm run dev
```

In a second Terminal:

```sh
cd ~/Downloads/EDITH-Emiliano
npm run scheduler
```

Open http://localhost:3000 on your Mac. Try **What time is it?** and **Search the web for the latest NASA news**. Adjust your timezone in Settings if needed. Web replies identify the search provider and provide real source links; they are retrieved excerpts rather than full-page analysis. Check source publication dates for current information.

The updater preserves your existing .env, Ollama model/provider choice, database, private document storage, password and unrelated files. Adjust paths if you installed elsewhere. Keep your existing installation folder; replacing it wholesale does not migrate your data. No new API key or model download is needed for this update.

## Fresh installation

Install Node.js **24**, open Ollama and run `ollama pull qwen2.5:3b`. From the new folder:

```sh
cd ~/Downloads/EDITH-Ollama
bash scripts/setup-cloud.sh
npm run dev
```

Run `npm run scheduler` in a second Terminal in the same folder. First opening asks you to create a private password of at least 12 characters. Fresh installations default to Ollama and qwen2.5:3b. Existing installations retain their selected model.

## Optional settings

Search sends only the current search query to Tavily, not your prior conversation, private documents or memory. To disable it, set WEB_SEARCH_ENABLED=false in your private .env and restart. WEB_SEARCH_PROVIDER=duckduckgo selects the alternative connector, with Wikipedia fallback for general questions. An optional private TAVILY_API_KEY uses your Tavily account's allowance instead of the limited keyless mode. The included README documents these options; never put keys in chat.

ElevenLabs remains separate: set ELEVENLABS_API_KEY and your selected ELEVENLABS_VOICE_ID privately, restart and preview the voice. Groq remains an optional cloud conversation provider with its own developer account/key and usage limits.

The original EDITH-Emiliano.zip link also contains this update under its original folder name. EDITH-Ollama.zip provides a distinct folder name for safe code updates.

## Validation

45 backend tests and 11 browser tests passed; production build, type checking and lint passed. Clock tests use actual saved timezones and DST; web transport tests cover actual-link parsing, keyless request headers, limits and failures. Upgrade tests check preservation of keys, password, task, database and original documents. Provider transports are mocked in automated tests. The managed cloud network blocked live Tavily/DuckDuckGo/Wikipedia requests with HTTP 403; live web connectivity must be checked on your Mac. Native macOS execution, real model inference and live ElevenLabs speech are not claimed as verified. The archives exclude private .env files, databases, uploaded originals, node_modules and generated builds.
