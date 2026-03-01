# Claude Multi-Account Setup

Got multiple Claude API keys and tired of switching configs manually? This script fixes that.

## What it does

Sets up aliases for different LLM providers (Anthropic, GLM, DeepSeek, Kimi, etc.) so you can switch between them instantly without messing with environment variables every time.

## Features

- **Multiple providers**: Anthropic (API Key or Web Auth), Z.ai/GLM, DeepSeek, Kimi, OpenRouter, or add your own
- **Interactive menus**: Nice selection menus (uses whiptail if you have it)
- **Custom alias names**: Name your aliases whatever you want (`glm`, `zai`, `work`, `personal`)
- **Model selection**: Choose which Opus/Sonnet/Haiku models to use
- **Subscription plans**: Set Claude/Pro/Max/Enterprise subscription for Anthropic accounts
- **Web authentication**: Use OAuth-based login instead of API keys for Anthropic
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
2. Pick your provider:

   **Anthropic options:**
   - **Anthropic (API Key)** - Quick setup with your API key
   - **Anthropic (Web Auth)** - Browser OAuth, no API key needed

   **Other providers:** Z.ai, DeepSeek, Kimi, etc.

3. Name your alias (e.g. `claude-pro`, `claude-work`, `glm`, `zai`)

4. **For API Key providers:**
   - Paste your API key when prompted

5. **For Web Auth:**
   - Press Enter when prompted for authentication
   - Browser opens automatically for OAuth login
   - Complete login in browser
   - Script continues when authenticated

6. **For Anthropic accounts:**
   - Select subscription plan:
     - Free, Claude, Claude Pro, Claude Max, Enterprise
     - Or "Ask every time" to pick on each launch

7. Select models (or skip for default)
8. Optionally add `--dangerously-skip-permissions` flag
9. Done!

---

### Web Auth vs API Key - Which should you use?

| Feature | API Key | Web Auth |
|---------|---------|----------|
| **Setup speed** | ⚡ Fast (paste key) | 🔐 Slower (OAuth flow) |
| **Multiple accounts** | ✗ Need multiple API keys | ✅ Separate OAuth sessions |
| **Subscription management** | Manual (via web portal) | Built-in prompts |
| | ||
| **Best for** | Single account, quick setup | Multiple accounts, work/personal separation |
| **Security** | API key stored locally | OAuth tokens stored securely |
| **Portability** | Easy (copy .claude_secrets) | Requires re-auth on new machine |

### Use your aliases

```bash
glm              # Start with GLM-5
zai              # Start with Z.ai
deepseek         # Start with DeepSeek
claude-pro       # Start Claude Pro with API key
claude-work      # Start Claude with Web Auth (work account)
```

#### Web Auth + Subscriptions examples

```bash
# Fixed subscription - always uses Pro
claude-pro        # → Uses Pro subscription
claude-max        # → Uses Max subscription

# "Ask every time" - interactive plan selection
claude-work       # → Prompts: Free/Claude/Pro/Max/Enterprise

# Switch between work/personal with same alias
claude-work       # → Launch, pick plan, use that plan for session
```

#### Subscription prompt (when "Ask every time" is set):
```
Select subscription plan for this session:
  1) Free
   2) Claude
  3) Claude Pro
  4) Claude Max
  5) Enterprise
Enter choice [1-5]: 3    # You pick Pro for this session
```

### Multiple terminals

Just open multiple tabs and use different aliases in each. Each tab has its own config.

### Multiple Anthropic accounts (Web Auth)

Perfect for separating work and personal Claude accounts:

```bash
# Setup process:
1. "Anthropic (Web Auth)" → alias: `claude-work`
2. OAuth login with your work email
3. Subscription: "Claude Pro"

4. "Anthropic (Web Auth)" → alias: `claude-personal`
5. OAuth login with your personal email
6. Subscription: "Ask every time"

# Now use them:
claude-work      # Work account, always Pro
claude-personal   # Personal account, prompts for plan each time
```

**File structure for web auth:**
```
~/.claude_configs/
├── claude-work/
│   └── [OAuth credentials]
└── claude-personal/
    └── [OAuth credentials]
```

Each web auth account is completely isolated - different OAuth sessions, different subscriptions.

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
| `~/.claude_configs/<alias>/` | Web auth credentials (for OAuth accounts) |
| `~/.claude_configs_backup/` | Backups before deleting |

## Supported providers & models (2026)

### Anthropic (Official)

**Two authentication methods - choose what works for you:**

#### 1. API Key Authentication
```
Anthropic (API Key)
```
- Uses your Anthropic API key directly
- Simple, straightforward
- Models: `claude-sonnet-4-6`, `claude-opus-4-6`, `claude-haiku-4-5-20251001`
- **Best for**: Quick setup, single account

#### 2. Web Authentication (OAuth) ⭐ NEW
```
Anthropic (Web Auth)
```
- Browser-based OAuth flow (like when you first run `claude`)
- No API key needed - credentials stored securely
- Each account gets isolated config directory
- **Best for**: Multiple Anthropic accounts (work/personal), Pro/Max subscriptions

**How Web Auth works:**
1. Script creates dedicated config directory: `~/.claude_configs/<alias>/`
2. Opens browser for OAuth authentication
3. Credentials stored in that directory
4. Each alias uses its own credentials

**Web Auth benefits:**
- No API keys to manage
- Separate credentials per account
- Perfect for: `claude-work`, `claude-personal`, `claude-pro`, etc.

### Subscription Plans (for Anthropic accounts)

When setting up an Anthropic account, choose your subscription plan:

| Plan | Use case |
|------|----------|
| **Free** | Testing, personal projects |
| **Claude** | Standard usage |
| **Claude Pro** | Higher limits, power users |
| **Claude Max** | Maximum limits, heavy usage |
| **Enterprise** | Enterprise tier |
| **Ask every time** ⚡ | Prompts on each launch - pick plan when you run it |

**How subscriptions work:**

**Fixed subscription** (pre-selected):
```bash
claude-pro    # Always uses Claude Pro subscription
```
Sets: `CLAUDE_SUBSCRIPTION_ID="claude-pro"`

**"Ask every time" mode:**
```bash
claude-work    # Prompts:
                # 1) Free
                # 2) Claude
                # 3) Claude Pro
                # 4) Claude Max
                # 5) Enterprise
```
Lets you pick plan per session - great for switching between work/personal

**Why subscription matters:**
- Different rate limits
- Different features available
- Pro/Max: Higher context, faster response, better performance

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
