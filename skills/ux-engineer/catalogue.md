# The failure catalogue

Read this for a deep or whole-application review. For a single change, the
four questions in [SKILL.md](SKILL.md) are enough.

Each entry gives the defect, the signal that reveals it in source, and the
fix. Signals are `rg` patterns and React/Next.js idioms; adapt them to the
stack in front of you. A signal is a place to look, not a verdict — confirm
before reporting.

---

## 1. Asynchronous states

### Fetch with no pending state
The screen renders nothing, or renders a broken layout, until data lands.
Worst on slow connections, invisible on localhost.

*Signal*: an `await` in a server component, or `useEffect`/`useQuery` in a
client one, where no branch renders for the in-flight case.

```bash
rg -n "useEffect\(" -A6 --glob '*.tsx' | rg -B3 "fetch\(|axios|\.get\("
fd -H '^page\.tsx$' src/app | while read -r p; do
  [ -f "$(dirname "$p")/loading.tsx" ] || echo "no loading.tsx beside $p"
done
```

*Fix*: a skeleton matching the final layout's dimensions, so nothing jumps
when data arrives. In the App Router, `loading.tsx` at the segment covers
every screen below it. Prefer that over per-component spinners.

### Fetch with no error state
A failed request produces a permanent spinner or a blank region. The user
cannot tell whether it is slow or dead.

*Signal*: a promise with no `.catch`, no error boundary above it, and no
`isError` branch. Also `catch` blocks whose entire body is `console.error`.

```bash
rg -n "catch\s*\([^)]*\)\s*\{\s*(console\.(log|error)[^}]*)?\}" --glob '*.{ts,tsx}'
```

*Fix*: an `error.tsx` at the segment boundary, with a `reset()` retry. Per
screen, an error branch that states what failed and offers a way forward.
Never an empty catch.

### No distinction between empty and error
Both render nothing, so a working product with no data looks identical to an
outage.

*Fix*: separate branches. Empty says what the thing is and offers the action
that creates the first one. Error says it failed and offers retry.

### Dynamic route with no not-found
`/orders/[id]` with a deleted or mistyped id crashes, spins, or renders a
skeleton of undefined fields. Arrives constantly via stale bookmarks.

*Signal*: `params.id` used to fetch, with no `notFound()` call and no
`not-found.tsx` in the segment.

```bash
rg -n "params" --glob 'src/app/**/\[*\]/**/page.tsx' -l | while read -r p; do
  rg -q "notFound\(\)" "$p" || echo "no notFound() in $p"
done
```

*Fix*: call `notFound()` when the record is missing, and give the segment a
`not-found.tsx` that links somewhere useful.

### Stale data presented as fresh
Cached or optimistic values shown with no indication they may be out of date,
usually after a background refetch fails.

*Fix*: keep showing the stale data — blanking it is worse — but mark it, and
surface that the refresh failed with a retry.

### Waterfalls
Sequential awaits that could run together turn one slow screen into four.

*Signal*: consecutive `await` calls in one scope with no data dependency
between them.

*Fix*: `Promise.all`, or move fetches to where they can stream in parallel.

---

## 2. Navigation and reachability

### Orphan screen
A route exists that nothing links to. Reachable only by typing the URL, so in
practice it does not exist.

*Signal*: a route whose path never appears in an `href` or router call.

```bash
rg -n "href=|router\.(push|replace)\(|redirect\(" --glob '!node_modules' -o
```

*Fix*: link it from where a user would look for it, or delete it. Legitimate
exceptions are entry points reached from email, QR, or external systems —
those are real, and should be recorded as such rather than "fixed."

### Dead end
A screen a user can reach with no way onward except the browser back button.
Most common on terminal screens: order confirmed, payment complete, signup
finished.

*Fix*: every terminal screen gets an onward action — back to the thing they
were doing, or the obvious next task.

### Navigation that drops context
A user filters, sorts, paginates, opens a row, returns — and the table has
reset. Their work is gone.

*Signal*: `router.push('/path')` with a bare string where the current URL
carries query state.

```bash
rg -n "router\.(push|replace)\(['\"\`]/" --glob '*.{ts,tsx}'
```

