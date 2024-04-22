--[[
    Example Service
    
    This is an example to demonstrate how to use the BaseService class to implement a game service.
    
    **NOTE:** After declaring you service, you have to include your package inside the main.lua file!
]]--
require 'common'
require 'services.baseservice'
require 'mission_gen'
require 'recruit_list'

--Declare class DebugTools
local DebugTools = Class('DebugTools', BaseService)

--[[---------------------------------------------------------------
    DebugTools:initialize()
      DebugTools class constructor
---------------------------------------------------------------]]
function DebugTools:initialize()
  BaseService.initialize(self)
  PrintInfo('DebugTools:initialize()')
end

--[[---------------------------------------------------------------
    DebugTools:__gc()
      DebugTools class gc method
      Essentially called when the garbage collector collects the service.
	  TODO: Currently causes issues.  debug later.
  ---------------------------------------------------------------]]
--function DebugTools:__gc()
--  PrintInfo('*****************DebugTools:__gc()')
--end

--[[---------------------------------------------------------------
    DebugTools:OnInit()
      Called on initialization of the script engine by the game!
---------------------------------------------------------------]]
function DebugTools:OnInit()
  assert(self, 'DebugTools:OnInit() : self is null!')
  PrintInfo("\n<!> ExampleSvc: Init..")
end

--[[---------------------------------------------------------------
    DebugTools:OnDeinit()
      Called on de-initialization of the script engine by the game!
---------------------------------------------------------------]]
function DebugTools:OnDeinit()
  assert(self, 'DebugTools:OnDeinit() : self is null!')
  PrintInfo("\n<!> ExampleSvc: Deinit..")
end

--[[---------------------------------------------------------------
    DebugTools:OnSaveLoad()
      When the Continue button is pressed this is called!
---------------------------------------------------------------]]
function DebugTools:OnSaveLoad()
    PrintInfo("\n<!> DebugTools: LoadSavedData..")
    local lang = STRINGS:LocaleCode()
    if lang ~= SV.Services.RecruitList_lastLanguage then
        for _, ordered_zone_data in pairs(RECRUIT_LIST.getDungeonOrder()) do
            local zone_id = ordered_zone_data.zone
            ordered_zone_data.name = RECRUIT_LIST.getZoneSummary(zone_id).Name:ToLocal()
            local zone_data = RECRUIT_LIST.getDungeonListSV()[zone_id]
            if zone_data then
                for segment_id, segment_data in pairs(zone_data) do
                    segment_data.name = RECRUIT_LIST.build_segment_name(_DATA:GetZone(zone_id).Segments[segment_id])
                end
            end
        end
        SV.Services.RecruitList_lastLanguage = lang
    end
end

--[[---------------------------------------------------------------
    DebugTools:OnMenuButtonPressed()
      When the main menu button is pressed or the main menu should be enabled this is called!
      This is called as a coroutine.
---------------------------------------------------------------]]
function DebugTools:OnMenuButtonPressed()
    -- TODO: Remove this when the memory leak is fixed or confirmed not a leak
    if DebugTools.MainMenu == nil then
        DebugTools.MainMenu = RogueEssence.Menu.MainMenu()
    end

    DebugTools.MainMenu:SetupChoices()
    local index = 4
    if RogueEssence.GameManager.Instance.CurrentScene == RogueEssence.Dungeon.DungeonScene.Instance then
        index = 5
    end
    DebugTools.MainMenu.Choices:RemoveAt(index)
    DebugTools.MainMenu.Choices:Insert(index, RogueEssence.Menu.MenuTextChoice(STRINGS:FormatKey("MENU_OTHERS_TITLE"), function () _MENU:AddMenu(DebugTools:CustomDungeonOthersMenu(), false) end))

    --Custom menu stuff for jobs.
    --Check if we're in a dungeon or not. Only do main menu changes outside of a dungeon.
    if SV.MissionsEnabled and RogueEssence.GameManager.Instance.CurrentScene ~= RogueEssence.Dungeon.DungeonScene.Instance then
        --not in a dungeon
        --Add Job List option
        local taken_count = MISSION_GEN.GetTakenCount()
        local job_list_color = Color.Red
        if taken_count > 0 then
            job_list_color = Color.White
        end

        DebugTools.MainMenu.Choices:Insert(4, RogueEssence.Menu.MenuTextChoice(Text.FormatKey("MENU_JOBLIST_TITLE"), function () _MENU:AddMenu(BoardMenu:new(COMMON.MISSION_BOARD_TAKEN, nil, DebugTools.MainMenu).menu, false) end, taken_count > 0, job_list_color))
    end

    DebugTools.MainMenu:SetupTitleAndSummary()

    DebugTools.MainMenu:InitMenu()
    TASK:WaitTask(_MENU:ProcessMenuCoroutine(DebugTools.MainMenu))
