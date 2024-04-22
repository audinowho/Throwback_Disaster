require 'common'
COMMONEX = {}

function COMMONEX.MaxPartySet(val)
  RogueEssence.Dungeon.ExplorerTeam.MAX_TEAM_SLOTS = val
end

function COMMONEX.PlayerCutscene()
  local character = RogueEssence.Dungeon.CharData()
  character.BaseForm = RogueEssence.Dungeon.MonsterID(SV.General.Starter.Species, SV.General.Starter.Form, SV.General.Starter.Skin, LUA_ENGINE:LuaCast(SV.General.Starter.Gender, Gender))
  GROUND:SetPlayer(character)
end

function COMMONEX.PointIncrease(val)
  UI:ResetSpeaker()
  local rankset = "none"
  local point = SV.global_quest.Points + val
  SV.global_quest.Points = point
  if point >= 1    then rankset = "normal" end
  if point >= 3    then rankset = "bronze" end
  if point >= 8    then rankset = "silver" end
  if point >= 25   then rankset = "gold" end
  if point >= 45   then rankset = "platinum" end
  if point >= 90   then rankset = "diamond" end
  if point >= 200  then rankset = "super" end
  if point >= 350  then rankset = "ultra" end
  if point >= 600  then rankset = "hyper" end
  if point >= 1000 then rankset = "master" end
  if point >= 2000 then rankset = "grandmaster" end
  UI:WaitShowDialogue(STRINGS:Format("Point Get: +{0} (Points: {1}, Rank: {2})", val, point, rankset))
  _DATA.Save.ActiveTeam:SetRank(rankset)
end

function COMMONEX.SidequestAccept(questname)
  SOUND:PlayFanfare("Fanfare/QuestAccept")
  UI:ResetSpeaker()
  UI:SetCenter(true)
  UI:WaitShowTimedDialogue(STRINGS:Format("New Quest: {0} has been accepted.", questname), 150)
  UI:SetCenter(false)
end

function COMMONEX.CharacterIntroduction(bg)
  UI:WaitShowBG(bg, 3, 120)
  GAME:WaitFrames(600)
  UI:WaitHideBG(120)
end

function COMMONEX.SidequestCleared(questname)
  SOUND:PlayFanfare("Fanfare/QuestCleared")
  UI:ResetSpeaker()
  UI:SetCenter(true)
  UI:WaitShowTimedDialogue(STRINGS:Format("{0} Quest has been cleared, Good job!", questname), 300)
  UI:SetCenter(false)
end

function COMMONEX.SpecialCharJoined(member,name,fanfare)
  UI:ResetSpeaker()
  if GAME:GetPlayerPartyCount() < 8 then
	_DATA.Save.ActiveTeam.Players:Add(member)
	local partycount = GAME:GetPlayerPartyCount()
	talk_evt = RogueEssence.Dungeon.BattleScriptEvent("AllyInteract")
    _DATA.Save.ActiveTeam.Players[partycount-1].ActionEvents:Add(talk_evt)
  else
    _DATA.Save.ActiveTeam.Assembly:Add(member)
	local assemblyCount = GAME:GetPlayerAssemblyCount()
	talk_evt = RogueEssence.Dungeon.BattleScriptEvent("AllyInteract")
    _DATA.Save.ActiveTeam.Assembly[assemblyCount-1].ActionEvents:Add(talk_evt)
  end
  if fanfare == 1 then
    SOUND:PlayFanfare("Fanfare/Friendship")
  elseif fanfare == 2 then
    SOUND:PlayFanfare("Fanfare/JoinTeam")
  end
  if fanfare == 2 then
    UI:SetCenter(true)
    UI:WaitShowTimedDialogue(STRINGS:Format("{0} joined the party.", name), 150)
    UI:SetCenter(false)
  end
end

function COMMONEX.SpecialCharLeft(uuid,name,notice)

  local party_table = GAME:GetPlayerPartyTable()
  UI:ResetSpeaker()
  local in_party = false
  for ii = 1, #party_table, 1 do
	local ent = party_table[ii]
	if ent.OriginalUUID == uuid then
	  in_party = true
	  j=ii-1
      break
	end
  end

  if not in_party then
	local assemblyCount = GAME:GetPlayerAssemblyCount()

    for i = 1,assemblyCount,1 do
	  p = GAME:GetPlayerAssemblyMember(i-1)
	  if p.OriginalUUID == uuid then --ERROR (attempt to index a number value (global 'p'))
		UI:WaitShowDialogue(STRINGS:Format("{0}, {1}", p.OriginalUUID, p.Nickname))
		j = i-1
	  end
    end
	GAME:RemovePlayerAssembly(j)
  else
    GAME:RemovePlayerTeam(j)
  end

  local partycount = GAME:GetPlayerPartyCount()
  
  if partycount == 0 then
    GAME:RemovePlayerAssembly(0)
	GAME:AddPlayerTeam(GAME:GetPlayerAssemblyMember(0))
  end
  if notice then
    SOUND:PlayFanfare("Fanfare/LeaveTeam")
    UI:SetCenter(true)
    UI:WaitShowTimedDialogue(STRINGS:Format("{0} left the party.", name), 120)
    UI:SetCenter(false)
  end
end

function COMMONEX.SpecialCharSave(uuid)
  local in_party = false
  for ii = 1, #party_table, 1 do
	local ent = party_table[ii]
	if ent.OriginalUUID == uuid then
	  savedstat = ent
      break
	end
  end

  if not in_party then
	local assemblyCount = GAME:GetPlayerAssemblyCount()

    for i = 1,assemblyCount,1 do
      p = GAME:GetPlayerAssemblyMember(i-1)
	  if p.OriginalUUID == uuid then
		savedstat = p
	  end
    end
  end
  return savedstat
end

function COMMONEX.SmoothRemove(char_)
  GROUND:Hide(char_)
  GAME:WaitFrames(15)
  GROUND:Unhide(char_)
  GAME:WaitFrames(15)
  GROUND:Hide(char_)
  GAME:WaitFrames(10)
  GROUND:Unhide(char_)
  GAME:WaitFrames(10)
  GROUND:Hide(char_)
  GAME:WaitFrames(5)
  GROUND:Unhide(char_)
  GAME:WaitFrames(5)
  GROUND:Hide(char_)
  GAME:WaitFrames(2)
  GROUND:Unhide(char_)
  GAME:WaitFrames(2)
  GROUND:RemoveCharacter(char_)
end

function COMMONEX.BossRest()
  UI:WaitShowDialogue(STRINGS:Format("You grew tired from the boss fight, and went to sleep in safe place for hours."))
  SOUND:PlayFanfare("Fanfare/GoodNight")
  GAME:WaitFrames(277)
end