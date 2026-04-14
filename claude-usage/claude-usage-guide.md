# Claude Usage Guide
Fonte: Comprehensive Workaround Guide for Claude Usage Limits (aggiornato al 30 marzo 2026)

---

## Il problema

Dal 23-26 marzo 2026 Anthropic ha introdotto silenziosamente moltiplicatori peak-hour che fanno consumare i limiti piu' velocemente durante l'orario lavorativo USA. Questo e' stato preceduto da una promo 2x off-peak (13-28 marzo) che molti interpretano come bait-and-switch.

Ci sono anche bug reali: sessioni che partono al 57% senza aver inviato nulla, contatori che saltano, singoli prompt che consumano il 30-100% della sessione. Interessa tutti i piani da Free a Max 20x ($200/mo). Anthropic dichiara ~7% degli utenti coinvolti; il consenso della community e' che sia la maggioranza degli utenti paganti.

---

## Orari di punta (Peak Hours)

Evita: **lunedi-venerdi 14:00-20:00 ora italiana**
Corrisponde a: 5am-11am PT (Pacific Time)

Verifica calcolo:
- Estate (CEST UTC+2, PDT UTC-7): 5am PDT = 12:00 UTC = 14:00 CEST, 11am PDT = 18:00 UTC = 20:00 CEST
- Inverno (CET UTC+1, PST UTC-8): 5am PST = 13:00 UTC = 14:00 CET, 11am PST = 19:00 UTC = 20:00 CET
- Transizioni DST: USA e UE cambiano DST in date diverse, possibile slittamento di 1h per pochi giorni

Finestre migliori:
- Weekdays prima delle 14:00 o dopo le 20:00
- Weekend: tutto il giorno (nessun moltiplicatore)

Nota: dal 28 marzo molti utenti segnalano consumi elevati anche fuori peak. Ufficialmente consigliato da Anthropic, ma non sempre affidabile.

---

## Trick: Session Timing

La finestra da 5h parte al tuo primo messaggio, non da quando ti svegli.

Strategia: manda qualsiasi prompt alle 6:00, inizia il lavoro vero alle 9:00. La finestra si resetta alle 11:00 invece che a meta' del blocco di lavoro principale.

---

## A. Workaround per tutti (web, mobile, desktop, CLI)

### A1. Sonnet al posto di Opus
Opus consuma ~5x piu' token a parita' di task. Sonnet gestisce ~80% dei task adeguatamente. Usa Opus solo per ragionamento complesso che lo richiede davvero.

### A2. Torna al modello 200K
Anthropic ha cambiato il default al modello 1M-token. Ogni prompt invia un payload molto piu' grande. Se vedi "1M" o "extended" nel nome del modello, torna al 200K standard. Miglioramento immediato segnalato da molti utenti.

### A3. Nuova conversazione per ogni task
Il contesto si accumula ad ogni messaggio. Thread lunghi diventano costosi. Inizia una nuova conversazione per ogni task. Copia le conclusioni chiave nel primo messaggio se hai bisogno di continuita'.

### A4. Prompt specifici
Prompt vaghi innescano esplorazione ampia. "Fix JWT validation in src/auth/validate.ts line 42" costa fino a 10x meno di "fix the auth bug". Vale anche per task non-coding: "Summarize financial risks in section 3" vs "tell me about this document".

### A5. Raggruppa le richieste in meno prompt
Ogni prompt porta overhead di contesto. Un prompt dettagliato con 3 domande consuma meno di 3 follow-up separati.

