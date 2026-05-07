Genera componentes frontend desde un UI spec estructurado.
El frontend define QUE (layout + data + interactions). Claude genera COMO (codigo limpio, performant, accessible).

## Inputs (leer siempre antes de generar)

1. `.stania/ui-standards.md` — reglas de arquitectura y calidad (OBLIGATORIO)
2. `.stania/layout-catalog.md` — catalogo de layouts predefinidos
3. `.stania/ui-specs/<name>.md` — spec del componente a generar
4. `packages/contracts/<contract>.ts` — tipos del contrato (si aplica)
5. `packages/contracts/generated/client/` — API client generado

Si `ui-standards.md` no existe: copiarlo de templates/ o crearlo con defaults.
Si `layout-catalog.md` no existe: copiarlo de templates/.

## Uso

- `/st-ui <name>` — Genera desde spec existente en `.stania/ui-specs/<name>.md`
- `/st-ui --new` — Crea spec interactivamente y luego genera
- `/st-ui --refine <name>` — Aplica ajustes visuales a componente existente
- `/st-ui --list` — Muestra specs disponibles

## Proceso

### 1. Validar spec

Leer `.stania/ui-specs/<name>.md`. Verificar campos obligatorios:
- Layout (debe existir en catalogo)
- Al menos 1 slot definido
- States (4 estados obligatorios)
- Contract referenciado existe (si tiene datos de API)

Si falta algo → preguntar al frontend. NO generar con spec incompleto.

### 2. Resolver layout

Leer `.stania/layout-catalog.md` → extraer el layout referenciado:
- Slots definidos para ese layout
- Comportamiento responsive default
- Tipo de componente (Server vs Client)

Verificar que los slots del spec coinciden con los slots del layout.

### 3. Resolver datos

Si tiene Contract:
```bash
cat packages/contracts/<contract>.ts | tail -30
cat packages/contracts/generated/client/<contract>.ts 2>/dev/null | tail -20
```

Extraer tipos de request/response. Usarlos para:
- Props del componente
- Return type del hook
- Mock data en tests

### 4. Generar estructura

```
features/<feature>/
├── components/
│   ├── <name>.tsx              ← Server Component (RSC) si layout lo indica
│   ├── <name>.client.tsx       ← Client islands (solo partes interactivas)
│   ├── <name>.skeleton.tsx     ← Loading state (matches layout dimensions)
│   └── <name>.error.tsx        ← Error boundary fallback
├── hooks/
│   └── use-<resource>.ts      ← TanStack Query hook con tipos del contract
├── lib/
│   └── <name>.utils.ts        ← Pure functions (formatters, validators)
└── __tests__/
    └── <name>.test.tsx        ← Testing Library + axe-core
```

### 5. Reglas de generacion (enforced por ui-standards.md)

**Server vs Client split:**
- Layout, data fetching, static content → Server Component
- Event handlers, hover effects, form inputs → Client Component
- Client boundary pushed as deep as possible (leaf nodes)

**Responsive (del layout catalog):**
- Generar usando el responsive behavior del catalogo
- Si spec tiene "responsive override" → aplicar override
- Mobile-first: base styles = mobile, `sm:` `md:` `lg:` para breakpoints

**States (siempre los 4):**
- loading → `.skeleton.tsx` que replica dimensiones del layout final
- empty → mensaje contextual + CTA primario
- error → `.error.tsx` con descripcion + retry
- success → componente principal

**Accessibility (de ui-standards.md):**
- Semantic HTML (no divs para todo)
- ARIA solo si HTML semantico no alcanza
- Focus management en modals/drawers
- Keyboard nav para todo lo interactivo

**Performance:**
- Dynamic import para charts, editors, heavy components
- next/image para toda imagen
- Suspense boundary en cada async component
- No layout shift (skeleton = mismas dimensiones)

### 6. Generar tests

```typescript
import { render, screen } from '@testing-library/react';
import { axe } from 'vitest-axe';
import { ComponentName } from '../components/component-name';

describe('ComponentName', () => {
  it('renders success state', () => { /* render with data → assert visible content */ });
  it('renders loading state', () => { /* render with loading → assert skeleton */ });
  it('renders empty state', () => { /* render with no data → assert CTA */ });
  it('renders error state', () => { /* render with error → assert retry button */ });
  it('handles [main interaction]', () => { /* user event → assert result */ });
  it('has no accessibility violations', async () => {
    const { container } = render(<ComponentName {...defaultProps} />);
    expect(await axe(container)).toHaveNoViolations();
  });
});
```

### 7. Verificar

```bash
pnpm typecheck --filter web 2>&1 | tail -5
pnpm test --filter web -- --testPathPattern="<name>" --bail 2>&1 | tail -10
```

### 7.5. Visual self-verification (agent-browser)

If `agent-browser` is installed:

```bash
if command -v agent-browser &>/dev/null; then
  agent-browser open http://localhost:3000/<page-route>
  agent-browser snapshot  # accessibility tree (~1K tokens)
fi
```

