game = {}

local layerSprites = {}
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

	layerSprites = {}
	for layer_name, layer in pairs(LDtk.get_layers(level_name)) do
		if not layer.tiles then
			goto continue
		end

		local tilemap = LDtk.create_tilemap(level_name, layer_name)

		local layerSprite = playdate.graphics.sprite.new()
		layerSprite:setTilemap(tilemap)
		layerSprite:moveTo(0, 0)
		layerSprite:setCenter(0, 0)
		layerSprite:setZIndex(layer.zIndex)
		layerSprite:add()
		layerSprites[layer_name] = layerSprite

		local emptyTiles = LDtk.get_empty_tileIDs(level_name, "Solid", layer_name)

		if emptyTiles then
			playdate.graphics.sprite.addWallSprites(tilemap, emptyTiles)
		end

		::continue::
	end

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
	for layer_name in pairs(LDtk.get_layers(game.level_name)) do
        layerSprites[layer_name]:remove()
        layerSprites[layer_name] = nil
    end

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

