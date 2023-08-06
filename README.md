# PlaydateLDtkImporter

[![Lua Version](https://img.shields.io/badge/Lua-5.4-yellowgreen)](https://lua.org) [![Toybox Compatible](https://img.shields.io/badge/toybox.py-compatible-brightgreen)](https://toyboxpy.io) [![Latest Version](https://img.shields.io/github/v/tag/NicMagnier/PlaydateLDtkImporter)](https://github.com/NicMagnier/PlaydateLDtkImporter/tags)

 Load tilemaps created with LDtk in playdate games

## How to use LDtk levels on Playdate

#### Using toybox.py

You can add it to your **Playdate** project by installing [**toybox.py**](https://toyboxpy.io), going to your project folder in a Terminal window and typing:

```console
toybox add LDtkImporter
toybox update
```

Then, if your code is in the `source` folder, just import the following:

```lua
import '../toyboxes/toyboxes.lua'
```

#### Manually

You first need to copy the file `Ldtk.lua` in your playdate project and to import it

```lua
import 'LDtk'
```

Next you need to load your main .ldtk file, typically during the game loading
```lua
LDtk.load( "MyWorld.ldtk" )
```

If your LDtk world is saved in multiple files (in this case you see a .ldtkl file for each level in your structure) you need to manually load the levels.
```lua
LDtk.load_level( "TheFirstLevel" )
```

And you can also release the level and the assets used by it.
```lua
LDtk.release_level( "TheFirstLevel" )
```

It is usually better to load a new level before releasing the previous one because if they share the same asset, these assets will not need to be loaded.


### Using a level

#### Tilemap
When you want to finally use a level in your game, you need to create the playdate tilemap object
```lua
LDtk.create_tilemap( "TheFirstLevel" ) 
```

#### Collisions
You can also query the tiles using enum values you have setup in your Ldtk world using `LDtk.get_tileIDs()` but to generate collision the Playdate SDK requires tiles that are should by empty so `LDtk.get_empty_tileIDs() should be used instead.
```lua
local tilemap = LDtk.create_tilemap( "TheFirstLevel", "gameplay_layer" ) 
playdate.graphics.sprite.addWallSprites( tilemap, LDtk.get_empty_tileIDs( "TheFirstLevel", "Solid", "gameplay_layer") )
```

#### Entities
`LDtk.get_entities()` will give you all the entities setup in a level including all their custom fields.

```lua
for index, entity in ipairs( LDtk.get_entities( "TheFirstLevel" ) ) do
	if entity.name=="Player" then
		player.sprite:add()
		player.init( entity )
	end
end
```

### Changelog

#### version 1.03
- Fix crash when the LDtk internal icons are used in a level

#### version 1.02
- Make it possible to have the ldtk file at the root of the project

#### version 1.01
- Make it possible to use tileset that are in any folder of the project, not just under the ldtk file
- Added function to generate image from a tileset rect