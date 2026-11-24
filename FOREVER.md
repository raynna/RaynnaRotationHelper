# Raynna's Rotation Helper - Forever

Version 2.0.0-forever-beta10, Interface 16001. Requires **ForeverAuras**, the WoW Forever WeakAuras fork (integration checked against installed version 1.3.9).

Install both addon folders in `_forever_/Interface/AddOns`, enable them, then reload. The helper creates its own group automatically; no aura import is needed.

## Display and controls

- The original seven suggestion slots: primary, positional alternative, defensive, threat, interrupt, pet and utility. Secondary suggestions such as Faerie Fire, buffs, defensives, pet healing and readable interrupt opportunities. Only learned abilities are considered.
- Suggestions refresh on target changes and every 0.2 seconds. Learned spell ranks are resolved through the modern spellbook.
- Standard Blizzard action bars highlight the primary action in gold and secondary actions in blue. Keybindings appear on aura icons when a matching visible action is found. Third-party bars are not currently integrated.
- An icon marked WAIT is a pending action, not a claim that it is currently usable. Pending primary actions do not highlight action buttons.
- `/rrh show`, `/rrh hide`, or `/rrh` control visibility.
- `/rrh settings` opens Raynna's mods. Choose the profile, target mode, visibility, scale and action highlights there.
- `/rrh unlock` opens the generated group in ForeverAuras options to move it. Close those options when finished. The settings page also has a center button.
- `/rrh scale 85` sets 85%; settings includes editable percentage and +/- controls.
- `/rrh profile cat`, `/rrh profile auto` and the settings profile button change profile selection.
- `/rrh mode trash` enables multi-target priorities; `auto` or `boss` select single-target priorities. Enemy counts are not automatically inferred.
- `/rrh debug` prints the selected profile, status and per-ability readiness.

Preferences are per character in RaynnaRotationHelperForeverDB. ForeverAuras stores the generated group and its position. The MoP source and saved variables remain separate.

## Coverage and limits

28 profiles span all nine Forever classes: Druid (Cat, Bear, Balance, Restoration damage), Warrior, Paladin, Hunter, Rogue, Mage, Priest, Shaman and Warlock. Auto reads points spent in the active talent configuration and selects its dominant branch. Druid form takes precedence; explicit profile selection overrides automatic detection. Tied or unavailable talent data falls back to learned hallmark abilities. Shredding Attacks ranks change the Cat builder; other passive talent effects are not all explicitly modeled.

The updated priorities include Forever abilities such as Shifting Power, Summon Hawk, Shank and Wrack. The source list records which profiles received a current guide review; remaining profiles use baseline priorities. This beta is not a full reproduction of every MoP feature or every optimized Forever talent variant. Healer profiles supply damage and utility suggestions, not healing-target selection. Seal twisting, automatic enemy counting, threat prediction and ground-target grading are not implemented.

Each condition is evaluated independently. An unreadable aura, health or resource condition is skipped instead of blanking all otherwise usable actions. Public cooldown flags are used when available. Unknown data is never decrypted or used in arithmetic. Suggestions can be less optimal when the client hides required information. Cast using normal action bars; icons do not automate actions.

## Validation

Lua 5.1 mocked tests cover a complete Cat Rake/Rip/Bite sequence, talent-dependent builders, active talent selection, paged Cat Form actions/keybinds, original slot meanings, GCD swipes, and all profile loads, live aura triggers, primary/secondary changes, learned ranks, target changes, secret fields, public cooldown flags, GCD comparisons, action highlights, key labels, scale and position persistence, and shared settings registration. These tests do not establish in-game visual correctness or rotation optimality. Live-client verification is still needed.

See SOURCES.md for guide and API references. The player ZIP contains only the Forever TOC/runtime, documentation and MIT license. ForeverAuras is a separately installed dependency and is not redistributed.


## beta3 corrections

- Resolve the current action page before the secure base slot, so shapeshift bars
  match the suggested spell. Refresh discovery on form/bar/binding changes.
