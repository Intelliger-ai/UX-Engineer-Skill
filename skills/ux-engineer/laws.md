# The laws, and how to apply them

The twenty-one principles collected as the Laws of UX, written for someone
writing code rather than someone designing a poster.

Each law below gives the principle, what it means in an implementation,
explicit directives for what to do while building, the check that verifies it,
and the way fast AI-assisted development specifically breaks it. Where Drumlin
enforces one, the rule id is named — those are the laws that turned out to be
mechanically checkable. The rest are judgement, which is why they are here and
not in a linter.

**Use a law as the reason behind a finding, not as decoration.** "Add a
loading state" is an instruction and gets argued with. "The screen is silent
for two seconds, and attention drifts past about four hundred milliseconds"
is a reason and does not. But do not cite a law you are not actually applying
— attaching a psychologist's name to an opinion does not make it evidence, and
it is obvious when a review does it.

---

## Start here: what are you building?

Jump to the laws that apply. This is the fastest way to use this file while
actually writing code.

| Building | Apply |
| --- | --- |
| **A form** | Postel · Miller · Proximity · Parkinson · Doherty · Zeigarnik · Prägnanz |
| **A list, table or feed** | Hick · Miller · Von Restorff · Serial Position · Pareto · Common Region |
| **A multi-step flow, wizard or checkout** | Goal-Gradient · Zeigarnik · Peak-End · Tesler · Uniform Connectedness |
| **A destructive action** | Peak-End · Von Restorff · Fitts · Tesler · Peak-End again |
| **Navigation, a route, a menu** | Jakob · Serial Position · Goal-Gradient · Hick |
| **A dashboard or data-dense screen** | Common Region · Proximity · Similarity · Miller · Pareto |
| **Anything that fetches** | Doherty · Peak-End · Tesler · Aesthetic-Usability |
| **Anything that mutates server state** | Doherty · Peak-End · Tesler · Zeigarnik |
| **A modal or dialog** | Common Region · Von Restorff · Jakob · Prägnanz |
| **A settings or admin page** | Hick · Occam · Miller · Pareto |
| **A landing or marketing page** | Aesthetic-Usability · Von Restorff · Serial Position · Prägnanz |
| **A search or filter interface** | Goal-Gradient · Hick · Postel · Miller |

## The five that matter most when moving fast

If you apply nothing else, apply these. They cover the majority of what goes
wrong in AI-assisted development, where code arrives faster than anyone can
consider what surrounds it.

1. **Tesler's Law** — complexity is conserved. Every case the code declines to
   handle is a case a person now handles instead.
2. **Doherty Threshold** — respond within 400ms or say something. This is
   every loading, pending, and progress state you will ever write.
3. **Peak-End Rule** — the session is remembered by its worst moment and its
   last one. Both are usually error handling.
4. **Jakob's Law** — people expect your product to work like the others. Do
   not invent.
5. **Hick's Law** — every choice costs time. Fewer options, better defaults.

---

# Heuristics

## 1. Aesthetic-Usability Effect

> People perceive attractive interfaces as easier to use, and forgive minor
> usability problems in something that looks considered.

Visual polish is not decoration — it buys tolerance. The same defect is a
shrug in a product that looks cared for and a reason to leave in one that does
not. The inverse is the dangerous half: an ugly interface gets blamed for
problems it does not have, and usability testing on unpolished work returns
harsher results than the design deserves.

**Apply it**

- Reuse the design system's primitives. Two buttons that are subtly different
  read as carelessness before anyone can articulate why.
- Reserve space for content that has not arrived. A layout that jumps as data
  lands reads as broken even when it is fast.
- Keep spacing, radii, weights, and colours on the scale the project already
  uses. Ad-hoc values are the most common source of "this looks off" with no
  identifiable cause.

**The agent's move**: before writing any component, search for an existing one.
`rg -l "Button|Card|Dialog|Input" src/components src/ui` — if a primitive
exists, import it. Writing a new button next to the existing one is the single
most common way an agent adds UX debt, and it is invisible in review because
the diff looks fine on its own.

