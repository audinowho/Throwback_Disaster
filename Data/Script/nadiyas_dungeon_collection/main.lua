--[[
  main.lua
  
  This file is loaded persistently.
  Its main purpose is to include anything that needs to stay persistently in the lua state.
  Things like services.
  If this file is modded, additional requires are added ON TOP of the base's requires.
  This is the only file with this behavior; everything else is overwrite!
]]--

--------------------------------------------------------------------------------------------------------------
-- Service Packages
--------------------------------------------------------------------------------------------------------------
--require 'nadiyas_dungeon_collection.services.chatter'
require 'nadiyas_dungeon_collection.services.debug_tools'
require 'nadiyas_dungeon_collection.services.menu_tools'
require 'nadiyas_dungeon_collection.services.upgrade_tools'
require 'nadiyas_dungeon_collection.services.music_service'

math.randomseed(os.time())