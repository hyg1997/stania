# Frontend Guide

Guide for frontend engineers and interns using Stania.

## Your Job

You define **what** the component does. Claude generates **how** it's built.

You write:
- What layout it uses (pick from catalog)
- What data it shows
- What the user can do
- What happens on loading/error/empty

You don't write:
- React code
- CSS/Tailwind classes
- Hooks or data fetching
- Tests

## Setup

Make sure the project has Stania installed:
```bash
npx stania
```

You need:
- Claude Code installed
- Access to the project repo
- Storybook running (`pnpm storybook`)

## Workflow

### Step 1: Get the layout catalog

Open `.stania/layout-catalog.md` to see available layouts:

| Layout | When to use |
|--------|-------------|
| **LIST** | Showing multiple items (orders, users, messages) |
| **DETAIL** | Viewing one item (profile, order details, settings page) |
| **FORM** | Collecting input (signup, create order, edit profile) |
| **DASHBOARD** | Overview with metrics (admin panel, analytics) |
| **GRID** | Card gallery (products, team members, portfolio) |
| **SIDEBAR** | Navigation + content (settings, docs, admin) |
| **MODAL** | Quick actions (confirm delete, create item, preview) |
| **SPLIT** | Two panels (chat, email inbox, code editor) |

### Step 2: Create your spec

```bash
cp .stania/ui-specs/_TEMPLATE.md .stania/ui-specs/my-component.md
```

Fill in the template. Here's a minimal example:

```markdown
# Product Card Grid

## Meta
- **Type**: section
- **Contract**: list-products
- **Priority**: P0

## Layout
**Layout**: GRID

**Slots**:
  - header: "Products" + search + category filter
  - card: product image, name, price, "Add to cart" button

## States
| State | UI |
|-------|-----|
| loading | 6 skeleton cards |
| empty | "No products found" + clear filters |
| error | "Failed to load" + retry |
| success | product grid |

## Interactions
| Trigger | Action | Result |
|---------|--------|--------|
| type in search | filter products | grid updates live |
| click category | filter by category | grid updates |
| click "Add to cart" | add to cart | button changes to "Added ✓" |
| scroll bottom | load next page | append cards |

## Design Notes
- Cards with subtle hover shadow
- Price in bold, green if on sale
- "Add to cart" button fills full card width on mobile
```

### Step 3: Generate the component

Open Claude Code and run:
```
/st-ui product-card-grid
```

Claude generates all the code: components, hooks, tests, and everything is connected to the real API contract types.

### Step 4: Review in Storybook

```bash
pnpm storybook
```

Check all states: default, loading, empty, error, mobile.

### Step 5: Request visual adjustments

If you want changes, run:
```
/st-ui --refine product-card-grid
```

Then describe what you want in plain language:
- "Cards need more rounded corners and a shadow on hover"
- "The search bar should be wider on desktop"
- "Add a fade-in animation when cards appear"
- "Price should be larger and use the brand green color"
- "On mobile, show 1 card per row instead of 2"

Claude edits the styling. You review in Storybook again.

## Tips

### Good specs vs bad specs

**Bad** (too vague):
```
Layout: LIST
Slots:
  - items: show the orders
```

**Good** (specific):
```
Layout: LIST
Slots:
  - header: "My Orders" + date range filter (last 7/30/90 days)
  - filters: status tabs (All | Pending | Confirmed | Cancelled)
  - item-row: order date, restaurant name, party size, status badge, "View" link
  - pagination: "Load more" button (not infinite scroll)
```

### How to describe interactions

Use this format: **trigger** → **action** → **result**

- "click the row" → "navigate" → "go to /orders/:id"
- "change the date filter" → "refetch with new date range" → "list updates"
- "long press on mobile" → "show context menu" → "edit/delete options"

### How to describe design

Be specific about what you want different from defaults:

- "Product image should be 1:1 aspect ratio with object-cover"
- "Status badges: green for confirmed, yellow for pending, red for cancelled"
- "Subtle gradient background from white to gray-50"
- "Cards should have a 2px left border colored by status"

### When to update spec vs refine

| Situation | Action |
|-----------|--------|
| Change colors, spacing, shadows | `/st-ui --refine` |
| Add hover effect or animation | `/st-ui --refine` |
| Add a new section or tab | Update spec → `/st-ui` |
| Change layout (LIST → GRID) | Update spec → `/st-ui` |
| Add new data field | Update spec → `/st-ui` |
| Fix mobile responsiveness | `/st-ui --refine` |

## Common Patterns

### Forms with validation

In your spec, describe the fields and validation rules:
```
Interactions:
| submit with empty name | show error | "Name is required" below field |
| submit with invalid email | show error | "Invalid email" below field |
| submit valid form | call API | show success toast + redirect |
```

### Tables with sorting

```
Interactions:
| click column header | sort by column | arrow indicator shows direction |
| click same header again | reverse sort | arrow flips |
```

### Infinite scroll vs pagination

```
# Infinite scroll:
| scroll bottom | load next page | append items, show spinner at bottom |

# Pagination:
| click page number | load that page | replace items, scroll to top |

# Load more button:
| click "Load more" | load next page | append items, hide button if last page |
```

### Modals and confirmations

```
Interactions:
| click "Delete" | show confirmation modal | "Are you sure?" with Cancel/Delete |
| click "Cancel" in modal | close modal | nothing changes |
| click "Delete" in modal | call DELETE API | remove item, show toast |
```

## FAQ

**Q: What if I don't know what layout to pick?**
A: Run `/st-ui --new` and Claude will ask you questions to figure it out.

**Q: Can I use a custom layout not in the catalog?**
A: Describe it in the "Responsive override" section of the spec. Claude adapts.

**Q: What if the component needs data from an API that doesn't have a contract yet?**
A: Tell the Tech Lead to run `/st-contract <name>` first. You need the contract before the spec.

**Q: Can I see a preview before generating?**
A: No preview before generation, but Storybook shows all states after. Changes are cheap — just `/st-ui --refine`.

**Q: What if I want to write code myself?**
A: Go ahead! The generated code is standard React + Tailwind. Edit directly. Just don't break TypeScript types.
