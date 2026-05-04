# [Component Name]

## Meta
- **Type**: page | section | widget | modal
- **Route**: /path (if page)
- **Contract**: contract-name (from packages/contracts/)
- **Priority**: P0 (must-have) | P1 (important) | P2 (nice-to-have)

## Layout

<!-- Pick ONE from catalog: LIST | DETAIL | FORM | DASHBOARD | GRID | SIDEBAR | MODAL | EMPTY | SPLIT -->

**Layout**: LAYOUT_NAME

**Slots**:
  - slot-name: what goes here
  - slot-name: what goes here

<!-- Override responsive behavior only if different from catalog default -->
**Responsive override** (optional):
  - mobile: description
  - desktop: description

## Data

<!-- What data does this component consume? Map to contract fields -->

| Field | Source | Display |
|-------|--------|---------|
| field_name | contract.response.field | How to show it |

## States

<!-- Describe what happens in each mandatory state -->

| State | UI |
|-------|-----|
| loading | skeleton matching layout |
| empty | message + CTA |
| error | what went wrong + retry |
| success | normal render |

## Interactions

<!-- What can the user DO? Each interaction = one row -->

| Trigger | Action | Result |
|---------|--------|--------|
| click [element] | what happens | what user sees |
| submit form | validate + call API | success toast / error inline |
| scroll bottom | load more | append items |

## Design Notes

<!-- Visual decisions that aren't covered by layout + theme -->

- Note about specific visual treatment
- Note about animations/transitions
- Note about specific component choices (e.g., "use Combobox not Select for country")

---

<!-- 
INSTRUCTIONS FOR FRONTEND:
1. Copy this template to .stania/ui-specs/<component-name>.md
2. Fill in the fields above
3. Run /st-ui <component-name>
4. Review in Storybook
5. If changes needed → update spec → re-run /st-ui

You do NOT write code. Only this spec.
The layout catalog is at .stania/layout-catalog.md
-->
