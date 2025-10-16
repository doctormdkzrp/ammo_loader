protoNames = require("prototypes.names")

local simulations = {}
simulations.e_confirm =
{
    init =
    [[
    require("__core__/lualib/story")
    require("__ammo-loader__/prototypes/names")
    player = game.simulation.create_test_player{name = "big k"}
    player.teleport({-8.5, -1.5})
    game.simulation.camera_player = player
    game.simulation.camera_position = {0, 0.5}
    game.simulation.camera_player_cursor_position = player.position
    player.character.direction = defines.direction.south
    game.surfaces[1].create_entity
    {
      name = 
      position = {-7, -5},
    }

    game.forces.player.technologies["logistic-system"].research_recursive()
    game.forces.player.technologies["logistics"].researched = true -- for splitters to be selectable

    chest = game.surfaces[1].find_entities_filtered{name = "requester-chest"}[1]
    button = ""
    slot_data = ""

    local story_table =
    {
      {
        {
          name = "start",
          init = function()
            button = "0"
            slot_data = "transport-belt"
          end,
          condition = function() return game.simulation.move_cursor({position = chest.position, speed = 0.75}) end
        },
        {
          condition = story_elapsed_check(0.25),
          action = function() player.opened = chest end
        },
        { condition = story_elapsed_check(0.25) },
        {
          name = "continue",
          condition = function()
            local target = game.simulation.get_widget_position({type = "logistics-button", data = button})
            return game.simulation.move_cursor({position = target, speed = 0.45})
          end
        },
        {
          condition = story_elapsed_check(0.25),
          action = function() game.simulation.mouse_click() end
        },
        {
          condition = function()
            local target = game.simulation.get_widget_position({type = "signal-id-base", data = slot_data})
            return game.simulation.move_cursor({position = target, speed = 0.45})
          end
        },
        {
          condition = story_elapsed_check(0.35),
          action = function() game.simulation.mouse_click() end
        },
        {
          condition = story_elapsed_check(0.75),
          action = function()
            game.simulation.control_press{control = "confirm-gui", notify = true}
          end
        },
        {
          condition = story_elapsed_check(0.25),
          action = function()
            if button == "5" then button = "6" end
            if button == "4" then
              button = "5"
              slot_data = "storage-chest"
            end
            if button == "3" then
              button = "4"
              slot_data = "small-electric-pole"
            end
            if button == "2" then
              button = "3"
              slot_data = "inserter"
            end
            if button == "1" then
              button = "2"
              slot_data = "splitter"
            end
            if button == "0" then
              button = "1"
              slot_data = "underground-belt"
            end
            if button < "6" then story_jump_to(storage.story, "continue") end
          end
        },
        {
          condition = function() return game.simulation.move_cursor({position = player.position, speed = 0.5}) end,
          action = function() player.opened = nil end
        },
        {
          condition = story_elapsed_check(0.5),
          action = function()
            local position = chest.position
            chest.destroy()
            chest = game.surfaces[1].create_entity{name = "requester-chest", position = position, force = player.force, create_build_effect_smoke = false}
            story_jump_to(storage.story, "start")
          end
        }
      }
    }
    tip_story_init(story_table)
  ]]
}
         action = function()
            player.clear_cursor()
            story_jump_to(storage.story, "start")
          end
        }
      }
    }
    tip_story_init(story_table)
  ]]
}

simulations.limit_chest =
{
  init =
  [[
    require("__core__/lualib/story")
    player = game.simulation.create_test_player{name = "big k"}
    player.teleport({-8.5, -1})
    game.simulation.camera_player = player
    game.simulation.camera_position = {0, 0.5}
    game.simulation.camera_alt_info = true
	  game.simulation.camera_player_cursor_position = player.position
	  storage.character = player.character
    player.character.direction = defines.direction.south

    game.surfaces[1].create_entities_from_blueprint_string
    {
      string = "0eNqdldtuozAQht/F16bCnEJ4lSpCHIbUkrGRbbqbRrx7xyFyu42jhXLHzPD9P/aMfSWtmGHSXFpSXQnvlDSker0Sw8+yES4mmxFIRaxupJmUtlELwpKFEi57+EsqttBAOQjorOZdBBL0+RKhAOih6eDbl8lyogSk5ZbDqnp7udRyHlvQiKb/x1EyKYMEJZ06Ug+UXEgVFajTzsMAujb8Axks9o9z/EMq8VIj9HweI684KRFQOb7kq07+ki8BXvpLXhzGZR5nLICIujcw9pHC4juGhTG5x3A5cImpZ6T8DkoRRH11bcBaLs/GVWkY1TvUM+YE7gb0NbcwYmpohAFK1vC6sXfVrtEo1anZtRvu7qh6F25sJKC52fBNdQr5L+iTdnzsgn/891zj6t+yWQB7+LYsBjS6fgQWz4AsCRDLzUaPe4weN2PLPVgWb+Yy9gxchsBsOzje5TjZ7zjf5DjdD842gbP94GITePtQe/DxF1Nt9QyhmWRfQylU04dmx+uWP36HEnuZVufTjJcK3gd/MO3OjNeE5jSl+QljzgEWfV1VlLzjyXJjJCXLyjQvDmkcF85Li6vbvdW+gC3LJ/CGSNU=",
      position = {-11, 0},
    }

    chest = game.surfaces[1].find_entity("steel-chest", {-8.5, 0.5})
    assert(chest)

    local story_table =
    {
      {
        {
          name = "start",
          condition = function() return game.simulation.move_cursor({position = chest.position}) end
        },
        {
          condition = story_elapsed_check(1),
          action = function() player.opened = chest end
        },
        { condition = story_elapsed_check(1) },
        {
          condition = function()
            local target = game.simulation.get_widget_position({type = "inventory-limit-slot-button"})
            return game.simulation.move_cursor({position = target})
          end
        },
        {
          condition = story_elapsed_check(0.25),
          action = function() game.simulation.mouse_click() end
        },
        {
          condition = function()
            local target = game.simulation.get_slot_position{inventory = "entity", inventory_index = defines.inventory.character_main, slot_index = 4}
            return game.simulation.move_cursor({position = target})
          end
        },
        {
          condition = story_elapsed_check(0.25),
          action = function() game.simulation.mouse_click() end
        },
        {
          condition = function() return game.simulation.move_cursor({position = player.position}) end
        },
        {
          condition = story_elapsed_check(0.25),
          action = function()
            inserter = game.surfaces[1].create_entity{name = "inserter", position = {chest.position.x, chest.position.y + 1}, direction = defines.direction.south, force = player.force, create_build_effect_smoke = false}
          end
        },
        {
          condition = story_elapsed_check(7),
          action = function() player.opened = nil end
        },
        {
          condition = story_elapsed_check(1),
          action = function()
            inserter.destroy()
            chest.destroy()
            chest = game.surfaces[1].create_entity{name = "steel-chest", position = {-8.5, 0.5}, force = player.force, create_build_effect_smoke = false}
            story_jump_to(storage.story, "start")
          end
        }
      }
    }
    tip_story_init(story_table)
  ]]
}

