# MiniMax Provider Integration — Design Spec

**Date:** 2026-04-03  
**Status:** Approved

## Summary

Add MiniMax as a dedicated provider in `claude-multi-account-setup.sh`, following the same pattern as ZAI, DeepSeek, and Kimi. Extend the README provider table accordingly.

## Scope

Three files change:
1. `claude-multi-account-setup.sh` — provider declaration, model array, case block
2. `README.md` — provider table row

## Changes

### 1. Provider entry

Add to the `PROVIDERS` associative array:

```bash
PROVIDERS[minimax]="MiniMax"
```

### 2. Model array

Add after the Kimi models section:

```bash
# MiniMax models — Endpoint: https://api.minimax.io/anthropic
declare -A MINIMAX_MODELS
MINIMAX_MODELS[MiniMax-M2.7]="M2.7 (Opus) - recursive self-improvement, real-world engineering"
MINIMAX_MODELS[MiniMax-M2.7-highspeed]="M2.7 Highspeed (Sonnet) - same perf, faster inference"
MINIMAX_MODELS[MiniMax-M2.5]="M2.5 (Sonnet) - optimized for code generation"
MINIMAX_MODELS[MiniMax-M2.5-highspeed]="M2.5 Highspeed (Haiku) - fast code, low latency"
MINIMAX_MODELS[M2-her]="M2-her - roleplay & multi-turn dialogue"
```

### 3. Provider case block

Add in `configure_provider()` after the `kimi)` block:

```bash
minimax)
    select_models_menu "minimax"
    BASE_URL="https://api.minimax.io/anthropic"
    USE_CUSTOM_HEADERS="false"
    USE_WEB_AUTH="false"
    api_key=$(show_input "API Key" "Enter API key for ${PROVIDERS[$provider]}:")
    if [ -z "$api_key" ]; then
        print_error "API key cannot be empty"
        return 1
    fi
    ;;
```

### 4. README table

Add row to the "Supported providers & models" table:

```
| **MiniMax** | `https://api.minimax.io/anthropic` | `MiniMax-M2.7`, `MiniMax-M2.7-highspeed`, `MiniMax-M2.5`, `MiniMax-M2.5-highspeed`, `M2-her` |
```

## API Details

- **Endpoint:** `https://api.minimax.io/anthropic` (international)
- **Auth:** `ANTHROPIC_AUTH_TOKEN` env var (standard pattern, no custom headers)
- **Source:** https://platform.minimax.io/docs/guides/text-ai-coding-tools

## Non-goals

- China endpoint (`api.minimaxi.com`) — not included per user decision
- Generic "OpenAI-compatible" provider abstraction — out of scope
