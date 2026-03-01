# Claude Multi-Account Setup

Got multiple Claude API keys and tired of switching configs manually? This script fixes that.

## What it does

Sets up aliases for different LLM providers (Anthropic, GLM, DeepSeek, Kimi, etc.) so you can switch between them instantly without messing with environment variables every time.

## Features

- **Multiple providers**: Anthropic, Z.ai/GLM, DeepSeek, Kimi, OpenRouter, or add your own
- **Interactive menus**: Nice selection menus (uses whiptail if you have it)
- **Custom alias names**: Name your aliases whatever you want (`glm`, `zai`, `work`, `personal`)
- **Model selection**: Choose which Opus/Sonnet/Haiku models to use
- **Secure**: API keys stored in separate file with chmod 600
- **Auto backup**: Backs up before deleting anything
- **Works with bash & zsh**: Auto-detects your shell

## Quick start

```bash
# Make it executable
chmod +x claude-multi-account-setup.sh

# Run it
./claude-multi-account-setup.sh

# (Optional) Install whiptail for nicer menus
sudo apt install whiptail     # Debian/Ubuntu
sudo pacman -S libnewt        # Arch
```

## How to use

### Add a new account

1. Run the script → `➕ Add new account/provider configuration`
2. Pick your provider (Z.ai, DeepSeek, whatever)
3. Name your alias (e.g. `glm`, `zai`, `my-ai` - whatever works for you)
4. Paste your API key
5. Select models (or skip)
6. Optionally add `--dangerously-skip-permissions` flag (not recommended, but available)
7. Done! Alias is ready to use

### Use your aliases

```bash
glm              # Start with GLM-5
zai              # Start with Z.ai
deepseek         # Start with DeepSeek
my-ai            # Your custom alias

# With arguments
glm -m "glm-4.7"     # Use specific model
glm --help           # Show help
```

### Multiple terminals

Just open multiple tabs and use different aliases in each. Each tab has its own config.

### Remove an account

```
Main Menu → ⚙️ Configuration Management → Remove specific configuration
```

Select from the list, confirm, and it's gone.

**Note**: Script will ask if you want to delete the API key too (separate choice).

## Files created

| File | What's in it |
|------|--------------|
| `~/.claude_secrets` | Your API keys (chmod 600) |
| `~/.bashrc` or `~/.zshrc` | Your aliases go here |
| `~/.claude_configs_backup/` | Backups before deleting |

## Supported providers & models (2026)

### Anthropic (Official)
- Endpoint: Default
- Models: `claude-sonnet-4-6`, `claude-opus-4-6`, `claude-haiku-4-5-20251001`

### Z.ai / Zhipu GLM
- Endpoint: `https://open.bigmodel.cn/api/anthropic`
- Models:
  - `glm-5` (Opus) - 745B, 200K context (latest, Feb 2026)
  - `glm-4.7` (Sonnet) - Main one
  - `glm-4.7-flash` (Sonnet) - Free & light
  - `glm-4.5-air` (Haiku) - Quick stuff
- Website: https://open.bigmodel.cn

### DeepSeek
- Endpoint: `https://api.deepseek.com/anthropic`
- Models:
  - `deepseek-reasoner` (Opus) - The smart one
  - `deepseek-chat` (Sonnet) - General use
- V4 coming soon (March 2026 supposedly)

### Kimi / Moonshot AI
- Endpoint: `https://api.moonshot.ai/anthropic`
- Models:
  - `kimi-k2.5` (Opus) - 1T params, 256K context (Jan 2026)
  - `kimi-k2` (Sonnet) - Main one
  - `kimi-k2-turbo` (Sonnet) - Faster
  - `moonshot-v1-*` (Haiku) - 8K/32K/128K

### OpenRouter
- Endpoint: `http://localhost:8787` (needs y-router)
- Models: Various via OpenRouter

**For OpenRouter you need y-router:**
```bash
git clone https://github.com/luohy15/y-router
cd y-router
docker-compose up -d
```

## Switch between bash/zsh

Not sure which shell is being used?

```
Main Menu → ℹ️ Settings & Information → 🐚 Change shell type
```

You can switch between bash and zsh there. New aliases will go to the appropriate file.

## Troubleshooting

### Aliases don't work after setup?

```bash
source ~/.bashrc   # or source ~/.zshrc
```

Or restart your terminal.

### Which shell am I using?

```
Main Menu → ℹ️ Settings & Information → View secrets file location
```

Look for "Shell Type: bash" or "Shell Type: zsh"

### View your API keys (careful!)

```bash
cat ~/.claude_secrets
```

### List all your aliases

```bash
alias | grep claude
```

## Security stuff

- API keys stored in `~/.claude_secrets` with chmod 600 (only you can read)
- File won't be committed (in .gitignore)
- Auto-backup before deleting anything

## Requirements

- Linux (should work on macOS too, untested)
- Bash or Zsh
- Claude Code: `npm install -g @anthropic-ai/claude-code`
- API keys from whatever providers you want to use
- Optional: `whiptail` for nicer menus

## License

MIT - do whatever you want with it.

## Bugs / feature requests

If something breaks or you add something cool, feel free to open a PR or issue.
