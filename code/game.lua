game = {}

local _background_sprite = playdate.graphics.sprite.new()

function game.init( level_name )
	goto_level( level_name )
end

function goto_level( level_name, direction )
	if not level_name then return end

	local previous_level = game.level_name

	game.level_name = level_name
	LDtk.load_level( level_name )

	-- we release the previous level after loading the new one so that it doesn't unload the tileset if we reuse it
	LDtk.release_level( previous_level )
	playdate.graphics.sprite.removeAll()

	game.tilemap = LDtk.create_tilemap( level_name ) 

	_background_sprite:setTilemap( game.tilemap )
	_background_sprite:moveTo( 0, 0)
	_background_sprite:setCenter(0, 0)
	_background_sprite:setZIndex( -1 )
	_background_sprite:add()

	playdate.graphics.sprite.addWallSprites( game.tilemap, LDtk.get_empty_tileIDs( level_name, "Solid") )

	for index, entity in ipairs( LDtk.get_entities( level_name ) ) do
		if entity.name=="Player" then
			if entity.fields.EntranceDirection == direction then
				player.sprite:add()
				player.init( entity )
			end
		end
	end


	playdate.graphics.sprite.setAlwaysRedraw(true)
end

function game.shutdown()
	_background_sprite:remove()
	LDtk.release_level( game.level_name )
end


function game.update()
	player.update()
	playdate.graphics.sprite.update()
end

function game.drawBackground(x,y,w,h)
	-- game.tilemap:draw(0,0, playdate.geometry.rect.new(x,y,w,h))
	game.tilemap:draw(0,0)
end

