# ClawApp

<p align="center"><strong>📱 Chat with your OpenClaw AI agent from any mobile browser</strong></p>

<p align="center">
  <a href="#overview">Overview</a> •
  <a href="#features">Features</a> •
  <a href="#quick-start">Quick start</a> •
  <a href="#deployment">Deployment</a> •
  <a href="#configuration">Configuration</a> •
  <a href="#troubleshooting">Troubleshooting</a> •
  <a href="#security">Security</a>
</p>

---

## Overview

[OpenClaw](https://github.com/openclaw/openclaw) is an AI agent platform. Its Gateway commonly listens on the local loopback interface (127.0.0.1:18789), so a phone on another device cannot connect to it directly.

ClawApp provides a mobile-friendly web client and a server-side bridge between the browser and the OpenClaw Gateway. Open the client in your phone browser without installing a native app.

### Connection architecture

```text
Mobile browser
     │
     │ HTTP requests + Server-Sent Events (SSE)
     ▼
ClawApp server (default port 3210)
     │
     │ WebSocket + Ed25519 device authentication
     ▼
OpenClaw Gateway (default port 18789)
```

The server manages the Gateway connection and device-authentication handshake. The browser sends commands over HTTP and receives events through an SSE stream.

## Features

- 💬 Real-time AI conversations with streamed responses
- 📷 Image uploads and AI image responses
- 📝 Markdown rendering and code highlighting with XSS protections
- ⚡ Quick commands, including /model, /think, and /new
- 🔧 Live tool-call status
- 🎤 Voice input (speech-to-text; requires an HTTPS secure context)
- 🤖 Multiple agents, selectable when creating a conversation
- 📋 Session management: switch, create, and delete conversations
- 🌙 Light, dark, and system-matched themes
- 🌐 English and Chinese interface translations
- 🔄 Automatic reconnection and message de-duplication
- 🔒 Proxy token/password protection and Ed25519 device authentication
- 💾 Persistent offline message history using IndexedDB
- 👋 First-time user guidance
- 📱 Progressive Web App (PWA) support
- 📦 Android packaging through Capacitor
- 🖥️ Desktop packaging through Electron for Windows, macOS, and Linux

## Screenshots

<table align="center">
  <tr>
    <td align="center"><img src="docs/image/login-page.png" width="220" alt="Connection screen" /><br/><sub>Connection</sub></td>
    <td align="center"><img src="docs/image/chat-response.png" width="220" alt="AI chat response" /><br/><sub>Streaming chat</sub></td>
    <td align="center"><img src="docs/image/chat-commands.jpg" width="220" alt="Quick commands" /><br/><sub>Quick commands</sub></td>
  </tr>
  <tr>
    <td align="center"><img src="docs/image/session-manager.jpg" width="220" alt="Session manager" /><br/><sub>Sessions</sub></td>
    <td align="center"><img src="docs/image/commands-panel.png" width="220" alt="Command panel" /><br/><sub>Command panel</sub></td>
    <td align="center"><img src="docs/image/settings-panel.jpg" width="220" alt="Settings panel" /><br/><sub>Settings</sub></td>
  </tr>
</table>

## Quick start

### Requirements

- An OpenClaw Gateway reachable from the machine running ClawApp (default port: 18789)
- Node.js 18 or later and npm
- Docker and Docker Compose (only for Docker deployment)

### 1. Clone the repository

```bash
git clone https://github.com/auraecosystem/Clawapp.git
cd Clawapp
```

### 2. Install dependencies and build the web client

```bash
npm run install:all
npm run build:h5
```

### 3. Configure the server

Copy the example environment file:

```bash
cp server/.env.example server/.env
```

Edit server/.env and set a strong proxy password and your OpenClaw Gateway credentials:

```dotenv
PROXY_PORT=3210
PROXY_TOKEN=replace-with-a-long-random-secret
OPENCLAW_GATEWAY_URL=ws://127.0.0.1:18789
OPENCLAW_GATEWAY_TOKEN=your-openclaw-gateway-token

# If your Gateway uses password authentication, use this instead:
# OPENCLAW_GATEWAY_PASSWORD=your-openclaw-gateway-password
```

These credentials serve different purposes:

- PROXY_TOKEN is the password users enter to access ClawApp.
- OPENCLAW_GATEWAY_TOKEN or OPENCLAW_GATEWAY_PASSWORD authenticates ClawApp to the OpenClaw Gateway.

Use the authentication method configured in your Gateway. Never commit real credentials to Git.

### 4. Start ClawApp

```bash
npm start
```

The server listens on port 3210 by default. On your phone, open http://YOUR_COMPUTER_IP:3210 and enter the proxy token.

## Deployment

### Local network

1. Start the OpenClaw Gateway.
2. Install dependencies and build the H5 client.
3. Configure server/.env.
4. Run npm start.
5. Open http://YOUR_COMPUTER_IP:3210 on your phone.

Find your computer's local IP address:

```bash
# macOS
ifconfig

# Windows
ipconfig

# Linux
ip addr
```

Use the address assigned to the network interface connected to your Wi-Fi or LAN. Do not use localhost on your phone; it refers to the phone itself.

### Docker

Create a .env file in the repository root:

```dotenv
PROXY_TOKEN=replace-with-a-long-random-secret
OPENCLAW_GATEWAY_TOKEN=your-openclaw-gateway-token
ALLOWED_ORIGINS=
```

Build and start the service:

```bash
docker compose up -d --build
docker compose logs -f
```

The provided Compose configuration uses host.docker.internal to reach a Gateway running on the Docker host. Make sure the Gateway is reachable from inside the container and that its authentication settings match the environment variables.

Stop the service:

```bash
docker compose down
```

### Run with PM2

```bash
npm install -g pm2
pm2 start server/index.js --name clawapp
pm2 save
pm2 startup
```

Check the process and logs:

```bash
pm2 status
pm2 logs clawapp
```

## Remote access

When your phone and ClawApp server are on different networks, expose ClawApp through a secure tunnel or reverse proxy.

### Cloudflare Tunnel

Cloudflare Tunnel can provide an HTTPS endpoint without requiring a public IP address. Configure a tunnel to forward traffic to the local ClawApp service on port 3210.

HTTPS is important because browsers generally require a secure context for microphone access. For temporary testing, use a quick tunnel. For a persistent deployment, configure a named tunnel and hostname in your Cloudflare account, and apply appropriate access controls.

### SSH reverse tunnel

This option requires a server with a public IP address and SSH access. Run this command on the machine hosting ClawApp:

```bash
ssh -f -N -o ServerAliveInterval=15 -o ServerAliveCountMax=4 -R 0.0.0.0:3210:127.0.0.1:3210 user@YOUR_SERVER_IP
```

The remote SSH server must allow remote port forwarding. Depending on its configuration, GatewayPorts yes may be required in /etc/ssh/sshd_config. Allow the required port through the server firewall.

This basic tunnel does not provide HTTPS. Use a TLS-terminating reverse proxy if you need browser features that require a secure context.

### Nginx reverse proxy

Configure Nginx to terminate TLS and forward requests to ClawApp. The proxy must support streaming responses and keep connections open.

```nginx
server {
    listen 443 ssl;
    server_name chat.example.com;

    ssl_certificate /path/to/fullchain.pem;
    ssl_certificate_key /path/to/privkey.pem;

    location / {
        proxy_pass http://127.0.0.1:3210;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_buffering off;
        proxy_read_timeout 86400;
    }
}
```

| Method | Advantages | Considerations |
| --- | --- | --- |
| Cloudflare Tunnel | HTTPS endpoint; no public IP required | Depends on Cloudflare |
| SSH tunnel | Simple and uses SSH | Requires a public server; tunnel needs monitoring |
| Nginx reverse proxy | Flexible domain and TLS configuration | Requires server administration and certificate management |
| Tailscale or ZeroTier | Private encrypted network access | Client software is required on devices |

## Connection settings

### Server address

Enter the address of the machine running ClawApp, including port 3210.

- Local network: 192.168.1.100:3210
- Public hostname: chat.example.com
- Local machine: localhost:3210 (only when the browser is running on the same machine)

### Proxy token

The login token is the value of PROXY_TOKEN in server/.env. It is the access password you define for ClawApp.

Check the configured value on the server:

```bash
grep '^PROXY_TOKEN=' server/.env
```

### OpenClaw Gateway credentials

The Gateway credential is separate from the ClawApp proxy token. Check your OpenClaw configuration and use the matching authentication method in server/.env.

Token authentication:

```dotenv
OPENCLAW_GATEWAY_TOKEN=your-openclaw-gateway-token
```

Password authentication:

```dotenv
OPENCLAW_GATEWAY_PASSWORD=your-openclaw-gateway-password
```

If both are configured, the server gives the password setting precedence. Keep Gateway credentials on the server; never expose them in the browser client or commit them to the repository.

### Client preferences

Open the settings menu in the chat interface to change:

- Theme: light, dark, or follow system
- Language: English or Chinese
- Connection: disconnect and return to the connection screen

## Configuration

The server reads its settings from server/.env.

| Variable | Required | Default | Description |
| --- | --- | --- | --- |
| PROXY_PORT | No | 3210 | Port used by the ClawApp server |
| PROXY_TOKEN | Yes | Generated on first run if missing | Password required by the H5 client |
| OPENCLAW_GATEWAY_URL | No | ws://127.0.0.1:18789 | WebSocket URL of the OpenClaw Gateway |
| OPENCLAW_GATEWAY_TOKEN | One auth method required | — | Gateway token authentication |
| OPENCLAW_GATEWAY_PASSWORD | One auth method required | — | Gateway password authentication; takes precedence when set |
| MEDIA_ALLOW_ALL | No | 0 | Set to 1 to allow media access from any path |
| MEDIA_ALLOWED_DIRS | No | Built-in allowed directories | Additional comma-separated directories permitted for media access |
| ALLOWED_ORIGINS | No | — | Additional comma-separated browser origins allowed by CORS |

By default, media access is restricted to approved directories. Avoid enabling unrestricted media access unless you understand the security implications.

## Project structure

```text
Clawapp/
├── server/                  # HTTP/SSE bridge to the OpenClaw Gateway
│   ├── index.js             # Express server, Gateway connection, and API routes
│   ├── package.json
│   ├── Dockerfile
│   └── .env.example
├── h5/                      # Mobile web client
│   ├── src/
│   │   ├── main.js          # Application entry point and connection screen
│   │   ├── ws-client.js     # Client transport and connection handling
│   │   ├── chat-ui.js       # Chat interface
│   │   ├── session-picker.js
│   │   ├── message-db.js    # IndexedDB message persistence
│   │   ├── offline-queue.js # Offline queue and synchronization
│   │   ├── commands.js      # Quick commands
│   │   ├── markdown.js      # Markdown rendering and code highlighting
│   │   ├── media.js         # Media handling
│   │   ├── i18n.js          # Interface translations
│   │   ├── theme.js         # Theme management
│   │   └── settings.js      # Client settings
│   ├── index.html
│   └── vite.config.js
├── electron/                # Desktop application
├── android/                 # Android application project
├── .github/workflows/       # GitHub Actions workflows
├── docs/                    # Documentation and screenshots
├── capacitor.config.ts      # Capacitor configuration
├── Dockerfile               # Multi-stage Docker build
├── docker-compose.yml       # Container deployment
└── README.md
```

## Development

Install dependencies:

```bash
npm run install:all
```

Start the H5 development server:

```bash
npm run dev:h5
```

Start the ClawApp server in a separate terminal:

```bash
npm run dev:server
```

Build the H5 client:

```bash
npm run build:h5
```

Build desktop packages:

```bash
npm run build:desktop
```

Platform-specific desktop builds:

```bash
npm run build:desktop:win
npm run build:desktop:mac
npm run build:desktop:linux
```

## Troubleshooting

### The client stays on “Connecting” or reports a 502 error

1. Confirm that the OpenClaw Gateway is running and reachable from the ClawApp server.
2. Check OPENCLAW_GATEWAY_URL and the Gateway authentication settings in server/.env.
3. Review the ClawApp server logs for Gateway connection or device-pairing errors.
4. If the Gateway reports NOT_PAIRED or pairing required, approve the pending device from the Gateway host using the OpenClaw device-pairing workflow:

   ```bash
   openclaw gateway call device.pair.list --json
   openclaw gateway call device.pair.approve --params '{"requestId":"YOUR_REQUEST_ID"}' --json
   ```

5. When using Docker, verify that the Gateway URL is reachable from inside the container. The supplied Compose configuration uses ws://host.docker.internal:18789.

### The phone cannot open the page

1. Confirm that the phone and computer are on the same Wi-Fi network, if using local access.
2. Use the computer's LAN IP address, not localhost.
3. Check that the computer firewall allows inbound connections to port 3210.
4. Confirm that ClawApp is running and listening on the expected port.

### Streaming or live updates stop unexpectedly

Check whether a reverse proxy is buffering streaming responses or closing idle connections. Disable proxy buffering for the ClawApp route and increase the proxy read timeout. Also check network stability and the ClawApp server logs.

### Can multiple people use one ClawApp server?

The server can handle multiple client connections. Each connection reaches the configured OpenClaw instance. Do not expose a shared instance publicly without appropriate access controls.

### How do I add another language?

Add translation strings to h5/src/i18n.js and update the language selection in the client settings. Keep translation keys consistent across all language packs.

### Voice input does not work

Browsers generally require HTTPS (or a localhost development context) to grant microphone access. Use an HTTPS reverse proxy or secure tunnel, then grant microphone permission in the browser.

### Docker cannot install npm packages

If package downloads time out, check DNS and network connectivity from the Docker build environment. You can also build and run the project directly on the host:

```bash
npm run install:all
npm run build:h5
cp server/.env.example server/.env
# Edit server/.env, then:
npm start
```

### Port 3210 is already in use

Find the process using the port and stop it before starting another ClawApp instance.

On Linux or macOS:

```bash
lsof -i :3210
```

If you use Docker, check running containers:

```bash
docker compose ps
docker compose down
```

### PM2 cannot find Node.js after a reboot

If Node.js was installed through a version manager such as nvm, the non-interactive startup environment may not load it automatically. Configure PM2's startup service with the correct Node.js environment and verify the executable path after reboot.

### Can ClawApp run on a server without OpenClaw installed?

Yes, if that server can securely reach an OpenClaw Gateway running elsewhere. Use a private network or SSH tunnel to connect the ClawApp server to the machine hosting the Gateway. Do not expose the Gateway port directly to the public internet.

## Security

- Set a strong, unique PROXY_TOKEN. Generate one with:

  ```bash
  openssl rand -hex 24
  ```

- Keep OPENCLAW_GATEWAY_TOKEN and OPENCLAW_GATEWAY_PASSWORD in the server-side environment file only.
- Never commit .env files, private keys, or credentials to Git.
- Use HTTPS for public access.
- Consider adding an additional access-control layer in front of a public deployment.
- Restrict firewall rules to the ports and hosts that must be reachable.
- Keep media access restricted to trusted directories. Do not enable MEDIA_ALLOW_ALL=1 on an exposed server unless absolutely necessary.
- Keep OpenClaw and ClawApp dependencies updated.


## Additional troubleshooting

### Port 3210 is already in use

Another process or an earlier ClawApp instance may already be using port 3210. Identify it before starting another instance:

```bash
lsof -i :3210
```

If the process is managed by PM2, stop the relevant process. If it is running in Docker, inspect and stop the container:

```bash
docker compose ps
docker compose down
```

### PM2 repeatedly restarts ClawApp

Check that the OpenClaw Gateway is running and that the credentials in `server/.env` are correct. Then inspect the PM2 logs:

```bash
pm2 logs clawapp --lines 30
```

If Node.js was installed with nvm, PM2's startup service may not load the nvm environment after a reboot. Check the absolute Node.js path with `which node`, then configure PM2's startup environment to use that installation. Do not create system-wide symlinks unless you understand how your Node.js installation is managed.

### Does ClawApp require changes to OpenClaw?

No OpenClaw plugin or additional Gateway port is required for the documented setup. The OpenClaw Gateway must be running and reachable by the ClawApp server, and the correct Gateway credentials must be configured server-side.

### Can ClawApp run on a server without a local OpenClaw installation?

Yes. The remote ClawApp server must have a secure network path to the machine running the Gateway. One option is an SSH local forward opened from the ClawApp server to the computer hosting OpenClaw:

```bash
ssh -f -N -L 127.0.0.1:18789:127.0.0.1:18789 user@YOUR_OPENCLAW_HOST
```

With this tunnel active, configure ClawApp to connect to `ws://127.0.0.1:18789`. Keep the tunnel private and do not expose the Gateway port directly to the public internet.

### Remote users can open the page but cannot chat

The ClawApp server also needs connectivity to an OpenClaw Gateway. Opening port 3210 to the phone is not enough if the Gateway is unavailable from the server. Verify `OPENCLAW_GATEWAY_URL`, the tunnel or private network, and the Gateway credentials.

## Related projects

- [OpenClaw](https://github.com/openclaw/openclaw) — AI agent platform used by ClawApp.
- [OpenClaw Chinese translation](https://github.com/1186258278/OpenClawChineseTranslation) — Community-maintained Chinese localization.
- [cftunnel](https://github.com/qingchencloud/cftunnel) — CLI for managing Cloudflare Tunnels.
- [cftunnel desktop client](https://github.com/qingchencloud/cftunnel-app) — Desktop interface for cftunnel.

## Community

Use the community channels to discuss usage, report issues, and follow project updates.

<p align="center">
  <a href="https://discord.gg/U9AttmsNHh"><img src="https://img.shields.io/badge/Discord-Join%20the%20community-5865F2?style=for-the-badge&logo=discord&logoColor=white" alt="Join Discord"></a>
  &nbsp;
  <a href="https://yb.tencent.com/gp/i/LsvIw7mdR7Lb"><img src="https://img.shields.io/badge/Yuanbao-Join%20the%20community-FF6A00?style=for-the-badge&logo=tencent-qq&logoColor=white" alt="Join Yuanbao community"></a>
  &nbsp;
  <a href="https://qt.cool/c/OpenClaw"><img src="https://img.shields.io/badge/QQ%20Group-Join%20the%20discussion-12B7F5?style=for-the-badge&logo=tencent-qq&logoColor=white" alt="Join QQ group"></a>
  &nbsp;
  <a href="https://qt.cool/c/OpenClawWx"><img src="https://img.shields.io/badge/WeChat-Join%20the%20group-07C160?style=for-the-badge&logo=wechat&logoColor=white" alt="Join WeChat group"></a>
  &nbsp;
  <a href="https://qt.cool/c/feishu"><img src="https://img.shields.io/badge/Feishu-Join%20the%20group-3370FF?style=for-the-badge&logo=lark&logoColor=white" alt="Join Feishu group"></a>
</p>

### QQ group

<p align="center">
  <img src="docs/image/OpenClaw-QQ.png" alt="QQ community group QR code" width="200">
</p>
<p align="center"><em>Scan the QR code or use the <a href="https://qt.cool/c/OpenClaw">group link</a> to join.</em></p>

### WeChat group

<p align="center">
  <a href="https://qt.cool/c/OpenClawWx"><img src="docs/image/OpenClawWx.png" alt="WeChat community group QR code" width="200"></a>
</p>
<p align="center"><em>Scan the QR code or use the <a href="https://qt.cool/c/OpenClawWx">group link</a> to join and share feedback.</em></p>

### Feishu group

<p align="center">
  <a href="https://qt.cool/c/feishu"><img src="https://qt.cool/c/feishu/qr.png" alt="Feishu community group QR code" width="200"></a>
</p>
<p align="center"><em>Scan the QR code or use the <a href="https://qt.cool/c/feishu">group link</a> to join.</em></p>

### Contributors

Thank you to everyone who has contributed to ClawApp.

<p align="center">
  <a href="https://github.com/1186258278"><img src="https://avatars.githubusercontent.com/u/42165041?v=4" width="64" height="64" style="border-radius:50%" alt="1186258278"></a>
  &nbsp;&nbsp;
  <a href="https://github.com/youyli03"><img src="https://avatars.githubusercontent.com/u/123646696?v=4" width="64" height="64" style="border-radius:50%" alt="youyli03"></a>
  &nbsp;&nbsp;
  <a href="https://github.com/2221186349"><img src="https://avatars.githubusercontent.com/u/78676214?v=4" width="64" height="64" style="border-radius:50%" alt="2221186349"></a>
</p>

<p align="center">
  <a href="https://claw.qt.cool">ClawPanel</a><br>
  <a href="https://clawapp.saharaai.com">clawapp.saharaai.com</a>
</p>

## License

ClawApp is distributed under the MIT License.
