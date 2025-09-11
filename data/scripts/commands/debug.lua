package.path = package.path .. ";data/scripts/lib/?.lua"
include ("stringutility")
function execute(sender, commandName)

    local player = Player()
    if not player then
        return 1, "", "You're not in a ship!"
    end

    local self = player.craft
    if not self then
        return 1, "", "You're not in a ship!"
    end

    local craft = self.selectedObject or self

    craft:addScript("lib/entitydbg.lua")

    return 0, "", ""
end

function getDescription()
    return "Enable Debug Panel"%_t
end

function getHelp()
    return ("Open the debug panel: ${cmd}"%_t)%{cmd="/debug"}
end