end

function DebugTools:CustomDungeonOthersMenu()
    -- TODO: Remove this when the memory leak is fixed or confirmed not a leak
    if DebugTools.OthersMenu == nil then
        DebugTools.OthersMenu = RogueEssence.Menu.OthersMenu()
    end
    local menu = DebugTools.OthersMenu;
    menu:SetupChoices();

    local isGround = RogueEssence.GameManager.Instance.CurrentScene == RogueEssence.Ground.GroundScene.Instance
    local enabled = not isGround or not _DATA.Save.NoRecruiting
    local color = Color.White
    if not enabled then color = Color.Red end
    menu.Choices:Insert(1, RogueEssence.Menu.MenuTextChoice("Recruits", function () _MENU:AddMenu(RecruitMainChoice:new(menu.Bounds.Width+menu.Bounds.X+2).menu, true) end, enabled, color))

    if SV.MissionsEnabled and RogueEssence.GameManager.Instance.CurrentScene == RogueEssence.Dungeon.DungeonScene.Instance then
        menu.Choices:Add(RogueEssence.Menu.MenuTextChoice("Mission Objectives", function () _MENU:AddMenu(DungeonJobList:new().menu, false) end))
    end
    menu:InitMenu();
    return menu
end


--[[---------------------------------------------------------------
    DebugTools:OnNewGame()
      When a debug save file is loaded this is called!
---------------------------------------------------------------]]
function DebugTools:OnNewGame()
  assert(self, 'DebugTools:OnNewGame() : self is null!')

	for ii = 1, _DATA.Start.Chars.Count, 1 do
		_DATA.Save:RogueUnlockMonster(_DATA.Start.Chars[ii-1].ID.Species)
	end

	if _DATA.Save.ActiveTeam.Players.Count > 0 then
		local talk_evt = RogueEssence.Dungeon.BattleScriptEvent("AllyInteract")
		_DATA.Save.ActiveTeam.Players[0].ActionEvents:Add(talk_evt)
		_DATA.Save:RegisterMonster(_DATA.Save.ActiveTeam.Players[0].BaseForm.Species)

		_DATA.Save.ActiveTeam:SetRank("roguelocke")
		if not GAME:InRogueMode() then
			_DATA.Save.ActiveTeam:SetRank("none")
			_DATA.Save.ActiveTeam.Bank = 0
		end
		SV.General.Starter = _DATA.Save.ActiveTeam.Players[0].BaseForm
	else
		PrintInfo("\n<!> ExampleSvc: Preparing debug save file")
		_DATA.Save.ActiveTeam:SetRank("roguelocke")
		_DATA.Save.ActiveTeam.Name = "Debug"
		_DATA.Save.ActiveTeam.Money = 1000
		_DATA.Save.ActiveTeam.Bank = 1000000

		local mon_id = RogueEssence.Dungeon.MonsterID("td_shuilanlan", 0, "normal", Gender.Male)
		_DATA.Save.ActiveTeam.Players:Add(_DATA.Save.ActiveTeam:CreatePlayer(_DATA.Save.Rand, mon_id, 15, "", 0))
		mon_id = RogueEssence.Dungeon.MonsterID("td_notebeat", 0, "normal", Gender.Male)
		_DATA.Save.ActiveTeam.Players:Add(_DATA.Save.ActiveTeam:CreatePlayer(_DATA.Save.Rand, mon_id, 15, "", 0))
		mon_id = RogueEssence.Dungeon.MonsterID("td_powpow", 0, "normal", Gender.Male)
		_DATA.Save.ActiveTeam.Players:Add(_DATA.Save.ActiveTeam:CreatePlayer(_DATA.Save.Rand, mon_id, 15, "", 0))


		local talk_evt = RogueEssence.Dungeon.BattleScriptEvent("AllyInteract")
		_DATA.Save.ActiveTeam.Players[0].ActionEvents:Add(talk_evt)
		talk_evt = RogueEssence.Dungeon.BattleScriptEvent("AllyInteract")
		_DATA.Save.ActiveTeam.Players[1].ActionEvents:Add(talk_evt)
		talk_evt = RogueEssence.Dungeon.BattleScriptEvent("AllyInteract")
		_DATA.Save.ActiveTeam.Players[2].ActionEvents:Add(talk_evt)

		_DATA.Save.ActiveTeam.Leader.IsFounder = true

		_DATA.Save:UpdateTeamProfile(true)

		local dungeon_keys = _DATA.DataIndices[RogueEssence.Data.DataManager.DataType.Zone]:GetOrderedKeys(false)
		for ii = 0, dungeon_keys.Count-1 ,1 do
			GAME:UnlockDungeon(dungeon_keys[ii])
		end

		--for ii = 900, 2370, 1 do
		--  GAME:GivePlayerStorageItem(ii)
		--  SV.unlocked_trades[ii] = true
		--end

		--for ii = 1, 10000, 1 do
		--  mon_id = RogueEssence.Dungeon.MonsterID("bulbasaur", 0, "normal", Gender.Male)
		--  _DATA.Save.ActiveTeam.Assembly:Add(_DATA.Save.ActiveTeam:CreatePlayer(_DATA.Save.Rand, mon_id, 50, "", 0))
		--end

		if SV.base_camp ~= nil then
			SV.base_camp.ExpositionComplete = true
			SV.base_camp.IntroComplete = true
		end
		if SV.test_grounds ~= nil then
			SV.test_grounds.DemoComplete = true
		end
		SV.General.Starter = _DATA.Save.ActiveTeam.Players[0].BaseForm
	end
