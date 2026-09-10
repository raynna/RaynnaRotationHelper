# Raynna Rotation Helper

Raynna Rotation Helper is a World of Warcraft Mists of Pandaria Classic addon that drives a generated WeakAuras rotation helper.

It creates and updates a WeakAura group for:

- a single primary next-action recommendation
- an alternate next-action slot when a positional choice is uncertain
- action bar glow for the recommended primary/alternate action
- defensive, threat, interrupt/control, pet, and utility side suggestions
- dynamic resource pips based on class/spec resources such as combo points, arcane charges, holy power, soul shards, burning embers, and demonic fury

## Requirements

- World of Warcraft Classic: Mists of Pandaria
- WeakAuras

WeakAuras is listed as a required dependency because this addon generates and updates the WeakAura display data.

## Usage

Install the `RaynnaRotationHelper` folder into:

```text
World of Warcraft/_classic_/Interface/AddOns/
```

Then reload in game:

```text
/reload
```

Useful slash commands:

```text
/rrh
/rrh debug
/rrh mode
/rrh mode auto
/rrh mode boss
/rrh mode trash
```

## Notes

The helper is intentionally conservative. It avoids turning utility actions, pet maintenance, tank threat warnings, and caster control into the main rotation button unless they are part of the actual spec priority.
