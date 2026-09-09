# Driving Drumlin

[Drumlin](https://github.com/Intelliger-ai/drumlin) reads a Next.js codebase,
builds a graph of the product's screens, states, actions and transitions, and
runs deterministic rules over that graph. It answers the structural questions
in [SKILL.md](SKILL.md) — reachability, dead ends, missing states across a
whole section — with certainty rather than with grep.

Everything runs locally. No source leaves the machine and there is no model
call in the analysis path, so findings are reproducible and are not opinions.

## Is it here?

```bash
command -v drumlin >/dev/null && drumlin --version
```

If it is absent, do not install it uninvited. This skill works without it.
Mention it once if the project is Next.js and the problems you are finding are
structural.

If it is present but the project has no `.drumlin/`, `drumlin check` still
works — but nothing is stored, so the `UX-` numbers last only as long as the
output and no decision can be recorded against them. Suggest `drumlin init`,
which creates a directory meant to be committed.

## Reading the state of things

```bash
drumlin check                      # every open finding
drumlin check --changed            # only findings from files you touched
drumlin check --format json        # for parsing
drumlin check --severity high      # high and critical only
drumlin graph                      # the screen graph as an outline
drumlin rules                      # the active rules
```

`--changed` narrows what you are shown, not what was examined. Analysis is
always whole-graph, because reachability is global — a screen can be orphaned
by an edit three directories away. Bare, it means the git working tree; given
a revision — `drumlin check --changed main` — it means everything since that
point, which is the one to use when reviewing a branch.

Useful flags across commands:

| Flag | Effect |
| --- | --- |
| `--app <path>` | pick the app; required when a monorepo holds several |
| `--format <fmt>` | `text` (default) or `json` |
| `--severity <s>` | floor: `info`, `low`, `medium`, `high`, `critical` |
| `--rule <ids>` | comma-separated rule ids, to check one thing |
| `--limit <n>` | cap the listing |
| `--fail-on <s>` | exit non-zero when a finding reaches this severity |
| `--accepted` | include findings a human has already accepted |
| `--no-daemon` | run in-process; use when you suspect a stale index |
| `--no-cache` | re-index from source, ignoring the derived cache |

## The ten rules

All deterministic or structural. Nothing here is a model judgement.

| Rule | Severity | What it catches |
| --- | --- | --- |
| `flow.destructive.no-confirm` | critical | an irreversible action with no confirmation and no undo |
| `state.route.no-error` | high | a failed request fails silently |
| `async.mutation.no-feedback` | high | a mutation showing neither progress nor failure |
| `state.route.no-loading` | medium | a route fetches but renders nothing while waiting |
| `state.route.no-not-found` | medium | a dynamic route has no answer for a bad id |
| `flow.dead-end` | medium | a screen a user can reach but not leave |
| `flow.orphan` | medium | a screen nothing links to |
| `context.navigation.drops-search-params` | medium | navigation that discards filters |
| `ds.duplicate-primitive` | low | a primitive reimplemented beside the design system's |
| `component.select-overload` | low | a select bound to an unbounded collection |

Rules about roles and permissions are deliberately absent. Drumlin can see
that a route checks a role but not which roles *should* reach it, so that is a
question it asks — via `drumlin context` — rather than a rule it enforces.

## Working an issue

Start from the packet, never from the one-line message:

```bash
drumlin check                 # find the id
drumlin graph --format json   # the neighbourhood, if you need more
```

A finding message says what is wrong. The packet behind it carries the
acceptance criteria, the evidence, the local graph, which files to start in,
and the command that re-tests it. Over MCP that is `drumlin_get_issue`.

Findings describe the product, not the code. `flow.orphan` does not mean a
file is unused — it means a user cannot get to a screen. `state.route.no-error`
does not mean a `try`/`catch` is missing — it means a screen that fetches has
nothing to show when the fetch fails. Fix the experience, not the rule.

## What you may not do

**You may never make a finding go away.**

`drumlin accept` is the only action that stops a finding being reported, so it
is the only one that requires a person. It refuses to run without an
interactive terminal, refuses callers that look like an agent or CI, requires
a written reason, and is not exposed over MCP at all. Do not try to route
around it. The refusal is the feature: an agent that can silence a finding
will eventually silence one in order to finish a turn.

Two things you can do instead, and should.

### If you fixed it, say so and have it checked

```bash
drumlin claim UX-0007 --note "added error.tsx at the /reports segment"
```

This re-derives the graph from source, re-runs the rule, and reports whether
the finding is actually gone. It exits non-zero if it is not — so a failing
claim tells you your fix did not work, which is worth knowing before you end
the turn. It does not read your note, so there is nothing to phrase carefully.

**Do not add `--format json` to `claim` or `verify` if you intend to check the
exit code.** In JSON mode both commands exit 0 whatever the outcome, so a fix
that did not work looks like success. Read the `outcome` field instead, or
leave the format alone and trust the exit code. This is the one place where
the convenient thing quietly reports the wrong answer.

Verification has four outcomes, and only the first resolves anything:

| Outcome | Meaning |
| --- | --- |
| `gone` | the rule no longer fires against fresh source — resolved |
| `present` | still there; your fix did not land |
| `vanished` | the subject was deleted rather than fixed |
| `inconclusive` | the rule was disabled, so nothing was proven |

`vanished` and `inconclusive` exist because they are the two ways to make a
finding quiet without improving anything. Do not reach for either. They are
recorded under those names and read as exactly what they are.

Only Drumlin's verifier can mark anything `resolved`. Your claim is a hint
about what to test, not proof.

### If you think the finding is wrong, argue

```bash
drumlin propose UX-0012 --reason "this route is an email entry point, not orphaned"
```

The proposal sits on the issue with your reasoning intact and changes nothing
until a person grants it with `drumlin accept` or turns it down with
`drumlin decline`. Say in your reply that you proposed it, so the human knows
there is something waiting.

Being right that a finding is a false positive is common. Acting on being
right is the thing you must not do.

## The MCP tools

When Drumlin's plugin is installed and the project is activated, four
read-only tools are available. Prefer them over shelling out — they talk to a
warm index and come back much faster.

| Tool | Input | Use it |
| --- | --- | --- |
| `drumlin_project_summary` | none | before structural changes: screens, entry points, route sections, open issues by severity, and the design-system primitives that already exist |
| `drumlin_get_flow` | `route` | before changing navigation: what links in, what it links out to, which loading/error/not-found states cover it |
| `drumlin_get_issue` | `id` | when handed an issue id: the full packet |
| `drumlin_check_changed` | `severity` (optional) | after editing: findings attributable to what you touched |

`drumlin_get_flow` is the one that earns its keep. Inbound links live in
whatever imports the screen — a table column definition, a sidebar three
directories away — and reading the page file tells you nothing about them.
Rename or remove a route without checking and you leave a dead link the type
checker will not catch.

All four return prose, not JSON. Read the text; do not try to parse it.

They also refuse to run unless the project has been initialised *and*
activated. If a tool comes back saying the project is not activated, that is a
human's decision to make — `drumlin activate` is how a person says they want
this repository analysed. Report it and fall back to the CLI, which is not
gated, or to reading the code yourself.

There is no tool for accepting, closing, or resolving. That is not an
oversight.

## Setup, if a human asks you to do it

```bash
npm install -g drumlin      # needs Node 22 or newer
cd your-next-app
drumlin init                # creates .drumlin/, meant to be committed
drumlin check
```

For the editor integration:

```bash
drumlin connect cursor      # install the plugin, once per machine
drumlin activate            # switch it on, per project
```

Two things sit between those and neither is Drumlin's to do: **"Allow local
plugin imports"** must be enabled in Cursor's dashboard settings, and Cursor
must be **restarted**. Without both, the hooks are installed but never fire.

`drumlin activate` is separate on purpose. A plugin installs once and its
hooks fire in every workspace you open, which would make "I want this on this
project" and "I want this reading every repository I own" the same decision.
The flag lives in the committed config, so switching it on is a reviewable
diff rather than local state on one laptop.

## Sending issues elsewhere

```bash
drumlin export --to linear --out issues.csv
drumlin export --to github --out issues.sh    # a gh issue create script
drumlin export --to markdown
drumlin export --to linear --new              # only what has not been sent yet
```

Use `--to`. On this one command `--format` is an alias for the export target
rather than the output format, so `--format json` fails with an unknown
target. Without `--out` the body goes to stdout.

Exporting does not close anything in Drumlin. An issue closed in Linear is
still open here until it is verified.

## When something looks wrong

**Findings that contradict what you just read in the source.** The index may
be stale. Re-run with `--no-daemon`, which analyses in-process from current
source. If that disagrees with the daemon, say so in your reply — it is worth
a human knowing.

**"Found N Next.js apps. Choose one with --app".** Deliberate. Analysing an
arbitrary one produces a report that looks plausible and describes a different
product.

**`flow.orphan` on a route reached by emailed link or bookmark.** Correct, in
that nothing in the source links to it, which is all Drumlin can see. This is
the textbook case for `drumlin propose`. A human can list it under
`entryPoints` in `.drumlin/config.yaml`, after which it is reachable by
definition.

**A rule that is wrong about this codebase in general.** Not yours to decide.
Report it and let a human disable it in `.drumlin/config.yaml`.

## What Drumlin does not do

Do not assume these exist:

- **No browser automation.** `drumlin check --observed <file>` diffs a
  recorded browser run against the source graph, but Drumlin does not produce
  that recording — the Playwright adapter is not built. If you have your own
  browser tool, use it directly.
- **Next.js only.** Other frameworks parse but yield almost nothing.
- **No role or permission rules.** `drumlin context` proposes a model and
  states what it cannot know; it does not enforce.
