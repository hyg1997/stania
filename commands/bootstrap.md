Inicializa un proyecto profesional desde cero o desde lo que ya exista.
Analiza el estado actual, construye lo que falta, y crea `.stania/` para tracking.

## Paso 1: Diagnostico

Escanea el directorio actual y reporta:

```
[ ] Git inicializado (.git/)
[ ] .gitignore configurado
[ ] CLAUDE.md (contexto maestro)
[ ] .stania/ (state tracking)
[ ] package.json / pyproject.toml / go.mod (proyecto inicializado)
[ ] Monorepo configurado (turbo.json / pnpm-workspace.yaml)
[ ] Linter configurado (biome.json / .eslintrc / ruff.toml)
[ ] TypeScript strict (tsconfig con strict: true)
[ ] Test framework (vitest / jest / pytest)
[ ] Pre-commit hooks (husky / lint-staged)
[ ] CI/CD (.github/workflows/)
[ ] Docs estructura (docs/)
```

Muestra el diagnostico y espera confirmacion.

## Paso 2: Recopilar contexto

Si no existe CLAUDE.md, pregunta:

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
Si ya existe CLAUDE.md, leerlo y confirmar.

## Paso 3: Crear .stania/

Crear `.stania/config.json`:

```json
{
  "version": "1.0.0",
  "projectName": "[nombre del proyecto]",
  "stack": {
    "language": "[detectado o preguntado]",
    "framework": "[detectado]",
    "packageManager": "[detectado]",
    "testRunner": "[detectado]",
    "linter": "[detectado]",
    "typeChecker": "[detectado]"
  },
  "architecture": "[clean | mvc | simple]",
  "hardening": {
    "mutationThreshold": 80,
    "coverageTarget": { "domain": 80, "application": 60, "overall": 60 }
  },
  "createdAt": "[ISO8601]"
}
```

Crear `.stania/progress.json`:
```json
{
  "aggregates": {},
  "lastSession": null
}
```

Agregar a `.gitignore`:
```
.stania/progress.json
.stania/specs/
```

Mantener en git: `.stania/config.json` y `.stania/domain-model.json`.

## Paso 4: Construir lo que falta

Ejecutar en orden, saltando lo que ya existe:

### 4.1 Git
```bash
git init (si no existe)
```
.gitignore con: node_modules, .env, .env.local, .DS_Store, dist, build, .next, .turbo, __pycache__, .pytest_cache, .mypy_cache, *.log

### 4.2 CLAUDE.md
Crear con:
- Identidad del proyecto
- Stack decidido
- Principios de codigo
- Flujo de ingenieria: SPEC → BUILD → CHECK → SHIP → RETRO
- Referencia a docs/

### 4.3 Docs estructura
```
docs/
├── 00-context.md
├── 01-product-spec.md
├── 02-architecture.md
└── decisions/
```
Llenar con lo que se sepa. Dejar TODOs claros.

### 4.4 Monorepo (si aplica)
Si es monorepo TypeScript:
- pnpm-workspace.yaml
- turbo.json con pipelines: build, dev, test, lint, typecheck
- apps/ y packages/

### 4.5 Tooling de calidad

TypeScript:
- tsconfig.json con strict: true, noUncheckedIndexedAccess: true
- biome.json
- vitest.config.ts

Python:
- pyproject.toml con mypy strict y ruff
- pytest configurado

Go:
- golangci-lint config

### 4.6 Pre-commit hooks
- Instalar husky + lint-staged (TS) o pre-commit (Python)
- Hook: typecheck + lint + format en archivos modificados

### 4.7 Scripts en package.json (TypeScript)
```json
{
  "dev": "turbo dev",
  "build": "turbo build",
  "test": "turbo test",
  "typecheck": "turbo typecheck",
  "lint": "biome check .",
  "lint:fix": "biome check --write .",
  "validate": "pnpm typecheck && pnpm lint && pnpm test"
}
```

### 4.8 Estructura de codigo (si Clean Architecture)
```
src/
├── domain/
│   ├── entities/
│   ├── value-objects/
│   ├── events/
│   └── ports/
├── application/
│   ├── commands/
│   ├── queries/
│   └── dtos/
├── infrastructure/
│   ├── persistence/
│   ├── external/
│   └── config/
└── tests/
    ├── domain/
    ├── application/
    └── integration/
```

## Paso 5: Verificacion

Correr:
1. Install de dependencias
2. Typecheck → debe pasar
3. Lint → debe pasar
4. Test → debe pasar (aunque sea vacio)

Si algo falla, arreglar antes de terminar.

## Paso 6: Primer commit

```bash
git add .
git commit -m "chore: project bootstrap with stania engineering tooling"
```

## Paso 7: Reporte

Mostrar:
- Que se creo
- Que quedo pendiente
- Siguiente paso: "/model para definir el dominio" o "/spec para la primera feature"