end

--[[---------------------------------------------------------------
    DebugTools:OnLossPenalty()
      Called when the player fails a dungeon in main progress
  ---------------------------------------------------------------]]
function DebugTools:OnLossPenalty(save) 
  assert(self, 'DebugTools:OnLossPenalty() : self is null!')
  
  --wipedout enable
  SV.wipedout = true
 
  --remove money
  save.ActiveTeam.Money = 0
  local inv_count = save.ActiveTeam:GetInvCount() - 1

  --remove bag items
  for i = inv_count, 0, -1 do
    local entry = _DATA:GetItem(save.ActiveTeam:GetInv(i).ID)
    if not entry.CannotDrop then
      save.ActiveTeam:RemoveFromInv(i)
    end
  end
  
  --remove equips
  local player_count = save.ActiveTeam.Players.Count
  for i = 0, player_count - 1, 1 do 
    local player = save.ActiveTeam.Players[i]
    if player.EquippedItem.ID ~= '' and player.EquippedItem.ID ~= nil then 
      local entry = _DATA:GetItem(player.EquippedItem.ID)
      if not entry.CannotDrop then
         player:SilentDequipItem()
      end
    end
  end
end

--[[---------------------------------------------------------------
    DebugTools:OnDungeonFloorEnd()
      When leaving a dungeon floor this is called.
---------------------------------------------------------------]]
function DebugTools:OnDungeonFloorEnd(ignore, ignore2)
    assert(self, 'DebugTools:OnDungeonFloorEnd() : self is null!')
    local location = RECRUIT_LIST.getCurrentMap()
    RECRUIT_LIST.generateDungeonListSV(location.zone, location.segment)

    -- update floor count for this location
    RECRUIT_LIST.updateFloorsCleared(location.zone, location.segment, location.floor)
    RECRUIT_LIST.markAsExplored(location.zone, location.segment)
end

