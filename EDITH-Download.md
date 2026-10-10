# Download E.D.I.T.H. for Emiliano

Download **EDITH-Emiliano.zip** from this branch using GitHub’s download button. This bundle contains the updated personal assistant source, setup instructions and configuration placeholders. It contains no credentials, personal database, uploaded originals or generated build.

## Launch on your Mac

Install Node.js **24**, unzip the archive in Downloads, and run in Terminal:

```sh
cd ~/Downloads/EDITH-Emiliano
bash scripts/setup-cloud.sh
npm run dev
```

Open `http://localhost:3000` on your Mac and create a private password of at least 12 characters.

In a second Terminal window:

```sh
cd ~/Downloads/EDITH-Emiliano
npm run scheduler
```

Keep both terminals running. See the included README and `.env.example` for secure AI, ElevenLabs, telephone, calendar and notification configuration. The backend suite passed 31 tests and the browser suite passed 9 tests in the cloud Linux environment; build, type checking and lint also passed. Automated external-provider tests used mocks. Native macOS execution and live provider operations require the corresponding platform/credentials.

## Free cloud AI and voice

The update includes a Groq cloud AI preset, setup controls and useful messages for missing keys or usage limits. Groq offers a free developer account with usage limits. Create your own key at https://console.groq.com/keys. In your private `.env` file set `AI_PROVIDER="groq"` and `GROQ_API_KEY` to your key. The preset uses `openai/gpt-oss-20b` by default. Restart both terminals, choose **Use Groq cloud AI** in Integrations, then **Test model connection**.

For ElevenLabs voice, create an API key with Text-to-Speech access and copy the selected voice's ID from your voice library. Put them in `.env` as `ELEVENLABS_API_KEY` and `ELEVENLABS_VOICE_ID`, restart both processes, then preview the voice. Do not put keys in chat.

**You can use Groq with the earlier download without replacing files.** Edit the existing `.env` entries:

```dotenv
AI_PROVIDER="openai-compatible"
AI_BASE_URL="https://api.groq.com/openai/v1"
AI_MODEL="openai/gpt-oss-20b"
AI_API_KEY="paste_your_own_groq_key_here"
ELEVENLABS_API_KEY="paste_your_own_elevenlabs_key_here"
ELEVENLABS_VOICE_ID="paste_your_selected_voice_id_here"
```

Restart both processes and test the connection. Keep your existing `.env`, database and `.edith-runtime` when updating source; replacing an entire extracted folder does not migrate personal data. Neither a configuration entry nor the mocked tests prove that your account is connected; verify that with your own key in the app.
