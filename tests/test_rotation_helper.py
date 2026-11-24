"""Forever port tests using Lua 5.1 and mocked WoW/ForeverAuras APIs."""
from pathlib import Path
from lupa.lua51 import LuaRuntime
ROOT = Path(__file__).resolve().parents[1]
lua = LuaRuntime(unpack_returned_tuples=True)
lua.execute((ROOT / 'tests/wow_mock.lua').read_text(encoding='utf-8'))
lua.execute(r"""
A = {}
AURA_DATA={}; AURA_LOGIN=true
ForeverAuras={
 IsLoginFinished=function() return AURA_LOGIN end,
 Add=function(data) AURA_DATA[data.id]=data end,
 GetData=function(id) return AURA_DATA[id] end,
 ScanEvents=function() end,
 OpenOptions=function(id) OPEN_AURA=id end,
}
WeakAuras=ForeverAuras
CLASS='DRUID'; KNOWN={}; COOLDOWNS={}; AURAS={}; USABLE={}; COMBO=0; FORM=1; COMBAT=false
SECRET={}
function issecretvalue(value) return rawequal(value, SECRET) end
function UnitClass() return CLASS, CLASS end
function UnitPowerType() return 3 end
function UnitPower(unit, powerType) if powerType==4 then return COMBO end return 100 end
function UnitPowerMax() return 100 end
function UnitCanAttack() return true end
function UnitIsDeadOrGhost() return false end
function UnitHealth() return 100 end
function UnitHealthMax() return 100 end
function GetComboPoints() return COMBO end
function GetShapeshiftFormID() return FORM end
function InCombatLockdown() return COMBAT end
Enum.SpellBookSpellBank={Player=0}
C_Spell={
 GetSpellInfo=function(id) return {name='Spell'..id,iconID=id,spellID=id} end,
 IsSpellUsable=function(id) if USABLE[id] ~= nil then return USABLE[id] end return true end,
 GetSpellCooldown=function(id) return COOLDOWNS[id] or {startTime=0,duration=0,isEnabled=true} end,
 IsSpellInRange=function() return true end,
}
C_SpellBook={
 FindSpellBookSlotForSpell=function(name) local id=tonumber(name:match('Spell(%d+)'));return KNOWN[id] end,
 GetSpellBookItemInfo=function(slot) return {spellID=slot,isPassive=false} end,
 IsSpellKnown=function(id) return KNOWN[id] ~= nil end,
}
C_UnitAuras={GetAuraDataByIndex=function(unit,index) return (AURAS[unit] or {})[index] end}
""")
addon = ROOT if (ROOT / 'RaynnaRotationHelper.toc').exists() else ROOT / 'RaynnaRotationHelper'
for line in (addon / 'RaynnaRotationHelper.toc').read_text(encoding='utf-8').splitlines():
    if line.strip() and not line.startswith('#'):
        lua.execute('assert(loadstring(...))("RaynnaRotationHelper", A)', (addon / line.replace('\\', '/')).read_text(encoding='utf-8'))