**Check**: does this reuse the existing primitive, and does the skeleton
reserve the same space the loaded content occupies?

**Where vibe coding breaks it**: each generated screen is internally
consistent and inconsistent with every other one, because each was written
without looking at the last.

**Drumlin**: `ds.duplicate-primitive`, `state.route.no-loading`

## 2. Fitts's Law

> Time to acquire a target is a function of its distance and its size. Small,
> distant targets are slow and error-prone.

The practical consequences are size, position, and — the half people forget —
*separation*. The same property that makes a target easy to hit makes its
neighbour easy to hit by accident.

**Apply it**

- Minimum 44×44px touch targets (Apple HIG); 48dp on Material. This is the
  tappable area, not the icon inside it — pad the button, do not enlarge the
  glyph.
- Put the primary action where the hand already is: the end of the form, the
  bottom of the sheet, within thumb reach on mobile.
- Screen edges and corners are effectively infinite targets, because the
  pointer stops there. This is why menu bars and docks live there.
- **Separate destructive actions from safe ones.** Never place Delete
  immediately beside Save.
- Larger targets for the actions that matter most; a primary button should be
  physically bigger than a tertiary one.

**The agent's move**: whenever you place a destructive control adjacent to a
frequently used one, move it — into an overflow menu, behind a confirmation,
or to the opposite side. When you write an icon-only button, set an explicit
minimum size; icon buttons default to the icon's size, which is almost always
too small.

**Check**: are tap targets ≥44px, and is the delete button somewhere a
misclick will not find?

## 3. Goal-Gradient Effect

> Motivation increases as people approach a goal. Visible progress pulls
> people forward; lost progress pushes them out.

Effort already spent is what keeps someone going, which makes destroying that
effort the most expensive thing an interface can do. A loyalty card with two
stamps pre-filled gets completed more often than an empty one with a lower
target — endowed progress works.

**Apply it**

- Show progress in anything with more than two steps: "Step 2 of 4", a bar, a
  checklist.
- Start the progress above zero where it is honest to do so. An onboarding
  checklist with "account created" already ticked is accurate and motivating.
- **Never discard accumulated work.** Filters, sort order, form input, scroll
  position, and partially completed steps must survive navigation, refresh,
  and failure.
- Put URL state in the URL, so it survives reload, back, and sharing.
- Shorten the perceived remaining distance: show what is left, not what is
  done, when the remaining part is small.

**The agent's move**: when you write a `router.push` from a screen that holds
filter, sort, pagination, or scroll state, carry that state through — read
`useSearchParams()` and re-append it. When you write a form submit handler,
the failure branch must leave every field populated. Treat "the user has to
redo something they already did" as a defect of the same severity as a crash.

**Check**: if this fails, or they leave and come back, is their work still
there?

**Where vibe coding breaks it**: generated navigation is almost always a bare
`router.push('/path')`, because the model is writing the destination and not
thinking about the origin's state.

**Drumlin**: `context.navigation.drops-search-params`, `flow.dead-end`

## 4. Hick's Law

> The time to decide grows with the number and complexity of choices —
> logarithmically, as `RT = a + b·log₂(n+1)`.

Logarithmic matters: going from four options to eight is not twice as bad, but
going from four to four hundred is unusable. And the law is about *decisions*,
not items — a long list you scan is different from a long list you must
choose from.

**Apply it**

- One primary action per screen. Everything else is visually secondary.
- Bound your option sets. A select bound to a collection that grows with the
  data is fine in development and broken in production.
- Past roughly ten options, add search. Past fifty, reconsider the control —
  a combobox with typeahead, a grouped list, or a different interaction.
- Categorise and chunk long lists so the decision becomes several small ones
  instead of one large one.
- Use defaults aggressively. A default is a decision you made so the user does
  not have to.
- Progressive disclosure: hide advanced options until asked for.
- Break long forms into steps. Ten fields on one screen is a worse decision
  problem than ten fields across three.

**The agent's move**: whenever you bind a `<select>`, a dropdown, or a radio
group to an array whose length you cannot state at build time, treat it as a
defect and add search or grouping in the same edit. Whenever you add a second
primary-styled button to a screen, demote one.

