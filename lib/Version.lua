version = {}
version._latest = 217

function version._init()
    storage["version"] = {}
    storage["version"]["cur"] = version._latest
end
Init.registerFunc(version._init)
-- version.latest = version._latest
-- version.debugUpdate = true
function version.latest() return version._latest end
function version.needUpdate()
    local mas = storage["version"]
    if not mas then return true end
    local ver = mas.cur
    if not ver then return true end
    if (version._latest ~= ver) then
        -- inform("need update!")
        return true
    end
    return false
end
function version.update(doPreInit)
    doPreInit = doPreInit or true
    storage["version"].cur = version._latest
    -- util.clearRenders()
    rendering.clear("ammo-loader")
    -- local latest = version.latest()
    Init.doInit(doPreInit)
    -- storage["_ver"] = {}
    -- storage["_ver"].latest = latest
    -- version.set(version.latest())
    inform("successfully updated globals")
end
