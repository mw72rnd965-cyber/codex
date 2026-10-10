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

Keep both terminals running. See the included README and `.env.example` for secure AI, ElevenLabs, telephone, calendar and notification configuration. The backend suite passed 24 tests and the browser suite passed 8 tests in the cloud Linux environment. The clean bundle’s install, sign-in page and independent scheduler were verified there. Automated external-provider tests used mocks. Native macOS execution and live provider operations require the corresponding platform/credentials.