**Check**: is the number of choices bounded, and bounded small? If not, does
it have search, grouping, or a different control?

**Drumlin**: `component.select-overload`

## 5. Jakob's Law

> People spend most of their time on other products, so they expect yours to
> work the same way.

This is the strongest available argument against novelty, and the one most
worth deploying against a request to be different for its own sake. Every
convention you break spends a user's attention on learning your interface
instead of doing their task.

**Apply it**

- Logo top-left goes home. Search top-right or centre. Cart top-right.
  Settings behind an avatar. Do not be clever with these.
- Links look like links. Buttons look like buttons. Blue and underlined means
  navigable.
- Use native controls — `select`, `input type="date"`, `dialog` — unless there
  is a specific, stated reason not to. Custom replacements are worse at
  keyboard, screen readers, mobile, and autofill, and reimplementing them
  correctly is a project, not a component.
- Follow the platform: iOS back-swipe, Android back button, browser back.
- Standard icons keep standard meanings. A magnifying glass is search, never
  zoom-only.
- When you must break a convention, make the new thing self-evident, and
  expect to pay for it.

**The agent's move**: before building any custom control, check whether a
native element or the project's existing library covers it. Prefer
`<dialog>`, `<details>`, `<input type="...">`, and the design system's
primitives over hand-rolled equivalents in every case where they fit. If you
add a route that no conventional path reaches, you have violated this law
even though the page works.

**Check**: does this behave the way this thing behaves everywhere else?

**Drumlin**: `flow.orphan`, `ds.duplicate-primitive`

## 6. Miller's Law

> Working memory holds about seven items, plus or minus two — but the useful
> half of this is chunking, not the number.

The number is widely over-applied; it does not mean "seven menu items". What
it does mean is that unstructured information is expensive to hold, and
structure is free to add.

**Apply it**

- Chunk long strings: phone numbers, card numbers, IBANs, codes, IDs. Format
  as you display, and accept any format on input.
- Group form fields into labelled sections. Six fields in three groups is
  easier than six in a column.
- Never require the user to carry a value between screens. If step three needs
  something from step one, show it there.
- Summarise before you ask for confirmation. Do not make someone remember what
  they configured two screens ago.
- Keep the things being compared visible at the same time.

**The agent's move**: any time your implementation requires the user to
remember something the application already knows, display it instead. Any
time you render a long identifier, chunk it.

**Check**: does anything here ask the user to remember what the interface
could have kept for them?

**Drumlin**: `component.select-overload`

## 7. Parkinson's Law

> Work expands to fill the time available for its completion.

In an interface this cuts two ways: give someone a slow path and they will
take it, and show a task as long and they will treat it as long.

**Apply it**

- Autofill everything you can infer: country from locale, city from postcode,
  name from the account, date from context.
- Use `autocomplete` attributes properly so the browser can fill the rest.
  `autocomplete="street-address"`, `"cc-number"`, `"one-time-code"`.
- Delete fields rather than optimise them. The fastest field is the one that
  is not there.
- Do not add artificial delay to make work seem substantial. It occasionally
  increases trust and always wastes the user's time.
- Set expectations honestly — "takes about two minutes" — and then beat them.

**The agent's move**: for every form field you write, ask whether the value
can be inferred, defaulted, or removed. Always set `autocomplete` on
name, email, address, phone, and payment inputs; omitting it is a silent
degradation that nobody reports.

**Check**: which of these fields could be prefilled, inferred, or deleted?

---

# Gestalt principles

How people parse a layout before reading a word of it. Mostly CSS, and mostly
cheap to get right if you are deliberate.

## 8. Law of Common Region

> Elements inside a shared boundary are perceived as a group.

A border, a card, a background tint, or an enclosure creates a group whether
you intended one or not — and it overrides proximity. Two distant items in one
box read as more related than two adjacent items in different boxes.

**Apply it**

- Put an item's actions inside that item's container. An action rendered in a
  card that operates on something outside it will be misread.
- Use cards to group, not to decorate. A card around a single unrelated
  element makes a promise about grouping that is not kept.
