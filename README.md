# Physics-Saver

**Token-efficient document retrieval for AI conversations.**

Physics-Saver is an MCP server that stops AI models from swallowing entire documents into context. It ranks document chunks with five physics models and returns only the sections that matter — typically **5–10% of the source material**, cutting token usage by up to 95% on Claude Desktop, Claude Code, and Gemini CLI.

## Highlights

- **MCP server mode** — callable tools (`ingest_document`, `search_documents`, `list_documents`, `clear_documents`) inside any MCP-compatible assistant
- **Five physics models** — gravitational rank fusion, thermal decay, damped harmonic oscillation, Boltzmann entropy thresholding, wave interference
- **Persistent state** — documents survive restarts, with configurable time-to-live
- **Single static binary** for Windows, macOS, and Linux
- **One-click installers** for every platform

## How It Works

Instead of pasting entire documents into your chat, the assistant calls `search_documents` when it needs information. Five physics models score every chunk:

| Model | Role |
|---|---|
| Gravitational | Newtonian rank fusion based on query–chunk distance |
| Thermal | Exponential context decay (Newton's Law of Cooling) |
| Damped harmonic oscillator | Token budget control that adapts to query complexity |
| Boltzmann distribution | Entropy-based thresholding for top-k selection |
| Wave interference | Constructive fusion of related chunks, cancellation of noise |

Search results are wrapped in `<document-chunk>` blocks preceded by a preamble instructing the model to treat retrieved data as quoted material, never as instructions.

## One-Click Installation

### Windows

1. Download `Physics-Saver-Setup-3.0.0.exe` from the latest [release](https://github.com/BaldheadBill/physics-saver/releases).
2. Double-click and follow the wizard. Optionally tick *Register with Claude Desktop* / *Register with Gemini CLI*.
3. Restart Claude Desktop / Gemini CLI. Done.

### macOS

1. Download `install.command` from the repository.
2. Double-click it. If Gatekeeper warns on first run, right-click → **Open**.
3. Answer the prompts — it installs to `~/.local/bin` and can register with Claude Desktop and Gemini CLI automatically.

### Linux

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/BaldheadBill/physics-saver/main/installer/install.sh)
```

### Manual / From Source

```bash
cargo install physics-saver --locked
```

The `installer/` folder contains the sources for all installers: `install.ps1` (Windows), `install.sh` (macOS/Linux), `install.command` (macOS double-click), and `Physics-Saver.iss` (Inno Setup source for the Windows setup.exe).

## MCP Integration

Run the server mode:

```bash
physics-saver mcp
```

### Claude Desktop (Windows)

Edit `%APPDATA%\Claude\claude_desktop_config.json` (Settings → Developer → Edit Config), then fully quit and restart Claude Desktop:

```json
{
  "mcpServers": {
    "physics-saver": {
      "command": "C:\\path\\to\\physics-saver.exe",
      "args": ["mcp"],
      "env": {
        "PHYSICS_SAVER_STATE_FILE": "C:\\path\\to\\physics-saver-state.json"
      }
    }
  }
}
```

### Claude Code

```bash
claude mcp add physics-saver --transport stdio -- C:\path\to\physics-saver.exe mcp
```

### Gemini CLI

```bash
gemini mcp add physics-saver "C:\path\to\physics-saver.exe" mcp
```

Or add the same `mcpServers` block to `~/.gemini/settings.json`.

### Exposed Tools

| Tool | Arguments | Purpose |
|---|---|---|
| `ingest_document` | `path` (required) | Load a UTF-8 text document |
| `search_documents` | `query` (required), `k` (default 5, max 20) | Return top-k chunks ranked by physics |
| `list_documents` | — | List ingested documents and chunk counts |
| `clear_documents` | — | Remove all documents |

## Command Line Interface

```bash
physics-saver mcp                 # run as MCP server for Claude/Gemini
physics-saver ingest <file>       # load a document
physics-saver search "<query>" [k]  # search top-k chunks (default k=5)
physics-saver list                # list documents
physics-saver status              # show store status
physics-saver clear               # remove all documents
physics-saver help                # show help
```

State is persisted to `physics-saver-state.json` in the working directory. Override with `PHYSICS_SAVER_STATE_FILE`.

## Environment Variables

| Variable | Default | Purpose |
|---|---|---|
| `PHYSICS_SAVER_MODE` | `1` | Enable physics scoring (`0` disables) |
| `PHYSICS_SAVER_THERMAL_K` | `0.1` | Thermal decay rate |
| `PHYSICS_SAVER_ENTROPY_TEMP` | `1.0` | Boltzmann entropy temperature |
| `PHYSICS_SAVER_MCP_TTL_MINUTES` | `30` | Document time-to-live in minutes |
| `PHYSICS_SAVER_STATE_FILE` | `physics-saver-state.json` | State file location |

## Build From Source

```bash
cargo build --release
cargo test --release
```

Binaries land in `target/release/`.

## Troubleshooting

- **Server doesn't connect** — verify the `command` path is absolute and correct, then restart the AI app completely (configs are read at startup).
- **Tools don't appear** — check the app's MCP logs; the server writes diagnostics to stderr only (stdout is reserved for the protocol).
- **Windows USB drive refuses to run the exe** — Windows blocks executables on some removable/FAT32 drives; install to the local disk (the installer does this by default).

## Credits & Copyright

Physics-Saver was designed, built, and is copyrighted by **VantEdge Intelligence**, Atlanta, GA, USA.

Copyright © 2026 VantEdge Intelligence, Atlanta, GA. All rights reserved.
Released as open source under the [MIT License](LICENSE).

For more information: https://vantedgeintelligence.com/
