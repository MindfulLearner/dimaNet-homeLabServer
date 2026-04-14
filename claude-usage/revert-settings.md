# Revert settings.json

Leggi questo file e applica il revert.

## Cosa fare

Sostituisci il contenuto di `~/.claude/settings.json` con questo:

```json
{
  "enabledPlugins": {
    "clangd-lsp@claude-plugins-official": true
  },
  "alwaysThinkingEnabled": true
}
```

## Cosa stai rimuovendo

| Chiave | Valore rimosso | Effetto del revert |
|---|---|---|
| `model` | `sonnet` | Claude Code torna a scegliere il modello da solo (potrebbe usare Opus) |
| `MAX_THINKING_TOKENS` | `10000` | Thinking torna fino a 32K token per risposta |
| `CLAUDE_AUTOCOMPACT_PCT_OVERRIDE` | `50` | Autocompact torna al 95% (default) |
| `CLAUDE_CODE_SUBAGENT_MODEL` | `haiku` | Subagenti tornano sul modello principale |

## Cosa rimane invariato

- `alwaysThinkingEnabled: true` - rimane, era gia' presente prima
- `clangd-lsp@claude-plugins-official` - rimane, era gia' presente prima