lua.execute(r"""
KNOWN[1822]=1823; KNOWN[1082]=1082; KNOWN[768]=768
A.events.OnEvent(A.events,'PLAYER_LOGIN')
assert(A.db and A.frame and A.aurasEnabled and not A.frame.shown, 'aura display replaces native panel')
assert(A.ResolveSpell(1822)==1823, 'current trained rank resolved')
assert(A.last.primary.id==1823, 'missing Rake recommended when data readable')
AURAS.target={{name='Spell1822',expirationTime=NOW+12}}
A.Update(); assert(A.last.primary.id==1082,'existing Rake leads to builder')
AURAS.target={{name=SECRET,expirationTime=SECRET}}
A.Update(); assert(A.last.primary.id==1082, 'secret aura does not block readable builder')
AURAS.target={}; COMBAT=true
A.Update(); assert(A.last.primary.id==1823,'readable empty combat scan supports missing Rake')
COMBAT=false; AURAS.target={}
COOLDOWNS[1823]={startTime=SECRET,duration=SECRET,isEnabled=true}
A.Update(); assert(A.last.primary.id==1082,'secret cooldown does not block ready builder')
COOLDOWNS[1823]=nil
local oldRange=C_Spell.IsSpellInRange
C_Spell.IsSpellInRange=function() return SECRET end
A.Update(); assert(A.last.primary.id==1823,'unknown range does not blank usable action')
C_Spell.IsSpellInRange=oldRange
COOLDOWNS[1823]={startTime=NOW,duration=1,isEnabled=true}
assert(A.Ready(1823)==false,'short real cooldown is not treated as GCD')
COOLDOWNS[61304]={startTime=NOW,duration=1,isEnabled=true}
assert(A.Ready(1823)==true,'actual GCD recognized')
COOLDOWNS={}
SlashCmdList.RAYNNAROTATIONHELPER('hide'); assert(A.db.hidden and not A.frame.shown)
SlashCmdList.RAYNNAROTATIONHELPER('show'); assert(not A.db.hidden and not A.frame.shown)
SlashCmdList.RAYNNAROTATIONHELPER('scale 10'); assert(A.db.scale==0.4)
SlashCmdList.RAYNNAROTATIONHELPER('scale 250'); assert(A.db.scale==1.8)
SlashCmdList.RAYNNAROTATIONHELPER('profile bear'); assert(A.Profile().key=='bear')
SlashCmdList.RAYNNAROTATIONHELPER('mode trash'); assert(A.db.mode=='trash')
assert(RaynnaModsSettingsRegistry.pages.rotationhelper,'shared settings integration')
for _,profile in ipairs(A.profiles) do
 A.class=profile.class; A.db.profile=profile.key; KNOWN={}; AURAS={}; USABLE={}
 for _,rule in ipairs(profile.rules) do KNOWN[rule.id]=rule.id end
 A.RefreshSpells(); local result=A.Evaluate()
 assert(result.profile==profile and #result.guide>0, 'every class profile yields a learned-spell guide')
 A.Draw(result)
end
A.class='MONK'; A.RefreshSpells(); assert(A.Evaluate().profile==nil, 'MoP-only classes not advertised')
A.class='DRUID'; A.db.profile='auto'; KNOWN={}; A.RefreshSpells()
assert(#A.Evaluate().guide==0,'unlearned spells are not suggested')
print('PASS: ForeverAuras login, ranks, aura/cooldown/range secrets, GCD, settings, all 28 profiles, unsupported classes')
""")

lua.execute(r"""
A.class='DRUID'; A.db.profile='cat'; A.db.hidden=false; A.db.actionBarGlow=true
KNOWN={[1082]=1082}; A.RefreshSpells(); A.Update()
ActionButton1=CreateFrame('Button'); ActionButton1.action=1; ActionButton1:Show()
GetActionInfo=function() return 'spell',1082 end
A.PrepareActionGlows(); A.UpdateActionGlows()
assert(A.actionGlows.ActionButton1.border.shown, 'readable primary glows on action bar')
GetActionInfo=function() return SECRET,SECRET end
A.UpdateActionGlows(); assert(not A.actionGlows.ActionButton1.border.shown, 'secret action slot ignored')
GetActionInfo=function() return 'spell',1082 end
A.db.hidden=true; A.UpdateActionGlows(); assert(not A.actionGlows.ActionButton1.border.shown,'hidden helper clears glow')
-- Settings callbacks do not overwrite percentage input every frame.
local settings = RaynnaModsSettingsRegistry.pages.rotationhelper.frame
assert(settings:GetScript('OnUpdate')==nil)
local input
for _,frame in ipairs(Frames) do if frame.parent==settings and frame.kind=='EditBox' then input=frame end end
input:SetText('85%'); input.OnEnterPressed(input); assert(A.db.scale==0.85)
input:SetText('invalid'); input.OnEnterPressed(input); assert(A.db.scale==0.85)
input:SetText('20%'); input.OnEscapePressed(input); assert(input:GetText()=='85%')
A.frame.OnDragStop(A.frame); assert(A.db.position.point=='CENTER')
print('PASS: action glow/secret action filtering, hide cleanup, scale entry and movement persistence')
""")
# Compile every Lua file in the release; the original MoP implementation stays unchanged.
for path in (addon / 'Forever').glob('*.lua'):
    lua.execute('assert(loadstring(...))', path.read_text(encoding='utf-8'))

