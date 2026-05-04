Maneja evolucion de contratos — que pasa cuando un contrato cambia despues de estar implementado.
Detecta cambios, clasifica impacto, actualiza artefactos generados, y guia la migracion.

## Modos

- `/st-migrate <contract-name>` — Analizar y migrar un contrato que cambio
- `/st-migrate --check` — Dry-run: mostrar que cambiaria sin modificar archivos

## Proceso

### 1. Detectar cambios en el contrato

Leer el contrato actual y comparar con la version commiteada:

```bash
# Diff del contrato contra ultimo commit
git diff HEAD -- packages/contracts/<name>.ts 2>/dev/null
# Si no hay cambios en working tree, comparar contra commit anterior
git diff HEAD~1 -- packages/contracts/<name>.ts 2>/dev/null
```

Si no hay diff detectable, preguntar al usuario: "Que cambio en el contrato?"

Parsear el diff y clasificar cada cambio:

| Simbolo | Tipo | Clasificacion |
|---------|------|---------------|
| `+` | Campo nuevo opcional | NON-BREAKING |
| `+` | Campo nuevo required | BREAKING |
| `-` | Campo eliminado | BREAKING |
| `~` | Campo renombrado | BREAKING |
| `~` | Tipo cambiado | BREAKING |

### 2. Clasificar impacto global

```
CONTRACT: <name> (BREAKING | NON-BREAKING)
Changes:
  + guestEmail (string, optional)     <- non-breaking
  ~ partySize (number -> PartySize)   <- breaking (type change)
  - guestPhone                        <- breaking (removed)
```

Si TODOS los cambios son non-breaking → clasificar contrato como NON-BREAKING.
Si AL MENOS UN cambio es breaking → clasificar contrato como BREAKING.

### 3. Actualizar artefactos generados

Regenerar los 3 artefactos derivados del contrato:

#### 3.1 Mocks (MSW handlers)

Archivo: `packages/contracts/generated/mocks/<name>.ts`

- Agregar campos nuevos al response mock con datos realistas
- Remover campos eliminados
- Actualizar tipos cambiados
- Mantener estructura de handlers existente

#### 3.2 API Client

Archivo: `packages/contracts/generated/client/<name>.ts`

- Actualizar imports de tipos
- Ajustar request/response handling si hay cambios de tipo
- Asegurar que el client refleja exactamente el contrato nuevo

#### 3.3 Port Interfaces (backend)

Archivo: `packages/contracts/generated/ports/<name>.ts`

- Actualizar firma de metodos
- Actualizar imports de tipos
- Result types deben reflejar nuevos error cases si aplican

En modo `--check`: NO modificar archivos, solo reportar que se regeneraria.

### 4. Encontrar componentes afectados

Buscar todos los archivos que importan del contrato o sus artefactos generados:

```bash
# Imports directos del contrato
grep -rn "from.*contracts.*<name>" --include="*.ts" --include="*.tsx" apps/ src/ 2>/dev/null

# Imports de tipos del contrato
grep -rn "<Name>Request\|<Name>Response\|<Name>Error" --include="*.ts" --include="*.tsx" apps/ src/ 2>/dev/null

# Imports del client generado
grep -rn "from.*generated/client.*<name>" --include="*.ts" --include="*.tsx" apps/ src/ 2>/dev/null

# Imports del port generado
grep -rn "from.*generated/ports.*<name>" --include="*.ts" --include="*.tsx" apps/ src/ 2>/dev/null
```

Agrupar por tipo:
- **Backend handlers** (apps/api/)
- **Frontend hooks/components** (apps/web/)
- **Tests** (archivos con .test. o .spec.)

### 5. Analisis de impacto (BREAKING)

Si el contrato es BREAKING:

#### 5.1 Mostrar impacto

```
Affected:
  -> apps/api/src/application/<name>.handler.ts       (uses removed field)
  -> apps/web/features/<name>/hooks/use-<name>.ts     (type mismatch)
  -> apps/web/features/<name>/components/<name>.tsx   (references old type)

Impact: 3 files will break after regeneration
```

#### 5.2 Sugerir estrategia de migracion

Analizar dependencias y sugerir orden:

- **Backend first** (recomendado si el campo se elimino del response):
  "Actualiza backend para no depender del campo eliminado, luego frontend."

- **Frontend first** (recomendado si se agrego campo required al request):
  "Actualiza frontend para enviar el nuevo campo, luego backend lo consume."

- **Simultaneous** (si ambos necesitan cambiar a la vez):
  "Ambos lados deben actualizar. Coordinar en un solo PR."

Presentar al usuario la estrategia con razonamiento.

#### 5.3 Ofrecer crear issue de migracion

```
Quieres que cree un GitHub issue para trackear esta migracion?
```

Si acepta:

```bash
gh issue create \
  --title "migrate: <name> contract breaking change" \
  --label "migration,contract,breaking-change" \
  --body "## Contract: <name>

### Changes
- [lista de cambios]

### Affected files
- [lista de archivos]

### Migration strategy
[estrategia sugerida]

### Checklist
- [ ] Update backend handler
- [ ] Update frontend components
- [ ] Regenerate mocks/client/ports
- [ ] Run /st-check
- [ ] Run /st-integrate"
```

### 6. Accion para NON-BREAKING

Si el contrato es NON-BREAKING:

1. Regenerar artefactos automaticamente (mocks, client, ports)
2. Listar componentes que PODRIAN beneficiarse del nuevo campo:

```
Auto-updated:
  [ok] generated/mocks/<name>.ts
  [ok] generated/client/<name>.ts
  [ok] generated/ports/<name>.ts

Suggestion: These components could use the new field 'guestEmail':
  -> apps/web/features/reservation/components/reservation-form.client.tsx
  -> apps/api/src/application/create-reservation.handler.ts
```

3. Preguntar: "Quieres que actualice alguno de estos componentes para usar el nuevo campo?"

### 7. Commit + push

Despues de aplicar cambios:

```bash
git add packages/contracts/generated/
git commit -m "migrate(<name>): update generated artifacts for contract change"
git push
```

Si hubo cambios en archivos fuera de generated/:
```bash
git add -A
git commit -m "migrate(<name>): adapt implementation to contract evolution"
git push
```

## Reporte final

```
=== MIGRATION: <name> ===
Type:           BREAKING | NON-BREAKING
Changes:        +2 added, ~1 changed, -1 removed
Generated:      3 files regenerated
Affected:       N files need manual update (BREAKING only)
Strategy:       Backend first (BREAKING only)
Issue:          #42 created (BREAKING only)

VERDICT: [DONE] All artifacts updated
         [ACTION NEEDED] N files need manual migration — see issue #42
```

## Reglas

- NUNCA modificar el contrato — el contrato ya cambio, esta command solo propaga el cambio
- En modo --check: NUNCA modificar archivos — solo reportar
- Campos opcionales agregados son siempre non-breaking
- Campos required agregados son breaking (consumer no los envia aun)
- Si no puede detectar diff automaticamente, preguntar al usuario que cambio
- Datos en mocks deben ser realistas (no "test", "foo", "bar")
- Si `.stania/` no existe, funcionar igual — solo no persistir estado
- Si no hay artefactos generados (primera vez), sugerir correr `/st-contract` primero
