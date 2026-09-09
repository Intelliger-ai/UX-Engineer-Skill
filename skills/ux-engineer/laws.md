# The laws

The twenty-one principles collected as the Laws of UX, written for someone
writing code rather than someone designing a poster.

Each entry gives what the law says, what it means in an implementation, and
the check you can actually run. Where Drumlin enforces one, the rule id is
named — those are the laws that turned out to be mechanically checkable. The
rest are judgement, which is why they are here rather than in a linter.

Use this as the *why* behind a finding. "Add a loading state" is an
instruction; "the screen is silent for two seconds and the Doherty Threshold
says attention is lost past four hundred milliseconds" is a reason, and a
reason is what survives an argument with someone who does not want to do it.

Do not cite a law you are not actually applying. Decorating an opinion with a
psychologist's name does not make it evidence, and it is transparent when a
review does it.

---

## Heuristics

### Aesthetic-Usability Effect
People perceive attractive interfaces as easier to use, and will forgive
minor usability problems in something that looks considered.

*In code*: visual consistency is functional, not decorative. Reimplementing a
primitive next to the design system's produces two buttons that are subtly
different, and the inconsistency reads as carelessness before anyone can say
why. Layout that jumps as data arrives reads as broken even when it is fast.

*Check*: does this reuse the existing primitive? Does the skeleton reserve the
same space the loaded content will occupy?

*Drumlin*: `ds.duplicate-primitive`, `state.route.no-loading`

### Fitts's Law
Time to hit a target is a function of its distance and its size. Small, far
targets are slow and error-prone.

*In code*: touch targets around 44px minimum. The primary action belongs
where the hand already is — bottom of a form, not scrolled away. Destructive
actions belong *away* from the safe ones, because the same law that makes a
target easy to hit makes its neighbour easy to hit by accident.

*Check*: are the tap targets big enough, and is the delete button somewhere a
misclick will not find?

### Goal-Gradient Effect
Motivation increases as people approach a goal. Visible progress pulls people
through; losing progress pushes them out.

*In code*: show progress in multi-step flows, and never discard it. A wizard
that resets on error, a filter set that vanishes on back-navigation, and a
form that clears on a failed submit all destroy accumulated progress at the
moment the user was most invested.

*Check*: if this fails, or they navigate away and return, is their work still
there?

*Drumlin*: `context.navigation.drops-search-params`, `flow.dead-end`

### Hick's Law
Decision time grows with the number and complexity of choices.

*In code*: this is the one that fires on unbounded collections. A select bound
to a list that grows with the data is fine with six options and unusable with
six hundred. Also: one primary action per screen, progressive disclosure for
advanced options, sensible defaults so the common path needs no decision.

*Check*: is the number of options bounded, and bounded small? If not, does it
have search, grouping, or a different control entirely?

*Drumlin*: `component.select-overload`

### Jakob's Law
People spend most of their time on other sites, and expect yours to work the
same way.

*In code*: the strongest argument against novelty in navigation, form
behaviour, and controls. Logo goes home. Back goes back. A blue underlined
thing is a link. Custom-built replacements for native controls need to earn
their existence, and most do not.

*Check*: does this behave the way the same thing behaves everywhere else? If
it is a route nobody can reach by the conventional path, that is this law
failing.

*Drumlin*: `flow.orphan`, `ds.duplicate-primitive`

### Miller's Law
Working memory holds roughly seven items, give or take two — and the useful
half of this is chunking, not the number.

*In code*: group related fields into sections. Break long numbers into
chunks. Do not ask someone to hold a value from screen one to use on screen
three; carry it for them. Do not make them remember what they filtered.

*Check*: does anything here require the user to remember something the
interface could have kept for them?

*Drumlin*: `component.select-overload`

### Parkinson's Law
Work expands to fill the time available. People will take as long as you
give them.

*In code*: autofill what you can, use sensible defaults, and do not make
people type what you already know. A task that could take fifteen seconds
will take ninety if the form is arranged to allow it.

*Check*: which of these fields could be prefilled, inferred, or removed?

---

## Gestalt principles

These four are about how people parse a layout before they read a word of it.
They are mostly CSS.

### Law of Common Region
Things inside a shared boundary are perceived as a group.

*In code*: a card, a bordered panel, or a shaded region creates a group whether
you intended one or not. Conversely, related things that need to read as
related need a container. Watch for actions rendered inside a card that
operate on something outside it.

### Law of Proximity
Things placed near each other are perceived as related.

*In code*: spacing is meaning. The commonest defect is a label equidistant
between two inputs, or a helper text closer to the next field than to its own.
Error messages must sit nearer their field than any other.

*Check*: for every label, hint and error, is it clearly closest to what it
describes?

### Law of Prägnanz
People resolve ambiguous layouts into the simplest interpretation available.

