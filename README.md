# Phy6 Token Saver

**Token-efficient document retrieval for AI conversations.**

Phy6 Token Saver is an MCP server that ranks document chunks with five physics models and returns only the sections that matter.

## Installation

### Linux and macOS

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/BaldheadBill/physics-saver/main/installer/install.sh)
```

### From source

```bash
cargo install phy6-token-saver --locked
```

## MCP Integration

Run the server:

```bash
phy6-token-saver mcp
```

Example client configuration:

```json
{
  "mcpServers": {
    "phy6-token-saver": {
      "command": "/path/to/phy6-token-saver",
      "args": ["mcp"],
      "env": {
        "Phy6_State_File": "/path/to/phy6-token-saver-state.json"
      }
    }
  }
}
```

## Command Line Interface

```bash
phy6-token-saver mcp
phy6-token-saver ingest <file>
phy6-token-saver search "<query>" [k]
phy6-token-saver list
phy6-token-saver status
phy6-token-saver clear
phy6-token-saver help
```

State is persisted to `phy6-token-saver-state.json`. Override it with `Phy6_State_File`.

## Environment Variables

The short `Phy6_` names are the supported configuration names:

| Variable | Default | Purpose |
|---|---:|---|
| `Phy6_Mode` | `1` | Enable physics scoring (`0` disables) |
| `Phy6_Thermal_K` | `0.1` | Thermal decay rate |
| `Phy6_Entropy_Temp` | `1.0` | Boltzmann entropy temperature |
| `Phy6_TTL_Minutes` | `30` | Document time-to-live in minutes |
| `Phy6_State_File` | `phy6-token-saver-state.json` | State file location |

## Build From Source

```bash
cargo build --release
cargo test --release
```

## Credits & Copyright

Phy6 Token Saver was designed, built, and is copyrighted by **VantEdge Intelligence**, Atlanta, GA, USA.

Copyright © 2026 VantEdge Intelligence, Atlanta, GA. All rights reserved.
Released as open source under the [MIT License](LICENSE).

For more information: https://vantedgeintelligence.com/
