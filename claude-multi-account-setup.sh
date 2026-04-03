#!/bin/bash

# claude-multi-account-setup.sh
#
# Manage multiple Claude Code accounts/API keys on one machine
# Supports: Anthropic, Zai (GLM), DeepSeek, Kimi, OpenRouter, plus custom
# Because switching configs manually is annoying :)

# No set -e - lets you cancel menus with ESC without everything dying

# Colors - makes things nicer
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# Where stuff lives
SECRETS_FILE="$HOME/.claude_secrets"
CONFIG_FILE="$HOME/.claude_multi_config"
CONFIG_BACKUP_DIR="$HOME/.claude_configs_backup"
CLAUDE_CONFIGS_BASE="$HOME/.claude_configs"

# Check if whiptail/dialog is available (for pretty menus)
DIALOG_CMD=""
if command -v whiptail &> /dev/null; then
    DIALOG_CMD="whiptail"
elif command -v dialog &> /dev/null; then
    DIALOG_CMD="dialog"
fi

# Supported providers
declare -A PROVIDERS
PROVIDERS[anthropic]="Anthropic (API Key)"
PROVIDERS[claude-webauth]="Anthropic (Web Auth)"
PROVIDERS[zai]="Z.ai (GLM)"
PROVIDERS[deepseek]="DeepSeek"
PROVIDERS[kimi]="Kimi (Moonshot AI)"
PROVIDERS[minimax]="MiniMax"
PROVIDERS[openrouter]="OpenRouter"
PROVIDERS[custom]="Custom Provider"

# Anthropic subscription plans
declare -A SUBSCRIPTION_PLANS
SUBSCRIPTION_PLANS[none]="Free (No subscription)"
SUBSCRIPTION_PLANS[claude]="Claude (Standard)"
SUBSCRIPTION_PLANS[claude-pro]="Claude Pro"
SUBSCRIPTION_PLANS[claude-max]="Claude Max"
SUBSCRIPTION_PLANS[enterprise]="Enterprise"

# Anthropic models
declare -A ANTHROPIC_MODELS
ANTHROPIC_MODELS[claude-sonnet-4-6]="Sonnet 4.6"
ANTHROPIC_MODELS[claude-opus-4-6]="Opus 4.6"
ANTHROPIC_MODELS[claude-haiku-4-5-20251001]="Haiku 4.5"

# Z.ai / Zhipu GLM models (2026)
# Endpoint: https://open.bigmodel.cn/api/anthropic
declare -A ZAI_MODELS
ZAI_MODELS[glm-5]="GLM-5 (Opus) - 745B params, 200K context"
ZAI_MODELS[glm-4.7]="GLM-4.7 (Sonnet) - Main one"
ZAI_MODELS[glm-4.7-flash]="GLM-4.7 Flash (Sonnet) - Free, lightweight"
ZAI_MODELS[glm-4.5-air]="GLM-4.5 Air (Haiku) - Quick stuff"
ZAI_MODELS[glm-4.6v]="GLM-4.6V (Multimodal) - Vision + tools"

# DeepSeek models (2026)
# Endpoint: https://api.deepseek.com/anthropic
# DeepSeek V4 coming soon (March 2026 maybe?)
declare -A DEEPSEEK_MODELS
DEEPSEEK_MODELS[deepseek-reasoner]="DeepSeek Reasoner (Opus)"
DEEPSEEK_MODELS[deepseek-chat]="DeepSeek Chat (Sonnet)"

# Kimi / Moonshot AI models (2026)
# Endpoint: https://api.moonshot.ai/anthropic
declare -A KIMI_MODELS
KIMI_MODELS[kimi-k2.5]="Kimi K2.5 (Opus) - 1T params, 256K context"
KIMI_MODELS[kimi-k2]="Kimi K2 (Sonnet) - Main one"
KIMI_MODELS[kimi-k2-turbo]="Kimi K2 Turbo (Sonnet) - Faster"
KIMI_MODELS[moonshot-v1-128k]="Moonshot v1 128K (Haiku)"
KIMI_MODELS[moonshot-v1-32k]="Moonshot v1 32K (Haiku)"
KIMI_MODELS[moonshot-v1-8k]="Moonshot v1 8K (Haiku)"

# MiniMax models (2026)
# Endpoint: https://api.minimax.io/anthropic
# Note: MiniMax-M2.7-highspeed requires a Pay-as-you-go API key (not Token Plan)
# M2.5/M2-her variants are not supported on the Anthropic-compatible endpoint
declare -A MINIMAX_MODELS
MINIMAX_MODELS[MiniMax-M2.7]="M2.7 - recommended, works with all API key types"
MINIMAX_MODELS[MiniMax-M2.7-highspeed]="M2.7 Highspeed - faster, requires Pay-as-you-go API key"

# OpenRouter models
declare -A OPENROUTER_MODELS
OPENROUTER_MODELS[anthropic/claude-sonnet-4-6]="Claude Sonnet 4.6"
OPENROUTER_MODELS[anthropic/claude-opus-4-6]="Claude Opus 4.6"
OPENROUTER_MODELS[anthropic/claude-haiku-4-5-20251001]="Claude Haiku 4.5"
OPENROUTER_MODELS[deepseek/deepseek-chat]="DeepSeek Chat"
OPENROUTER_MODELS[deepseek/deepseek-reasoner]="DeepSeek Reasoner"

declare -A CUSTOM_MODELS

# Helper functions

