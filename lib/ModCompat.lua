Mods = {}

-- function Mods._init()
--     storage.Mods = {}
--     storage.Mods.isActive = {}

--     --* cache if certain mods are active
--     -- if (game.active_mods["EndgameCombat"]) then
--     --     storage.Mods.isActive.EndgameCombat = true
--     -- end
-- end
-- Init.registerFunc(Mods._init)

Mods.VehicleTurrets = {}
function Mods.VehicleTurrets.isVehicleTurret(ent)
    if (ent.type == "ammo-turret") and (ent.name:find("vehicle-")) then
        return true
    end
    return false
end

Mods.LogisticTurrets = {}
Mods.LogisticTurrets._interfaceName = "turret-interface"
function Mods.LogisticTurrets.modActive()
    if (script.active_mods["Logistic-Gun-Turret"]) then
        return true
    end
    return false
end
function Mods.LogisticTurrets.isLogisticTurret(ent)
    local entsFound = ent.surface.find_entities_filtered{area=ent.bounding_box}
    for ind, _ in pairs(entsFound) do
        if (_.name == Mods.LogisticTurrets._interfaceName) then
            return true
        end
    end
    return false
end
function Mods.LogisticTurrets.findConnectedSlots(ent)
    local entsFound = ent.surface.find_entities_filtered{area=ent.bounding_box}
    local slots = {}
    for ind, _ in pairs(entsFound) do
        if (_.prototype.type == "ammo-turret") then
            slots = SL.getSlotsFromEnt(_)
            break
        end
    end
    return slots
end