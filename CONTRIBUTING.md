# Contributing

This repository is one agent skill and the files it links to. There is nothing
to build and nothing to install to work on it.

```bash
git clone https://github.com/Intelliger-ai/UX-Engineer-Skill.git
cd UX-Engineer-Skill
./install.sh --link      # symlink, so edits take effect on the next agent restart
```

## The useful contribution

A defect the catalogue misses, with the signal that reveals it in source and
the fix. Ideally one you hit in real code — imagined defects tend to produce
entries that are true but never fire.

An entry earns its place if an agent can act on it. That means three things:

- **What the user loses.** Not "the loading state is missing" but "the screen
  is blank for two seconds and the user thinks it is broken."
- **How to find it.** An `rg` pattern, a file convention, a framework idiom.
  Something concrete enough to look for, honest enough that a hit is a place
  to check rather than a verdict.
- **What to do.** The fix, and the shape of the fix — a section-level error
  boundary rather than eight local try/catches.

## What to keep out

**Anything that cannot be checked.** "Use good visual hierarchy" is not
actionable and costs context.

**Framework trivia.** The catalogue is React and Next.js flavoured in its
signals because that is where the users are, but every entry should describe
a defect that exists in any web application. If it only makes sense in one
framework version, it belongs in a fork.

**Length for its own sake.** `SKILL.md` stays under 500 lines. Skills load
into a context window shared with the conversation, the codebase, and every
other skill — every line competes. If an addition belongs in `catalogue.md`
rather than `SKILL.md`, put it there.

**Checks that can be gamed cosmetically, without saying so.** If a new check
can be satisfied in a way that leaves the product worse, name that cheat in
the same entry. That section of the skill is doing more work than the checks
themselves.

## Style

Match what is there. Prose over bullet fragments where the reasoning matters;
tables for things that are genuinely enumerable. Write for an agent reading it
once, mid-task, with a limited budget — say the thing, give the signal, move
on.

Do not add emoji, and do not add severity icons to the report format. The
report template in `SKILL.md` is the one agents copy.

## Testing a change

There is no test suite; the way to check a skill is to run it.

1. `./install.sh --link` and restart your agent.
2. Point it at a real application with known problems.
3. Ask for a UX review, and read what comes back for whether the new entry
   fired, fired for the right reason, and produced a fix worth making.

A change that makes the agent report more findings is not automatically an
improvement. A review nobody reads because it has sixty entries is worse than
one with twelve.

## Pull requests

One concern per pull request. Say what you changed and why, and if you tested
against a real codebase, say which kind — the answer differs a lot between an
App Router app, a Pages Router app, and something that is neither.
