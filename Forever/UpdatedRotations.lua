local _, A = ...

-- Reviewed against the November 2026 Icy Veins Forever rotation pages.
-- SOURCES.md records the individual pages and supported conditions.
local function r(id, hint, condition, value)
    return { id = id, hint = hint, condition = condition, value = value }
end
local function set(class, key, rules)
    for _, profile in ipairs(A.profiles) do
        if profile.class == class and profile.key == key then
            profile.rules = rules
            return
        end
    end
end
set('DRUID', 'cat', {
    r(22568, 'Bite with 5 points, sufficient Energy and Rip active', 'catbite'),
    r(1322605, 'Convert Mana to Energy at 50 Energy or less', 'energymax', 50),
    r(5221, 'Spend Clearcasting on Shred from behind', 'proc', 16870),
    r(1079, 'Apply Rip with 5 combo points', 'combo', 5),
    r(1822, 'Apply Rake when the bleed expires', 'dot', 0),
    r(5221, 'Build with talented Shred from behind; Claw is the frontal alternative', 'talent', 16966),
    r(1082, 'Build combo points with Claw'),
})
set('DRUID', 'bear', {
    r(407995, 'Primal Bite when ready'),
    r(779, 'Swipe against several enemies', 'aoe'),
    r(414644, 'Build and maintain Lacerate'),
    r(6807, 'Queue Maul with spare Rage', 'rage', 35),
})
set('WARRIOR', 'fury', {
    r(1680, 'Whirlwind when ready'),
    r(23881, 'Bloodthirst when ready'),
    r(5308, 'Execute below 20% health', 'execute', 20),
    r(7384, 'Use an available Overpower proc', 'usable'),
    r(78, 'Queue Heroic Strike with spare Rage', 'rage', 50),
})
set('MAGE', 'fire', {
    r(11366, 'Pyroblast at three Heating Up stacks', 'stacks', { 400624, 3 }),
    r(2136, 'Fire Blast to build Heating Up'),
    r(44614, 'Frostfire Bolt if learned'),
    r(133, 'Fireball filler'),
})
set('HUNTER', 'beast', {
    r(1978, 'Maintain Serpent Sting', 'dot', 0),
    r(1293241, 'Summon Hawk when ready'),
    r(19434, 'Aimed Shot between Auto Shots'),
    r(2643, 'Multi-Shot against multiple targets', 'aoe'),
    r(3044, 'Arcane Shot between Auto Shots'),
    r(75, 'Continue Auto Shot'),
})
set('ROGUE', 'combat', {
    r(5171, 'Maintain Slice and Dice', 'slice'),
    r(1943, 'Maintain Rupture at 5 points', 'combo', 5),
    r(1329549, 'Shank without capping Energy', 'energymax', 70),
    r(2098, 'Eviscerate at 5 combo points', 'combo', 5),
    r(1752, 'Build combo points'),
})
set('PRIEST', 'shadow', {
    r(589, 'Maintain Shadow Word: Pain', 'dot', 0),
    r(2944, 'Maintain Devouring Plague', 'dot', 0),
    r(8092, 'Mind Blast when ready'),
    r(32379, 'Shadow Word: Death when ready'),
    r(15286, 'Maintain Vampiric Embrace', 'dot', 0),
    r(15407, 'Mind Flay filler'),
    r(585, 'Smite while leveling'),
})
set('SHAMAN', 'elemental', {
    r(8050, 'Maintain Flame Shock', 'dot', 0),
    r(421, 'Chain Lightning when ready'),
    r(1535, 'Fire Nova against multiple enemies', 'aoe'),
    r(403, 'Lightning Bolt filler'),
})
set('WARLOCK', 'affliction', {
    r(980, 'Maintain Bane of Agony', 'dot', 0),
    r(172, 'Maintain Corruption', 'dot', 0),
    r(18265, 'Maintain Siphon Life', 'dot', 0),
    r(348, 'Maintain Immolate', 'dot', 0),
    r(686, 'Use an instant Shadow Bolt proc', 'proc', 17941),
    r(1316697, 'Wrack while damage-over-time effects are active'),
    r(686, 'Shadow Bolt while leveling'),
})
-- Retain seal maintenance and add Forever's learned melee attacks. Full
-- weapon-speed-dependent seal twisting requires readable Echo stacks.
for _, profile in ipairs(A.profiles) do
    if profile.class == 'PALADIN' and profile.key == 'retribution' then
        table.insert(profile.rules, 4, r(1310903, 'Use Holy Strike when ready'))
        table.insert(profile.rules, 5, r(20473, 'Holy Shock if learned'))
    end
end
