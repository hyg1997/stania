Muestra estimacion de tokens consumidos en la sesion actual y por comando.

## Logica

No hay acceso programatico a tokens reales. Estimar:

### Por herramienta
- **Read file**: `wc -c <file>` / 3.5 = tokens estimados
- **Bash output**: output chars / 4
- **Edit**: changed chars / 3.5
- **Agent spawn**: 4000 base + contenido del prompt + tool outputs
- **System prompt**: ~3000 tokens (cargado una vez)

### Por comando Stania
Estimaciones tipicas:
- /st-check: ~8K tokens (3 parallel validations + hardening)
- /st-build (1 aggregate): ~15K tokens (4 layers + tests)
- /st-build (parallel, N aggregates): ~15K x N tokens
- /st-agent: ~20K tokens (full implementation + check)
- /st-ship: ~5K tokens (incremental audit)
- /st-spec: ~3K tokens
- /st-contract: ~4K tokens
- /st-next: ~2K tokens
- /st-retro: ~1K tokens

### Output format
```
⚡ SESSION TOKEN ESTIMATE
Commands run: /st-check, /st-build Training/Routine
Est. input:  ~25K tokens
Est. output: ~8K tokens
Est. total:  ~33K tokens

Biggest consumers:
1. /st-build Training/Routine: ~15K (4 file reads + 8 edits + 3 bash)
2. /st-check: ~8K (3 parallel validations)
3. Context (CLAUDE.md + system): ~3K

💡 Optimization tips:
- [specific tips based on what was detected]
```

### Reglas
- Mostrar siempre al final del output: "Estimates are approximate. Check your dashboard for actual usage."
- Si detecta ineficiencias (ej: se leyo el mismo archivo 3 veces), sugerir fix
- No bloquear ni requerir confirmacion — es informativo
