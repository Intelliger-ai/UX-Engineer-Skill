---
name: ux-engineer
description: >-
  Reviews and repairs the user experience of a web application the way a UX
  engineer would: checking that every surface which waits, fails or comes back
  empty says so; that every route can be reached and left; that mutations
  report their outcome; and that destructive actions ask first. Use after
  adding or changing a page, route, form, button, modal, dialog or data fetch;
  when asked for a UX review, a design pass, or an accessibility check; when
  someone says a flow feels broken, janky, confusing or unfinished; and before
  calling a feature done. Drives the Drumlin CLI for whole-graph structural
  analysis when it is installed.
---

# UX Engineer

Most user-experience defects are invisible in the file you are editing. They
live between files: a page nothing links to, a fetch with no failure branch, a
button that fires a mutation and never says whether it worked. The file reads
fine on its own. The product is broken.

This is the failure mode of fast, generated code specifically. Code written a
screen at a time is coherent a screen at a time. Nobody wrote the connective
tissue, because no single file is where it belongs.

So the discipline here is not "write better components." It is: after changing
anything a user touches, look one level out from the file you changed, and ask
what happens to a person when things do not go well.

Everything below is reasoning you can do by reading code. No tool is required
and nothing needs installing. If the [Drumlin](https://github.com/Intelliger-ai/drumlin)
CLI happens to be present it will answer the structural questions faster and
with certainty, but it is an accelerator, not a prerequisite — do not stop, and
do not install anything uninvited, if it is absent.

## When to run this

Run the loop below after you:

- add or change a route, page, or layout
- add a data fetch, query, or `await` that renders something
- wire a mutation, form submission, or any button that changes server state
- add navigation: a link, a redirect, a router call, a modal
- add a destructive action: delete, archive, cancel, revoke, remove
- finish a feature and are about to say it is done

Also run it when someone reports a flow as slow, confusing, janky, broken, or
unfinished. Those words usually describe a missing state, not a bug.

## While you build

Most of this is cheapest at the moment of writing and expensive an hour later,
because by then the fix is a rewrite and the context is gone. These are the
moves that cost nothing in the same edit. Apply them as you go; do not defer
them to the review pass, and never leave them as a `TODO`.

| When you write | Do this in the same edit |
| --- | --- |
| a control that triggers a request | disable it and show it is working |
| a `catch` | decide what the user sees and what they can do next |
| `router.push` from a screen with filters or a search | carry the search params through |
| a `<select>` bound to an array of unknown length | add search or grouping |
| a destructive handler | add a confirmation that names the target |
| a new component | search for the existing primitive first |
| a form field | set `autocomplete`, then ask if it can be inferred or removed |
| a terminal or success screen | add the onward action |
| a dynamic route | add the not-found path |
| a second primary button | demote one of them |
| a fetch | write the empty and error branches beside the loaded one |

[laws.md](laws.md) opens with a table mapping what you are building — a form,
a table, a checkout, a dashboard — to the principles that apply to it. Read
that row before starting something substantial. It takes a moment and changes
what you write.

## The loop

After the change is made, review it:

```
1. Neighbourhood  — find what connects to the thing you changed
2. Four questions — states, reachability, feedback, consequence
3. Verify         — run it if you can, don't assume
4. Report         — severity, location, and the fix
```

### 1. Establish the neighbourhood

Before judging a screen, find out what it is part of. You cannot see any of
this from inside the file:

```bash
# What links here? (inbound — the reachability question)
rg -n "href=[\"'\`][^\"'\`]*your-route|push\(['\"\`][^'\"\`]*your-route" --glob '!node_modules'

# What does this import, and who imports it?
rg -n "from ['\"].*ComponentName" --glob '!node_modules'

# Does this section already have shared error/loading handling?
fd -H '^(error|loading|not-found)\.(tsx|jsx|ts|js)$' path/to/section
```

Two things matter most. **Inbound links**, because a route with none can only
be reached by typing the URL. And **section-level handling**, because in
Next.js an `error.tsx` or `loading.tsx` at a segment boundary covers every
screen beneath it — the fix for eight screens is often one file, and adding
eight local try/catches instead is the wrong shape.

If Drumlin is installed, it answers both directly and far better. See
[drumlin.md](drumlin.md).

### 2. The four questions

Ask these of every surface you touched. They are ordered by how much damage
the answer causes.

Each rests on an established principle, and [laws.md](laws.md) has the
twenty-one of them written out with what each means in code. Reach for it when
you need to explain *why* a finding matters to someone inclined to skip it —
"the screen is silent for two seconds" is an observation, and "attention
drifts past about four hundred milliseconds, which is the Doherty Threshold"
is an argument. Do not cite a law you are not actually applying.

**Consequence — can the user destroy something by accident?**
A destructive action needs a confirmation that names the specific thing being
destroyed ("Delete invoice INV-2043?" not "Are you sure?"), and the confirming
button must carry the verb ("Delete", not "OK"). If it cannot be undone, say
so. If it can, prefer an undo toast over a dialog — it interrupts nobody and
is safer, because the dialog people click through reflexively protects no one.

**Feedback — does the user learn what happened?**
Every mutation has three moments and owes the user all three: it is running
(disable the trigger, show it is working), it succeeded (say so, or make the
change visibly land), it failed (surface the reason and leave their input
intact). The common defect is a button that does all its work correctly and
tells the user nothing, so they click it again.

**States — what does this show when things are not fine?**
Anything that awaits, fetches, or renders a list owes the user four renders:

| State | Owed when | The usual defect |
| --- | --- | --- |
| Pending | the request is in flight | blank screen, or layout that jumps when data lands |
| Empty | the request succeeded with nothing | "no results" indistinguishable from broken |
| Error | the request failed | fails silently; user sees a permanent spinner |
| Loaded | the happy path | the only one anybody wrote |

Empty and error are different and must look different. A list that renders
nothing because there are no invoices, and a list that renders nothing because
the API 500'd, are the same pixels and completely different problems. The
empty state should also say what to do next — an empty list with a "Create
your first invoice" action is a feature; an empty list with the word "Empty" is
a dead end.

An error state must contain a way forward: retry, go back, or contact. A red
message with no action is a wall.

For dynamic routes (`/orders/[id]`), a bad or stale id is not an edge case —
it arrives via old bookmarks and shared links constantly. It needs a real
not-found answer, not a crash and not an infinite spinner.

**Reachability — can the user get here, and get out?**
A screen needs at least one inbound link from somewhere a user would look, and
at least one way onward that is not the browser back button. Watch for the
terminal-success dead end: a "Payment complete" screen with no link back into
the product is the most common version of this.

Also check that navigation preserves context. If a user filters a table, opens
a row, and comes back to an unfiltered table, their work was thrown away. In
practice this means carrying `searchParams` through router calls rather than
pushing a bare path.

### 3. Verify

Reading is not verifying. If you have a browser tool available, use it: load
the screen, and force the states you just claimed to handle.

The states that are actually broken are the ones nobody can trigger by
clicking normally, so trigger them deliberately:

- **Error** — throw in the fetch, or block the request in devtools
- **Pending** — throttle the network; a state that only exists for 80ms on
  localhost is untested, and is exactly the state a real user on a train sees
- **Empty** — filter for something that does not exist
- **Not found** — visit the route with a garbage id

If you have no browser, say in your report that the review was static. Do not
imply you exercised something you only read.

### 4. Report

Lead with what a user loses, not with the rule. Group by severity, and give
the file, the fix, and enough reasoning that someone can disagree with you.

```
UX review — checkout flow

Critical
  Delete account has no confirmation — a misclick is unrecoverable.
    src/app/settings/account/page.tsx:88
    Fix: confirmation dialog naming the account, plus a typed confirmation.

High
  Payment failures are silent. The catch logs and returns, so a declined card
  looks identical to a successful one.
    src/app/checkout/actions.ts:41
    Fix: return the error to the form and render it near the submit button.

Medium
  Order history has no empty state; a new user sees a bare table header.
    src/app/orders/page.tsx:24
    Fix: empty state explaining there are no orders yet, linking to the catalog.
```

Severity is about the cost to the user, not the effort to fix:

- **Critical** — data loss, an unrecoverable action, or the user is stuck with
  no way out
- **High** — a failure the user cannot see, or a screen they cannot reach
- **Medium** — a missing state, lost context, or feedback they have to guess at
- **Low** — polish, copy, alignment

Cap the report. Fifteen findings that matter beat sixty that include every
missing `aria-label` in the codebase. If you found a large systemic issue, say
it once at the section level rather than repeating it per file.

## Fix the experience, not the symptom

Every check here describes something a user feels. It is always possible to
satisfy the letter of the check and leave the product worse, and that is the
main way this goes wrong:

- Adding a link nobody will ever click, so the page is technically reachable
- Wrapping a fetch in `try { } catch { }` that swallows the error, so it no
  longer fails "silently" because it no longer fails
- A spinner shown during a request that has no failure branch, so it spins
  forever when the request dies
- A confirmation dialog on a harmless action, training users to dismiss dialogs
  without reading them, which is what makes the dangerous one dangerous
- Toasting every success until the toasts are wallpaper

If the honest fix is bigger than the finding — the flow is wrong, the screen
should not exist, the empty state depends on a product decision nobody has
made — say that instead of papering over it. Ask. A question is a better
deliverable than a plausible wrong answer about someone's product.

## What not to do

**Do not mass-refactor while reviewing.** Fix what you were asked to fix and
report the rest. A UX review that arrives as a 40-file diff cannot be reviewed
and will not be merged.

**Do not add dependencies for this.** Loading, empty, and error states are
markup. If the project has a design system, use its primitives; the second
most common way to add UX debt is writing a new button next to the existing
one. Look before you build.

**Do not invent product copy for decisions you cannot make.** "No invoices
yet" is safe. Inventing what an empty state should offer, what a plan includes,
or what an error tells the user to do next can be wrong in ways that matter.

**Do not treat accessibility as a separate pass.** The high-value subset
belongs in the same loop, because these are UX failures with a narrower blast
radius: focus moves into a modal when it opens and returns when it closes,
Escape closes it, interactive things are `button` and `a` rather than `div`
with an `onClick`, form inputs have associated labels, errors are tied to
their field, and content that changes without navigation is announced. The
exhaustive list is in [catalogue.md](catalogue.md).

## When Drumlin is installed

[Drumlin](https://github.com/Intelliger-ai/drumlin) builds a graph of a Next.js
app's screens, states, actions and transitions, and runs deterministic rules
over it. It answers the structural questions in this skill — reachability, dead
ends, missing states across a whole section — with certainty rather than
grep.

Check for it once, at the start:

```bash
command -v drumlin >/dev/null && drumlin check --format json
```

If it is there, run it and treat its findings as the structural half of your
review, then use your own judgement for everything it cannot see: copy, visual
hierarchy, whether the flow makes sense at all.

If it is not there, do not install it uninvited and do not stop — this skill
stands on its own. Mention it once if the project is Next.js and the problems
you are finding are structural, since that is what it is for.

One rule matters more than the rest: **you may never make a Drumlin finding go
away.** You cannot accept, close, or resolve an issue; `drumlin accept` refuses
to run for an agent by design. If you fixed something, run `drumlin claim <id>`
and let the verifier decide. If you believe a finding is wrong, run
`drumlin propose <id> --reason "..."` and let a person rule on it.

Full command reference, the MCP tools, and the issue lifecycle are in
[drumlin.md](drumlin.md).

## Reference

- [catalogue.md](catalogue.md) — the full failure catalogue: what to look for,
  the code signal that reveals it, and the fix. Read when doing a deep or
  whole-app review rather than checking a single change.
- [laws.md](laws.md) — the twenty-one Laws of UX. Opens with a table mapping
  what you are building to the laws that apply, and the five that matter most
  under speed. Each law then gives the principle, what it means in code,
  explicit directives for what to do while writing, the check, and the way
  fast AI-assisted development specifically breaks it. Read the relevant row
  before building something substantial, and the full entry when you need the
  reasoning behind a finding.
- [drumlin.md](drumlin.md) — driving the Drumlin CLI and its MCP tools:
  commands, flags, exit codes, and who is allowed to close an issue. Only
  relevant if Drumlin is installed.

---

*This skill is provided as-is, with no warranty of any kind and no liability
accepted for any outcome of following it. Its output is advisory and can be
wrong. A human is responsible for reviewing and accepting any change made on
its advice. See the DISCLAIMER in the source repository.*
