--[[
    Example Service
    
    This is an example to demonstrate how to use the BaseService class to implement a game service.
    
    **NOTE:** After declaring you service, you have to include your package inside the main.lua file!
]]--
require 'nadiyas_dungeon_collection.common'
require 'origin.services.baseservice'
require 'nadiyas_dungeon_collection.recruit_list'

--Declare class MenuTools
local MenuTools = Class('MenuTools', BaseService)


--[[---------------------------------------------------------------
    MenuTools:initialize()
      MenuTools class constructor
---------------------------------------------------------------]]
function MenuTools:initialize()
  BaseService.initialize(self)
  PrintInfo('MenuTools:initialize()')
end

--[[---------------------------------------------------------------
    MenuTools:__gc()
      MenuTools class gc method
      Essentially called when the garbage collector collects the service.
	  TODO: Currently causes issues.  debug later.
  ---------------------------------------------------------------]]
--function MenuTools:__gc()
--  PrintInfo('*****************MenuTools:__gc()')
--end


--[[---------------------------------------------------------------
    MenuTools:OnMenuButtonPressed()
      When the main menu button is pressed or the main menu should be enabled this is called!
      This is called as a coroutine.
---------------------------------------------------------------]]

--[[---------------------------------------------------------------
    MenuTools:OnMenuButtonPressed()
      When the main menu button is pressed or the main menu should be enabled this is called!
      This is called as a coroutine.
---------------------------------------------------------------]]
function MenuTools:OnMenuButtonPressed()
    -- TODO: Remove this when the memory leak is fixed or confirmed not a leak
    if MenuTools.MainMenu == nil then
        MenuTools.MainMenu = RogueEssence.Menu.MainMenu()
    end
    MenuTools.MainMenu:SetupChoices()
    local index = 4
    if RogueEssence.GameManager.Instance.CurrentScene == RogueEssence.Dungeon.DungeonScene.Instance then
        index = 5
    end
    MenuTools.MainMenu.Choices:RemoveAt(index)
    MenuTools.MainMenu.Choices:Insert(index, RogueEssence.Menu.MenuTextChoice(STRINGS:FormatKey("MENU_OTHERS_TITLE"), function () _MENU:AddMenu(MenuTools:CustomDungeonOthersMenu(), false) end))

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

        MenuTools.MainMenu.Choices:Insert(4, RogueEssence.Menu.MenuTextChoice(Text.FormatKey("MENU_JOBLIST_TITLE"), function () _MENU:AddMenu(BoardMenu:new(COMMON.MISSION_BOARD_TAKEN, nil, MenuTools.MainMenu).menu, false) end, taken_count > 0, job_list_color))
    end

    MenuTools.MainMenu:SetupTitleAndSummary()

    MenuTools.MainMenu:InitMenu()
    TASK:WaitTask(_MENU:ProcessMenuCoroutine(MenuTools.MainMenu))
end

function MenuTools:CustomDungeonOthersMenu()
    -- TODO: Remove this when the memory leak is fixed or confirmed not a leak
    if MenuTools.OthersMenu == nil then
        MenuTools.OthersMenu = RogueEssence.Menu.OthersMenu()
    end
    local menu = MenuTools.OthersMenu;
    menu:SetupChoices();

    local isGround = RogueEssence.GameManager.Instance.CurrentScene == RogueEssence.Ground.GroundScene.Instance
    local enabled = not isGround or not _DATA.Save.NoRecruiting
    local color = Color.White
    if not enabled then color = Color.Red end
    menu.Choices:Insert(1, RogueEssence.Menu.MenuTextChoice("Recruits", function () _MENU:AddMenu(RecruitListMainMenu:new(menu.Bounds.Width+menu.Bounds.X+2).menu, true) end, enabled, color))

    if SV.MissionsEnabled and RogueEssence.GameManager.Instance.CurrentScene == RogueEssence.Dungeon.DungeonScene.Instance then
        menu.Choices:Add(RogueEssence.Menu.MenuTextChoice("Mission Objectives", function () _MENU:AddMenu(DungeonJobList:new().menu, false) end))
    end
    menu:InitMenu();
    return menu
end


---Summary
-- Subscribe to all channels this service wants callbacks from
function MenuTools:Subscribe(med)
  med:Subscribe("MenuTools", EngineServiceEvents.MenuButtonPressed,        function() self.OnMenuButtonPressed() end )
end

---Summary
-- un-subscribe to all channels this service subscribed to
function MenuTools:UnSubscribe(med)
end


--Add our service
SCRIPT:AddService("MenuTools", MenuTools:new())
return MenuTools