# switchpilot

Switch GitHub Copilot CLI models to your local LLM setup with one command.

## Prerequisites

- Windows 10/11 with PowerShell 5.1 or PowerShell 7+
- [GitHub Copilot CLI](https://docs.github.com/en/copilot/github-copilot-in-the-cli/using-github-copilot-in-the-cli) installed
- A running local LLM server (Ollama, LM Studio, llama.cpp, etc.)

Your execution policy must allow scripts to run. If you see an "execution policy" error, run:

```
Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
```

## Quick Install

1. Download or clone this folder
2. Open PowerShell in the folder and run:

```
.\install.ps1
```

3. Restart your terminal or reload your profile:

```
. $PROFILE
```

## Configure

Edit the model registry at `%USERPROFILE%\.copilot\model_registry.json`. The installer copies an example there automatically. Replace the values with your setup:

```json
{
  "qwen-coder-3b": {
    "model": "qwen2.5-coder:3b",
    "providerType": "openai",
    "providerUrl": "http://localhost:11434/v1",
    "api_key": "ollama",
    "context": 32768,
    "output": 8192,
    "offline": true,
    "compactionThreshold": 0.9
  }
}
```

### Registry Fields

| Field                | Description                                                    |
|----------------------|----------------------------------------------------------------|
| `model`              | Model name your provider expects                               |
| `providerType`       | `openai`, `anthropic`, `azure`, `google`, `xai`                |
| `providerUrl`        | Base URL of your local API (must include `/v1`)                |
| `api_key`            | API key (for local servers, use any placeholder)               |
| `context`            | Max prompt tokens                                              |
| `output`             | Max output tokens                                              |
| `offline`            | `true` for local models, `false` for cloud                     |
| `compactionThreshold`| Auto-compaction threshold value between 0 and 1 (0.6 for 60%)  |

You can add multiple models to the registry — one entry per model.

## Usage

```
switchpilot qwen-coder-3b          # Switch to a model (persists across sessions)
switchpilot -List                  # Show all available models
switchpilot -Remove                # Clear all COPILOT_* environment variables
switchpilot qwen-coder-3b -Scope Process  # Temporary, this session only

# Shorter shortcuts also work:
switchpilot list
switchpilot remove
```

## How It Works

`switchpilot` is an alias for `Set-CopilotModel.ps1`. It reads your model registry and sets these environment variables:

| Variable                                  | Source                                                        |
|-------------------------------------------|---------------------------------------------------------------|
| `COPILOT_MODEL`                           | `model`                                                       |
| `COPILOT_PROVIDER_TYPE`                   | `providerType`                                                |
| `COPILOT_PROVIDER_BASE_URL`               | `providerUrl`                                                 |
| `COPILOT_PROVIDER_API_KEY`                | `api_key`                                                     |
| `COPILOT_PROVIDER_MAX_PROMPT_TOKENS`      | `context`                                                     |
| `COPILOT_PROVIDER_MAX_OUTPUT_TOKENS`      | `output`                                                      |
| `COPILOT_OFFLINE`                         | `offline`                                                     |
| `COPILOT_BACKGROUND_COMPACTION_THRESHOLD` | `compactionThreshold` or `compaction` (backward compatible)   |

Variables are set at the **User** scope by default, so they persist across terminal sessions until you switch or remove them.

## Troubleshooting

**`switchpilot` is not recognized**

Reload your profile: `. $PROFILE`, or restart PowerShell. If that doesn't work, check that the alias was added to your profile file.

**Model registry not found**

Make sure `%USERPROFILE%\.copilot\model_registry.json` exists. The installer creates it from the example — if you deleted it, copy `model_registry.json.example` there again.

**Execution policy error**

Run `Set-ExecutionPolicy -Scope CurrentUser RemoteSigned` in an elevated PowerShell window.

**Copilot still using cloud models**

Run `switchpilot -List` to verify env vars. You may need to restart VS Code or your terminal for the GitHub Copilot extension to pick up the change.

## Uninstall

Run from the switchpilot folder:

```
.\uninstall.ps1
```

This removes the script, cleans up your profile aliases, and optionally deletes the registry.
