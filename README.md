# Claude Multi-Account Setup

Helper script to set up aliases for different LLM providers (Anthropic, GLM, DeepSeek, Kimi, etc.) and switch between them instantly.

## Quick start

```bash
chmod +x claude-multi-account-setup.sh
./claude-multi-account-setup.sh
```

Optional: Install whiptail for nicer menus
```bash
sudo apt install whiptail     # Debian/Ubuntu
sudo pacman -S libnewt        # Arch
```

## How to use

### Add a new account

1. Run the script
2. Pick your provider:
   - **Anthropic (API Key)** - Quick setup with your API key
   - **Anthropic (Web Auth)** - Browser OAuth, no API key needed
   - **Other providers:** Z.ai, DeepSeek, Kimi, etc.
3. Name your alias
4. Paste your API key (or complete OAuth login for Web Auth)
5. Select subscription plan (Anthropic accounts only)
6. Select models (optional)
7. Done!

### Use your aliases

```bash
glm              # Start with GLM
zai              # Start with Z.ai
deepseek         # Start with DeepSeek
claude-pro       # Start Claude Pro with API key
claude-work      # Start Claude with Web Auth
```

### Remove an account

Main Menu → Configuration Management → Remove specific configuration

## Supported providers & models

| Provider | Endpoint | Models |
|----------|----------|--------|
| **Anthropic** | Default | `claude-sonnet-4-6`, `claude-opus-4-6`, `claude-haiku-4-5-20251001` |
| **Z.ai / GLM** | `https://open.bigmodel.cn/api/anthropic` | `glm-5`, `glm-4.7`, `glm-4.7-flash`, `glm-4.5-air` |
| **DeepSeek** | `https://api.deepseek.com/anthropic` | `deepseek-reasoner`, `deepseek-chat` |
| **Kimi** | `https://api.moonshot.ai/anthropic` | `kimi-k2.5`, `kimi-k2`, `kimi-k2-turbo`, `moonshot-v1-*` |
| **OpenRouter** | `http://localhost:8787` | Various (needs [y-router](https://github.com/luohy15/y-router)) |

**Anthropic subscriptions:** Free, Claude, Claude Pro, Claude Max, Enterprise, or "Ask every time"

## Files created

| File | Purpose |
|------|---------|
| `~/.claude_secrets` | API keys (chmod 600) |
| `~/.bashrc` or `~/.zshrc` | Aliases |
| `~/.claude_configs/<alias>/` | Web auth credentials (OAuth accounts) |
| `~/.claude_configs_backup/` | Backups |

## Troubleshooting

**Aliases don't work?**
```bash
source ~/.bashrc   # or source ~/.zshrc
```

**List all aliases:**
```bash
alias | grep claude
```

**Change shell type:**
Main Menu → Settings → Change shell type

## Requirements

- Linux (macOS should work too, untested)
- Bash or Zsh
- Claude Code: `npm install -g @anthropic-ai/claude-code`
- API keys from your providers
- Optional: `whiptail` for nicer menus

## License

MIT
