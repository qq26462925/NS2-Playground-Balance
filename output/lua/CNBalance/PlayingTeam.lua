local oldGetIsResearchRelevant = debug.getupvaluex(PlayingTeam.OnResearchComplete, "GetIsResearchRelevant")

local relevantResearchIds
local function extGetIsResearchRelevant(techId)

    if not relevantResearchIds then
        relevantResearchIds = {}
        relevantResearchIds[kTechId.LifeSustain] = 1
        relevantResearchIds[kTechId.NanoArmor] = 1
        
        relevantResearchIds[kTechId.StandardSupply] = 2
        relevantResearchIds[kTechId.PistolAxeUpgrade] = 2
        relevantResearchIds[kTechId.RifleUpgrade] = 2
        
        relevantResearchIds[kTechId.KinematicSupply] = 2
        relevantResearchIds[kTechId.DragonBreath] = 2
        
        relevantResearchIds[kTechId.ExplosiveSupply] = 2
        relevantResearchIds[kTechId.MinesUpgrade] = 2
        relevantResearchIds[kTechId.GrenadeLauncherDetectionShot] = 2
        relevantResearchIds[kTechId.GrenadeLauncherAllyBlast] = 2
        relevantResearchIds[kTechId.GrenadeLauncherUpgrade] = 2

        relevantResearchIds[kTechId.Devour] = 1
        relevantResearchIds[kTechId.FastTunnel] = 1
    end

    local relevant = relevantResearchIds[techId]
    if relevant ~= nil then
        return relevant
    end

    return oldGetIsResearchRelevant(techId)
end
debug.setupvaluex(PlayingTeam.OnResearchComplete, "GetIsResearchRelevant", extGetIsResearchRelevant)