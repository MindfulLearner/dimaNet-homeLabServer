# claude-usage/

Strumenti e documentazione per usare Claude in modo efficiente.

---

## File

| File | Cosa fa |
|---|---|
| `claude-planner.html` | Planner interattivo — aprilo nel browser |
| `claude-tips.html` | Tips, CLI config, hybrid workflow, bottom line per piano |
| `claude-usage-guide.md` | Guida completa: problema, orari, workaround A-C |
| `settings.md` | settings.json applicato + come fare revert |

---

## claude-planner.html

Apri nel browser (doppio click o `open claude-planner.html`).

### Cosa fa

**Banner in cima** — stato corrente: fuori peak / peak / weekend, con countdown.

**Control panel** — due righe di input:
- `Sessione`: ore:minuti rimasti nella sessione 5h + % consumato. Mostra ritmo (es. "sei al 45%, dovresti essere al 40% — in ritmo").
- `Settimana`: % consumato tutti i modelli + solo Sonnet. Distribuisce il budget rimanente sui giorni rimasti.

**Calendario settimanale** — heatmap 7 giorni x 24 ore. Verde = off-peak, Rosso = peak, Blu = weekend, Viola = finestra sessione attiva.

**Piano orario sessione** — tabella 5h suddivisa in slot con azione consigliata (es. "2h rimaste: chiudi i task aperti, esegui /compact").

**Session tracker** (sidebar) — anello % consumato + tempo trascorso/rimasto/reset.

**Distribuzione budget settimanale** — 7 card giornaliere con quota consigliata + banner pace (in pari / indietro / molto indietro / avanti). Il banner mostra anche il massimo raggiungibile a fine settimana — se e' sotto 100% significa che alcune sessioni sono gia' perse.

**Piano mensile** — inserisci giorno di rinnovo + tipo piano. Mostra giorno del ciclo, giorni rimasti, % ciclo trascorso, e un tip contestuale che cambia in base a: posizione nel ciclo, utilizzo settimanale, ora del giorno, piano.

**Utilizzo reale** (ccusage) — carica `~/.claude/projects/` via File System Access API. Legge i JSONL locali, mostra token sessione/oggi/settimana, costo, breakdown per modello. Su macOS: nel picker `Cmd+Shift+G`, incolla `~/.claude/projects`, premi Invio.

### Flusso di utilizzo

1. Apri il planner.
2. Guarda il banner — sei in peak? Aspetta le 20:00.
3. Quando avvii una sessione: inserisci l'orario di reset (es. `05:00` = 5h rimaste) e la % consumata.
4. Aggiorna la % consumata durante la sessione per tenere il ritmo.
5. A inizio settimana: inserisci la % settimanale usata (tutti + Sonnet) per vedere la distribuzione.
6. Inserisci piano e giorno di rinnovo una volta sola — persiste in localStorage.

### Persistenza

Tutti i valori sono salvati in localStorage. Si ripristinano al refresh. Il timestamp di reset e' salvato come epoch — il countdown continua anche se chiudi e riapri la pagina (finche' non scade).

---

## claude-tips.html

Pagina separata con contenuto di riferimento (non funzionale). Aprila dal link "Tips" nell'header del planner.

Contiene:
- Quick Tips (10 regole pratiche)
- CLI Config — blocco settings.json con copy button
- Monitoring tools (ccusage, ccburn, read-once hook)
- Hybrid Workflow — quale tool usare per quale task quando i limiti stringono
- Bottom line per piano (Pro / Max 5x-20x / Web)

---

## claude-usage-guide.md

Guida completa al problema dei limiti Claude (aggiornata marzo 2026).

Sezioni:
- Il problema (peak multiplier, bug noti)
- Orari di punta con calcolo DST
- Trick session timing (prompt 6:00, lavoro 9:00)
- Workaround A: tutti i client (Sonnet, 200K, prompt specifici, batch, no PDF raw)
- Workaround B: solo CLI (settings.json, .claudeignore, CLAUDE.md snello, read-once hook, /compact)
- Workaround C: strumenti alternativi (Gemini CLI, Codex, Cursor, API diretta)
- Bottom line per piano

---

## settings.md

settings.json corrente applicato + istruzioni revert.