--[[---------------------------------------------------------------
    DebugTools:OnUpgrade()
      When version differences are found while loading a save this is called.
---------------------------------------------------------------]]
function DebugTools:OnUpgrade()
    assert(self, 'DebugTools:OnUpgrade() : self is null!')
    PrintInfo("RecruitList =>> Loading version")
    local old_version = {Major = 0, Minor = 0, Build = 0, Revision = 0}
    -- get old version
    for i=0, _DATA.Save.Mods.Count-1, 1 do
        local mod = _DATA.Save.Mods[i]
        if mod.Name == "Dungeon Recruitment List" then
            old_version = mod.Version
            break
        end
    end

    --hide accidental dev mode message
    if old_version.Major < 2 or (old_version.Major == 2 and old_version.Minor < 3) or
            (old_version.Minor == 3 and old_version.Build < 1) then
        SV.Services.RecruitList_show_unrecruitable = nil
    end

    -- update dungeon list data
    local list =  RECRUIT_LIST.getDungeonListSV()
    if old_version.Major < 2 or (old_version.Major == 2 and old_version.Minor < 2) then
        SV.Services.RecruitList_DungeonOrder = {}
        for zone, zone_data in pairs(list) do
            for segment, _ in pairs(zone_data) do
                if old_version.Major < 2 or (old_version.Major == 2 and old_version.Minor < 0) then
                    RECRUIT_LIST.generateDungeonListSV(zone, segment)
                else
                    RECRUIT_LIST.updateSegmentName(zone, segment)
                end
                RECRUIT_LIST.markAsExplored(zone, segment)
            end
        end
    end

    -- update dungeon order data
    if old_version.Major < 2 or (old_version.Major == 2 and old_version.Minor < 0) then
        local order = RECRUIT_LIST.getDungeonOrder()
        for _, entry in pairs(order) do
            if list[entry.zone] then
                for segment, _ in pairs(list[entry.zone]) do
                    RECRUIT_LIST.markAsExplored(entry.zone, segment)
                end
            end
        end

        -- add all completed dungeons
        for entry in luanet.each(_DATA.Save.DungeonUnlocks) do
            if entry.Value == RogueEssence.Data.GameProgress.UnlockState.Completed and
                    not RECRUIT_LIST.segmentDataExists(entry.Key, 0) then

                local data = RECRUIT_LIST.getSegmentData(entry.Key, 0)
                if data ~= nil then
                    local length = data.totalFloors
                    RECRUIT_LIST.updateFloorsCleared(entry.Key,0, length)
                    RECRUIT_LIST.markAsExplored(entry.Key, 0)
                end
            end
        end
    end

    PrintInfo("RecruitList =>> Loaded version")
end


---Summary
-- Subscribe to all channels this service wants callbacks from
function DebugTools:Subscribe(med)
    med:Subscribe("DebugTools", EngineServiceEvents.Init,                function() self.OnInit(self) end )
    med:Subscribe("DebugTools", EngineServiceEvents.Deinit,              function() self.OnDeinit(self) end )
    med:Subscribe("DebugTools", EngineServiceEvents.MenuButtonPressed,        function() self.OnMenuButtonPressed() end )
    med:Subscribe("DebugTools", EngineServiceEvents.NewGame,        function() self.OnNewGame(self) end )
    med:Subscribe("DebugTools", EngineServiceEvents.LossPenalty,        function(_, args) self.OnLossPenalty(self, args[0]) end )
    med:Subscribe("DebugTools", EngineServiceEvents.DungeonFloorExit,  function(dungeonloc, result) self.OnDungeonFloorEnd(self, dungeonloc, result) end )
    med:Subscribe("DebugTools", EngineServiceEvents.UpgradeSave,       function(mapid) self.OnUpgrade(self) end )
    med:Subscribe("DebugTools", EngineServiceEvents.LoadSavedData,     function() self.OnSaveLoad(self) end )
end

---Summary
-- un-subscribe to all channels this service subscribed to
function DebugTools:UnSubscribe(med)
end

---Summary
-- The update method is run as a coroutine for each services.
function DebugTools:Update(gtime)
    --  while(true)
    --    coroutine.yield()
    --  end
end

--Add our service
SCRIPT:AddService("DebugTools", DebugTools:new())
return DebugTools