lua.execute(r"""
A.db.hidden=false; A.db.profile='cat'; A.class='DRUID'; AURAS={}; COOLDOWNS={}; USABLE={}
KNOWN={[1822]=1823,[1082]=1082,[16857]=16857}; A.RefreshSpells(); A.Update()
assert(A.last.primary.id==1823 and A.last.support[1].id==16857,'primary and independent Faerie Fire')
AURAS.target={{name='Spell16857',expirationTime=NOW+40},{name='Spell1822',expirationTime=NOW+9}}
A.Update(); assert(A.last.primary.id==1082 and #A.last.support==0,'applied debuffs update both icons')
COOLDOWNS[1082]={startTime=SECRET,duration=SECRET,isActive=false,isEnabled=true}
assert(A.Ready(1082)==true,'public inactive cooldown accepted with secret timestamps')
USABLE[1082]=false; USABLE[1823]=false; A.Update()
assert(A.last.primary.pending,'waiting action retained when energy unavailable')
local id,label=RaynnaRotationHelperForeverSlot(1); assert(label=='WAIT')
USABLE={}; COOLDOWNS={}; AURAS={}; A.Update()
local group=AURA_DATA[A.auraGroupID]; assert(#group.controlledChildren==7)
for slot,id in ipairs(group.controlledChildren) do
 local data=AURA_DATA[id]; aura_env={}
 local active=assert(loadstring('return '..data.triggers[1].trigger.custom))()()
 assert(active==(slot==1 or slot==7), 'only populated live slots show')
 if active then assert(assert(loadstring('return '..data.triggers[1].trigger.customIcon))()()) end
end
SlashCmdList.RAYNNAROTATIONHELPER('hide'); assert(RaynnaRotationHelperForeverSlot(1)==nil)
SlashCmdList.RAYNNAROTATIONHELPER('show')
group.xOffset=123; group.yOffset=-44; A.InstallAuras()
assert(AURA_DATA[A.auraGroupID].xOffset==123 and AURA_DATA[A.auraGroupID].yOffset==-44,'saved aura position retained')
A.SetScale(0.8); assert(AURA_DATA[A.auraGroupID].scale==0.8)
SlashCmdList.RAYNNAROTATIONHELPER('unlock'); assert(OPEN_AURA==A.auraGroupID)
A.CenterAuras(); assert(AURA_DATA[A.auraGroupID].xOffset==0)
GetActionInfo=function() return 'spell',999,nil,1823 end
GetBindingKey=function(binding) assert(binding=='ACTIONBUTTON1'); return 'SHIFT-1' end
assert(A.KeyForSpell(1823)=='S-1','modern action spell ID and binding label')
A.UpdateActionGlows(); assert(A.actionGlows.ActionButton1.border.shown)
GetActionInfo=function() return 'spell',16857 end
A.UpdateActionGlows(); assert(A.actionGlows.ActionButton1.border.shown,'secondary action highlight')
UnitCanAttack=function() return false end; A.events.OnEvent(A.events,'PLAYER_TARGET_CHANGED')
assert(not A.last.primary and #A.last.support==0,'no offensive icons without hostile target')
print('PASS: generated aura triggers, dynamic secondary icons, public cooldown state, pending action, bindings, target changes, aura persistence')
""")

lua.execute(r"""
UnitCanAttack=function() return true end
UnitCastingInfo=function() return 'Cast',nil,nil,0,5,false,'cast-id',false,123 end
A.class='MAGE'; A.db.profile='fire'; KNOWN={[2139]=2139,[133]=133}; A.RefreshSpells(); A.Update()
assert(A.last.support[1].id==2139,'readable interruptible cast suggests Counterspell')
UnitCastingInfo=function() return 'Cast',nil,nil,0,5,false,'cast-id',SECRET,123 end
A.Update(); assert(#A.last.support==0,'unknown interruptibility does not imply interruptible')
local group=AURA_DATA[A.auraGroupID]
AURA_DATA[group.controlledChildren[1]].width=70
A.InstallAuras(); assert(AURA_DATA[group.controlledChildren[1]].width==70,'custom aura sizing retained')
print('PASS: interrupt eligibility and custom aura sizing persistence')
""")

