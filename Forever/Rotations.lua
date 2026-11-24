local _, A = ...

-- Classic baseline priorities, not the MoP simulation. Only learned spells are
-- displayed. Hints remain visible when Forever withholds a rule's combat data.
-- Profile selection is explicit; Auto uses learned hallmark spells and form.
A.profiles = {}
local function rule(id, hint, condition, value)
    return { id = id, hint = hint, condition = condition, value = value }
end
local function add(class, key, name, signature, rules)
    table.insert(A.profiles, { class = class, key = key, name = name, signature = signature, rules = rules })
end
local function dot(id, hint)
    return rule(id, hint or 'Maintain your damage over time effect', 'dot', 2)
end
local function buff(id, hint)
    return rule(id, hint or 'Maintain this buff', 'buff', 0)
end
local function hit(id, hint)
    return rule(id, hint or 'Use when ready')
end
local function aoe(id, hint)
    return rule(id, hint or 'Use against multiple enemies', 'aoe')
end
local function finisher(id, hint)
    return rule(id, hint, 'combo', 5)
end

add('DRUID', 'cat', 'Feral Cat', 768, {
    finisher(1079, 'At 5 combo points, maintain Rip'),
    dot(1822, 'Maintain Rake'),
    finisher(22568, 'At 5 combo points, Bite if Rip will last'),
    hit(5221, 'Shred from behind; use Claw from the front'),
    hit(1082, 'Claw when you cannot Shred'),
})
add('DRUID', 'bear', 'Feral Bear', 5487, {
    dot(99, 'Maintain Demoralizing Roar'),
    aoe(779, 'Swipe for several enemies'),
    hit(6807, 'Queue Maul when you have spare rage'),
})
add('DRUID', 'balance', 'Balance', 24858, {
    dot(8921),
    dot(5570),
    hit(2912, 'Starfire for sustained damage'),
    hit(5176, 'Wrath for a shorter cast'),
})
add('DRUID', 'restoration', 'Restoration (damage)', 18562, { dot(8921), hit(5176) })

add('WARRIOR', 'arms', 'Arms', 12294, {
    rule(5308, 'Execute below 20% target health', 'execute', 20),
    hit(7384, 'Overpower after a dodge'),
    hit(12294),
    aoe(1680),
    hit(1464, 'Slam when it will not delay your weapon swing'),
    rule(78, 'Queue Heroic Strike only with spare rage', 'rage', 50),
})
add('WARRIOR', 'fury', 'Fury', 23881, {
    rule(5308, 'Execute below 20% target health', 'execute', 20),
    hit(23881),
    aoe(1680),
    rule(78, 'Queue Heroic Strike only with spare rage', 'rage', 50),
})
add('WARRIOR', 'protection', 'Protection', 23922, {
    hit(23922),
    hit(6572, 'Revenge after blocking, dodging or parrying'),
    rule(7386, 'Build and maintain 5 Sunder Armor stacks', 'manual'),
    rule(78, 'Queue Heroic Strike only with spare rage', 'rage', 50),
})

add('PALADIN', 'retribution', 'Retribution', 20375, {
    buff(20375, 'Maintain Seal of Command'),
    buff(21084, 'Use Seal of Righteousness if Command is unavailable'),
    hit(20271, 'Judge, then refresh your seal'),
    aoe(26573),
    rule(24275, 'Hammer of Wrath below 20% target health', 'execute', 20),
})
add('PALADIN', 'protection', 'Protection', 20925, {
    buff(25780, 'Maintain Righteous Fury while tanking'),
    buff(21084),
    hit(20925, 'Maintain Holy Shield while tanking'),
    hit(26573, 'Consecrate when enemies are in melee'),
    hit(20271),
})
add('PALADIN', 'holy', 'Holy (damage)', 20473, { buff(21084), hit(20271), hit(20473) })

add('HUNTER', 'beast', 'Beast Mastery', 19574, {
    dot(1978, 'Maintain Serpent Sting on lasting targets'),
    hit(3044),
    aoe(2643),
    rule(75, 'Keep Auto Shot running; avoid clipping shots', 'manual'),
})
add('HUNTER', 'marks', 'Marksmanship', 19434, {
    dot(1978),
    hit(19434, 'Aimed Shot between Auto Shots'),
    hit(3044),
    aoe(2643),
    rule(75, 'Keep Auto Shot running', 'manual'),
})
add('HUNTER', 'survival', 'Survival', 19386, {
    dot(1978),
    hit(3044),
    aoe(2643),
    rule(75, 'Keep Auto Shot running', 'manual'),
})