- Separate distinct groups with a real boundary, not just extra margin, when
  the distinction matters.
- Keep form sections in visible regions when a form is long.

**The agent's move**: when you wrap something in a card or bordered container,
confirm that everything inside belongs to the same thing, and that nothing
belonging to it is left outside.

## 9. Law of Proximity

> Elements placed near each other are perceived as related.

Spacing is meaning, and it is the most common thing to get subtly wrong,
because it looks fine until you measure it.

**Apply it**

- A label must be closer to its input than to any other input. The classic
  failure is a label sitting exactly between two fields.
- Helper text and error messages belong nearer their field than the next
  field. Error text placed below the input, above the next label, needs
  asymmetric margin to read correctly.
- Space *between* groups must exceed space *within* a group. If they are
  equal, there are no groups.
- Related actions cluster; unrelated actions separate.

**The agent's move**: when you write a field with a label, hint, and error,
set the margins asymmetrically — tight above the input, loose below the group.
Equal vertical rhythm through a form destroys the grouping.

**Check**: for every label, hint, and error, is it unambiguously closest to
what it describes?

## 10. Law of Prägnanz

> People interpret ambiguous or complex images in the simplest form available.

The reader will resolve your layout into the simplest thing it could be, which
may not be the thing it is. Complexity does not survive the trip.

**Apply it**

- Prefer flat, obvious structure to deep nesting. A three-level nested card is
  read as one thing.
- Simple shapes and clear alignment are processed faster and with less effort.
- If a layout can be misread, assume it will be read the simplest way.
- Reduce visual elements until removing one more would lose meaning.

**The agent's move**: when a component's JSX nests more than about three
levels of visual containers, flatten it. The nesting is usually a build-up of
successive small additions, and it reads as noise.

## 11. Law of Similarity

> Elements that look alike are perceived as having the same function.

Appearance is a promise about behaviour. Break it and everything becomes
untrustworthy.

**Apply it**

- If it is not interactive, do not style it like the interactive things. No
  underlined non-link text, no button-shaped labels.
- If it is interactive, make it look like the other interactive things.
- Two controls that do very different things must not look identical —
  especially a destructive one next to a safe one.
- Keep one visual language per meaning: one danger colour, one primary
  treatment, one disabled state.

**The agent's move**: never style a `div` to look like a button — use a
`button`. Never make text blue and underlined unless it navigates.

## 12. Law of Uniform Connectedness

> Elements visually connected — by a line, a shared background, an enclosure —
> are perceived as more related than elements merely near each other.

The strongest of the grouping principles. It beats proximity and similarity
when they disagree, which makes it the tool for when grouping really must not
be misread.

**Apply it**

- Connect the steps of a wizard or stepper with a visible line.
- Connect a control to what it controls: a toolbar attached to its table, a
  tab attached to its panel.
- Use a shared background to bind a heading to its section.
- Connect related items in a timeline or thread.

**The agent's move**: when you build a stepper, breadcrumb, or timeline, draw
the connector. A row of disconnected circles is a set of options; a row of
connected circles is a sequence.

---

# Cognitive biases

## 13. Peak-End Rule

> People judge an experience by its most intense point and by how it ended,
> not by the sum or average of the experience.

The most consequential law here for error handling. The peak of nearly any
session is the moment something went wrong, and the end is whatever was on
screen last. Handle those two well and the rest is forgiven; handle them
badly and nothing else counts.

**Apply it**

- **Invest disproportionately in failure states.** They are the peak. An
  error that explains itself and offers a way forward converts the worst
  moment into a neutral one.
- Never let a failure be silent. A silent failure is a peak the user
  experiences later, without context, and blames you for.
- **End well.** Terminal screens — order confirmed, signup complete, payment
  taken — must acknowledge, reassure, and offer the obvious next thing. A
  success screen with nowhere to go is a bad ending to a good experience.
- Make moments of delight land at the end, not the beginning.
- Confirmations should confirm the outcome, not the mechanism: "Invoice sent
  to Ana", not "Operation completed".

**The agent's move**: whenever you write a `catch`, ask what the user sees and
what they can do next. Both answers must be non-empty. Whenever you write a
terminal screen, add the onward action in the same edit.