lua.execute(r"""
-- Cat form must use the paged action slot, not the secure base index.
A.class='DRUID'; A.db.profile='cat'; A.db.hidden=false; FORM=1
KNOWN={[1822]=1823,[1082]=1082,[1079]=1079,[22568]=22568}; A.RefreshSpells()
ActionButton1.GetAttribute=function() return 1 end
ActionButton1.CalculateAction=function() return 73 end
ActionButton1.action=73
GetActionInfo=function(slot) if slot==73 then return 'spell',1823 else return 'spell',999 end end
GetBindingKey=function(binding) if binding=='ACTIONBUTTON1' then return '2' end end
COMBO=0; AURAS={}; COOLDOWNS={}; USABLE={}
A.Update(); assert(A.last.primary.id==1823)
assert(A.KeyForSpell(1823)=='2' and A.actionGlows.ActionButton1.border.shown,'paged Cat bar resolves both binding and glow')
GetBindingKey=function() return nil end
ActionButton1.HotKey=CreateFrame('FontString'); ActionButton1.HotKey:SetText('S-2')
assert(A.KeyForSpell(1823)=='S-2','displayed hotkey fallback')
local energy=100
UnitPower=function(unit,kind) return kind==4 and COMBO or energy end
local bleeds={}
C_UnitAuras.GetAuraDataBySpellName=function(unit,name,filter)
 assert(filter=='HARMFUL|PLAYER' or filter=='HELPFUL' or filter=='HARMFUL')
 return bleeds[unit..name]
end
AURAS.target={}
A.Update(); assert(A.last.primary.id==1823,'readable absent Rake is suggested')
bleeds.targetSpell1822={expirationTime=NOW+9}
A.Update(); assert(A.last.primary.id==1082,'build points while Rake is up')
COMBO=5; A.Update(); assert(A.last.primary.id==1079,'missing Rip at five points')
bleeds.targetSpell1079={expirationTime=NOW+12}
A.Update(); assert(A.last.primary.id==22568,'Bite with maintained bleeds and sufficient energy')
energy=45; A.Update(); assert(A.last.primary.id~=22568,'do not Bite without required energy')
bleeds.targetSpell1079={expirationTime=NOW+1}; A.Update(); assert(A.last.primary.id==1079,'refresh expiring Rip')
COMBO=0; bleeds.targetSpell1822=nil; A.Update(); assert(A.last.primary.id==1823,'expired Rake reapplied')
-- Talent selection is independent of having learned a hallmark ability.
C_ClassTalents={GetActiveConfigID=function() return 4 end}
C_Traits={
 GetConfigInfo=function() return {treeIDs={10}} end,
 GetGroupDisplayInfoByTreeID=function() return {{groupID=1},{groupID=2},{groupID=3}} end,
 GetTreeNodes=function() return {11,12,13} end,
 GetNodeInfo=function(config,id) return {ranksPurchased=id==12 and 5 or 1,groupIDs={id-10},activeEntry={entryID=id}} end,
 GetEntryInfo=function(config,id) return {definitionID=id} end,
 GetDefinitionInfo=function(id) return {spellID=1000+id} end,
}
A.class='MAGE'; A.db.profile='auto'; KNOWN={}; A.RefreshSpells(); A.RefreshTalents()
assert(A.Profile().key=='fire' and A.talentRanks[1012]==5,'dominant active talent branch and ranks')
A.db.profile='frost'; assert(A.Profile().key=='frost','explicit profile overrides talents')
A.class='DRUID'; A.db.profile='auto'; FORM=5; A.RefreshTalents()
assert(A.Profile().key=='bear','Druid form takes precedence over Feral talent branch')
print('PASS: paged bar bindings/glows, displayed hotkey fallback, complete Cat bleed/energy sequence, active talents and form overrides')
""")

