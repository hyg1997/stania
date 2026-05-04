Genera fixtures tipados y seeders de base de datos a partir del modelo de dominio.
Datos realistas, coherentes, y deterministas — no "John Doe" en todos lados.

## Modos

- `/st-seed` — Generar fixtures para todos los aggregates del domain model
- `/st-seed <aggregate>` — Generar para un aggregate especifico
- `/st-seed --db` — Ademas generar y correr database seeder

## Paso 1: Leer fuentes

1. Leer `.stania/domain-model.json` — extraer aggregates, value objects, relaciones
2. Leer `packages/contracts/**/*.ts` — entender shapes de request/response
3. Leer `.stania/config.json` para stack y convenciones

Si `.stania/domain-model.json` no existe:
"No hay modelo de dominio. Corro /st-model primero?"

Si se pidio un aggregate especifico, filtrar solo ese bounded context.

## Paso 2: Generar pool de datos realistas

Construir datos inline SIN faker como dependencia. Usar pools deterministas:

```typescript
// Pools internos — NO exportar, NO depender de librerias
const FIRST_NAMES = ['Mariana', 'Kenji', 'Fatima', 'Oleksandr', 'Priya', 'Santiago', 'Yuki', 'Amara', 'Dmitri', 'Ines'];
const LAST_NAMES = ['Nakamura', 'Okafor', 'Lindqvist', 'Reyes', 'Petrov', 'Al-Rashid', 'Chen', 'Kowalski', 'Dubois', 'Sharma'];
const DOMAINS = ['outlook.com', 'gmail.com', 'proton.me', 'icloud.com', 'hey.com'];
```

Reglas de coherencia:
- `created_at` < `updated_at` < `deleted_at` siempre
- FK references apuntan a IDs que existen en el fixture set
- Cantidades y precios tienen sentido para el dominio
- Enums usan solo valores validos definidos en el modelo
- Al menos un nombre con caracteres unicode (acentos, kanji, cyrillico)

## Paso 3: Generar fixture factories

Crear `packages/contracts/generated/fixtures/<aggregate>.fixtures.ts` por cada aggregate:

```typescript
import type { Reservation, ReservationStatus } from '../../reservation';

// Deterministic seed helper
let _seed = 0;
function nextIndex(pool: readonly unknown[]): number {
  return (_seed++) % pool.length;
}
function resetSeed(): void { _seed = 0; }

// Builder pattern
class ReservationBuilder {
  private data: Reservation = {
    id: 'rsv_00000000-0000-0000-0000-000000000001',
    userId: 'usr_00000000-0000-0000-0000-000000000001',
    restaurantId: 'rst_00000000-0000-0000-0000-000000000001',
    partySize: 2,
    date: '2025-03-15T19:30:00Z',
    status: 'confirmed',
    createdAt: '2025-03-10T08:00:00Z',
    updatedAt: '2025-03-10T08:00:00Z',
  };

  withId(id: string) { this.data.id = id; return this; }
  withPartySize(n: number) { this.data.partySize = n; return this; }
  confirmed() { this.data.status = 'confirmed'; return this; }
  cancelled() { this.data.status = 'cancelled'; this.data.updatedAt = '2025-03-12T10:00:00Z'; return this; }
  pending() { this.data.status = 'pending'; return this; }

  build(): Reservation { return { ...this.data }; }
}

export function aReservation(): ReservationBuilder {
  return new ReservationBuilder();
}

// Pre-built instances
export const RESERVATION_FIXTURES = {
  /** Happy path: confirmed reservation for 2 */
  happy: aReservation().confirmed().build(),
  /** Edge case: max party size, unicode name in related user */
  edgeCase: aReservation().withPartySize(20).pending().build(),
  /** Error state: cancelled after confirmation */
  errorState: aReservation().confirmed().cancelled().build(),
} as const;

export { resetSeed };
```

Cada fixture file DEBE incluir:
- Un builder con metodos fluidos para cada campo/estado
- `FIXTURES` object con al menos 3 instancias:
  - `happy` — caso feliz, datos completos y validos
  - `edgeCase` — limites: arrays vacios, valores maximos, unicode, null optionals
  - `errorState` — estado invalido o de error (cancelado, expirado, rechazado)
- `resetSeed()` para reproducibilidad
- Imports tipados desde los contratos (nunca `any`)

## Paso 4: Generar index

Crear `packages/contracts/generated/fixtures/index.ts`:

```typescript
export * from './reservation.fixtures';
export * from './user.fixtures';
// ... un export por aggregate
```

## Paso 5: Generar database seeder (solo con --db)

Crear `apps/api/src/infrastructure/seed.ts`:

```typescript
import { RESERVATION_FIXTURES } from '@packages/contracts/generated/fixtures';
import { USER_FIXTURES } from '@packages/contracts/generated/fixtures';
// import db client segun stack detectado

async function seed() {
  console.log('Seeding database...');

  // Orden respeta FK constraints (padres primero)
  await seedUsers();
  await seedRestaurants();
  await seedReservations();

  console.log('Done. Seeded N records.');
}

async function seedUsers() {
  const users = Object.values(USER_FIXTURES);
  for (const user of users) {
    await db.user.upsert({ where: { id: user.id }, create: user, update: user });
  }
}

// ... repeat per aggregate

seed().catch(console.error);
```

Reglas del seeder:
- Respetar orden de FK constraints (entidades padre antes que hijas)
- Usar upsert para idempotencia (re-run safe)
- Detectar ORM del proyecto (Prisma, Drizzle, TypeORM, Knex) y usar su API
- Si --db: ejecutar `npx ts-node apps/api/src/infrastructure/seed.ts` o equivalente

## Paso 6: Verificar

```bash
# Typecheck fixtures
pnpm typecheck 2>&1 | grep -i "fixtures" | tail -10
```

Si hay errores de tipo → corregir antes de reportar.

## Reporte final

```
=== SEED GENERATION ===
Aggregates:     4 processed
Fixtures:       12 instances (4 happy, 4 edge, 4 error)
Builders:       4 created
DB Seeder:      generated (--db) | skipped

Files created:
  packages/contracts/generated/fixtures/reservation.fixtures.ts
  packages/contracts/generated/fixtures/user.fixtures.ts
  packages/contracts/generated/fixtures/restaurant.fixtures.ts
  packages/contracts/generated/fixtures/order.fixtures.ts
  packages/contracts/generated/fixtures/index.ts
  apps/api/src/infrastructure/seed.ts  (--db only)

Usage:
  import { aReservation, RESERVATION_FIXTURES } from '@packages/contracts/generated/fixtures';
  const custom = aReservation().withPartySize(8).pending().build();
```

## Reglas

- Fixtures DEBEN usar tipos del contrato — nunca `any`, nunca inline types
- Builder pattern obligatorio para composabilidad en tests
- Datos deterministas: misma ejecucion = mismos datos (seed counter, no Math.random)
- NO agregar faker, chance, ni ninguna libreria de datos aleatorios
- Pools de datos diversos: nombres multiculturales, no solo anglosajones
- Al menos un fixture con caracteres unicode por aggregate
- Fechas logicas: created < updated < deleted, start < end
- IDs con prefijo del aggregate para legibilidad (usr_, rsv_, ord_)
- Si no hay contratos definidos, usar los tipos del domain model directamente
- Fixtures NO deben testear logica — son datos de entrada, no assertions