**Check**: what is the worst moment in this flow, and what is on screen last?

**Drumlin**: `state.route.no-error`, `async.mutation.no-feedback`,
`flow.dead-end`, `flow.destructive.no-confirm`

## 14. Serial Position Effect

> Items at the beginning and end of a series are the most likely to be
> remembered; the middle is where things go to be forgotten.

**Apply it**

- Put the most important navigation items first and last. The middle of a nav
  bar is the weakest position.
- In a list of actions, the first and last get seen; bury nothing important in
  the middle.
- Primary actions at the ends of a toolbar, not the centre.
- In long option lists, order by importance rather than alphabetically, unless
  the user is looking something up by name.

**The agent's move**: when adding an item to existing navigation, do not
append by default — decide whether it belongs at an end based on importance.

## 15. Von Restorff Effect (Isolation Effect)

> The item that differs from the rest is the one that gets noticed and
> remembered.

Emphasis is zero-sum. Every additional emphasised element reduces the
emphasis of all the others.

**Apply it**

- Exactly one primary action per view. If everything is emphasised, nothing
  is.
- Make the destructive action look different from everything around it. A
  delete styled like the rest will be clicked like the rest.
- Highlight the recommended plan, the default option, the unread item — but
  only one class of thing at a time.
- Never use colour alone to carry the difference; colour-blind users and
  greyscale rendering lose it. Pair colour with weight, icon, or label.

**The agent's move**: when you add a button to a screen that already has a
primary button, make the new one secondary unless it is genuinely the main
action, in which case demote the old one. Two primaries is a defect.

**Check**: is there one visually dominant action, and is it the right one?

## 16. Zeigarnik Effect

> Unfinished tasks are remembered better than completed ones, and create
> tension that pulls toward completion.

**Apply it**

- Show progress on incomplete things: onboarding checklists, profile
  completeness, draft states.
- **Preserve partial work.** Autosave drafts, keep partially filled forms,
  remember where a multi-step flow was abandoned, and let people resume.
- Surface the resumable thing when they return: "Continue where you left off".
- Use the tension honestly. An artificial incompleteness bar that never
  reaches full is manipulative and is noticed.

**The agent's move**: for any form longer than a few fields, or any flow with
more than two steps, persist state so it survives a reload. `localStorage` or
URL state is usually enough, and the absence of it is only discovered by a
user who has just lost twenty minutes.

---

# Principles

## 17. Doherty Threshold

> Productivity rises sharply when a system and its user interact at a pace —
> under 400ms — where neither waits on the other.

The number behind every loading and pending state in this skill. The
complementary set is Nielsen's: under 100ms feels instantaneous, under 1s
keeps flow with a noticeable pause, and past 10s attention is gone.

**Apply it**

- **Under 400ms**: do nothing. A spinner that flashes for 80ms is noise and
  makes the interface feel busier, not faster.
- **400ms to 1s**: acknowledge immediately. Disable the control, show the
  skeleton, change state. The response does not have to be the result.
- **1s to 10s**: show determinate progress if you possibly can. An
  indeterminate spinner conveys no information and time passes more slowly
  while watching one.
- **Over 10s**: let them leave. Background the work, notify on completion, and
  never block the interface.
- Delay spinners by 200–400ms so fast responses never show one.
- Use optimistic updates where the operation nearly always succeeds — but
  always implement the reconcile-and-revert path.
- Skeletons should match the shape of what is coming, so nothing shifts when
  it arrives.

**The agent's move**: whenever you write a control that triggers a request,
add the pending state in the **same edit** — disable the trigger and show it
is working. Not as a follow-up, not as a `TODO`. A pending state deferred is a
pending state never written.

**Check**: what does the user see between the click and the result?

**Drumlin**: `state.route.no-loading`, `async.mutation.no-feedback`

## 18. Occam's Razor

> Among competing designs that deliver the same outcome, choose the one with
> the fewest assumptions and the fewest elements.

The argument for deletion, and the one an agent is least likely to reach for
unprompted, because generating is easier than removing.