- Fall back to click bindings and the displayed HotKey text for icon key labels.
- Query auras by localized spell name first. Unrelated secret auras no longer
  make an otherwise readable missing bleed disappear from the priority list.
- Read the active talent configuration without opening the talent window.
- Restore the original fixed slot positions, public recommendation slot contract,
  positional Shred/Claw alternative and readable GCD swipe.

This remains a Forever adaptation, not certified 1:1 MoP feature parity. The
original resource-pip artwork, healing-target selection/frame highlights,
nameplate threat scanning and ground-AoE grading are not implemented. Neither
unit tests nor these changes establish live-client parity; those limits must
not be described as complete original-addon behavior.


## beta4 macro matching

Keybinding labels and action highlights now share a macro-text fallback when
GetMacroSpell does not resolve an ability. The exact `#showtooltip`, `/cast Rake`,
`/startattack [harm,nodead]` macro is covered by a regression test. Matching uses
complete spell names, supports rank suffixes and reads conditional branches via
the client parser when available. It never executes macro text. Sequence matches
identify a macro containing the ability, not a prediction of its next sequence step.


## beta5 action matching diagnostics

A non-matching macro API result no longer suppresses the exact macro-text fallback.
Use `/rrh bars` while a suggestion is showing to print the selected spell,
discovered buttons, current slots, resolved spells, matches and hotkey text.
Macro bodies are not printed. This diagnoses client behavior; passing mocked
tests alone does not establish that a live-client matching issue is resolved.


## beta6 shared aura reader

Auras.lua now supplies presence, duration and stacks for every profile. Negative
name lookups no longer bypass rank/ID/index checks. Known presence with hidden
duration suppresses reapplication without inventing a timer. Restricted empty
scans remain unknown. Personal bleeds are distinguished from other casters;
Faerie Fire variants share one debuff family. `/rrh auras` prints safe state
information for the current profile if further live-client diagnosis is needed.

Regression checks cover 39 profile aura rules plus name/index disagreement,
learned ranks, hidden timers, ownership and the reported Rake/Faerie Fire case.
These are mocked API scenarios, not a guarantee of every build's live behavior.


## beta7 macro IDs and explicit aura absence

Modern action results `macro, spellID, spell` now match the spell directly, rather
than passing the spell ID to the macro-index APIs. Item subtype IDs are excluded.
Legacy macro-index and readable body matching remain available.

All candidate aura-ID queries returning readable nil on an existing, visible
unit now establishes absence, even when general enumeration is restricted.
Secret/error results and invisible units remain unknown. This restores missing
Faerie Fire suggestions without overriding positive Rake/Rip observations.
Diagnostics include ID query failure counts and target visibility.


## beta8 rank coverage and conservative aura absence

Collect every readable learned spellbook rank and use rank subtext to select the
highest trained cast. Aura queries include the whole learned family, allowing a
lower-rank effect to be detected too. Player-buff and bulk-aura APIs provide
additional positive observations. Unknown/restricted empty results no longer
establish absence, reversing beta7's unsafe assumption. This can withhold an
apply suggestion when the client supplies no readable evidence; it must not
invent an absent aura. Macro matching is unchanged from the working beta7 path.

`/rrh auras` now includes individual ID/name/index results and Mark of the Wild.
Tests cover ranked Rake and Mark plus player-only/bulk API fallbacks. Live-client
resolution has not been confirmed.


## beta9 diagnostic detail

No rotation behavior changes. `/rrh auras` now retains readable API error messages,
includes player/bulk queries, and stores its report in per-character saved settings.
Reloading after the command writes the report to disk for inspection.


## beta10 disabled-helper safety

Persisted aura triggers and duration callbacks check whether helper functions
exist before calling them. With Rotation Helper disabled, the saved auras hide
and clear stale state instead of repeatedly throwing Lua errors. Existing saved
auras need regeneration while enabled or a targeted offline repair; installing
new addon files alone cannot change ForeverAuras saved data while it is disabled.