Verify via snapshot:
- Component renders (key refs present in tree)
- 4 states work (loading skeleton → empty CTA → error retry → success content)
- No broken layout (semantic structure matches spec)
- Interactive elements are accessible (buttons, inputs have labels)

If issues found: fix before commit. If agent-browser not installed: skip.

### 8. Commit

```bash
git add features/<feature>/
git commit -m "ui(<name>): implement from spec [<layout>]"
```

## Modo --new (interactivo)

Guiar al frontend con preguntas cerradas:

1. "Nombre del componente?" → slug
2. "Tipo: page, section, widget, o modal?"
3. "Que layout?" → mostrar nombres del catalogo con 1 linea descriptiva:
   - LIST — tabla/lista con filtros y acciones
   - DETAIL — vista de un recurso con tabs
   - FORM — formulario (single o wizard)
   - DASHBOARD — metricas con KPIs y charts
   - GRID — grid de cards (productos, galeria)
   - SIDEBAR — nav lateral + contenido
   - MODAL — overlay (confirmacion, quick-create)
   - SPLIT — dos paneles (chat, master-detail)
4. "Que datos usa? (nombre del contrato, o 'ninguno')"
5. "Que puede hacer el usuario?" → interactions (lista libre)
6. "Algo especial visualmente?" → design notes

Generar spec → mostrar al frontend → confirmar → generar codigo.

## Modo --refine (ajustes visuales)

El frontend pide cambios en lenguaje natural sobre un componente ya generado.
NO regenera desde cero — edita el código existente.

### Proceso

1. Leer el componente actual:
```bash
cat features/<feature>/components/<name>.tsx
```

2. Leer ui-standards.md (para no violar reglas al editar)

3. Preguntar: "Que quieres ajustar?" — el frontend responde en lenguaje natural:
   - "mas padding en las cards"
   - "sombra mas pronunciada en hover"
   - "transicion suave al abrir el dropdown"
   - "el boton principal mas grande en mobile"
   - "fondo degradado de azul a morado"
   - "animacion de entrada tipo fade-in con slide-up"

4. Aplicar cambios SOLO en Tailwind classes o agregar CSS animations.
   - Preferir utilidades de Tailwind (`transition-all duration-300 ease-out`)
   - Para animaciones custom: agregar `@keyframes` en globals.css + clase Tailwind con `animate-[name]`
   - NUNCA romper la arquitectura (no convertir Server en Client por un hover effect)
   - NUNCA agregar dependencias nuevas para un ajuste visual

5. Si el ajuste requiere interactividad (hover state, click animation):
   - Verificar si ya es Client Component
   - Si no: extraer SOLO la parte interactiva a un `.client.tsx` leaf
   - Usar CSS-only cuando sea posible (`group-hover:`, `peer-checked:`, `transition-*`)

6. Mostrar el diff al frontend para confirmacion.

7. Si confirma:
```bash
pnpm typecheck --filter web 2>&1 | tail -3
git add features/<feature>/
git commit -m "style(<name>): <descripcion corta del ajuste>"
```

### Ajustes comunes (CSS-only, sin Client boundary)

| Peticion | Tailwind |
|----------|----------|
| Sombra | `shadow-sm` `shadow-md` `shadow-lg` `shadow-xl` |
| Bordes redondeados | `rounded-sm` `rounded-md` `rounded-lg` `rounded-full` |
| Hover effect | `hover:scale-105 hover:shadow-lg transition-all` |
| Fade in | `animate-in fade-in duration-300` |
| Slide up | `animate-in slide-in-from-bottom-4 duration-300` |
| Gradiente | `bg-gradient-to-r from-blue-500 to-purple-600` |
| Glassmorphism | `bg-white/10 backdrop-blur-md border border-white/20` |
| Spacing | `p-4 md:p-6 lg:p-8` (responsive padding) |
| Max width | `max-w-sm` `max-w-md` `max-w-lg` `max-w-2xl` |

### Efectos que requieren Client boundary

| Peticion | Solucion |
|----------|----------|
| Click animation | `framer-motion` o CSS `active:scale-95` |
| Scroll-triggered | `intersection-observer` + class toggle |
| Drag & drop | Requiere lib (`@dnd-kit`) |
| Tooltip on hover | shadcn/ui Tooltip (ya es Client) |
| Count-up numbers | Client + `useEffect` |

## Reglas

- NUNCA generar sin leer ui-standards.md primero
- NUNCA generar si spec esta incompleto (preguntar)
- NUNCA `any` en tipos — usar contract types o definir interface
- NUNCA snapshot tests
- SIEMPRE los 4 estados (loading, empty, error, success)
- SIEMPRE accessibility test con axe
- SIEMPRE responsive (mobile-first desde layout catalog)
- Si falta contrato → "Primero /st-contract <name>"
- Si falta mock → verificar que MSW handler existe
- En --refine: NUNCA romper arquitectura por un ajuste visual
- En --refine: preferir CSS-only sobre JavaScript cuando sea posible