*Fix*: carry `searchParams` through the navigation, and treat URL state as
the source of truth for filters so it survives reload and sharing.

### Back button does not do what it looks like it does
Modals that do not register history, wizards that jump to the start, replaced
history that skips a step.

*Fix*: `push` when a step should be reversible, `replace` only when it should
not. Make routed modals a real route so back closes them.

### Redirect loops and silent bounces
An auth guard redirecting to a login that redirects back. Or a route that
quietly sends the user elsewhere with no explanation of why.

*Fix*: break the cycle on a state flag, and when a redirect is a
consequence of permission or state, say so on arrival.

### Full page loads inside an app
Raw `<a href>` for internal navigation drops client state and flashes white.

*Signal*: `<a href="/` in a framework that has a `Link`.

*Fix*: framework `Link`. Reserve `<a>` for external and for downloads.

---

## 3. Mutations and feedback

### No pending state
The trigger stays enabled and unchanged while the request runs, so the user
clicks it again.

*Signal*: an `onClick` or `action` calling a mutation, with no `isPending`,
`disabled`, or `useTransition` in the same component.

*Fix*: disable the trigger and show it is working. Keep the label stable —
swapping the text to "Saving…" and back causes the button to resize.

### Double submission
A second click fires a second write. Duplicate charges, duplicate records.

*Fix*: disable on submit, and guard on the server too. Client-side alone is
not a guarantee.

### Silent success
The write worked, nothing changed visibly, the user assumes it failed.

*Fix*: make the result land in the UI. Prefer the change itself becoming
visible over a toast announcing it.

### Silent failure
The write failed, the UI proceeded anyway. The worst defect in this document,
because the user believes their data is saved.

*Signal*: a mutation whose rejection path is a bare `console.error`, or an
action returning `void` where the caller cannot know it failed.

*Fix*: surface the failure where the user is looking — near the control they
used, not in a corner toast that disappears in four seconds.

### Optimistic update with no rollback
The UI shows success immediately and never reverts when the server rejects.

*Fix*: if optimistic, always implement the reconcile-and-revert path, and tell
the user when it reverts.

### Input lost on failure
The form clears or the modal closes on error, destroying what the user typed.

*Fix*: never clear on failure. Keep the values, mark the fields, let them
retry from where they are.

---

## 4. Destructive actions

### No confirmation
Delete, archive, revoke, cancel, remove — fired directly from a click.

*Signal*: a handler calling a `DELETE` or a `delete*`/`remove*` action with no
dialog component and no confirmation state in the same file.

```bash
rg -n "(delete|remove|destroy|revoke|archive|cancel)[A-Z]\w*\(" --glob '*.{ts,tsx}'
```

*Fix*: confirm, or make it undoable. Undo is usually better UX and always
better than a dialog people dismiss reflexively.

### Confirmation that does not identify the target
"Are you sure?" with no name. In a list, the user cannot tell which row they
are about to destroy.

*Fix*: name the specific object, and put the verb on the button — "Delete
invoice INV-2043" and a button reading "Delete", never "OK".

### Consequence not stated
The user is not told the deletion cascades, is permanent, or affects others.

*Fix*: state the blast radius in the dialog, and require typed confirmation
for the genuinely irreversible.

### Destructive styled as ordinary
A delete that looks like every other button, sitting next to the one people
actually want.

*Fix*: distinct treatment, and physical separation from the safe action.

---

## 5. Forms

- **Validation only on submit** — the user fills eight fields to learn the
  second was wrong. Validate on blur, keep submit-time as the backstop.
- **Errors not attached to fields** — a summary at the top with no indication
  which input is wrong. Tie each message to its field with `aria-describedby`
  and move focus to the first invalid one.
- **Unlabelled inputs** — placeholder used as label, so the label vanishes
  once typing starts and screen readers get nothing. Use a real `label`.
- **Unexplained requirements** — password rules revealed only by rejection.
  State constraints up front.
- **No unsaved-changes guard** — a long form abandoned by a stray click.
  Warn before navigating away from a dirty form.
- **Reset on error** — see *Input lost on failure* above.
- **Wrong input affordances** — free text for a date, no `inputMode` for
  numbers, autocomplete off on address fields.
