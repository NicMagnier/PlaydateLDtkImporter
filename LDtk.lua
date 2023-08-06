-- version 1.03
--
-- Read levels made with LDtk level editor
-- More information about LDtk: https://ldtk.io/
--
-- Load the levels at the beginning of the game
--	LDtk.load( "levels/world.ldtk" )
--	tilemap = LDtk.create_tilemap( "Level_0" )
--
-- To get collision information, in LDtk create an enum for tiles (Wall, Water, Ladder etc.)
-- Use the enum in the tileset and tag tiles with the desired property
-- In your code:
-- 	playdate.graphics.sprite.addWallSprites( game.tilemap, LDtk.get_empty_tileIDs( "Level_0", "Solid") )

-- Tilsets
-- It is recommended to save the tileset image in the same folder (or in a sub folder) as the ldtk file
-- The tileset needs to be an image table so the filename should have the format: mytileset-table-w-h.format
-- If a tilemap use flipped tiles, you need to create an additional tileset image that includes mirrored version of the tiles
-- Original tileset: mytileset-table-8-8.png
-- Additional tileset filename: flipped-mytileset-table-8-8.png
-- Original tiles
--	(=\
-- Flipped tiles (image is 100% larger width and height, right side is flipped horozontally, bottom side is flipped vertically)
--	(=\/=)
--	(=/\=)

-- External levels
-- LDtk has an option to save each level in seperate files.
-- That allows you to load and unload levels when you need it instead of having the whole world in memory.
-- 	LDtk.load_level( "Level_1" )
--	LDtk.release_level( "Level_0" )
-- Note: release_level() is freeing the tileset so it is better to release a level after loading the next level if they use the same tilesets.

-- Fast loading
-- Parsing json can be long especially when running on the playdate
-- to speed up loading there is an option to load directly lua files
-- in the simulator call LDtk.export_to_lua_files() after a LDtl file is loaded to save the exported lua files in the save folder
-- copy the LDtk_lua_levels/ next to your .ldtk file in your project directory

LDtk = {}

local _ldtk_filepath = nil
local _ldtk_folder = nil
local _ldtk_filename = nil
local _ldtk_folder_table = nil
local _ldtk_lua_folder = nil

local _ldtk_lua_foldername = "LDtk_lua_levels"

local _level_files = {}
local _levels = {}
local _level_names = {} -- uids to name
local _level_rects = {}
local _tilesets = {}
local _imageTables = {}

local _use_external_files = false
local _use_lua_levels = false

local _ = {} -- for private functions

-- @use_lua_levels(optional)
--	true: will load lua precomputed levels
--	false: will load .ldtk files (slower)
--	nil: will load lua files if they exist
function LDtk.load( ldtk_file, use_lua_levels )
	_ldtk_filepath = ldtk_file
	_ldtk_folder, _ldtk_filename = _.get_folder_and_filename( ldtk_file )
	_ldtk_folder_table = _.get_folder_table( _ldtk_folder )
	_ldtk_lua_folder = _ldtk_folder.._ldtk_lua_foldername

	local lua_filename = _ldtk_lua_folder.._ldtk_filename..".pdz"

	-- check if we should load the lua files instead of the json files
	_use_lua_levels = use_lua_levels
	if _use_lua_levels then
		_use_lua_levels = playdate.file.exists( lua_filename )
	end

	-- simply load the level from the precomputed lua file
	if _use_lua_levels then
		print("LDtk Importer will use lua precomputed levels.")
		local data = playdate.file.run( lua_filename )

		_tilesets = data.tilesets
		_level_files = data.level_files
		_level_names = data.level_names
		_level_rects = data.level_rects
		_levels = data.levels
		_use_external_files = data.use_external_files

		if not _use_external_files then
			for level_name in pairs(_levels) do
				_.load_tileset( level_name )
			end
		end
		return
	end

	local data = json.decodeFile(ldtk_file)

	_use_external_files = data.externalLevels

	-- handle the tilesets
	for tileset_index, tileset_data in ipairs(data.defs.tilesets) do
		local tileset = {}

		_tilesets[ tileset_data.uid ] = tileset

		tileset.imageTable_filename = _.convert_relative_folder( tileset_data.relPath )
		tileset.imageWidth = tileset_data.pxWid
		tileset.imageHeight = tileset_data.pxHei

		-- Tile IDs list
		local gsize = tileset_data.tileGridSize
		local cw, ch = tileset_data.__cWid, tileset_data.__cHei
		local cw2, ch2 = cw*2, ch*2

		tileset.tileIDs = {}
		tileset.tileIDs_empty = {}
		tileset.tileIDs_flipped = {}
		tileset.tileIDs_flipped_empty = {}
		for index, enum_def in ipairs(tileset_data.enumTags) do
			local tileIDs = {}
			local tileIDs_flipped = {}

			local registered_tileIDs = {}
			local registered_tileIDs_flipped = {}

			for i, tileID in ipairs( enum_def.tileIds ) do
				-- normal tileset
				table.insert( tileIDs, 1+tileID)
				registered_tileIDs[ 1+tileID ] = true

				-- flipped tileset
				local cy = tileID//cw
				local cx = tileID - cy*cw
				local tileID_flip_no = 1 + cy*cw2 + cx
				local tileID_flip_x = 1 + cy*cw2 + (cw2-cx-1)
				local tileID_flip_y = 1 + (ch2-cy-1)*cw2 + cx
				local tileID_flip_xy = 1 + (ch2-cy-1)*cw2 + (cw2-cx-1)

				table.insert( tileIDs_flipped, tileID_flip_no)
				table.insert( tileIDs_flipped, tileID_flip_x)
				table.insert( tileIDs_flipped, tileID_flip_y)
				table.insert( tileIDs_flipped, tileID_flip_xy)

				registered_tileIDs_flipped[ tileID_flip_no ] = true
				registered_tileIDs_flipped[ tileID_flip_x ] = true
				registered_tileIDs_flipped[ tileID_flip_y ] = true
				registered_tileIDs_flipped[ tileID_flip_xy ] = true
			end

			-- empty versions
			local tileIDs_empty = {}
			for tileID = 1, cw*ch do
				if not registered_tileIDs[tileID] then
					table.insert( tileIDs_empty, tileID )
				end
			end

			-- flipped empty version
			local tileIDs_flipped_empty = {}
			for tileID = 1, cw2*ch2 do
				if not registered_tileIDs_flipped[tileID] then
					table.insert( tileIDs_flipped_empty, tileID )
				end
			end

			tileset.tileIDs[ enum_def.enumValueId ] = tileIDs
			tileset.tileIDs_empty[ enum_def.enumValueId ] = tileIDs_empty
			tileset.tileIDs_flipped[ enum_def.enumValueId ] = tileIDs_flipped
			tileset.tileIDs_flipped_empty[ enum_def.enumValueId ] = tileIDs_flipped_empty
		end

	end

	-- we list the level names (the complete list needs to be ready before calling LDtk.load_level())
	for level_index, level_data in ipairs(data.levels) do
		_level_names[ level_data.iid ] = level_data.identifier
		_level_rects[ level_data.identifier ] = { x=level_data.worldX, y=level_data.worldY, width=level_data.pxWid, height=level_data.pxHei }
	end

	-- we load the levels
	for level_index, level_data in ipairs(data.levels) do
		if level_data.externalRelPath then
			_level_files[ level_data.identifier ] = _.convert_relative_folder( level_data.externalRelPath )
		else
			LDtk.load_level( level_data )
			_.load_tileset( level_data.identifier )
		end
	end
end

-- Call this function to save the LDtk level in lua files to improve loading performance
-- The files will be saved in the aave folder of the game (PlaydateSDK/Disk/Data)
function LDtk.export_to_lua_files()
	if _use_lua_levels then
		print("LDtk, cannot export level in lua. The system had loaded lua files instead of .ldtk")
		return
	end

	local folder = _ldtk_lua_foldername.."/"
	playdate.file.mkdir(_ldtk_lua_foldername)

	local lua_level_files = {}
	for level_name, level_file in pairs(_level_files) do
		local filename = _.get_filename(level_file)
		lua_level_files[ level_name ] = _ldtk_lua_folder..filename..".pdz"
	end

	print("Export LDtk world")
	_.export_lua_table( folder.._ldtk_filename..".lua", {
		tilesets = _tilesets,
		level_files = lua_level_files,
		level_names = _level_names,
		level_rects = _level_rects,
		levels = _levels,
		use_external_files = _use_external_files
	})

	for level_name, level_file in pairs(_level_files) do
		print("Export LDtk level", level_name)

		LDtk.load_level( level_name )
		_.export_lua_table( folder.._.get_filename(level_file)..".lua", _levels[ level_name ])
		LDtk.release_level( level_name )
	end
end

-- load the level in memory
-- only necessary to call if the ldtk file is saved in multiple files
function LDtk.load_level( level_name )
	if _levels[ level_name ] then
		return
	end

	if _use_lua_levels then
		_levels[ level_name ] = playdate.file.run( _level_files[ level_name ] )
		_.load_tileset( level_name )
		return
	end

	local level_data
	if type(level_name)=="string" then
		level_data = json.decodeFile( _level_files[ level_name ] )
	else
		level_data = level_name
	end

	local level = {}
	_levels[ level_data.identifier ] = level

	level.neighbours = { east = {}, west = {}, north = {}, south = {}}
	local direction_table = { e = "east", w = "west", n = "north", s = "south" }
	for index, neighbour_data in ipairs(level_data.__neighbours) do
		local direction = direction_table[ neighbour_data.dir ]
		if direction then
			table.insert( level.neighbours[ direction ], _level_names[ neighbour_data.levelIid ])
		end
	end

	-- load level's custom fields
	for index, field_data in ipairs(level_data.fieldInstances) do
		level.custom_data = {}
		level.custom_data[ field_data.__identifier ] = field_data.__value
	end

	-- handle layers
	level.layers = {}
	local layer_count = #level_data.layerInstances
	for layer_index, layer_data in ipairs(level_data.layerInstances) do

		local layer = {}
		level.layers[ layer_data.__identifier ] = layer

		local layer_type = layer_data.__type

		layer.grid_size = layer_data.__gridSize
		layer.zIndex = layer_count - layer_index
		layer.rect = {
			x = level_data.worldX + layer_data.__pxTotalOffsetX,
			y = level_data.worldY + layer_data.__pxTotalOffsetY,
			width = layer_data.__cWid * layer_data.__gridSize,
			height = layer_data.__cHei * layer_data.__gridSize
			}

		-- load tileset
		if layer_data.__tilesetRelPath then
			layer.tileset_file = _.convert_relative_folder( layer_data.__tilesetRelPath )
		end
		layer.has_flipped_tiles = false

		-- handle tiles
		local tiles_data = layer_data.gridTiles
		if #layer_data.autoLayerTiles>0 then
			tiles_data = layer_data.autoLayerTiles
		end
		if #tiles_data>0 then
			layer.tilemap_width = layer_data.__cWid
			layer.tileset_uid = layer_data.__tilesetDefUid

			layer.tiles = {}

			local gsize = layer.grid_size
			local tileset_data = _tilesets[ layer.tileset_uid ]
			local cw, ch = tileset_data.imageWidth/gsize, tileset_data.imageHeight/gsize

			-- check we we have any flipped tiles
			for tile_index, tile_data in ipairs(tiles_data) do
				if tile_data.f~=0 then
					layer.has_flipped_tiles = true
					cw = cw * 2
					ch = ch * 2
					goto finish_flip_search
				end
			end
			::finish_flip_search::

			local tiles_list = {}
			for tile_index, tile_data in ipairs(tiles_data) do
				local id = (tile_data.px[2]/gsize)*layer_data.__cWid + tile_data.px[1]/gsize

				if layer.has_flipped_tiles then
					local cx, cy = tile_data.src[1]/gsize, tile_data.src[2]/gsize

					if tile_data.f==0 then
						tiles_list[id] = 1 + cy*cw + cx
					elseif tile_data.f==1 then
						tiles_list[id] = 1 + cy*cw + (cw-cx-1)
					elseif tile_data.f==2 then
						tiles_list[id] = 1 + (ch-cy-1)*cw + cx
					else
						tiles_list[id] = 1 + (ch-cy-1)*cw + (cw-cx-1)
					end
				else
					tiles_list[id] = 1 + tile_data.t
				end
			end

			for y = 0, layer_data.__cHei-1 do
				for x = 0, layer_data.__cWid-1 do
					local id = y*layer_data.__cWid + x

					if tiles_list[id] then
						table.insert( layer.tiles, math.floor(tiles_list[id]) )
					else
						table.insert( layer.tiles, 0 )
					end
				end
			end
		end

		local entities_data = layer_data.entityInstances
		if #entities_data>0 then
			layer.entities = {}

			for entity_index, entity_data in ipairs(entities_data) do
				local properties = {}
				for field_index, field_data in ipairs(entity_data.fieldInstances) do
					properties[ field_data.__identifier ] = field_data.__value
				end

				table.insert( layer.entities, {
					name = entity_data.__identifier,
					iid = entity_data.iid,
					tileset_rect = entity_data.__tile,
					position = { x=entity_data.px[1], y=entity_data.px[2] },
					center = { x=entity_data.__pivot[1], y=entity_data.__pivot[2] },
					size = { width=entity_data.width, height=entity_data.height },
					zIndex = layer.zIndex,
					fields = properties,
				})
			end
		end
	end

	_.load_tileset( level_name )
end

-- free the level from the memory
-- the tileset is also freed if no other level is using it
function LDtk.release_level( level_name )
	if not _use_external_files then
		print("LDtk file doesn't use external files. No need to load/release individual levels.")
		return
	end

	local level = _levels[level_name]
	if not level then return end

	-- release image table tilesets
	for layer_name, layer in pairs(level.layers) do
		_.release_tileset_imagetable( layer.tileset_file, layer.has_flipped_tiles)
	end

	_levels[level_name] = nil
end

-- get a list of entities
-- @layer_name is optional, if nil then it will return all the entities
-- entities format
-- 	.name : name of the entity class
-- 	.position : position of the entity
--	.center : alignment of the sprite around the position. can be used with sprite:setCenter()
--	.size :  width and height of the entity
--	.zIndex : layer index
-- 	.fields : all the custom fields data entered in the LDtk editor
function LDtk.get_entities( level_name, layer_name )
	local level = _levels[level_name]
	if not level then return end

	if not layer_name then
		local all_entities = {}
		for layer_name, layer in pairs(level.layers) do
			for entity_index, entity in pairs(layer.entities or {}) do
				table.insert( all_entities, entity)
			end
		end

		return all_entities
	end

	local layer = level.layers[ layer_name ]
	if not layer then return end

	return layer.entities or {}
end

-- return a tilemap for the level
-- @layer_name is optional, if nil then will return the first layer with tiles
function LDtk.create_tilemap( level_name, layer_name )
	local layer = _.get_tile_layer( level_name, layer_name )
	if not layer then return end

	local tilemap = playdate.graphics.tilemap.new()
	tilemap:setImageTable( layer.tileset_image )
	tilemap:setTiles( layer.tiles, layer.tilemap_width)

	return tilemap
end

-- return a table with all the adjacent levels
-- @direction is optional: values can be "east", "west", "north", "south"
function LDtk.get_neighbours( level_name, direction )
	local level = _levels[level_name]
	if not level then return end

	if not direction then
		return level.neighbours
	end

	return level.neighbours[ direction ]
end

-- return the position and site of the level in the world
-- always available, the level doesn't need to be loaded
function LDtk.get_rect( level_name )
	return _level_rects[ level_name ]
end

-- return custom data for the specified level
-- @field_name is optional, if nil then it will return all the fields as a table
function LDtk.get_custom_data( level_name, field_name )
	local level = _levels[ level_name ]
	if not level then
		return nil
	end

	local custom_data = level.custom_data
	if not custom_data then
		return nil
	end

	if field_name then
		return custom_data[ field_name ]
	end

	return custom_data
end

-- return all the tileIDs tagged in LDtk with tileset_enum_value
-- LDtk.get_tileIDs( "Level_0", "Solid" )
function LDtk.get_tileIDs( level_name, tileset_enum_value, layer_name )
	local layer = _.get_tile_layer( level_name, layer_name )
	if not layer then return end

	local tileset = _tilesets[ layer.tileset_uid ]
	if not tileset then return end

	if layer.has_flipped_tiles then
		return tileset.tileIDs_flipped[ tileset_enum_value ]
	end

	return tileset.tileIDs[ tileset_enum_value ]
end


-- return all the tileIDs NOT tagged in LDtk with tileset_enum_value
-- playdate functions usually require this function (getCollisionRects(emptyIDs), addWallSprites() )
function LDtk.get_empty_tileIDs( level_name, tileset_enum_value, layer_name )
	local layer = _.get_tile_layer( level_name, layer_name )
	if not layer then return end

	local tileset = _tilesets[ layer.tileset_uid ]
	if not tileset then return end

	if layer.has_flipped_tiles then
		return tileset.tileIDs_flipped_empty[ tileset_enum_value ]
	end

	return tileset.tileIDs_empty[ tileset_enum_value ]
end

-- return all layers from a level
function LDtk.get_layers(level_name)
	local level = _levels[level_name]

	if not level then return end
	return level.layers
end


-- Generate an image from a section of a tileset
-- https://ldtk.io/json/#ldtk-TilesetRect
-- You can use it as custom property
function LDtk.generate_image_from_tileset_rect( tileset_rect )
	if not tileset_rect then
		return nil
	end

	-- Load tileset
	local tileset = _tilesets[ tileset_rect.tilesetUid ]
	if not tileset then
		return nil
	end
	local cells = _.load_tileset_imagetable( tileset.imageTable_filename )
	if not cells then
		return nil
	end

	local cell_width, cell_height = cells[1]:getSize()
	local x_count = math.ceil( tileset_rect.w/cell_width )
	local y_count = math.ceil( tileset_rect.h/cell_height )

	local entity_image = playdate.graphics.image.new(tileset_rect.w, tileset_rect.h)

	playdate.graphics.lockFocus( entity_image )
		for y = 0, y_count-1 do
			for x = 0, x_count-1 do
				cells:getImage( 1 + (tileset_rect.x//cell_width) + x, 1 + (tileset_rect.y//cell_height) + y ):draw( x*cell_width, y*cell_height )
			end
		end
	playdate.graphics.unlockFocus()

	_.release_tileset_imagetable( tileset.imageTable_filename )

	return entity_image
end

-- Generate an image of an entity
-- The entity needs to have the 'Editor Visual' property set to a tileset in LDtk
function LDtk.generate_image_from_entity( entity )
	if not entity then
		return nil
	end

	if not entity.tileset_rect then
		print("LDtk: Cannot generate entity image. No tileset assigned to it.")
		return
	end

	return LDtk.generate_image_from_tileset_rect( entity.tileset_rect )
end

--
-- internal functions
--

function _.get_folder_and_filename( filepath )
	local folder, filename, extension = filepath:match("(.-)([^/.]-).([^.]+)$")
	return folder, filename
end

function _.get_filename( filepath )
	local folder, filename = _.get_folder_and_filename( filepath )
	return filename
end

function _.get_folder( filepath )
	local folder, filename = _.get_folder_and_filename( filepath )
	return folder
end


function _.get_folder_table( path )
	local delimiter = '/'
	local result = {}
	local string_index = 1
	local folder

	if not path then
		return result
	end

	local found_start, found_end = string.find( path, delimiter, string_index)
	while found_start do
		folder = string.sub( path, string_index , found_start-1 )
		if type(folder)=="string" and string.len(folder)>0 then
			table.insert(result, folder)
		end

		string_index = found_end + 1
		found_start, found_end = string.find( path, delimiter, string_index)
	end

	folder = string.sub( path, string_index)
	if type(folder)=="string" and string.len(folder)>0 then
		table.insert(result, folder)
	end

	return result
end

function _.convert_relative_folder( filepath )
	if not filepath then
		return nil
	end

	local ldtk_folder_end = #_ldtk_folder_table
	local relative_path_start = 1

	local relative_path_table = _.get_folder_table( filepath )
	for index, relative_folder in ipairs(relative_path_table) do
		if relative_folder==".." then
			ldtk_folder_end = ldtk_folder_end - 1
		elseif relative_folder~="." then
			goto skip_folders
		end

		relative_path_start = relative_path_start + 1
	end
	::skip_folders::

	if ldtk_folder_end<0 then
		error( "LDtk cannot access the following path because it is outside the project folder: "..filepath)
	end

	local absolute_path
	for index = 1, ldtk_folder_end do
		if absolute_path then
			absolute_path = absolute_path.."/".._ldtk_folder_table[ index ]
		else
			absolute_path = _ldtk_folder_table[ index ]
		end
	end
	for index = relative_path_start, #relative_path_table do
		if absolute_path then
			absolute_path = absolute_path.."/"..relative_path_table[ index ]
		else
			absolute_path = relative_path_table[ index ]
		end
	end

	print(absolute_path)
	return absolute_path
end

function _.load_tileset( level_name )
	local level = _levels[level_name]
	if not level then return end

	for layer_name, layer in pairs(level.layers) do
		if layer.tileset_file then
			layer.tileset_image = _.load_tileset_imagetable(layer.tileset_file, layer.has_flipped_tiles)
		end
	end
end

function _.load_tileset_imagetable(path, flipped)
	if not path then
		return
	end

	local id = path
	if flipped then
		id = id.."[flipped]"
	end

	if _imageTables[id] then
		_imageTables[id].count = _imageTables[id].count + 1
		return _imageTables[id].image
	end

	local image_filepath
	if flipped then
		local filename = path:match("^.+/(.+)$")
		local tileset_folder = path:sub(0, -#filename-1)
		image_filepath = tileset_folder.."flipped-"..filename
	else
		image_filepath = path
	end

	local image = playdate.graphics.imagetable.new(image_filepath)
	if not image then
		if flipped then
			error( "LDtk cannot load tileset "..image_filepath..". Tileset requires a flipped version of the image: flipped-filename-table-w-h.png", 3)
		else
			error( "LDtk cannot load tileset "..image_filepath..". Filename should have a image table format: name-table-w-h.png", 3)
		end

		return nil
	end

	_imageTables[id] = {
		count = 1,
		image = image
	}

	return image
end

function _.release_tileset_imagetable(path, flipped)
	if not path then return end

	local id = path
	if flipped then
		id = id.."[flipped]"
	end

	if not _imageTables[id] then
		print("LDtk: We release an image that was not loaded. Strange...")
		return
	end

	_imageTables[id].count = _imageTables[id].count - 1
	if _imageTables[id].count<=0 then
		_imageTables[id] = nil
	end
end

function _.get_tile_layer( level_name, layer_name )
	local level = _levels[level_name]
	if not level then return end

	if layer_name then
		return level.layers[ layer_name ]
	end

	for layer_name, layer in pairs(level.layers) do
		if layer.tiles then
			return layer
		end
	end
end

-- write the content of a table in a lua file
function _.export_lua_table( filepath, table_to_export )
	local function _isArray( t )
		if type(t[1])=="nil" then return false end

		local pairs_count = 0
		for key in pairs(t) do
			pairs_count = pairs_count + 1
			if type(key)~="number" then
				return false
			end
		end

		return pairs_count==#t
	end

	assert( filepath, "LDtk Importer export_lua_table(), filepath required")
	assert( table_to_export, "LDtk Importer export_lua_table(), table_to_export required")

	local file, file_error = playdate.file.open(filepath, playdate.file.kFileWrite)
	assert(file, "LDtk Importer export_lua_table(), Cannot open file",filepath," (",file_error,")")

	local _write_entry
	_write_entry = function( entry, name )
		local entry_type = type(entry)

		if entry_type=="table" then
			file:write("{")
			if _isArray( entry ) then
				for key, value in ipairs(entry) do
					_write_entry(value, key)
					file:write(",")
				end
			else
				for key, value in pairs(entry) do
					if type(key) == "number" then
						file:write("["..tostring(key).."]=")
					else
						file:write("[\""..tostring(key).."\"]=")
					end
					_write_entry(value, key)
					file:write(",")
				end
			end
			file:write("}")
		elseif entry_type=="string" then
			file:write("\""..tostring(entry).."\"")
		elseif entry_type=="boolean" or entry_type=="number" then
			file:write(tostring(entry))
		else
			file:write("nil")
		end
	end

	file:write("return ")
	_write_entry( table_to_export )

	file:close()
end
