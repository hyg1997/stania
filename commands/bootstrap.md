Inicializa un proyecto profesional desde cero o desde lo que ya exista.
Analiza el estado actual del directorio y construye todo lo que falta.

## Paso 1: Diagnostico

Escanea el directorio actual y reporta que existe:

```
[ ] Git inicializado (.git/)
[ ] .gitignore configurado
[ ] CLAUDE.md (contexto maestro)
[ ] package.json / pyproject.toml (proyecto inicializado)
[ ] Monorepo configurado (turbo.json / pnpm-workspace.yaml)
[ ] Linter configurado (biome.json / .eslintrc / ruff.toml)
[ ] TypeScript strict (tsconfig con strict: true)
[ ] Test framework (vitest / jest / pytest)
[ ] Pre-commit hooks (husky / lint-staged)
[ ] CI/CD (.github/workflows/)
[ ] Docs estructura (docs/)
[ ] Design system definido
```

Muestra el diagnostico al usuario y espera confirmacion para continuar.

## Paso 2: Recopilar contexto

Si no existe CLAUDE.md, pregunta al usuario:

1. **Que es el proyecto?** (1 oracion)
2. **Para quien?** (cliente ideal)
3. **Stack preferido?** Sugerir basado en lo detectado, o preguntar:
   - Frontend: Next.js / Nuxt / Astro / None
   - Backend: Fastify / Express / Django / FastAPI / None
   - DB: Postgres / MySQL / MongoDB / SQLite
   - Deploy: Vercel / Cloud Run / Railway / Docker
4. **Arquitectura?** Clean Architecture + DDD / Simple MVC / Serverless
5. **Es monorepo?** Si tiene frontend + backend → recomendar si

No preguntar todo — inferir lo posible del contexto.
Si ya existe CLAUDE.md, leerlo y confirmar que el contexto esta correcto.

## Paso 3: Construir lo que falta

Ejecutar en orden, saltando lo que ya existe:

### 3.1 Git
```bash
git init (si no existe)
.gitignore con: node_modules, .env, .env.local, .DS_Store, dist, build, .next, .turbo, __pycache__, .pytest_cache, .mypy_cache, *.log
```

### 3.2 CLAUDE.md
Crear CLAUDE.md con:
- Identidad del proyecto (de paso 2)
- Stack decidido
- Principios de codigo (Clean Architecture si aplica)
- Flujo de ingenieria: SPEC → GENERATE → VALIDATE → HARDEN → REVIEW
- Como trabajar conmigo (directo, sin preambulos, preguntar si ambiguo)
- Referencia a docs/

### 3.3 Docs estructura
```
docs/
├── 00-context.md        ← Contexto del negocio/proyecto
├── 01-product-spec.md   ← Que hace el producto
├── 02-architecture.md   ← Decisiones tecnicas
└── decisions/           ← ADRs futuros
```
Llenar con lo que se sepa. Dejar TODOs claros en lo que falte.

### 3.4 Monorepo (si aplica)
Si es monorepo TypeScript:
- pnpm-workspace.yaml
- turbo.json con pipelines: build, dev, test, lint, typecheck
- apps/ y packages/ directorios

### 3.5 Tooling de calidad
TypeScript:
- tsconfig.json con strict: true, noUncheckedIndexedAccess: true
- biome.json (reemplaza ESLint + Prettier)
- vitest.config.ts

Python:
- pyproject.toml con mypy strict y ruff
- pytest configurado

### 3.6 Pre-commit hooks
- Instalar husky + lint-staged (TS) o pre-commit (Python)
- Hook: typecheck + lint + format + test en archivos modificados
- Si falla → no pasa el commit

### 3.7 Scripts en package.json
```json
{
  "dev": "turbo dev",
  "build": "turbo build",
  "test": "turbo test",
  "test:domain": "vitest run --project domain",
  "typecheck": "turbo typecheck",
  "lint": "biome check .",
  "lint:fix": "biome check --write .",
  "format": "biome format --write .",
  "validate": "pnpm typecheck && pnpm lint && pnpm test",
  "test:mutate": "stryker run"
}
```

### 3.8 Estructura de codigo (si Clean Architecture)
```
src/
├── domain/          # Zero deps externas
│   ├── entities/
│   ├── value-objects/
│   ├── events/
│   └── ports/       # Interfaces
├── application/     # Commands, Queries, Handlers
│   ├── commands/
│   ├── queries/
│   └── dtos/
├── infrastructure/  # Implementa ports
│   ├── persistence/
│   ├── external/
│   └── config/
└── tests/
    ├── domain/
    ├── application/
    └── integration/
```

## Paso 4: Verificacion

Correr:
1. `pnpm install` (o equivalente)
2. `pnpm typecheck` → debe pasar
3. `pnpm lint` → debe pasar
4. `pnpm test` → debe pasar (aunque sea vacio)
5. `pnpm build` → debe compilar

Si algo falla, arreglar antes de terminar.

## Paso 5: Primer commit

```
git add .
git commit -m "chore: project bootstrap with engineering tooling"
```

## Paso 6: Reporte final

Mostrar al usuario:
- Que se creo
- Que quedo pendiente (TODOs en docs)
- Siguiente paso sugerido (primera feature o completar docs)
- Commands disponibles: /spec, /build, /check, /ship