print_header() {
    clear
    echo -e "${CYAN}${BOLD}"
    echo "═══════════════════════════════════════════════════════════════"
    echo "  Claude Code Multi-Account Setup v2.0"
    echo "═══════════════════════════════════════════════════════════════"
    echo -e "${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

# Menu functions - wraps whiptail/dialog with fallback to basic text menus

show_menu() {
    local title="$1"
    local text="$2"
    local height=20
    local width=60
    local menu_height=10
    shift 2

    if [ -n "$DIALOG_CMD" ]; then
        local options=()
        local i=1
        while [ $# -gt 0 ]; do
            options+=("$i" "$1")
            shift
            ((i++))
        done
        local output
        output=$($DIALOG_CMD --title "$title" --menu "$text" $height $width $menu_height "${options[@]}" 3>&2 2>&1 1>&3) || true
        if [ -n "$output" ]; then
            echo "$output"
            return 0
        else
            echo ""
            return 1
        fi
    else
        echo ""
        echo -e "${CYAN}$title${NC}"
        echo "$text"
        echo "────────────────────────────────────"
        local i=1
        while [ $# -gt 0 ]; do
            echo "  $i) $1"
            shift
            ((i++))
        done
        echo ""
        read -p "Enter choice [1-$((i-1))] or press Enter to cancel: " choice
        if [ "$choice" -ge 1 ] && [ "$choice" -lt "$i" ] 2>/dev/null; then
            echo "$choice"
            return 0
        else
            echo ""
            return 1
        fi
    fi
}

show_input() {
    local title="$1"
    local text="$2"
    local default="$3"

    if [ -n "$DIALOG_CMD" ]; then
        local result
        if [ -n "$default" ]; then
            result=$($DIALOG_CMD --title "$title" --inputbox "$text" 10 60 "$default" 3>&2 2>&1 1>&3) || true
        else
            result=$($DIALOG_CMD --title "$title" --inputbox "$text" 10 60 3>&2 2>&1 1>&3) || true
        fi
        if [ -n "$result" ] || [ -n "$default" ]; then
            echo "${result:-$default}"
            return 0
        else
            return 1
        fi
    else
        echo ""
        echo -e "${CYAN}$title${NC}"
        if [ -n "$default" ]; then
            read -p "$text [$default]: " result
            echo "${result:-$default}"
        else
            read -p "$text: " result
            echo "$result"
        fi
        return 0
    fi
}

show_yesno() {
    local title="$1"
    local text="$2"

    if [ -n "$DIALOG_CMD" ]; then
        $DIALOG_CMD --title "$title" --yesno "$text" 10 60 3>&2 2>&1 1>&3
        local status=$?
        return $status
    else
        echo ""
        echo -e "${CYAN}$title${NC}"
        echo "$text"
        read -p "Continue? (y/n): " -n 1 -r
        echo
        [[ $REPLY =~ ^[Yy]$ ]]
        return $?
    fi
}

show_msgbox() {
    local title="$1"
    local text="$2"

    if [ -n "$DIALOG_CMD" ]; then
        $DIALOG_CMD --title "$title" --msgbox "$text" 15 60 3>&2 2>&1 1>&3 || true
    else
        echo ""
        echo -e "${CYAN}$title${NC}"
        echo "$text"
        echo ""
        read -p "Press Enter to continue..." dummy
    fi
}

# Detect which shell we're running in

detect_shell() {
    if [ -n "$ZSH_VERSION" ]; then
        echo "zsh"
    elif [ -n "$BASH_VERSION" ]; then
        echo "bash"
    else
        if ps -p $PPID -o comm= 2>/dev/null | grep -q zsh; then
            echo "zsh"
        elif ps -p $PPID -o comm= 2>/dev/null | grep -q bash; then
            echo "bash"
        else
            echo "unknown"
        fi
    fi
}

# Get the right config file for the shell

get_shell_config_file() {
    local shell_type=$1
    case $shell_type in
        zsh)
            echo "$HOME/.zshrc"
            ;;
        bash)
            echo "$HOME/.bashrc"
            ;;
        *)
            echo "$HOME/.profile"
            ;;
    esac
}

# Setup functions

setup_secrets_file() {
    print_info "Setting up secure secrets file..."

    if [ ! -f "$SECRETS_FILE" ]; then
        touch "$SECRETS_FILE"
        chmod 600 "$SECRETS_FILE"
        print_success "Created secrets file at $SECRETS_FILE"
    else
        print_info "Secrets file already exists at $SECRETS_FILE"
    fi
}

# Add an API key to the secrets file

add_api_key() {
    local provider=$1
    local account_name=$2
    local api_key=$3

    if grep -q "^export ${account_name}_API_KEY=" "$SECRETS_FILE" 2>/dev/null; then
        print_warning "API key for $account_name already exists. Updating..."
        sed -i "/^export ${account_name}_API_KEY=/d" "$SECRETS_FILE"
    fi

    echo "export ${account_name}_API_KEY=\"$api_key\"" >> "$SECRETS_FILE"
    print_success "Added API key for $account_name"
}

# Add the alias to shell config