- **Disabled submit with no reason** — a greyed button that never explains
  what is missing. Prefer enabling it and showing errors on attempt.

---

## 6. Modals, dialogs, overlays

- Focus does not move into the dialog when it opens.
- Focus is not restored to the trigger when it closes.
- Focus is not trapped, so tabbing wanders behind the overlay.
- `Escape` does not close it.
- Background scrolls behind it, or the page jumps as the scrollbar disappears.
- Stacked modals with no coherent dismissal order.
- Content that should be a page is a modal: deep-linkable, shareable, or
  long-form content trapped in an overlay that cannot be linked to.

Prefer the platform `dialog` element or a headless library primitive; these
behaviours come free and are extremely easy to get wrong by hand.

---

## 7. Lists, tables, collections

- **No empty state** — a bare header row.
- **No pagination or virtualisation** — a list that renders every row and
  dies at scale.
- **Sort or filter state not in the URL** — cannot be shared or survived a
  reload.
- **Row actions with no bulk equivalent** — deleting fifty things one at a
  time.
- **No indication of total** — the user cannot tell whether they are seeing
  everything.
- **Layout shift on load** — rows arriving change column widths.
- **Select with far more options than a person can scan** — a dropdown of six
  hundred countries. Needs search, grouping, or a different control.

---

## 8. Accessibility

The subset that is high-value and cheap. These are UX failures that happen to
have a narrower blast radius; treat them in the same pass, not a separate one.

**Semantics**
- `div` with `onClick` instead of `button`: not focusable, not keyboard
  operable, invisible to assistive technology.
  ```bash
  rg -n "<div[^>]*onClick" --glob '*.{tsx,jsx}'
  ```
- Headings used for size rather than structure; skipped levels.
- Icon-only buttons with no accessible name.
  ```bash
  rg -n "<button[^>]*>\s*<(svg|Icon)" --glob '*.{tsx,jsx}'
  ```

**Keyboard**
- Anything reachable by mouse must be reachable by keyboard, in a sensible
  order, with a visible focus ring. Removing the outline with no replacement
  is the single most common violation.
  ```bash
  rg -n "outline:\s*(none|0)" --glob '*.{css,scss,tsx}'
  ```
- Positive `tabindex` values, which reorder focus unpredictably.

**Focus management**
- Focus after client-side route change: it should land somewhere meaningful,
  not stay on the link that was clicked.
- Focus after a list item is deleted: it should move to a neighbour, not be
  lost to `body`.

**Announcements**
- Content that changes without navigation — validation results, toasts, live
  counts, async loads — needs `aria-live` or it is silent to a screen reader.

**Perceivable**
- Colour as the only carrier of meaning: a red border with no message, status
  shown only as a coloured dot.
- Contrast below 4.5:1 for body text.
- Text that breaks or clips at 200% zoom.
- Motion that ignores `prefers-reduced-motion`.

---

## 9. Perceived performance

- **Layout shift** — content jumping as images, fonts, or data arrive. Reserve
  space: dimensions on media, skeletons shaped like their content.
- **Blocking the first render on non-critical data** — the whole page waits on
  a sidebar widget. Stream it separately.
- **No feedback under ~400ms of latency** — anything slower than that needs to
  acknowledge the click immediately, even before the result exists.
- **Spinners for fast operations** — a flash of spinner is noisier than no
  spinner. Delay it a few hundred milliseconds, then show it.
- **Unbounded waiting** — every request needs a timeout and a failure story.

---

## 10. Copy

- Error messages naming internals: status codes, exception text, table names.
- "Something went wrong" with no indication of what or what to do.
- Inconsistent vocabulary for one concept across screens — "organisation"
  here, "workspace" there, "team" in the settings.
- Buttons labelled by mechanism rather than outcome: "Submit" instead of
  "Send invoice".
- Destructive confirmations phrased so "Yes" is ambiguous.

---

## 11. Responsive and input modality

- Touch targets below roughly 44px.
- Hover-only affordances — a menu that only appears on hover is unreachable
  on touch.
- Horizontal overflow at narrow widths, usually a wide table with no strategy.
- Fixed elements colliding with the on-screen keyboard.
- Layouts that assume a mouse: drag-only interactions with no alternative.
