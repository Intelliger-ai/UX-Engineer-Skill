# UX Engineer Skill

[![Skill](https://img.shields.io/badge/agent%20skill-SKILL.md-blue)](skills/ux-engineer/SKILL.md)
[![Agents](https://img.shields.io/badge/agents-Claude%20Code%20%C2%B7%20Codex%20%C2%B7%20Cursor-blue)](#install)
[![License](https://img.shields.io/badge/license-Apache--2.0-blue)](LICENSE)

An agent skill that makes a coding agent review its own user-experience work
before calling it done — and, when [Drumlin](https://github.com/Intelliger-ai/drumlin)
is installed, drive a real analysis of the application's screen graph instead
of guessing.

One `SKILL.md`, installed into Claude Code, Codex, or Cursor.

## The problem it addresses

Coding agents write a screen at a time, and the code is coherent a screen at a
time. What goes missing is the connective tissue, because no single file is
where it belongs:

- The page nothing links to, reachable only by typing the URL.
- The fetch with no failure branch, so a dead API looks like a slow one.
- The button that fires a mutation and never says whether it worked, so the
  user clicks it again.
- The delete with no confirmation, one misclick from unrecoverable.
- The table you filtered, opened a row from, and came back to unfiltered.

None of these are visible in the file being edited. They are visible one level
out — and one level out is exactly what an agent focused on a diff does not
look at. This skill makes it look.

## What it does

The skill installs a review loop the agent runs after touching anything a user
interacts with:

```
1. Neighbourhood  — find what connects to the thing that changed
2. Four questions — consequence, feedback, states, reachability
3. Verify         — force the error and empty states, don't assume them
4. Report         — severity, location, and the fix
```

The four questions are ordered by how much damage the answer causes. *Can the
user destroy something by accident* comes before *does this have a loading
skeleton*, because a missing confirmation costs more than a missing spinner.

Behind that sits a catalogue of about seventy specific defects across
asynchronous states, navigation, mutations, destructive actions, forms,
modals, collections, accessibility, perceived performance, copy, and
responsive behaviour — each with the code signal that reveals it and the fix.
The agent reads the catalogue only for deep reviews, so the routine case stays
cheap in context.

### The twenty-one laws

The checks are not arbitrary. Each rests on an established principle from the
Laws of UX, and [laws.md](skills/ux-engineer/laws.md) writes all twenty-one out
— not as a design-theory glossary, but as what each one means in code and the
check it implies.

| | |
| --- | --- |
| **Heuristics** | Aesthetic-Usability Effect · Fitts's Law · Goal-Gradient Effect · Hick's Law · Jakob's Law · Miller's Law · Parkinson's Law |
| **Gestalt** | Common Region · Proximity · Prägnanz · Similarity · Uniform Connectedness |
| **Cognitive biases** | Peak-End Rule · Serial Position Effect · Von Restorff Effect · Zeigarnik Effect |
| **Principles** | Doherty Threshold · Occam's Razor · Pareto Principle · Postel's Law · Tesler's Law |

The point is to give a finding a reason rather than an assertion. "The screen
is silent for two seconds" is an observation; "attention drifts past about four
hundred milliseconds, which is the Doherty Threshold" is an argument, and an
argument is what survives contact with someone who does not want to do the
work. The skill is explicitly told not to cite a law it is not applying —
decorating an opinion with a psychologist's name is not evidence.

Tesler's Law does the most work in practice. Every missing error state,
absent not-found handler, and forgotten filter is irreducible complexity the
code declined to absorb, so a person carries it instead.

## It does not need Drumlin

Everything above is reasoning an agent can do by reading source. The skill
requires no tooling, no install, no daemon, no account, and no network. Point
it at a React, Next.js, Vue, or Svelte codebase and it works — the signals in
the catalogue are React-flavoured because that is where most users are, but
every defect it describes exists in any web application.

[Drumlin](https://github.com/Intelliger-ai/drumlin) makes the structural half
faster and certain rather than inferred, and the skill uses it when it is
there. It is an accelerator, not a prerequisite, and the skill is told not to
install it uninvited.

### It also says what not to do

The part that matters most in practice. Every check in the skill can be
satisfied cosmetically, and an agent under pressure to finish will do exactly
that. So the skill names the specific cheats and forbids them: the link nobody
will click that makes a page technically reachable, the `catch {}` that stops
a failure being silent by stopping it being a failure, the spinner on a
request with no error branch that therefore spins forever, the confirmation
dialog on a harmless action that trains people to dismiss dialogs.

It also tells the agent to ask rather than invent when the honest fix depends
on a product decision nobody has made.

## Install

Clone and run the installer. It detects which agents are on the machine and
installs for each:

```bash
git clone https://github.com/Intelliger-ai/UX-Engineer-Skill.git
cd UX-Engineer-Skill
./install.sh
```

Or name them:

```bash
./install.sh claude cursor        # only these
./install.sh --project            # into this repository, committed and shared
./install.sh --link               # symlink, for editing the skill itself
./install.sh --uninstall          # remove it
```

Restart the agent afterwards so it rescans.

### Installing by hand

The skill is one directory. Copy `skills/ux-engineer/` to wherever your agent
reads skills from:

| Agent | Personal | Per-repository |
| --- | --- | --- |
| Claude Code | `~/.claude/skills/ux-engineer/` | `.claude/skills/ux-engineer/` |
| Codex | `~/.agents/skills/ux-engineer/` | `.agents/skills/ux-engineer/` |
| Cursor | `~/.cursor/skills/ux-engineer/` | `.cursor/skills/ux-engineer/` |

Personal installs apply to every project on your machine. Per-repository
installs get committed, so everyone working in that repo gets the same review
standard — usually what you want for a team.

Codex also still scans the older `~/.codex/skills/`. If the skill does not
appear, check both locations.

## Using it

The skill is written to fire on its own. Its description matches on route,
page, form, button, modal, and data-fetch work, so during ordinary
feature-building the agent picks it up without being asked. That is the point:
a review you have to remember to request is a review that does not happen.

To invoke it deliberately:

| Agent | How |
| --- | --- |
| Claude Code | `/ux-engineer`, or just ask for a UX review |
| Codex | type `$` and pick it, or `/skills` |
| Cursor | mention the skill by name in your message |

Phrases that trigger it: *review the UX*, *does this flow make sense*, *check
accessibility*, *this feels janky*, *is this ready to ship*.

### If you would rather it stayed quiet

Add `disable-model-invocation: true` to the frontmatter of
`skills/ux-engineer/SKILL.md` and it will only load when you name it.

## Working with Drumlin

The skill works on its own — everything above is reasoning the agent can do by
reading code. But the structural questions are the ones grep answers badly.
*Does anything link to this route* is a whole-repository question, and an
agent answering it with a regex will be confidently wrong.

[**Drumlin**](https://github.com/Intelliger-ai/drumlin) is the CLI that answers
those properly. It reads a Next.js codebase, builds a graph of the product's
screens, states, actions and transitions, and runs deterministic rules over
that graph. No model call in the analysis path, no source leaving the machine.

```bash
npm install -g drumlin

cd your-next-app
drumlin init      # creates .drumlin/, meant to be committed
drumlin check
```

```
UX-0001  high  8 screens under /reports fetch data with no error state, so a failed request fails silently on each.
    src/app/(reports)/reports/audit/page.tsx
    fix: Add an error boundary at /reports with a retry affordance; it covers every screen in the section.
    affects: /reports/audit, /reports/dashboard, /reports/weekly and 5 more
    state.route.no-error · deterministic · confidence 0.85
```

When Drumlin is present the skill uses it for the structural half of the
review and keeps its own judgement for what a graph cannot see: whether the
copy is right, whether the hierarchy reads, whether the flow makes sense at
all.

Drumlin also ships a Cursor plugin — an MCP server with four read-only tools,
plus hooks that re-index in the background while an agent edits and hand new
high-severity findings back at the end of a turn:

```bash
drumlin connect cursor   # install the plugin, once per machine
drumlin activate         # switch it on, per project
```

Full command reference in [skills/ux-engineer/drumlin.md](skills/ux-engineer/drumlin.md)
and in the [Drumlin README](https://github.com/Intelliger-ai/drumlin#readme).

### The agent is not allowed to close its own findings

Worth understanding before you wire an agent to any issue tracker, because it
is where a tool like this usually fails: an agent that can silence a finding
will eventually silence one in order to finish its turn.

Drumlin splits the surface by what each action costs if it is wrong. Only
`drumlin accept` stops a finding being reported, so it is the only one that
requires a person — it refuses to run without an interactive terminal, refuses
callers that look like an agent or CI, and is not exposed over MCP at all. An
agent that believes a finding is wrong runs `drumlin propose` and argues its
case; a human rules on it. An agent that fixed something runs `drumlin claim`,
and only Drumlin's verifier, re-deriving from source, can mark it resolved.

The skill encodes that: **you may never make a finding go away.**

## Repository layout

```
skills/ux-engineer/
  SKILL.md        the skill: triggers, the loop, the four questions, the rules
  catalogue.md    the full defect catalogue, read for deep reviews
  laws.md         the twenty-one Laws of UX, mapped to code
  drumlin.md      driving the Drumlin CLI and its MCP tools
install.sh        installs into Claude Code, Codex and/or Cursor
```

`SKILL.md` is deliberately kept under 500 lines and links one level deep to
the other three. Skills are loaded into a context window shared with the
conversation and everything else, so the routine path has to stay small; the
detail is one read away when it is actually needed.

## Adapting it

The skill is markdown. Fork it and edit it — that is the intended use.

Things worth changing for your codebase: name your design system so the agent
stops reinventing its primitives, add the empty-state and error copy
conventions your product already uses, and add your framework's idioms if you
are not on Next.js. The catalogue's signals are `rg` patterns and React
idioms; the reasoning behind each entry is framework-independent.

If you keep the skill under `.agents/skills/` in your own repository, the
edits travel with the codebase they describe, which is usually the right home
for anything product-specific.

## Contributing

Issues and pull requests welcome. See [CONTRIBUTING.md](CONTRIBUTING.md).

The useful contribution is a defect the catalogue misses, with the signal that
reveals it — ideally one you hit in real code rather than one you can imagine.

## Disclaimer

**No warranty. No liability. Use entirely at your own risk.**

This skill is provided as is. The authors, contributors, and Intelliger AI
accept **no responsibility and no liability of any kind whatsoever** for
anything arising from its use, to the maximum extent permitted by law.

It instructs an AI coding agent, so its output is advisory and can be wrong in
both directions: it misses real defects, and it reports defects that are not
real. A clean review means nothing on its own. **A qualified human must review,
test, and approve every change** before it reaches anything with real users or
real data.

It is **not an accessibility audit and not a compliance tool.** Using it does
not make software conformant with WCAG, the ADA, Section 508, the European
Accessibility Act, or any other standard or law. It is not a security review
either.

Not affiliated with or endorsed by Jon Yablonski, Laws of UX, Anthropic,
OpenAI, Cursor, or any other organisation named here.

Full terms in [DISCLAIMER.md](DISCLAIMER.md), which you should read before
using this.

## License

Apache-2.0. See [LICENSE](LICENSE). Sections 7 and 8 disclaim warranty and
limit liability, and apply in full.