**Apply it**

- Every field, option, step, and element must justify its existence. If it
  cannot, remove it.
- Analyse and remove before you optimise. A faster version of an unnecessary
  step is still an unnecessary step.
- Reduce until removing one more thing would take away meaning — then stop.
- Prefer one good default over three configurable options.

**The agent's move**: "delete this screen", "merge these two steps", and
"remove this field" are legitimate findings and often the best available fix.
Say so when it is true, rather than proposing an improvement to something that
should not exist.

## 19. Pareto Principle

> Roughly eighty percent of effects come from twenty percent of causes.

A prioritisation rule, and the reason a review should be short.

**Apply it**

- Weight findings by traffic. A silent failure in checkout outranks every
  cosmetic issue on a settings page nobody opens.
- Identify the two or three flows that carry the product and hold them to a
  higher standard than everything else.
- Cap the review. Fifteen findings that matter beat sixty that include every
  missing `aria-label`, because the long list does not get read.
- When optimising, find the actual bottleneck rather than improving what is
  convenient to improve.

**The agent's move**: before reporting, sort by how many users hit the path.
If the list runs long, cut from the bottom rather than delivering all of it.

**Check**: is this on the path most people take?

## 20. Postel's Law (Robustness Principle)

> Be conservative in what you send, liberal in what you accept.

The most avoidable class of form failure. Rejecting input a human obviously
meant correctly is a self-inflicted wound.

**Apply it**

- Accept phone numbers with spaces, brackets, dashes, and country prefixes.
  Normalise on the way in.
- Accept card numbers with spaces. Accept postcodes in any case. Trim
  whitespace on emails rather than rejecting them.
- Accept dates in more than one format, and say which you assumed.
- Accept pasted content that carries formatting, and clean it silently.
- Be strict about output: consistent, predictable, well-formed, and the same
  everywhere.
- Handle the hostile and the absent gracefully — empty responses, nulls,
  unexpected shapes, slow networks, offline.

**The agent's move**: every validation rule you write should normalise before
it rejects. If input can be repaired unambiguously, repair it. Reserve
rejection for genuine ambiguity, and when you must reject, say precisely what
was expected.

**Check**: what reasonable input does this reject?

## 21. Tesler's Law (Conservation of Complexity)

> Every system has an irreducible amount of complexity. The only question is
> who absorbs it — the product, or the user.

The law behind most of Drumlin's rules and the one most often resolved the
wrong way, because pushing complexity onto the user is invisible in a diff.

**Apply it**

- A missing error state does not remove the possibility of failure. It moves
  the consequence to the user.
- A missing not-found handler does not make bad ids stop arriving.
- Filters the app declines to remember are filters the user re-applies.
- A destructive action with no confirmation does not make mistakes less
  likely, only less recoverable.
- Absorb complexity in the code: smart defaults, inference, autosave,
  normalisation, retries, sensible fallbacks.
- Do not oversimplify past the point where the product stops doing its job.
  Complexity that genuinely belongs to the domain should be made manageable
  rather than hidden.

**The agent's move**: whenever you find yourself thinking "the user can just
—", stop. That sentence is this law being violated. The user can just re-enter
the filters, can just refresh, can just check whether it saved — each one is
work you declined to do.

**Check**: is there a hard case here that the code is quietly leaving to a
person?

**Drumlin**: `state.route.no-error`, `state.route.no-not-found`,
`context.navigation.drops-search-params`, `flow.destructive.no-confirm`

---

## Where these came from

The Laws of UX were collected by Jon Yablonski at
[lawsofux.com](https://lawsofux.com) and in his book of the same name. He did
not invent them — each is established work from psychology, cognitive science,
and Gestalt theory, credited to the researchers behind it — and the
contribution is the curation.

The descriptions, directives, and code guidance above are written for this
skill and are not reproduced from that source. Read the original for the
research; it is better on theory, and this file is only trying to make the
theory executable.

Response-time thresholds referenced under the Doherty Threshold come from
Miller (1968) and Nielsen's usability engineering work. Touch target sizes come
from the Apple Human Interface Guidelines and Material Design.
