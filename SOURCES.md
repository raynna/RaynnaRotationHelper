# Forever priority and API references

Reviewed 2026-11-13. These are reference inputs for independently written priorities, not imported aura packs or copied guide prose. They describe raid builds; not every talent variant is modeled.

Current Icy Veins Forever guides used for the nine reviewed class profiles:

- Feral Cat/Bear: https://www.icy-veins.com/wow-forever/feral-druid-melee-dps-and-tank-pve-rotation-cooldowns-abilities
- Fury: https://www.icy-veins.com/wow-forever/fury-warrior-melee-dps-pve-rotation-cooldowns-abilities
- Retribution: https://www.icy-veins.com/wow-forever/retribution-paladin-melee-dps-pve-rotation-cooldowns-abilities
- Beast Mastery: https://www.icy-veins.com/wow-forever/beast-mastery-hunter-ranged-dps-pve-rotation-cooldowns-abilities
- Combat Rogue: https://www.icy-veins.com/wow-forever/combat-rogue-melee-dps-pve-rotation-cooldowns-abilities
- Fire: https://www.icy-veins.com/wow-forever/fire-mage-ranged-dps-pve-rotation-cooldowns-abilities
- Shadow: https://www.icy-veins.com/wow-forever/shadow-priest-ranged-dps-pve-rotation-cooldowns-abilities
- Elemental: https://www.icy-veins.com/wow-forever/elemental-shaman-ranged-dps-pve-rotation-cooldowns-abilities
- Affliction: https://www.icy-veins.com/wow-forever/affliction-warlock-ranged-dps-pve-rotation-cooldowns-abilities

Forever spell IDs were cross-checked in the corresponding db.icy-veins.com spell records (407995, 1322605, 1293241, 1329549, 1316697). Priorities are shipped snapshots, not automatically downloaded updates.

API definitions:

- https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/SpellDocumentation.lua
- https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/SpellSharedDocumentation.lua
- https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/SpellBookDocumentation.lua
- https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/UnitAuraDocumentation.lua

Display integration uses the installed ForeverAuras 1.3.9 public Add/GetData/OpenOptions API and WeakAuras-compatible icon/group schema. No fork source is included. The original MIT-licensed project is https://github.com/raynna/RaynnaRotationHelper .

Action page/binding behavior checked against:
https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_ActionBar/Shared/ActionButton.lua

Shredding Attacks: https://db.icy-veins.com/wow-forever/spells/16966

Modern macro return contract: https://github.com/AdiAddons/AdiButtonAuras/issues/422 (maintainer confirmation; no code copied).
