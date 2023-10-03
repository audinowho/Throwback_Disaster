
ListType = luanet.import_type('System.Collections.Generic.List`1')
MobSpawnType = luanet.import_type('RogueEssence.LevelGen.MobSpawn')

function BATTLE_SCRIPT.MonsterOrbEvent(owner, ownerChar, context, args)
	context.TurnCancel.Cancel = true
  local radius = 5 -- 5 tiles square around the origin of the user!
  local shiny_rate = 32 -- 1/32 chance to be shiny!

  local rect_area = RogueElements.Loc(1)
  local rect_area2 = RogueElements.Loc(3)

  function checkBlock(loc)
    local result = _ZONE.CurrentMap:TileBlocked(loc)
    return result
  end

  function checkDiagBlock(loc)
    return true
  end

  local origin = context.User.CharLoc

  local leftmost_x = math.maxinteger
  local rightmost_x = math.mininteger

  local downmost_y = math.mininteger
  local upmost_y = math.maxinteger

  local top_left = RogueElements.Loc(origin.X - radius, origin.Y - radius)
  local bottom_right =  RogueElements.Loc(origin.X + radius, origin.Y + radius)

  local valid_tile_total = 0
  for x = math.max(top_left.X, 0), math.min(bottom_right.X, _ZONE.CurrentMap.Width - 1), 1 do
    for y = math.max(top_left.Y, 0), math.min(bottom_right.Y, _ZONE.CurrentMap.Height - 1), 1 do
      local testLoc = RogueElements.Loc(x,y)
      local is_choke_point = RogueElements.Grid.IsChokePoint(testLoc - rect_area, rect_area2, testLoc, checkBlock, checkDiagBlock)
      local tile_block = _ZONE.CurrentMap:TileBlocked(testLoc)
      local char_at = _ZONE.CurrentMap:GetCharAtLoc(testLoc)

      if tile_block == false and char_at == nil and not is_choke_point then
        valid_tile_total = valid_tile_total + 1
        leftmost_x = math.min(testLoc.X, leftmost_x)
        rightmost_x = math.max(testLoc.X, rightmost_x)
        downmost_y = math.max(testLoc.Y, downmost_y)
        upmost_y = math.min(testLoc.Y, upmost_y)
      end
    end
  end

  local house_event = PMDC.Dungeon.MonsterHouseMapEvent();

  local tl = RogueElements.Loc(leftmost_x - 1, upmost_y - 1)
  local br =  RogueElements.Loc(rightmost_x + 1, downmost_y + 1)

  local bounds = RogueElements.Rect.FromPoints(tl, br)
  house_event.Bounds = bounds

  local min_enemies = math.floor(valid_tile_total / 5)
  local max_enemies = math.floor(valid_tile_total / 4)
  local total_enemies = _DATA.Save.Rand:Next(min_enemies, max_enemies)
  
  local all_spawns = LUA_ENGINE:MakeGenericType( ListType, { MobSpawnType }, { })
  for i = 0,  _ZONE.CurrentMap.TeamSpawns.Count - 1, 1 do
    local possible_spawns = _ZONE.CurrentMap.TeamSpawns:GetSpawn(i):GetPossibleSpawns()
    for j = 0, possible_spawns.Count - 1, 1 do
      local spawn = possible_spawns:GetSpawn(j)
      all_spawns:Add(spawn)
    end
  end

  if all_spawns.Count > 0 then
    for _ = 1, total_enemies, 1 do
      local randint = _DATA.Save.Rand:Next(0, all_spawns.Count - 1)
      local spawn = all_spawns[randint]
      spawn.SpawnFeatures:Add(PMDC.LevelGen.MobSpawnAltColor(shiny_rate))
      house_event.Mobs:Add(spawn)
    end
  end

  if total_enemies > 0 and house_event.Mobs.Count > 0 then
    local charaContext = RogueEssence.Dungeon.SingleCharContext(context.User)
    TASK:WaitTask(house_event:Apply(owner, ownerChar, charaContext))
    GAME:WaitFrames(20)
  else
    GAME:WaitFrames(20)
    UI:WaitShowDialogue(RogueEssence.StringKey("MSG_NO_ENEMIES_SPAWN"):ToLocal())
    GAME:WaitFrames(20)
  end
end

local function LocToNearestItem(origin, radius, item_name)
  local x = 0
  local y = 0
  local dx, dy = 0, -1
  for _ = 1, radius ^ 2 do
    local testLoc = RogueElements.Loc(origin.X + x, origin.Y + y)
    local item_idx = _ZONE.CurrentMap:GetItem(testLoc)
  
    if item_idx ~= -1 then
      local item = _ZONE.CurrentMap.Items[item_idx]
      if item.Value == item_name then
        return testLoc
      end
    end

    if x == y or (x < 0 and x == -y) or (x > 0 and x == 1 - y) then
        dx, dy = -dy, dx  
    end
    x, y = x + dx, y + dy
  end
end

function BATTLE_SCRIPT.NearestItemInRadius(owner, ownerChar, context, args)
  local item_name = args.Item
  local radius = args.Radius
  local origin = context.User.CharLoc
  local item_loc = LocToNearestItem(origin, radius, item_name)
  if item_loc == nil then
    context.CancelState.Cancel = true
    local inv_item = RogueEssence.Dungeon.InvItem(item_name)
    local map_item = RogueEssence.Dungeon.MapItem(inv_item)
    local msg = RogueEssence.StringKey("MSG_NO_WARP_ITEM"):ToLocal()

    msg = string.gsub(msg, "%{0%}", map_item:GetDungeonName())

    UI:WaitShowDialogue(msg)
  elseif item_loc == context.User.CharLoc then
    context.CancelState.Cancel = true
    UI:WaitShowDialogue(STRINGS:FormatKey("MSG_WARP_FAIL", context.User:GetDisplayName(true)))
  else
    local tbl = LTBL(context.User)
    tbl.ItemLoc = item_loc
  end
end

function BATTLE_SCRIPT.WarpToItemEvent(owner, ownerChar, context, args)
  local tbl = LTBL(context.User)
  local item_loc = tbl.ItemLoc
  if item_loc ~= nil then
    TASK:WaitTask(_DUNGEON:WarpNear(context.User, item_loc, 0, true));
  end
  tbl.ItemLoc = nil
end