*In code*: if a layout can be misread, it will be read the simplest way, which
may not be yours. Deep nesting and ornate structure get flattened by the
reader into something wrong.

### Law of Similarity
Things that look alike are perceived as having the same function.

*In code*: if it is not clickable, do not style it like the clickable things.
If two buttons do very different things, they should not be identical. This
is why a disabled-looking element that is actually interactive fails, and why
underlined non-link text fails.

### Law of Uniform Connectedness
Things visually connected — by a line, a shared background, an enclosure —
are perceived as more related than things merely near each other.

*In code*: connect the steps of a wizard. Connect a control to the thing it
controls. This is stronger than proximity, and will override it when the two
disagree.

---

## Cognitive biases

### Peak-End Rule
People judge an experience by its most intense moment and by how it ended,
not by the average.

*In code*: the most consequential law in this document for error handling. The
peak of almost any session is the moment something went wrong, and the end is
whatever the user saw last. A silent failure and a dead-end success screen are
both direct violations. Handle the failure well and the whole session is
remembered as fine.

*Check*: what is the worst moment in this flow, and what does the last screen
look like?

*Drumlin*: `state.route.no-error`, `async.mutation.no-feedback`,
`flow.dead-end`, `flow.destructive.no-confirm`

### Serial Position Effect
The first and last items in a series are the most likely to be remembered.

*In code*: put the important navigation items at the ends, not buried in the
middle. In a long list of options, the middle is where things go to be
ignored.

### Von Restorff Effect
The thing that differs from its neighbours is the thing that gets noticed.

*In code*: exactly one primary action per view. If everything is emphasised
nothing is, and the corollary bites hardest on destructive actions — a delete
styled like everything else will be clicked like everything else.

*Check*: is there one visually dominant action, and is it the one you want?

### Zeigarnik Effect
Unfinished tasks are remembered better than finished ones, and people feel
pulled to complete them.

*In code*: this is why progress indicators work and why partially complete
states should be visible rather than hidden. It is also why an unfinished
task that the user cannot resume is unusually irritating — save drafts,
preserve partial input, and let people pick up where they stopped.

---

## Principles

### Doherty Threshold
Productivity rises sharply when the system responds in under about 400ms.
Beyond that, attention drifts and the interaction feels like waiting.

*In code*: the number behind every loading and pending state in this skill.
Under 400ms, do nothing — a spinner that flashes is worse than no spinner.
Past it, acknowledge the interaction immediately even though the result does
not exist yet: disable the button, show the skeleton, start the progress. If
the work is genuinely long, show real progress rather than an indeterminate
spinner, because an indeterminate spinner conveys no information at all.

*Check*: what does the user see between the click and the result?

*Drumlin*: `state.route.no-loading`, `async.mutation.no-feedback`

### Occam's Razor
Among competing designs that work, prefer the one with fewest assumptions and
fewest elements.

*In code*: the argument for deleting things. Every field, option, and step
should justify itself. When a review finds a screen that would be better
smaller, say so — removing is a legitimate fix and usually the best one.

### Pareto Principle
Roughly eighty percent of effects come from twenty percent of causes.

*In code*: a prioritisation rule for reviews. Most of the pain in a product is
concentrated in a few flows, and polishing a rarely used settings page while
the checkout silently fails is a misallocation. Weight findings by how many
users hit the path.

*Check*: is this on the path most people take?

### Postel's Law
Be liberal in what you accept, conservative in what you send.

*In code*: accept the phone number with spaces, the card number with dashes,
the date in either order, the email with trailing whitespace. Normalise on the
way in rather than rejecting. Rejecting input a human obviously meant
correctly is the most avoidable form failure there is. Be strict about what
you render back: predictable, consistent, well-formed.

*Check*: what reasonable input does this reject?

### Tesler's Law
Every system has irreducible complexity. The only question is who absorbs it —
the product or the user.

*In code*: the law behind most of Drumlin's rules, and the one that most often
gets resolved the wrong way. A missing error state does not remove the
possibility of failure, it just moves the problem to the user. Same for a
missing not-found handler, a filter set the app declines to remember, and a
destructive action with no confirmation. Each is complexity the code refused,
so a person has to carry it.

*Check*: is there a hard case here that the code is quietly leaving to the
user?

*Drumlin*: `state.route.no-error`, `state.route.no-not-found`,
`context.navigation.drops-search-params`, `flow.destructive.no-confirm`

---

## Where these came from

The Laws of UX were collected by Jon Yablonski at
[lawsofux.com](https://lawsofux.com) and in his book of the same name. He did
not invent them — each is established work from psychology, cognitive science,
and Gestalt theory — and the contribution is the curation.

The descriptions above are written for this skill and are not reproduced from
that source. Read the original if you want the research behind any of them; it
is better on the theory, and this file is only trying to make the theory
executable.