lua.execute(r"""
A.class='DRUID'; A.db.profile='cat'; FORM=1; COMBO=0
KNOWN={[5221]=5221,[1082]=1082}; A.RefreshSpells(); A.talentRanks={[16966]=3}
UnitPower=function(unit,kind) return kind==4 and 0 or 100 end
A.Update(); assert(A.last.primary.id==5221 and A.last.alternate.id==1082,'Shredding Attacks changes builder with frontal alternative')
assert(RaynnaRotationHelperGetRecommendation(2)==1082,'original alternate-slot contract')
A.talentRanks={}; A.Update(); assert(A.last.primary.id==1082,'hybrid without Shredding Attacks uses Claw')
COOLDOWNS[61304]={duration=1.5,startTime=NOW}
local duration,expiry=RaynnaRotationHelperForeverGCD(); assert(duration==1.5 and expiry==NOW+1.5)
COOLDOWNS[61304]={duration=SECRET,startTime=SECRET}
assert(RaynnaRotationHelperForeverGCD()==0,'GCD rendering does not perform secret arithmetic')
print('PASS: talent-dependent Cat builder, positional alternative slot, readable GCD swipe')
""")

lua.execute(r"""
A.db.hidden=false; A.db.actionBarGlow=true
A.last={primary={id=1823},support={}}
local originalInfo=C_Spell.GetSpellInfo
C_Spell.GetSpellInfo=function(id) if id==1823 then return {name='Rake',iconID=1823} end return originalInfo(id) end
GetActionInfo=function() return 'macro',7 end
GetMacroSpell=function() return nil end
local body='#showtooltip\n/cast Rake\n/startattack [harm,nodead]'
GetMacroBody=function() return body end
GetBindingKey=function(binding) if binding=='ACTIONBUTTON1' then return '3' end end
assert(A.KeyForSpell(1823)=='3','exact user Rake macro supplies keybind')
A.UpdateActionGlows(); assert(A.actionGlows.ActionButton1.border.shown,'exact user Rake macro highlights')
body='#showtooltip\n/cast Rake (Rank 2)\n/startattack [harm,nodead]'
assert(A.KeyForSpell(1823)=='3','explicit rank suffix matches learned spell')
body='/say Rake\n/cast RakeSomethingElse\n/startattack'
assert(A.KeyForSpell(1823)=='','comments/chat and partial names do not match')
body='/cast [harm,nodead] Rake'
SecureCmdOptionParse=function() return 'Rake' end
assert(A.KeyForSpell(1823)=='3','active conditional branch')
SecureCmdOptionParse=function() return nil end
assert(A.KeyForSpell(1823)=='','inactive conditional branch')
SecureCmdOptionParse=nil
GetMacroBody=nil; GetMacroInfo=function() return 'Attack',123,'#showtooltip\n/cast Rake\n/startattack [harm,nodead]' end
assert(A.KeyForSpell(1823)=='3','legacy macro body API fallback')
GetMacroInfo=function() return 'Attack',123,SECRET end
assert(A.KeyForSpell(1823)=='','restricted macro text ignored')
GetMacroSpell=function() return 'Rake' end
assert(A.KeyForSpell(1823)=='3','macro API spell-name return supported')
print('PASS: exact Rake macro binding and glow, ranks, conditional branches, body API fallback, restricted text and false-positive filtering')
""")

lua.execute(r"""
GetMacroBody=function() return '#showtooltip\n/cast Rake\n/startattack [harm,nodead]' end
GetMacroSpell=function() return 99999 end
assert(A.KeyForSpell(1823)=='3','non-matching macro API result still falls back to exact cast text')
A.UpdateActionGlows(); assert(A.actionGlows.ActionButton1.border.shown)
A.DebugActionBars()
print('PASS: macro fallback after stale resolved spell and safe action-bar diagnostics')
""")