add_shell_function() {
    local shell_type=$1
    local provider=$2
    local account_name=$3
    local alias_name=$4
    local base_url=$5
    local opus_model=$6
    local sonnet_model=$7
    local haiku_model=$8
    local use_custom_headers=$9
    local skip_permissions=${10}
    local use_web_auth=${11}
    local web_auth_dir=${12}
    local subscription=${13}

    local config_file=$(get_shell_config_file "$shell_type")
    local function_code=""

    function_code+="# === CLAUDE MULTI-ACCOUNT: $alias_name ===\n"
    # Use single quotes so API key variables expand at alias execution time, not at source time
    function_code+="alias $alias_name='"

    local env_vars=""

    # Web auth / config dir: use CLAUDE_CONFIG_DIR instead of API key
    if [ "$use_web_auth" = "true" ]; then
        env_vars="CLAUDE_CONFIG_DIR=\"$web_auth_dir\""
    elif [ "$provider" != "anthropic" ]; then
        # API key auth for other providers
        env_vars="ANTHROPIC_AUTH_TOKEN=\"\$${account_name}_API_KEY\""
    fi

    if [ -n "$base_url" ]; then
        env_vars="$env_vars ANTHROPIC_BASE_URL=\"$base_url\""
    fi

    if [ -n "$opus_model" ]; then
        env_vars="$env_vars ANTHROPIC_DEFAULT_OPUS_MODEL=\"$opus_model\""
    fi

    if [ -n "$sonnet_model" ]; then
        env_vars="$env_vars ANTHROPIC_DEFAULT_SONNET_MODEL=\"$sonnet_model\""
    fi

    if [ -n "$haiku_model" ]; then
        env_vars="$env_vars ANTHROPIC_DEFAULT_HAIKU_MODEL=\"$haiku_model\""
    fi

    if [ "$use_custom_headers" = "true" ]; then
        env_vars="$env_vars ANTHROPIC_CUSTOM_HEADERS=\"x-api-key: \$${account_name}_API_KEY\""
    fi

    if [ "$provider" != "anthropic" ] && [ "$use_web_auth" != "true" ]; then
        env_vars="$env_vars CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1"
    fi

    # Subscription handling - set as env var
    if [ -n "$subscription" ] && [ "$subscription" != "none" ] && [ "$subscription" != "" ]; then
        env_vars="$env_vars CLAUDE_SUBSCRIPTION_ID=\"$subscription\""
    fi

    if [ "$skip_alias_creation" != "true" ]; then
        if [ -n "$env_vars" ]; then
            function_code+="$env_vars "
        fi

        function_code+="claude"

        if [ "$skip_permissions" = "true" ]; then
            function_code+=" --dangerously-skip-permissions"
        fi

        function_code+=" \"\$@\"'\n"
    fi

    if grep -q "# === CLAUDE MULTI-ACCOUNT: $alias_name ===" "$config_file" 2>/dev/null; then
        if show_yesno "Warning" "Alias $alias_name already exists. Replace it?"; then
            sed -i "/# === CLAUDE MULTI-ACCOUNT: $alias_name ===/,/^$/d" "$config_file" 2>/dev/null || true
        else
            print_info "Skipping $alias_name"
            return 1
        fi
    fi

    echo -e "$function_code" >> "$config_file"
    print_success "Added alias '$alias_name' to $config_file"
    return 0
}

# Provider selection

# Select subscription plan for Anthropic

select_subscription_menu() {
    local options=()
    for plan_id in "${!SUBSCRIPTION_PLANS[@]}"; do
        options+=("${SUBSCRIPTION_PLANS[$plan_id]}")
    done

    local choice=$(show_menu "Select Subscription Plan" "Choose your Anthropic subscription plan:" "${options[@]}")

    if [ -z "$choice" ]; then
        echo ""
        return
    fi

    local i=1
    for plan_id in "${!SUBSCRIPTION_PLANS[@]}"; do
        if [ "$i" -eq "$choice" ]; then
            echo "$plan_id"
            return
        fi
        ((i++))
    done
    echo ""
}

# Sync MCP servers and plugins from the default ~/.claude config to a custom CLAUDE_CONFIG_DIR