### A6. Pre-processa i documenti esternamente
Converti i PDF in testo prima di caricarli. Parsali con ChatGPT prima (limiti piu' generosi) e manda il testo estratto a Claude. Gli utenti Pro che fanno ricerca segnalano che i PDF consumano l'80% di una sessione.

---

## B. Workaround CLI (solo Claude Code)

Questi funzionano SOLO in Claude Code (terminale). Non in web app, mobile, o desktop.

### B1. Il blocco settings.json

Aggiungi a `~/.claude/settings.json`:

```json
{
  "model": "sonnet",
  "env": {
    "MAX_THINKING_TOKENS": "10000",
    "CLAUDE_AUTOCOMPACT_PCT_OVERRIDE": "50",
    "CLAUDE_CODE_SUBAGENT_MODEL": "haiku"
  }
}
```

Cosa fa ogni riga:
- `model: sonnet` - default Sonnet (~60% piu' economico di Opus)
- `MAX_THINKING_TOKENS: 10000` - limita i token di thinking nascosto da 32K a 10K (~70% di risparmio)
- `CLAUDE_AUTOCOMPACT_PCT_OVERRIDE: 50` - compatta il contesto al 50% invece che al 95%
- `CLAUDE_CODE_SUBAGENT_MODEL: haiku` - sub-agenti su Haiku (~80% piu' economico)

Risparmio complessivo: 60-80% in un'unica configurazione.

### B2. File .claudeignore
Funziona come .gitignore. Blocca la lettura di node_modules/, dist/, *.lock, __pycache__/, ecc. Il risparmio si accumula su ogni prompt.

### B3. Tieni CLAUDE.md sotto 60 righe
Questo file viene caricato in ogni messaggio. Usa 4 file piccoli (~800 token totali) invece di uno grande (~11.000 token). Riduzione del 90% del costo di avvio sessione. Tutto il resto va in docs/ e viene caricato on demand.

### B4. Read-once hook
Claude rilegge i file molto piu' del necessario. Questo hook blocca le ri-letture ridondanti, riducendo del 40-90% il consumo di token dello strumento Read. Misurato: ~38K token risparmiati su ~94K letture totali in una singola sessione.

```bash
curl -fsSL https://raw.githubusercontent.com/Bande-a-Bonnot/Boucle-framework/main/tools/read-once/install.sh | bash
```

### B5. /clear e /compact aggressivi
- `/clear` tra task non correlati (usa `/rename` prima per poter fare `/resume`)
- `/compact` ai breakpoint logici
- Non lasciare mai che il contesto superi ~200K anche se 1M e' disponibile

### B6. Pianifica in Opus, implementa in Sonnet (Max 5x/20x)
Usa Opus per architettura e pianificazione, poi passa a Sonnet per la generazione del codice.

### B7. Strumenti di monitoring

```bash
npx ccusage@latest    # token usage da log locali, report per giorno/sessione/finestra 5h
ccburn --compact      # grafici visivi, mostra se raggiungerai il 100% prima del reset
ccburn --json         # output JSON da passare a Claude perche' si auto-regoli
```

- **Claude-Code-Usage-Monitor**: dashboard terminale in tempo reale con burn rate e avvisi predittivi
- **ccstatusline / claude-powerline**: token usage nella status bar del terminale

### B8. Salva le spiegazioni localmente

```bash
claude "explain the database schema" > docs/schema-explanation.md
```

Referenziare il file in seguito costa molto meno token della ri-analisi.

---

## C. Strumenti alternativi e strategie multi-provider

| Tool | Note |
|---|---|
| Codex CLI ($20/mo) | GPT concorrenziale per coding, open source, limiti raramente raggiunti |
| Gemini CLI (gratuito) | 60 req/min, 1.000 req/giorno, contesto 1M. Alternativa terminale free piu' forte |
| Gemini web / NotebookLM (gratuito) | Fallback per ricerca e analisi documenti |
| Cursor (a pagamento) | Sonnet come backend, molti utenti lo usano 8h consecutive senza problemi |
| Modelli open-weight (gratuito/locale) | Qwen 3.6 su OpenRouter vicino a qualita' Opus, in miglioramento rapido |
| API diretta Anthropic (pay-per-token) | Prezzi certi, nessun moltiplicatore, token cached non contano, Batch API al 50% |

### Hybrid workflow

| Task | Strumento |
|---|---|
| Pianificazione e architettura | Claude Opus |
| Implementazione codice | Codex CLI, Cursor, o modelli locali |
| Esplorazione file e test | Sub-agenti Haiku o modelli locali |
| Parsing documenti | ChatGPT (limiti piu' generosi) |
| Ricerca | Gemini free o Perplexity |

---

## Bottom Line per piano

### Pro $20/mo
Le opzioni sono sostanzialmente la sezione A: usare meno e in modo piu' intelligente. Il consenso Reddit: il piano e' appena distinguibile dal Free al momento. I workaround aiutano marginalmente. La CLI config e' obbligatoria per reggere.

### Max $100-200/mo con Claude Code
Il blocco settings.json + read-once hook + CLAUDE.md snello + strumenti di monitoring puo' allungare l'uso di 3-5x. Tollerabile per setup ottimizzati, penalizzante per chi usa i default.

### Web e Mobile (qualsiasi piano)
Nessun accesso alle ottimizzazioni CLI. Solo disciplina: orari, prompt specifici, thread corti, evitare modelli 1M.

---

## Cosa chiede la community ad Anthropic
- Dashboard di utilizzo in tempo reale
- Definizioni stabili e pubblicate dei tier
- Comunicazioni email per cambiamenti al servizio
- "Limp home mode": rallentamento progressivo invece di hard-cut
- Reset dei limiti per il periodo di A/B testing silenzioso
