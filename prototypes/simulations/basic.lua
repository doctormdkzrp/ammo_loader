player = game.simulation.create_test_player { name = "big k" }
player.teleport({ -8.5, -1.5 })
game.simulation.camera_player = player
game.simulation.camera_position = { 0, 0.5 }
game.simulation.camera_player_cursor_position = player.position
player.character.direction = defines.direction.south
game.surfaces[1].create_entity
{
    name = protoNames.chests.loader,
    position = { -7, -5 },
}

game.forces.player.technologies[protoNames.tech.requester].research_recursive()
game.forces.player.technologies["logistics"].researched = true -- for splitters to be selectable

chest = game.surfaces[1].find_entities_filtered { name = protoNames.chests.loader }[1]
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
            condition = function() return game.simulation.move_cursor({ position = chest.position, speed = 0.75 }) end
        },
        {
            condition = story_elapsed_check(0.25),
            action = function() player.opened = chest end
        },
        { condition = story_elapsed_check(0.25) },
        {
            name = "continue",
            condition = function()
                local target = game.simulation.get_widget_position({ type = "text-button", data = button })
                return game.simulation.move_cursor({ position = target, speed = 0.45 })
            end
        },
        {
            condition = story_elapsed_check(0.25),
            action = function() game.simulation.mouse_click() end
        },
        {
            condition = function()
                local target = game.simulation.get_widget_position({ type = "signal-id-base", data = slot_data })
                return game.simulation.move_cursor({ position = target, speed = 0.45 })
            end
        },
        {
            condition = story_elapsed_check(0.35),
            action = function() game.simulation.mouse_click() end
        },
        {
            condition = story_elapsed_check(0.75),
            action = function()
                game.simulation.control_press { control = "confirm-gui", notify = true }
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
            condition = function() return game.simulation.move_cursor({ position = player.position, speed = 0.5 }) end,
            action = function() player.opened = nil end
        },
        {
            condition = story_elapsed_check(0.5),
            action = function()
                local position = chest.position
                chest.destroy()
                chest = game.surfaces[1].create_entity { name = "requester-chest", position = position, force = player.force, create_build_effect_smoke = false }
                story_jump_to(storage.story, "start")
            end
        }
    }
}
tip_story_init(story_table)