sync_mcp_from_default_config() {
    local target_dir=$1
    local default_config="$HOME/.claude"

    if ! command -v python3 &>/dev/null; then
        print_warning "python3 not found - skipping MCP sync"
        return 0
    fi

    if [ ! -f "$default_config/settings.json" ]; then
        return 0
    fi

    local has_enabled_plugins=false
    local has_extra_marketplaces=false

    # Check for enabledPlugins in default settings.json
    local plugin_count
    plugin_count=$(python3 -c "
import json
try:
    d = json.load(open('$default_config/settings.json'))
    print(len(d.get('enabledPlugins', {})))
except:
    print(0)
" 2>/dev/null)
    [ "${plugin_count:-0}" -gt 0 ] && has_enabled_plugins=true

    # Check for extraKnownMarketplaces in default settings.json
    local marketplace_count
    marketplace_count=$(python3 -c "
import json
try:
    d = json.load(open('$default_config/settings.json'))
    print(len(d.get('extraKnownMarketplaces', {})))
except:
    print(0)
" 2>/dev/null)
    [ "${marketplace_count:-0}" -gt 0 ] && has_extra_marketplaces=true

    if ! $has_enabled_plugins && ! $has_extra_marketplaces; then
        return 0
    fi

    local sync_msg="Found plugin configurations in your default Claude config (~/.claude):\n"
    $has_enabled_plugins && sync_msg+="  • Enabled plugins (e.g. Playwright, z.ai tools)\n"
    $has_extra_marketplaces && sync_msg+="  • Extra plugin marketplaces\n"
    sync_msg+="\nSync these to the new account config?"

    if ! show_yesno "Sync Plugins" "$sync_msg"; then
        return 0
    fi

    mkdir -p "$target_dir"

    # Merge enabledPlugins and extraKnownMarketplaces into target settings.json
    python3 - <<PYEOF
import json

src = json.load(open('$default_config/settings.json'))
target_file = '$target_dir/settings.json'

try:
    target = json.load(open(target_file))
except Exception:
    target = {}

if src.get('enabledPlugins'):
    target.setdefault('enabledPlugins', {})
    target['enabledPlugins'].update(src['enabledPlugins'])

if src.get('extraKnownMarketplaces'):
    target.setdefault('extraKnownMarketplaces', {})
    target['extraKnownMarketplaces'].update(src['extraKnownMarketplaces'])

with open(target_file, 'w') as f:
    json.dump(target, f, indent=2)
PYEOF
    print_success "Synced plugin config into $target_dir/settings.json"

    # Copy plugins cache directory if it exists (speeds up first launch)
    if [ -d "$default_config/plugins" ]; then
        cp -r "$default_config/plugins" "$target_dir/"
        print_success "Copied plugins cache to $target_dir/plugins/"
    fi
}

# Setup web authentication for Claude

setup_web_auth() {
    local alias_name=$1
    local config_dir=$2

    # Create config directory
    mkdir -p "$config_dir"

    clear
    echo -e "${CYAN}${BOLD}"
    echo "═══════════════════════════════════════════════════════════════"
    echo "  Setting up Web Authentication"
    echo "═══════════════════════════════════════════════════════════════"
    echo -e "${NC}"
    echo ""
    echo "Config directory: $config_dir"
    echo ""
    echo "You'll now be prompted to authenticate via your browser."
    echo "This is the same process as when you first run claude."
    echo ""

    read -p "Press Enter to continue to authentication..." dummy

    # Run claude with the custom config directory to trigger web auth
    echo ""
    echo "Starting Claude authentication..."
    echo ""

    CLAUDE_CONFIG_DIR="$config_dir" claude

    echo ""
    if [ $? -eq 0 ]; then
        print_success "Web authentication completed!"
        print_info "Credentials saved to: $config_dir"
    else
        print_error "Authentication failed or was cancelled"
        print_info "You can retry by running: CLAUDE_CONFIG_DIR=$config_dir claude"
        read -p "Press Enter to continue anyway..." dummy
    fi
}

select_provider_menu() {
    local options=()
    for key in "${!PROVIDERS[@]}"; do
        options+=("${PROVIDERS[$key]}")
    done

    local choice=$(show_menu "Select Provider" "Choose your API provider:" "${options[@]}")

    if [ -z "$choice" ]; then
        return 1
    fi

    local i=1
    for key in "${!PROVIDERS[@]}"; do
        if [ "$i" -eq "$choice" ]; then
            echo "$key"
            return 0
        fi
        ((i++))
    done
    return 1
}

# Model selection menu

select_models_menu() {
    local provider=$1
    local models_var="${provider^^}_MODELS"

    eval "declare -n models=\$models_var"

    if [ ${#models[@]} -eq 0 ]; then
        print_warning "No predefined models for $provider"
        return
    fi

    local opus_model=""
    local sonnet_model=""
    local haiku_model=""

    local options=()
    local model_keys=()
    for model_id in "${!models[@]}"; do
        options+=("${models[$model_id]}")
        model_keys+=("$model_id")
    done
    options+=("Custom model entry")
    options+=("Skip")

    local opus_choice=$(show_menu "Select Opus Model" "Choose the Opus model for ${PROVIDERS[$provider]}:" "${options[@]}")
    if [ -n "$opus_choice" ]; then
        if [ "$opus_choice" -le ${#models[@]} ] 2>/dev/null; then
            opus_model="${model_keys[$((opus_choice-1))]}"
        elif [ "$opus_choice" -eq $(( ${#models[@]} + 1 )) ] 2>/dev/null; then
            opus_model=$(show_input "Custom Opus Model" "Enter custom Opus model ID:" "") || opus_model=""
        fi
    fi

    local sonnet_choice=$(show_menu "Select Sonnet Model" "Choose the Sonnet model for ${PROVIDERS[$provider]}:" "${options[@]}")
    if [ -n "$sonnet_choice" ]; then
        if [ "$sonnet_choice" -le ${#models[@]} ] 2>/dev/null; then
            sonnet_model="${model_keys[$((sonnet_choice-1))]}"
        elif [ "$sonnet_choice" -eq $(( ${#models[@]} + 1 )) ] 2>/dev/null; then
            sonnet_model=$(show_input "Custom Sonnet Model" "Enter custom Sonnet model ID:" "") || sonnet_model=""
        fi
    fi

    local haiku_choice=$(show_menu "Select Haiku Model" "Choose the Haiku model for ${PROVIDERS[$provider]}:" "${options[@]}")
    if [ -n "$haiku_choice" ]; then
        if [ "$haiku_choice" -le ${#models[@]} ] 2>/dev/null; then
            haiku_model="${model_keys[$((haiku_choice-1))]}"
        elif [ "$haiku_choice" -eq $(( ${#models[@]} + 1 )) ] 2>/dev/null; then
            haiku_model=$(show_input "Custom Haiku Model" "Enter custom Haiku model ID:" "") || haiku_model=""
        fi
    fi

    SELECTED_OPUS_MODEL="$opus_model"
    SELECTED_SONNET_MODEL="$sonnet_model"
    SELECTED_HAIKU_MODEL="$haiku_model"
}

# Configure a provider

configure_provider() {
    local provider=$1
    local shell_type=$2

    clear
    echo -e "${CYAN}${BOLD}Configuring ${PROVIDERS[$provider]}${NC}"
    echo "────────────────────────────────────"

    local default_alias="claude-$provider"
    local alias_name=$(show_input "Alias Name" \
        "Enter a custom alias name for this configuration.\nThis is the command you'll type to start Claude Code.\nExamples: claude-zai, glm, my-ai, work-ai" \
        "$default_alias")

    if [ -z "$alias_name" ]; then
        print_error "Alias name cannot be empty"
        return 1
    fi

    local account_name="${alias_name^^}"
    account_name=${account_name//-/_}

    # Variable for API key (set inside case statements for providers that need it)
    local api_key=""

    SELECTED_OPUS_MODEL=""
    SELECTED_SONNET_MODEL=""
    SELECTED_HAIKU_MODEL=""
    BASE_URL=""
    USE_CUSTOM_HEADERS="false"
    SKIP_PERMISSIONS="false"
    USE_WEB_AUTH="false"
    WEB_AUTH_DIR=""
    SELECTED_SUBSCRIPTION=""

    case $provider in
        anthropic)
            select_models_menu "anthropic"
            BASE_URL=""
            USE_CUSTOM_HEADERS="false"
            USE_WEB_AUTH="false"
            # Select subscription plan
            SELECTED_SUBSCRIPTION=$(select_subscription_menu)
            # Ask for API key
            api_key=$(show_input "API Key" "Enter API key for ${PROVIDERS[$provider]}:")
            if [ -z "$api_key" ]; then
                print_error "API key cannot be empty"
                return 1
            fi
            ;;
        claude-webauth)
            select_models_menu "anthropic"
            BASE_URL=""
            USE_CUSTOM_HEADERS="false"
            USE_WEB_AUTH="true"
            # Create unique config directory for this account
            WEB_AUTH_DIR="$CLAUDE_CONFIGS_BASE/${alias_name}"
            # Select subscription plan
            SELECTED_SUBSCRIPTION=$(select_subscription_menu)
            # No API key needed - web auth handles it!
            ;;
        zai)
            select_models_menu "zai"
            BASE_URL="https://open.bigmodel.cn/api/anthropic"
            USE_CUSTOM_HEADERS="false"
            USE_WEB_AUTH="false"
            # Ask for API key
            api_key=$(show_input "API Key" "Enter API key for ${PROVIDERS[$provider]}:")
            if [ -z "$api_key" ]; then
                print_error "API key cannot be empty"
                return 1
            fi
            ;;
        deepseek)
            select_models_menu "deepseek"
            BASE_URL="https://api.deepseek.com/anthropic"
            USE_CUSTOM_HEADERS="false"
            USE_WEB_AUTH="false"
            # Ask for API key
            api_key=$(show_input "API Key" "Enter API key for ${PROVIDERS[$provider]}:")
            if [ -z "$api_key" ]; then
                print_error "API key cannot be empty"
                return 1
            fi
            ;;
        kimi)
            select_models_menu "kimi"
            BASE_URL="https://api.moonshot.ai/anthropic"
            USE_CUSTOM_HEADERS="false"
            USE_WEB_AUTH="false"
            # Ask for API key
            api_key=$(show_input "API Key" "Enter API key for ${PROVIDERS[$provider]}:")
            if [ -z "$api_key" ]; then
                print_error "API key cannot be empty"
                return 1
            fi
            ;;
        minimax)
            # MiniMax uses settings.json + CLAUDE_CONFIG_DIR (recommended by MiniMax docs)
            # All model/URL config goes in settings.json; alias only sets CLAUDE_CONFIG_DIR
            BASE_URL=""
            USE_CUSTOM_HEADERS="false"
            USE_WEB_AUTH="true"
            WEB_AUTH_DIR="$CLAUDE_CONFIGS_BASE/${alias_name}"
            api_key=$(show_input "API Key" "Enter API key for ${PROVIDERS[$provider]}:")
            if [ -z "$api_key" ]; then
                print_error "API key cannot be empty"
                return 1
            fi
            ;;
        openrouter)
            select_models_menu "openrouter"
            BASE_URL=$(show_input "OpenRouter URL" "Enter OpenRouter base URL:" "http://localhost:8787")
            USE_CUSTOM_HEADERS="true"
            USE_WEB_AUTH="false"
            # Ask for API key
            api_key=$(show_input "API Key" "Enter API key for ${PROVIDERS[$provider]}:")
            if [ -z "$api_key" ]; then
                print_error "API key cannot be empty"
                return 1
            fi
            ;;
        custom)
            BASE_URL=$(show_input "Custom Base URL" "Enter custom base URL:")
            select_models_menu "custom" || true
            if show_yesno "Custom Headers" "Use custom headers for API key?"; then
                USE_CUSTOM_HEADERS="true"
            else
                USE_CUSTOM_HEADERS="false"
            fi
            USE_WEB_AUTH="false"
            # Ask for API key
            api_key=$(show_input "API Key" "Enter API key for ${PROVIDERS[$provider]}:")
            if [ -z "$api_key" ]; then
                print_error "API key cannot be empty"
                return 1
            fi
            ;;
    esac

    if show_yesno "⚠️  Skip Permissions?" \
        "⚠️  WARNING: Not Recommended!\n\nAdd --dangerously-skip-permissions flag?\n\nThis bypasses permission prompts but may reduce security.\nOnly use this if you understand the risks!"; then
        SKIP_PERMISSIONS="true"
        print_warning "Skip permissions flag enabled"
    else
        SKIP_PERMISSIONS="false"
    fi

    # For minimax: write settings.json into config dir, use CLAUDE_CONFIG_DIR alias
    if [ "$provider" = "minimax" ]; then
        mkdir -p "$WEB_AUTH_DIR"
        local minimax_model="MiniMax-M2.7"
        python3 -c "
import json
config = {
    'env': {
        'ANTHROPIC_BASE_URL': 'https://api.minimax.io/anthropic',
        'ANTHROPIC_AUTH_TOKEN': '$api_key',
        'API_TIMEOUT_MS': '3000000',
        'CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC': '1',
        'ANTHROPIC_MODEL': '$minimax_model',
        'ANTHROPIC_SMALL_FAST_MODEL': '$minimax_model',
        'ANTHROPIC_DEFAULT_SONNET_MODEL': '$minimax_model',
        'ANTHROPIC_DEFAULT_OPUS_MODEL': '$minimax_model',
        'ANTHROPIC_DEFAULT_HAIKU_MODEL': '$minimax_model'
    }
}
with open('$WEB_AUTH_DIR/settings.json', 'w') as f:
    json.dump(config, f, indent=2)
" || { print_error "Failed to write settings.json (python3 required)"; return 1; }
        chmod 600 "$WEB_AUTH_DIR/settings.json"
        sync_mcp_from_default_config "$WEB_AUTH_DIR"
        print_success "Created MiniMax config at $WEB_AUTH_DIR/settings.json"
    # For web auth, don't save API key - trigger web auth instead
    elif [ "$USE_WEB_AUTH" = "true" ]; then
        setup_web_auth "$alias_name" "$WEB_AUTH_DIR"
        sync_mcp_from_default_config "$WEB_AUTH_DIR"
    else
        # For API key auth, save the key (only if api_key was set)
        if [ -n "$api_key" ]; then
            add_api_key "$provider" "$account_name" "$api_key"
        fi
    fi

    add_shell_function "$shell_type" "$provider" "$account_name" "$alias_name" \
        "$BASE_URL" "$SELECTED_OPUS_MODEL" "$SELECTED_SONNET_MODEL" "$SELECTED_HAIKU_MODEL" \
        "$USE_CUSTOM_HEADERS" "$SKIP_PERMISSIONS" "$USE_WEB_AUTH" "$WEB_AUTH_DIR" "$SELECTED_SUBSCRIPTION"

    if [ $? -ne 0 ]; then
        return 1
    fi

    configuration_success_menu "$alias_name" "$provider" "$shell_type" "$SKIP_PERMISSIONS" "$SELECTED_SUBSCRIPTION"
}

# Success menu after configuration

configuration_success_menu() {
    local alias_name=$1
    local provider=$2
    local shell_type=$3
    local skip_permissions=$4
    local subscription=$5
    local config_file=$(get_shell_config_file "$shell_type")

    while true; do
        clear
        echo -e "${GREEN}${BOLD}"
        echo "═══════════════════════════════════════════════════════════════"
        echo "  ✓ Configuration Created Successfully!"
        echo "═══════════════════════════════════════════════════════════════"
        echo -e "${NC}"

        echo ""
        echo -e "${BOLD}Configuration Details:${NC}"
        echo "────────────────────────────────────"
        echo "  Alias:        ${CYAN}$alias_name${NC}"
        echo "  Provider:     ${PROVIDERS[$provider]}"
        echo "  Config File:  $config_file"

        # Show different info based on auth type
        if [ "$provider" = "claude-webauth" ]; then
            echo "  Auth Type:    Web Auth (OAuth)"
            echo "  Config Dir:   $CLAUDE_CONFIGS_BASE/${alias_name}"
        else
            echo "  Secrets:      $SECRETS_FILE"
        fi

        # Show subscription info if applicable
        if [ -n "$subscription" ] && [ "$subscription" != "" ]; then
            if [ "$subscription" = "prompt" ]; then
                echo -e "  Subscription: ${YELLOW}Ask on every launch${NC}"
            elif [ "$subscription" != "none" ]; then
                local sub_name="${SUBSCRIPTION_PLANS[$subscription]}"
                echo -e "  Subscription: ${CYAN}${sub_name}${NC}"
            fi
        fi

        if [ "$skip_permissions" = "true" ]; then
            echo -e "  Flags:        ${YELLOW}--dangerously-skip-permissions${NC}"
        fi

        echo ""
        echo -e "${BOLD}Usage:${NC}"
        echo "────────────────────────────────────"
        echo -e "  ${GREEN}$alias_name${NC}           # Start Claude Code"

        if [ "$subscription" = "prompt" ]; then
            echo -e "  ${YELLOW}(Will ask for subscription plan)${NC}"
        fi

        if [ "$skip_permissions" = "true" ]; then
            echo -e "  ${YELLOW}(Permission checks disabled)${NC}"
        fi

        echo ""
        echo -e "${BOLD}Next Steps:${NC}"
        echo "────────────────────────────────────"
        echo "  1) Reload shell configuration"
        echo "  2) Return to main menu"
        echo "  3) Exit script"

        local choice=$(show_menu "What's next?" "Configuration complete!" \
            "🔄 Reload shell configuration now" \
            "← Return to main menu" \
            "🚪 Exit script")

        case $choice in
            1)
                source "$config_file" 2>/dev/null
                if [ $? -eq 0 ]; then
                    show_msgbox "Reloaded" "✓ Shell configuration reloaded!\n\nYou can now use: $alias_name"
                else
                    show_msgbox "Reload Notice" "Could not auto-reload.\n\nPlease run manually:\n  source $config_file"
                fi
                ;;
            2)
                return 0
                ;;
            3|0)
                clear
                print_success "Configuration saved!"
                echo ""
                print_info "To use your new alias, reload your shell:"
                echo "  source $config_file"
                echo "  Or restart your terminal"
                echo ""
                exit 0
                ;;
        esac
    done
}

# List configurations

list_configurations() {
    local shell_type=$1
    local config_file=$(get_shell_config_file "$shell_type")

    if grep -q "# === CLAUDE MULTI-ACCOUNT:" "$config_file" 2>/dev/null; then
        local configs=""
        while IFS= read -r line; do
            local alias=$(echo "$line" | sed 's/# === CLAUDE MULTI-ACCOUNT: //' | sed 's/ ===//')
            configs+="  • $alias\n"
        done < <(grep "# === CLAUDE MULTI-ACCOUNT:" "$config_file")
        show_msgbox "Current Configurations" "Configurations in $config_file:\n\n$configs"
    else
        show_msgbox "No Configurations" "No configurations found in $config_file"
    fi
}

# Remove a configuration

remove_configuration() {
    local shell_type=$1
    local config_file=$(get_shell_config_file "$shell_type")

    local configs=()
    if grep -q "# === CLAUDE MULTI-ACCOUNT:" "$config_file" 2>/dev/null; then
        while IFS= read -r line; do
            local alias=$(echo "$line" | sed 's/# === CLAUDE MULTI-ACCOUNT: //' | sed 's/ ===//')
            configs+=("$alias")
        done < <(grep "# === CLAUDE MULTI-ACCOUNT:" "$config_file")
    fi

    if [ ${#configs[@]} -eq 0 ]; then
        show_msgbox "No Configurations" "No configurations found in $config_file"
        return
    fi

    local menu_options=("${configs[@]}")
    menu_options+=("← Back to menu")

    local choice=$(show_menu "Remove Configuration" "Select a configuration to remove:" "${menu_options[@]}")

    if [ -z "$choice" ] || [ "$choice" -gt ${#configs[@]} ]; then
        return
    fi

    local alias_name="${configs[$((choice-1))]}"

    if ! show_yesno "Confirm Removal" "Remove configuration for '${alias_name}'?\n\nThis will remove the alias from your shell config.\n\nYou'll also be asked about removing the API key separately."; then
        return
    fi

    if grep -q "# === CLAUDE MULTI-ACCOUNT: $alias_name ===" "$config_file"; then
        local backup_file="${config_file}.backup.$(date +%Y%m%d_%H%M%S)"
        cp "$config_file" "$backup_file"

        sed -i "/# === CLAUDE MULTI-ACCOUNT: $alias_name ===/,/^$/d" "$config_file" 2>/dev/null || true
        sed -i "/# === CLAUDE MULTI-ACCOUNT: $alias_name ===/,+1d" "$config_file" 2>/dev/null || true

        show_msgbox "Removal Complete" "✓ Removed '$alias_name' from $config_file\n\nBackup: $backup_file"
    else
        show_msgbox "Not Found" "Configuration for '$alias_name' not found"
        return
    fi

    local account_name="${alias_name^^}"
    account_name=${account_name//-/_}

    if grep -q "^export ${account_name}_API_KEY=" "$SECRETS_FILE" 2>/dev/null; then
        if show_yesno "Remove API Key" "Also remove the API key for '${alias_name}' from $SECRETS_FILE?\n\n⚠️  This will permanently delete the API key from the secrets file."; then
            sed -i "/^export ${account_name}_API_KEY=/d" "$SECRETS_FILE"
            show_msgbox "API Key Removed" "✓ Removed API key for $account_name"
        else
            show_msgbox "API Key Kept" "API key for $account_name kept in $SECRETS_FILE"
        fi
    fi
}

# Clean up everything

cleanup_all() {
    local shell_type=$1
    local config_file=$(get_shell_config_file "$shell_type")

    if ! show_yesno "Confirm Cleanup" "⚠️  This will remove ALL Claude multi-account configurations!\n\nAre you sure?"; then
        return
    fi

    mkdir -p "$CONFIG_BACKUP_DIR"
    local timestamp=$(date +%Y%m%d_%H%M%S)

    if [ -f "$config_file" ]; then
        cp "$config_file" "$CONFIG_BACKUP_DIR/shell_config.$timestamp"
    fi

    if [ -f "$SECRETS_FILE" ]; then
        cp "$SECRETS_FILE" "$CONFIG_BACKUP_DIR/secrets.$timestamp"
    fi

    if grep -q "# === CLAUDE MULTI-ACCOUNT:" "$config_file" 2>/dev/null; then
        grep -v "# === CLAUDE MULTI-ACCOUNT:" "$config_file" | \
            grep -v "^ANTHROPIC_" | \
            grep -v "^alias claude-" | \
            grep -v "^CLAUDE_" > "${config_file}.tmp"
        mv "${config_file}.tmp" "$config_file"
    fi

    if [ -f "$SECRETS_FILE" ]; then
        rm "$SECRETS_FILE"
    fi

    show_msgbox "Cleanup Complete" "✓ All configurations removed\n\nBackups saved to:\n$CONFIG_BACKUP_DIR\n\nBackup timestamp: $timestamp"
}

# Show where files are

show_file_locations() {
    local config_file=$(get_shell_config_file "$SHELL_TYPE")

    show_msgbox "File Locations" \
        "Shell Type: $SHELL_TYPE\n\nSecrets file: $SECRETS_FILE\nConfig file: $config_file\n\nTo view secrets: cat $SECRETS_FILE\nTo edit secrets: nano $SECRETS_FILE\n\nTo change shell: Settings → Change shell type"
}

# Reload the shell config

reload_config() {
    local config_file=$(get_shell_config_file "$SHELL_TYPE")

    source "$config_file" 2>/dev/null || true

    show_msgbox "Reload Configuration" \
        "Shell: $SHELL_TYPE\nConfig: $config_file\n\n✓ Configuration reloaded!\n\nIf aliases don't work, restart your terminal or run:\n  source $config_file"
}

# Show usage info

show_usage_info() {
    show_msgbox "Usage Instructions" \
        "After setup, use your aliases to start Claude Code:\n\n  claude-zai          # Use Z.ai (GLM)\n  claude-deepseek     # Use DeepSeek\n  my-ai              # Your custom alias\n\nPass arguments as usual:\n  claude-zai -m \"glm-5\"\n  claude-zai --help\n\nOpen multiple terminals with different aliases!"
}

# Change shell type

change_shell_type() {
    local current_config=$(get_shell_config_file "$SHELL_TYPE")

    local choice=$(show_menu "Select Shell" "Current: $SHELL_TYPE → $current_config" \
        "Bash (~/.bashrc)" \
        "Zsh (~/.zshrc)" \
        "← Cancel")

    case $choice in
        1)
            SHELL_TYPE="bash"
            show_msgbox "Shell Changed" "✓ Shell type set to: bash\n\nConfig file: ~/.bashrc\n\nNew configurations will be added to ~/.bashrc"
            ;;
        2)
            SHELL_TYPE="zsh"
            show_msgbox "Shell Changed" "✓ Shell type set to: zsh\n\nConfig file: ~/.zshrc\n\nNew configurations will be added to ~/.zshrc"
            ;;
        3)
            return
            ;;
    esac
}

# Configuration management menu

configurations_menu() {
    while true; do
        clear
        local choice=$(show_menu "Configuration Management" "Manage your configurations" \
            "List current configurations" \
            "Remove specific configuration" \
            "Remove all configurations (cleanup)" \
            "← Return to Main Menu" \
            "Exit Script")

        case $choice in
            1)
                list_configurations "$SHELL_TYPE"
                ;;
            2)
                clear
                remove_configuration "$SHELL_TYPE"
                ;;
            3)
                clear
                cleanup_all "$SHELL_TYPE"
                ;;
            4)
                return 0
                ;;
            5|0)
                clear
                print_success "Goodbye!"
                echo ""
                print_info "Don't forget to reload your shell configuration:"
                echo "  source $(get_shell_config_file "$SHELL_TYPE")"
                echo ""
                exit 0
                ;;
        esac
    done
}

# Settings menu

settings_menu() {
    while true; do
        local config_file=$(get_shell_config_file "$SHELL_TYPE")
        local choice=$(show_menu "Settings & Information" "Current shell: $SHELL_TYPE | Config: $config_file" \
            "🐚 Change shell type (bash/zsh)" \
            "View secrets file location" \
            "Reload shell configuration" \
            "View usage instructions" \
            "← Return to Main Menu" \
            "Exit Script")

        case $choice in
            1)
                change_shell_type
                ;;
            2)
                show_file_locations
                ;;
            3)
                reload_config
                ;;
            4)
                show_usage_info
                ;;
            5)
                return 0
                ;;
            6|0)
                clear
                print_success "Goodbye!"
                echo ""
                print_info "Don't forget to reload your shell configuration:"
                echo "  source $(get_shell_config_file "$SHELL_TYPE")"
                echo ""
                exit 0
                ;;
        esac
    done
}

# Main menu

main_menu() {
    while true; do
        clear
        local choice=$(show_menu "Main Menu" "Claude Code Multi-Account Setup v2.0" \
            "➕ Add new account/provider configuration" \
            "⚙️  Configuration Management" \
            "ℹ️  Settings & Information" \
            "🚪 Exit")

        case $choice in
            1)
                local provider=$(select_provider_menu)
                if [ $? -eq 0 ] && [ -n "$provider" ]; then
                    configure_provider "$provider" "$SHELL_TYPE"
                fi
                ;;
            2)
                configurations_menu
                ;;
            3)
                settings_menu
                ;;
            4|0)
                clear
                print_success "Setup complete!"
                echo ""
                print_info "Don't forget to reload your shell configuration:"
                echo "  source $(get_shell_config_file "$SHELL_TYPE")"
                echo ""
                exit 0
                ;;
        esac
    done
}

# Main script entry point

main() {
    print_header

    SHELL_TYPE=$(detect_shell)
    print_info "Detected shell: $SHELL_TYPE"

    if [ "$SHELL_TYPE" = "unknown" ]; then
        SHELL_TYPE=$(show_input "Shell Type" "Could not detect shell. Enter bash or zsh:" "bash")
        SHELL_TYPE=${SHELL_TYPE,,}
    fi

    local config_file=$(get_shell_config_file "$SHELL_TYPE")
    print_info "Config file: $config_file"

    if [ -n "$DIALOG_CMD" ]; then
        print_success "Using $DIALOG_CMD for interactive menus"
    else
        print_warning "dialog/whiptail not found - using basic menus"
        print_info "Install whiptail for better experience: sudo apt install whiptail"
    fi

    setup_secrets_file

    # Go straight to main menu
    main_menu
}

main
