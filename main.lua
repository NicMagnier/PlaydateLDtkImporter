import 'CoreLibs/graphics'
import 'CoreLibs/object'
import "CoreLibs/sprites"

import 'LDtk'

import 'code/game'
import 'code/player'
import 'code/balance'
import 'code/approach'

playdate.display.setRefreshRate(30)

local ldtk_file = "levels/world.ldtk"
local use_ldtk_fastloading = true

-- simplest method is just to load the levels as is
-- this method should be fine for most cases
if not use_ldtk_fastloading then
	LDtk.load( ldtk_file )

-- To speed up loading times, you can export you levels as lua files and load them precompiled
else
	if playdate.isSimulator then
		-- In the simulator, we load the ldtk file and export the levels as lua files
		-- You need to copy the lua files in your project
		LDtk.load( ldtk_file )
		LDtk.export_to_lua_files()
	else
		-- On device, we tell the library to load using the lua files
		LDtk.load( ldtk_file, use_ldtk_fastloading )
	end
end


player.create()
game.init( "Level_0" )

function playdate.update()
	game.update()
end