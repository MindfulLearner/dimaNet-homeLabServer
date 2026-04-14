# Settings applicati - ~/.claude/settings.json

Data applicazione: 2026-04-14

## Configurazione attuale

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

## Cosa fa ogni impostazione

### `model: sonnet`
Claude Code usa Sonnet come modello fisso. Opus non viene mai attivato automaticamente.
Per usare Opus: `/model opus` nella chat oppure `--model claude-opus-4-6` da terminale.

### `MAX_THINKING_TOKENS: 10000`
Il thinking interno (ragionamento nascosto prima della risposta) e' limitato a 10K token invece dei 32K di default.
Attivo su ogni risposta perche' `alwaysThinkingEnabled: true`. Nessun impatto visibile sulla qualita' dei task normali.

### `CLAUDE_AUTOCOMPACT_PCT_OVERRIDE: 50`
Il contesto viene compattato quando raggiunge il 50% della capacita', invece del 95% di default.
Effetto: sessioni lunghe piu' stabili, meno rischio di comportamenti erratici a fine contesto.

### `CLAUDE_CODE_SUBAGENT_MODEL: haiku`
I subagenti usano Haiku. I subagenti sono attivati da:
- Agent tool: Explore, Plan, general-purpose
- Ricerche nel codebase in background
- Task delegati automaticamente da Claude Code

Il modello principale (Sonnet) resta per la conversazione diretta.

## Impostazioni preesistenti (invariate)

- `alwaysThinkingEnabled: true` - thinking attivo su ogni risposta
- `clangd-lsp@claude-plugins-official` - plugin LSP per C/C++

## Revert

Vedi `revert-settings.md` nella stessa cartella.