lua.execute(r"""
C_Spell.GetSpellInfo=function(id) return {name='Spell'..id,iconID=id} end
C_Secrets={ShouldAurasBeSecret=function() return false end}
C_UnitAuras.GetAuraDataBySpellName=function() return nil end
C_UnitAuras.GetUnitAuraBySpellID=nil
KNOWN={[1822]=1823}; A.RefreshSpells()
C_UnitAuras.GetAuraDataByIndex=function(unit,index)
 if index==1 then return {spellId=1823,name='DifferentRankName',expirationTime=NOW+8,applications=1} end
end
assert(A.AuraRemaining('target',1822,false)==8,'negative named lookup must not mask indexed learned rank')
C_UnitAuras.GetAuraDataByIndex=function() return nil end
C_UnitAuras.GetUnitAuraBySpellID=function(unit,id)
 if id==1823 then return {name=SECRET,expirationTime=SECRET,sourceUnit='player',isHarmful=true,applications=3} end
end
local state=A.AuraState('target',1822,false)
assert(state.present==true and state.remaining==nil and state.stacks==3)
assert(A.AuraNeedsRefresh('target',1822,false,0)==false,'known active bleed with hidden time is not reapplied')
assert(A.AuraStacks('target',1822,false)==3,'stack reader shares ID resolution')
C_UnitAuras.GetUnitAuraBySpellID=function(unit,id)
 if id==770 then return {expirationTime=NOW+30,sourceUnit='party1',isHarmful=true} end
end
assert(A.AuraNeedsRefresh('target',16857,false,0,true)==false,'caster Faerie Fire suppresses Feral variant regardless of caster')
C_UnitAuras.GetUnitAuraBySpellID=function(unit,id)
 if id==1823 then return {expirationTime=NOW+9,sourceUnit='party1',isHarmful=true} end
end
assert(A.AuraNeedsRefresh('target',1822,false,0)==true,'another player bleed does not replace ours')
assert(A.AuraNeedsRefresh('target',1822,false,0,true)==false,'explicit shared debuff permits another caster')
C_UnitAuras.GetUnitAuraBySpellID=function() return nil end
C_Secrets.ShouldAurasBeSecret=function() return true end
assert(A.AuraState('target',1822,false).present==nil,'restricted empty scans are unknown, not missing')
assert(A.AuraNeedsRefresh('target',1822,false,0)==nil)
C_Secrets.ShouldAurasBeSecret=function() return false end
local checked=0
for _,profile in ipairs(A.profiles) do
 for _,rule in ipairs(profile.rules) do
  if rule.condition=='dot' or rule.condition=='buff' or rule.condition=='proc' or rule.condition=='stacks'
      or (rule.condition=='combo' and (rule.id==1079 or rule.id==1943)) or rule.condition=='slice' then
   local base=rule.condition=='proc' and rule.value or (rule.condition=='stacks' and rule.value[1]) or rule.id
   local helpful=rule.condition=='buff' or rule.condition=='proc' or rule.condition=='stacks' or rule.condition=='slice'
   local unit=helpful and 'player' or 'target'
   local expiry=NOW+15
   C_UnitAuras.GetAuraDataByIndex=function(u,index,filter)
    if index==1 then return {spellId=base,name='Spell'..base,expirationTime=expiry,applications=3} end
   end
   assert(A.AuraNeedsRefresh(unit,base,helpful,2)==false,profile.class..':'..profile.key..' active aura')
   assert(A.AuraStacks(unit,base,helpful)==3)
   expiry=SECRET
   assert(A.AuraNeedsRefresh(unit,base,helpful,2)==false,'hidden duration preserves presence')
   expiry=NOW-1
   assert(A.AuraNeedsRefresh(unit,base,helpful,2)==true,'expired aura can be refreshed')
   C_UnitAuras.GetAuraDataByIndex=function() return nil end
   assert(A.AuraNeedsRefresh(unit,base,helpful,2)==true,'fully readable missing aura')
   checked=checked+1
  end
 end
end
assert(checked>25)
print('PASS: named lookup disagreement, learned ranks, hidden timers, caster ownership, Faerie Fire variants, restricted absence, '..checked..' profile aura rules')
""")

