Genera componentes frontend desde un UI spec definido por el intern o por el tech lead.
El intern define QUE (design, estados, eventos). El agente genera COMO (codigo limpio).

## Uso

- `/st-ui <component-name>` — Genera componente desde spec en `.stania/ui-specs/`
- `/st-ui --interactive` — Guia al usuario para crear el UI spec y luego genera

## Input: UI Spec

El intern o tech lead crea `.stania/ui-specs/<component-name>.md`:

```markdown
## Component: [NombreComponente]

**Type**: page | section | widget | modal | form
**Route**: /path (si es page)
**Contract**: [nombre del contrato que usa, si aplica]

**Props**:
  - prop1: tipo — descripcion
  - prop2: tipo — descripcion

**States**: idle → loading → success | error
**Transitions**:
  - idle + user clicks submit → loading
  - loading + API success → success
  - loading + API error → error
  - error + user clicks retry → loading

**Events**:
  - onSubmit(data) → call API
  - onCancel() → navigate back
  - onRetry() → re-call API

**Design**:
  - [Descripcion visual: layout, colores, spacing]
  - [Responsive: que cambia en mobile]

**Components used**: Button, Card, Input (de shadcn/ui)
```

## Proceso

### 1. Leer spec

```bash
cat .stania/ui-specs/<component-name>.md
```

Si no existe y es --interactive:
- Preguntar: que componente quieres?
- Guiar con preguntas sobre states, events, design
- Crear el archivo .stania/ui-specs/<name>.md
- Confirmar con el usuario antes de generar

### 2. Leer contrato relacionado

Si el UI spec referencia un contrato:
```bash
cat packages/contracts/<contract-name>.ts
cat packages/contracts/generated/client/<contract-name>.ts
```

Usar los tipos reales del contrato para props y API calls.

### 3. Generar componente

Crear estructura:
```
apps/web/src/components/<name>/
├── <Name>.tsx              ← Componente principal (presentational)
├── <Name>.container.tsx    ← Logic + API connection (si tiene state machine)
├── <Name>.test.tsx         ← Tests de interaccion
└── <Name>.stories.tsx      ← Storybook story
```

**Reglas de generacion:**
- Server Component por defecto. `"use client"` solo si tiene interactividad.
- Tailwind CSS para styling. No CSS modules, no styled-components.
- shadcn/ui components donde aplique (Button, Card, Input, Dialog, etc.)
- State machine explicita si hay multiples estados (no useState spaghetti)
- Zod para validacion de forms
- API client importado de `packages/contracts/generated/client/`
- React Hook Form para forms
- Error boundaries para error states
- Loading skeletons (no spinners genericos)

### 4. Generar Storybook story

```typescript
import type { Meta, StoryObj } from '@storybook/react';
import { [Name] } from './[Name]';

const meta: Meta<typeof [Name]> = {
  component: [Name],
  // args con datos realistas
};

export default meta;
type Story = StoryObj<typeof [Name]>;

export const Default: Story = { args: { /* props default */ } };
export const Loading: Story = { args: { /* estado loading */ } };
export const Error: Story = { args: { /* estado error */ } };
export const Mobile: Story = {
  parameters: { viewport: { defaultViewport: 'mobile1' } },
};
```

### 5. Verificar

```bash
pnpm typecheck 2>&1 | tail -5
```

### 6. Commit

```bash
git add apps/web/src/components/<name>/
git commit -m "ui(<name>): implement component from UI spec"
```

Si es para PR (intern creando):
```bash
git push -u origin ui/<name>
gh pr create --title "ui(<name>): [titulo]" --label "frontend,ready-to-review"
```

## Modo interactivo (para interns sin experiencia)

Si el intern no sabe que escribir en el UI spec, guiar con:

1. "Que hace este componente en una oracion?"
2. "Que datos muestra?" (mapear a props)
3. "Que puede hacer el usuario?" (mapear a events)
4. "Que pasa cuando falla?" (mapear a error state)
5. "Es un formulario, una lista, un dashboard, o un wizard?"

Generar el UI spec y mostrarlo para aprobacion antes de generar codigo.

## Reglas

- El intern NUNCA necesita escribir codigo — solo el spec
- Si falta contrato para los datos → "Primero /st-contract <name>"
- No generar componentes que dependan de APIs sin mock → verificar que el mock existe
- Storybook stories SIEMPRE — el intern valida visualmente ahi
- Mobile-first: generar siempre la variante responsive