add('ROGUE', 'combat', 'Combat', 13877, {
    rule(5171, 'Spend combo points to maintain Slice and Dice', 'slice'),
    finisher(2098, 'Eviscerate at 5 combo points'),
    hit(1752, 'Build combo points with Sinister Strike'),
})
add('ROGUE', 'assassination', 'Assassination', 14177, {
    rule(5171, 'Maintain Slice and Dice', 'slice'),
    finisher(1943, 'At 5 combo points, maintain Rupture'),
    finisher(2098, 'Eviscerate if Rupture will last'),
    hit(53, 'Backstab from behind with a dagger'),
    hit(1752, 'Sinister Strike from the front'),
})
add('ROGUE', 'subtlety', 'Subtlety', 16511, {
    rule(5171, 'Maintain Slice and Dice', 'slice'),
    finisher(2098, 'Eviscerate at 5 combo points'),
    hit(16511),
    hit(53, 'Backstab from behind with a dagger'),
    hit(1752),
})

add(
    'MAGE',
    'frost',
    'Frost',
    11958,
    { aoe(10, 'Blizzard when it is safe to channel'), hit(116), hit(2136, 'Fire Blast while moving') }
)
add('MAGE', 'fire', 'Fire', 11129, { hit(133), hit(2136, 'Fire Blast while moving'), aoe(2120) })
add(
    'MAGE',
    'arcane',
    'Arcane',
    12042,
    { hit(5143, 'Arcane Missiles when safe to channel'), hit(133), aoe(1449) }
)

add('PRIEST', 'shadow', 'Shadow', 15473, {
    dot(589),
    hit(8092),
    hit(15407, 'Mind Flay when safe to channel'),
    hit(585),
})
add('PRIEST', 'discipline', 'Discipline (damage)', 10060, { dot(589), hit(8092), hit(585) })
add('PRIEST', 'holy', 'Holy (damage)', 15430, { dot(14914), dot(589), hit(585) })

add(
    'SHAMAN',
    'elemental',
    'Elemental',
    16166,
    { dot(8050), aoe(421), hit(403), hit(8042, 'Earth Shock for instant damage') }
)
add(
    'SHAMAN',
    'enhancement',
    'Enhancement',
    17364,
    { hit(17364), dot(8050), hit(8042), hit(403, 'Lightning Bolt when outside melee') }
)
add('SHAMAN', 'restoration', 'Restoration (damage)', 16190, { dot(8050), hit(403) })

add('WARLOCK', 'affliction', 'Affliction', 18220, { dot(172), dot(980), hit(686) })
add('WARLOCK', 'demonology', 'Demonology', 19028, { dot(172), dot(348), dot(980), hit(686) })
add(
    'WARLOCK',
    'destruction',
    'Destruction',
    17962,
    { dot(348), dot(172), hit(17962, 'Conflagrate near the end of Immolate'), hit(686) }
)

-- Side slots are labelled reference actions, never automatic casts or health advice.
A.support = {
    DRUID = { 22812, 1850, 5185, 5487 },
    WARRIOR = { 871, 6552, 355, 6673 },
    PALADIN = { 642, 633, 853, 635 },
    HUNTER = { 5384, 5116, 136, 883 },
    ROGUE = { 5277, 1766, 1856, 2983 },
    MAGE = { 45438, 2139, 1953, 1459 },
    PRIEST = { 17, 139, 2061, 1243 },
    SHAMAN = { 331, 8042, 324, 556 },
    WARLOCK = { 6789, 5782, 1454, 688 },
}
A.defaults = {
    DRUID = 'balance',
    WARRIOR = 'arms',
    PALADIN = 'retribution',
    HUNTER = 'beast',
    ROGUE = 'combat',
    MAGE = 'frost',
    PRIEST = 'shadow',
    SHAMAN = 'elemental',
    WARLOCK = 'affliction',
}