lua.execute(r"""
A.class='DRUID'; A.db.profile='cat'; FORM=1; COMBO=0
KNOWN={[1822]=1823,[1082]=1082,[16857]=16857}; A.RefreshSpells()
C_Secrets.ShouldAurasBeSecret=function() return true end
C_UnitAuras.GetAuraDataBySpellName=function() return nil end
C_UnitAuras.GetAuraDataByIndex=function() return nil end
C_UnitAuras.GetUnitAuraBySpellID=function(unit,id)
 if id==1823 then return {expirationTime=SECRET,sourceUnit='player',isHarmful=true} end
 if id==770 then return {expirationTime=NOW+30,sourceUnit='party1',isHarmful=true} end
end
A.Update(); assert(A.last.primary.id==1082,'applied Rake with hidden timer allows builder instead of repeating Rake')
for _,entry in ipairs(A.last.support) do assert(entry.id~=16857,'applied caster Faerie Fire suppresses Feral suggestion') end
A.DebugAuras()
print('PASS: screenshot scenario with indexed/name APIs unavailable and both applied debuffs detected by ID')
""")

lua.execute(r"""
-- Modern macro action IDs describe the spell, not a GetMacroSpell index.
A.last={primary={id=1823},support={}}; A.db.hidden=false
GetActionInfo=function() return 'macro',1823,'spell' end
GetMacroSpell=function() error('must not be called with a spell ID') end
GetBindingKey=function(binding) if binding=='ACTIONBUTTON1' then return '3' end end
assert(A.KeyForSpell(1823)=='3','modern spell macro resolves its binding directly')
A.UpdateActionGlows(); assert(A.actionGlows.ActionButton1.border.shown)
GetActionInfo=function() return 'macro',1823,'item' end
assert(A.KeyForSpell(1823)=='','item macro ID must not be interpreted as spell or macro index')
UnitExists=function() return true end
UnitIsVisible=function() return true end
local applied=false
C_Secrets.ShouldAurasBeSecret=function() return false end
C_UnitAuras.GetAuraDataBySpellName=function() return nil end
C_UnitAuras.GetAuraDataByIndex=function() return nil end
C_UnitAuras.GetUnitAuraBySpellID=function(unit,id)
 if id==1823 then return {sourceUnit='player',isHarmful=true,expirationTime=NOW+8} end
 if id==770 and applied then return {sourceUnit='player',isHarmful=true,expirationTime=NOW+30} end
end
A.class='DRUID'; A.db.profile='cat'; KNOWN={[1822]=1823,[1082]=1082,[16857]=16857}
A.RefreshSpells(); A.Update()
assert(A.last.primary.id==1082 and A.last.support[1].id==16857,'missing Faerie Fire shown while Rake remains active')
applied=true; A.Update(); assert(#A.last.support==0,'applied Faerie Fire hides')
applied=false; A.Update(); assert(A.last.support[1].id==16857,'removed Faerie Fire returns')
UnitIsVisible=function() return false end
assert(A.AuraState('target',16857,false,true).present==nil,'invisible target is not proof of absence')
UnitIsVisible=function() return true end
C_UnitAuras.GetUnitAuraBySpellID=function() return SECRET end
assert(A.AuraState('target',16857,false,true).present==nil,'secret returns cannot prove absence')
C_UnitAuras.GetUnitAuraBySpellID=function() error('restricted query') end
assert(A.AuraState('target',16857,false,true).present==nil,'query failures cannot prove absence')
print('PASS: modern spell/item macro contracts; missing/applied/removed Faerie Fire; visibility, secret and API-failure guards')
""")

