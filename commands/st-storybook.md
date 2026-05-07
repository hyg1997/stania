Auto-generate Storybook stories from UI specs and existing components.

## Usage

- `/st-storybook` — Generate stories for all components without stories
- `/st-storybook <name>` — Generate story for specific component
- `/st-storybook --init` — Setup Storybook in the project

## --init: Setup

```bash
npx storybook@latest init --type nextjs 2>&1 | tail -10
```

Configure for dark theme if project uses dark mode. Add to `.storybook/preview.ts`.

## Step 1: Find components without stories

```bash
# Find all components
COMPONENTS=$(find apps/web/src/features -name "*.tsx" -not -name "*.test.*" -not -name "*.stories.*" -not -name "*.client.*" -not -name "*.skeleton.*" -not -name "*.error.*" 2>/dev/null)

# Find existing stories
STORIES=$(find apps/web/src -name "*.stories.tsx" 2>/dev/null)

# Diff to find missing
```

Report: "N components without stories: [list]"

## Step 2: Read UI spec (if exists)

For each component, check `.stania/ui-specs/<name>.md`:
- Layout type → determines story structure
- States → maps to story variants
- Interactions → maps to play functions
- Contract → maps to mock data

If no UI spec: read the component source to infer states and props.

## Step 3: Generate story

```typescript
import type { Meta, StoryObj } from '@storybook/react';
import { ComponentName } from './component-name';

const meta: Meta<typeof ComponentName> = {
  title: 'Features/<Feature>/<ComponentName>',
  component: ComponentName,
  tags: ['autodocs'],
};
export default meta;

type Story = StoryObj<typeof ComponentName>;

export const Default: Story = {
  args: { /* from contract types or UI spec */ },
};

export const Loading: Story = {
  args: { isLoading: true },
};

export const Empty: Story = {
  args: { data: [] },
};

export const Error: Story = {
  args: { error: new Error('Something went wrong') },
};

export const Mobile: Story = {
  parameters: { viewport: { defaultViewport: 'mobile1' } },
  args: { /* same as Default */ },
};
```

### Story rules

- Always include 4 state stories: Default, Loading, Empty, Error
- Add Mobile viewport story
- Use contract types for args (no `any`)
- Add interaction tests for key user flows:
  ```typescript
  export const WithInteraction: Story = {
    play: async ({ canvasElement }) => {
      const canvas = within(canvasElement);
      await userEvent.click(canvas.getByRole('button', { name: /submit/i }));
      await expect(canvas.getByText('Success')).toBeVisible();
    },
  };
  ```
- Use MSW handlers for API-dependent stories (from contracts/generated/mocks)

## Step 4: Verify

```bash
npx storybook build --test 2>&1 | tail -10
```

If build fails: fix story, retry once.

## Step 5: Commit

```bash
git add "*.stories.tsx"
git commit -m "docs(<name>): add storybook stories from ui-spec"
```

## Report

```
=== STORYBOOK ===
Generated: 3 stories (order-list, order-detail, order-form)
Variants: 5 per story (default, loading, empty, error, mobile)
Build: PASS

NEXT: Run `pnpm storybook` to preview.
```

## Rules

- Never generate stories for utility files or hooks
- Always include all 4 states + mobile
- Use contract types — no mocked primitives
- If Storybook not installed: suggest --init first
- Truncate all output
