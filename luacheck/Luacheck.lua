-- Globals provided by LDtkImporter.
--
-- This file can be used by toyboypy (https://toyboxpy.io) to import into a project's luacheck config.
--
-- Just add this to your project's .luacheckrc:
--    require "toyboxes/luacheck" (stds, files)
--
-- and then add 'toyboxes' to your std:
--    std = "lua54+playdate+toyboxes"

return {
    globals = {
        LDtk = {
            fields = {
                load = {},
                export_to_lua_files = {},
                load_level = {},
                release_level = {},
                get_entities = {},
                create_tilemap = {},
                get_neighbours = {},
                get_rect = {},
                get_tileIDs = {},
                get_empty_tileIDs = {},
                get_layers = {}
            }
        }
    }
}