lua.execute(r"""
-- FindSpellBookSlotForSpell may return rank one. Enumerate all trained ranks.
C_Spell.GetSpellInfo=function(id)
 local name=({[1822]='Rake',[1823]='Rake',[1824]='Rake',[1126]='Mark of the Wild',[5232]='Mark of the Wild'})[id]
 return {name=name or 'Spell'..id,iconID=id}
end
local spells={1822,1823,1824,1126,5232}
C_SpellBook.GetNumSpellBookSkillLines=function() return 1 end
C_SpellBook.GetSpellBookSkillLineInfo=function() return {itemIndexOffset=0,numSpellBookItems=5} end
C_SpellBook.GetSpellBookItemInfo=function(slot) return {spellID=spells[slot],isPassive=false,isOffSpec=false} end
C_SpellBook.GetSpellBookItemName=function(slot) return C_Spell.GetSpellInfo(spells[slot]).name,'Rank '..({1,2,3,1,2})[slot] end
C_SpellBook.IsSpellKnown=function(id) for _,v in ipairs(spells) do if id==v then return true end end return false end
C_SpellBook.FindSpellBookSlotForSpell=function(name) if name=='Rake' then return 1 elseif name=='Mark of the Wild' then return 4 end end
A.class='DRUID'; A.RefreshSpells()
assert(A.ResolveSpell(1822)==1824 and A.ResolveSpell(1126)==5232,'highest readable trained ranks selected')
C_Secrets.ShouldAurasBeSecret=function() return true end
C_UnitAuras.GetAuraDataBySpellName=function() return nil end
C_UnitAuras.GetAuraDataByIndex=function() return nil end
local appliedRank=1823
C_UnitAuras.GetUnitAuraBySpellID=function(unit,id)
 if id==appliedRank or id==5232 then return {spellId=id,sourceUnit='player',expirationTime=NOW+8} end
end
assert(A.AuraNeedsRefresh('target',1822,false,0)==false,'intermediate applied rank recognized even when highest learned differs')
assert(A.AuraNeedsRefresh('player',1126,true,0)==false,'ranked Mark recognized')
appliedRank=1824
assert(A.AuraNeedsRefresh('target',1822,false,0)==false,'highest applied rank recognized')
C_UnitAuras.GetUnitAuraBySpellID=function() return nil end
assert(A.AuraNeedsRefresh('target',1822,false,0)==nil,'empty combat APIs no longer prove absence even on a visible target')
A.DebugAuras()
print('PASS: full trained rank families, intermediate and highest aura ranks, ranked Mark, conservative restricted absence')
""")

lua.execute(r"""
C_UnitAuras.GetPlayerAuraBySpellID=function(id) if id==5232 then return {spellId=id,expirationTime=NOW+100} end end
assert(A.AuraNeedsRefresh('player',1126,true,0)==false,'player-only buff API detects ranked Mark')
C_UnitAuras.GetUnitAuras=function() return {{spellId=1824,name='Rake',expirationTime=NOW+8,sourceUnit='player'}} end
assert(A.AuraNeedsRefresh('target',1822,false,0)==false,'bulk aura API detects Rake when index/name queries are empty')
print('PASS: player-only buff API and bulk aura API fallbacks')
""")

lua.execute(r"""
C_UnitAuras.GetAuraDataByIndex=function() error('TEST: aura enumeration restricted') end
A.DebugAuras()
local found=false
for _,line in ipairs(A.db.auraDiagnostics) do
 if line:find('TEST: aura enumeration restricted',1,true) then found=true end
end
assert(found,'exact API error is retained in printed and saved diagnostics')
print('PASS: actionable API error detail retained')
""")

lua.execute(r"""
A.InstallAuras()
RaynnaRotationHelperForeverSlot=nil
RaynnaRotationHelperForeverGCD=nil
for _,id in ipairs(AURA_DATA[A.auraGroupID].controlledChildren) do
 local trigger=AURA_DATA[id].triggers[1].trigger
 aura_env={spell=1822,key='3'}
 assert(assert(loadstring('return '..trigger.custom))()()==false,'saved aura safely hides with addon disabled')
 assert(aura_env.spell==nil and aura_env.key==nil,'stale icon state cleared')
 if trigger.customDuration and trigger.customDuration~='' then
  local duration,expiry=assert(loadstring('return '..trigger.customDuration))()()
  assert(duration==0 and expiry==0,'disabled addon duration callback is safe')
 end
end
print('PASS: every persisted aura callback is safe with Rotation Helper disabled')
""")
