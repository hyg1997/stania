# Layout Catalog

Pre-defined layouts that frontends reference by name in UI specs.
Each layout has defined slots, responsive behavior, and component structure.

---

## LIST

Standard list with filters and actions.

```
┌─────────────────────────────────────┐
│ [Title]              [Filter] [+Add]│
├─────────────────────────────────────┤
│ ┌─────────────────────────────────┐ │
│ │ Item row                    [⋯] │ │
│ ├─────────────────────────────────┤ │
│ │ Item row                    [⋯] │ │
│ ├─────────────────────────────────┤ │
│ │ Item row                    [⋯] │ │
│ └─────────────────────────────────┘ │
│              [Load more]            │
└─────────────────────────────────────┘
```

**Slots**: header (title + actions), filters, item-row (repeated), pagination
**Responsive**: mobile stacks filters above list, item-row becomes card
**Component**: Server Component (list) + Client (filters, actions)

---

## DETAIL

Single resource view with sections.

```
┌─────────────────────────────────────┐
│ [←Back]  [Title]      [Edit][Delete]│
├─────────────────────────────────────┤
│ ┌──────────────┐ ┌────────────────┐ │
│ │              │ │   Key info     │ │
│ │   Hero/      │ │   - field      │ │
│ │   Preview    │ │   - field      │ │
│ │              │ │   - field      │ │
│ └──────────────┘ └────────────────┘ │
├─────────────────────────────────────┤
│ [Tab1] [Tab2] [Tab3]               │
│ ┌─────────────────────────────────┐ │
│ │   Tab content                   │ │
│ └─────────────────────────────────┘ │
└─────────────────────────────────────┘
```

**Slots**: header (back + title + actions), hero, key-info, tabs (content[])
**Responsive**: mobile stacks hero above info, tabs become accordion
**Component**: Server (layout + data) + Client (tabs, actions)

---

## FORM

Multi-step or single form with validation.

```
┌─────────────────────────────────────┐
│ [Title]                    [Step 1/3]│
├─────────────────────────────────────┤
│                                     │
│   [Label]                           │
│   ┌───────────────────────────────┐ │
│   │ Input                         │ │
│   └───────────────────────────────┘ │
│   [helper text]                     │
│                                     │
│   [Label]                           │
│   ┌───────────────────────────────┐ │
│   │ Input                         │ │
│   └───────────────────────────────┘ │
│                                     │
├─────────────────────────────────────┤
│           [Cancel]  [Submit/Next →] │
└─────────────────────────────────────┘
```

**Slots**: header (title + progress), fields[], footer (cancel + submit)
**Responsive**: full-width fields always, sticky footer on mobile
**Variants**: single-step, multi-step (wizard), inline-edit
**Component**: Client Component (React Hook Form + Zod)

---

## DASHBOARD

Metrics overview with cards and charts.

```
┌─────────────────────────────────────┐
│ [Title]           [Period ▾] [Export]│
├─────────────────────────────────────┤
│ ┌────┐ ┌────┐ ┌────┐ ┌────┐       │
│ │ KPI│ │ KPI│ │ KPI│ │ KPI│       │
│ └────┘ └────┘ └────┘ └────┘       │
├─────────────────────────────────────┤
│ ┌───────────────────┐ ┌──────────┐ │
│ │                   │ │          │ │
│ │   Main chart      │ │ Side     │ │
│ │                   │ │ panel    │ │
│ │                   │ │          │ │
│ └───────────────────┘ └──────────┘ │
├─────────────────────────────────────┤
│ ┌─────────────────────────────────┐ │
│ │   Table / recent activity       │ │
│ └─────────────────────────────────┘ │
└─────────────────────────────────────┘
```

**Slots**: header (title + controls), kpi-cards[], main-chart, side-panel, table
**Responsive**: mobile: KPIs 2-col grid, chart full-width, side-panel below
**Component**: Server (layout) + Client (chart, filters)

---

## GRID

Card grid with optional filters (products, gallery, team).

```
┌─────────────────────────────────────┐
│ [Title]              [Filter][View] │
├─────────────────────────────────────┤
│ ┌────────┐ ┌────────┐ ┌────────┐  │
│ │  Card  │ │  Card  │ │  Card  │  │
│ │        │ │        │ │        │  │
│ └────────┘ └────────┘ └────────┘  │
│ ┌────────┐ ┌────────┐ ┌────────┐  │
│ │  Card  │ │  Card  │ │  Card  │  │
│ │        │ │        │ │        │  │
│ └────────┘ └────────┘ └────────┘  │
└─────────────────────────────────────┘
```

**Slots**: header (title + filter + view-toggle), card (repeated)
**Responsive**: 1 col mobile, 2 col tablet, 3-4 col desktop
**Component**: Server (grid + cards) + Client (filters, infinite scroll)

---

## SIDEBAR

Settings, admin, docs — nav + content.

```
┌───────────┬─────────────────────────┐
│           │                         │
│  Nav      │   Content area          │
│  - Item   │                         │
│  - Item   │   (renders child page)  │
│  - Item   │                         │
│  - Item   │                         │
│           │                         │
└───────────┴─────────────────────────┘
```

**Slots**: nav (items[]), content (child route)
**Responsive**: mobile: nav becomes sheet/drawer, hamburger trigger
**Component**: Server (layout) + Client (mobile nav toggle)

---

## MODAL

Overlay for confirmations, quick-create, previews.

```
     ┌─────────────────────────┐
     │ [Title]            [✕]  │
     ├─────────────────────────┤
     │                         │
     │   Content               │
     │                         │
     ├─────────────────────────┤
     │      [Cancel] [Confirm] │
     └─────────────────────────┘
```

**Slots**: header (title + close), body, footer (actions)
**Responsive**: mobile: becomes full-screen sheet (bottom drawer)
**Component**: Client (Dialog from shadcn/ui, focus trap)

---

## EMPTY

Empty state / onboarding / zero-data.

```
┌─────────────────────────────────────┐
│                                     │
│          [Illustration]             │
│                                     │
│        Title: "No X yet"           │
│    Description of what to do next   │
│                                     │
│          [Primary CTA]              │
│                                     │
└─────────────────────────────────────┘
```

**Slots**: illustration (optional), title, description, cta
**Responsive**: centered always, max-width constraint
**Component**: Server Component (static)

---

## SPLIT

Side-by-side comparison, master-detail, chat.

```
┌────────────────┬────────────────────┐
│                │                    │
│   Left panel   │   Right panel      │
│   (list/nav)   │   (detail/chat)    │
│                │                    │
│                │                    │
└────────────────┴────────────────────┘
```

**Slots**: left-panel, right-panel
**Responsive**: mobile shows one panel at a time (navigation between them)
**Component**: Server (layout) + Client (panel switching on mobile)

---

## Usage in UI Specs

In the UI spec, reference layout by name and fill the slots:

```markdown
Layout: DASHBOARD
Slots:
  kpi-cards:
    - label: "Revenue", value: metrics.revenue, trend: up
    - label: "Users", value: metrics.users, trend: stable
  main-chart: line chart of daily revenue (recharts)
  side-panel: top 5 products list
  table: recent orders (last 10)
```

The layout defines structure. The spec defines content.
