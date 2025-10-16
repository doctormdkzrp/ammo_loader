---Name of an entity prototype
---@alias alEntityType string

---Used by TrackedChest and Force
---@alias alEntityFilter Hash<alEntityType, boolean>

---'whitelist' or 'blacklist'
---@alias alFilterMode string
---@see util#FilterModes

---Name of an Ammo Category
---@alias alAmmoCategory string

---Name of an ammo item prototype
---@alias alAmmoName string

---Layout for the ammo filters for TrackedSlot
---@alias alAmmoFilter Hash<alAmmoName, boolean>

---Layout for the entity filters for the Force class. Each filter can define multiple ammo types
---@class forceEntFilter
---@field mode alFilterMode
---@field ent alEntityType
---@field filters alAmmoName[]

---Base class for all objects that get an ID
---@class dbObject
---@field id int
---@field ent LuaEntity

---A value in TC.modes
---@alias alChestMode string