# settings.json

## Configurazione attuale

File: `~/.claude/settings.json`
Data applicazione: 2026-04-14

```json
{
  "enabledPlugins": {
    "clangd-lsp@claude-plugins-official": true
  },
  "alwaysThinkingEnabled": true,
  "model": "sonnet",
  "env": {
    "MAX_THINKING_TOKENS": "10000",
    "CLAUDE_AUTOCOMPACT_PCT_OVERRIDE": "50",
    "CLAUDE_CODE_SUBAGENT_MODEL": "haiku"
  }
}
```

## Cosa fa ogni chiave

| Chiave | Valore | Effetto |
|---|---|---|
| `model` | `sonnet` | Forza Sonnet come default. Per Opus: `/model opus` o `--model claude-opus-4-6` |
| `MAX_THINKING_TOKENS` | `10000` | Limita il thinking interno da 32K a 10K (~70% risparmio) |
| `CLAUDE_AUTOCOMPACT_PCT_OVERRIDE` | `50` | Compatta il contesto al 50% invece del 95% — sessioni piu' stabili |
| `CLAUDE_CODE_SUBAGENT_MODEL` | `haiku` | Subagenti (Explore, Plan, general-purpose) usano Haiku (~80% piu' economico) |
| `alwaysThinkingEnabled` | `true` | Thinking attivo su ogni risposta (preesistente) |
| `clangd-lsp` | `true` | Plugin LSP per C/C++ (preesistente) |

Risparmio complessivo stimato: 60-80% rispetto ai default.

## Revert

Sostituisci `~/.claude/settings.json` con:

```json
{
  "enabledPlugins": {
    "clangd-lsp@claude-plugins-official": true
  },
  "alwaysThinkingEnabled": true
}
```

Cosa torna ai default:

| Chiave rimossa | Effetto |
|---|---|
| `model` | Claude Code sceglie il modello da solo (potrebbe usare Opus) |
| `MAX_THINKING_TOKENS` | Thinking torna a 32K per risposta |
| `CLAUDE_AUTOCOMPACT_PCT_OVERRIDE` | Autocompact torna al 95% |
| `CLAUDE_CODE_SUBAGENT_MODEL` | Subagenti tornano sul modello principale |
