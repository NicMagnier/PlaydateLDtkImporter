import 'CoreLibs/graphics'
import 'CoreLibs/object'
import "CoreLibs/sprites"

import 'LDtk'

import 'code/game'
import 'code/player'
import 'code/balance'
import 'code/approach'

playdate.display.setRefreshRate(30)

-- we will try to load precomputed files only on the playdate itself to increase load speed
local use_ldtk_precomputed_levels = not playdate.isSimulator

-- Load the LDtk main file
LDtk.load( "levels/world.ldtk", use_ldtk_precomputed_levels )

-- if we run in the simulator, we export the level to the save directory.
if playdate.isSimulator then
	LDtk.export_to_lua_files()
end

player.create()
game.init( "Level_0" )

function playdate.update()
	game.update()
end