simulations.e_confirm =
{
  init =
  [[
    require("__core__/lualib/story")
    player = game.simulation.create_test_player{name = "big k"}
    player.teleport({-8.5, -1.5})
    game.simulation.camera_player = player
    game.simulation.camera_position = {0, 0.5}
    game.simulation.camera_player_cursor_position = player.position
    player.character.direction = defines.direction.south
    game.surfaces[1].create_entities_from_blueprint_string
    {
      string = "0eNptkd2KwyAQhd9lrk2pSQzBV1mWEt1JV0g0609pGnz3NbZkF6o3cgbPd5jjBmIKuFilPfANlDTaAf/YwKmrHqZ95tcFgYPyOAMBPcy7skaYxVgPkYDSX3gHTuMnAdReeYVPRhbrRYdZoE0P3t0EFuOSweg9KUGquiOwAq9jJG+A+gC4IJwfsq+AaDKiKSGaA4ETSm+VrFCjva5VagDtOEgsEemLSECEcUR7ceqRIPR8nEJW+7cv/gR0iV/J73SXEtiJ5Qx6PrG4N5n75v++h8ANrcueuqdt37Cu61rG+tTVLwHtlQY=",
      position = {-7, -5},
    }

    game.forces.player.technologies["logistic-system"].research_recursive()
    game.forces.player.technologies["logistics"].researched = true -- for splitters to be selectable

    chest = game.surfaces[1].find_entities_filtered{name = "requester-chest"}[1]
    button = ""
    slot_data = ""

    local story_table =
    {
      {
        {
          name = "start",
          init = function()
            button = "0"
            slot_data = "transport-belt"
          end,
          condition = function() return game.simulation.move_cursor({position = chest.position, speed = 0.75}) end
        },
        {
          condition = story_elapsed_check(0.25),
          action = function() player.opened = chest end
        },
        { condition = story_elapsed_check(0.25) },
        {
          name = "continue",
          condition = function()
            local target = game.simulation.get_widget_position({type = "logistics-button", data = button})
            return game.simulation.move_cursor({position = target, speed = 0.45})
          end
        },
        {
          condition = story_elapsed_check(0.25),
          action = function() game.simulation.mouse_click() end
        },
        {
          condition = function()
            local target = game.simulation.get_widget_position({type = "signal-id-base", data = slot_data})
            return game.simulation.move_cursor({position = target, speed = 0.45})
          end
        },
        {
          condition = story_elapsed_check(0.35),
          action = function() game.simulation.mouse_click() end
        },
        {
          condition = story_elapsed_check(0.75),
          action = function()
            game.simulation.control_press{control = "confirm-gui", notify = true}
          end
        },
        {
          condition = story_elapsed_check(0.25),
          action = function()
            if button == "5" then button = "6" end
            if button == "4" then
              button = "5"
              slot_data = "storage-chest"
            end
            if button == "3" then
              button = "4"
              slot_data = "small-electric-pole"
            end
            if button == "2" then
              button = "3"
              slot_data = "inserter"
            end
            if button == "1" then
              button = "2"
              slot_data = "splitter"
            end
            if button == "0" then
              button = "1"
              slot_data = "underground-belt"
            end
            if button < "6" then story_jump_to(storage.story, "continue") end
          end
        },
        {
          condition = function() return game.simulation.move_cursor({position = player.position, speed = 0.5}) end,
          action = function() player.opened = nil end
        },
        {
          condition = story_elapsed_check(0.5),
          action = function()
            local position = chest.position
            chest.destroy()
            chest = game.surfaces[1].create_entity{name = "requester-chest", position = position, force = player.force, create_build_effect_smoke = false}
            story_jump_to(storage.story, "start")
          end
        }
      }
    }
    tip_story_init(story_table)
  ]]
}