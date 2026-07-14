# Privacy Policy for NanoDash

**Last updated: July 14, 2026**

NanoDash ("the app", "we", "us") is a desktop application that displays a
dashboard of widgets — clock, calendar, weather, markets, system monitor, media
"now playing", a timer/stopwatch, a Live2D character, and an optional local voice
assistant — and can mirror that dashboard to an external USB-connected
touchscreen.

We take your privacy seriously. This policy explains what data the app handles,
where it goes, and the choices you have.

## Summary

- **We do not have servers, and we do not collect, store, or sell your personal
  data.** NanoDash has no user accounts and requires no sign-up.
- **All of your settings stay on your device.** Configuration (dashboard layout,
  API keys, calendar URLs, watchlists, etc.) is stored locally on your computer.
- **The app contains no advertising and no analytics or tracking SDKs.**
- Some optional features connect directly from your device to third‑party
  services **that you choose to enable** in order to fetch information. Those
  connections are described below.

## Data stored on your device

The following is saved locally on your computer (via the operating system's
standard application storage) and is never transmitted to us:

- Your dashboard configuration and enabled modules.
- Feature settings, including any API keys, endpoint URLs, calendar feed URLs,
  location/city, market watchlist symbols, and voice/agent preferences you enter.

You can remove this data at any time by clearing the app's settings or
uninstalling the app.

## Information the app processes locally (never leaves your device)

Some modules read information from your own computer purely to display it. This
data is processed on‑device and is **not** sent to us or to any third party:

- **System Monitor** — CPU, memory, and network usage of your computer.
- **Now Playing** — metadata about media currently playing on your computer
  (e.g. track title/artist), read from the operating system's media session.
- **Usage Monitor** — locally stored usage/rate‑limit logs of developer CLI tools
  installed on your computer (e.g. Claude Code, Codex).
- **Voice assistant** — when enabled, microphone audio is captured and processed
  **on your device** (voice activity detection, speech recognition, and
  text‑to‑speech run locally). Audio is not uploaded to us. (See the voice
  assistant note under third‑party services if you connect it to an external
  language model.)

## Third‑party services (optional features)

When you enable certain modules, the app connects **directly from your device**
to the following third‑party services to retrieve information. We do not operate
these services and receive no data from them. Each is governed by its own
provider's privacy policy.

| Feature | Service contacted | Data sent | Purpose |
|---|---|---|---|
| Weather | Open‑Meteo (`open-meteo.com`) | Your chosen location's coordinates/city | Retrieve weather forecast |
| Weather location lookup | ipwho.is (`ipwho.is`) | Your device's public IP address | Estimate your city when you use automatic location |
| Markets | Yahoo Finance (`finance.yahoo.com`) | The stock/crypto/FX symbols in your watchlist | Retrieve quotes |
| Calendar | The calendar server **you configure** (any iCalendar/ICS or CalDAV URL) | The feed URL and any credentials you enter | Retrieve your calendar events |
| Voice assistant / AI agent | The AI provider **you configure** (an OpenAI‑compatible endpoint such as `api.openai.com`, or Anthropic `api.anthropic.com`) | Your prompts/conversation text and your API key | Generate assistant responses |

Notes:

- **You control these connections.** No third‑party service is contacted unless
  you enable the corresponding module and, where applicable, provide the
  endpoint/credentials.
- **API keys and calendar credentials** you enter are stored locally and are sent
  only to the endpoint you configured, to authenticate your own requests.
- **AI agent/voice provider:** if you connect the assistant to an external
  language model, the text of your conversation (and, if you use voice, the
  transcribed text) is sent to that provider you selected. Please review that
  provider's privacy policy. If you do not configure an external provider, no
  conversation data leaves your device.

## Permissions the app may request

- **Microphone** — only if you enable the voice assistant, for on‑device speech
  processing.
- **Network access** — to contact the optional third‑party services listed above.
- **USB device access** — to communicate with the connected NanoDash touchscreen
  hardware, if present. No personal data is sent to the device beyond the
  on‑screen dashboard imagery you already see.

## Children's privacy

NanoDash is not directed at children and does not knowingly collect any personal
information from children.

## Changes to this policy

We may update this policy from time to time. Material changes will be reflected by
updating the "Last updated" date above.

## Contact

If you have questions about this privacy policy, contact us at:

**Email:** yplam@yplam.com
