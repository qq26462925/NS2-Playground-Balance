Onos.kBlockDoers =
set {
    "Minigun",
    "Railgun",
    "Pistol",
    "Rifle",
    "HeavyMachineGun",
    "Shotgun",
    "Axe",
    "Welder",
    "Sentry",
    "PulseGrenade",
    "ClusterFragment",
    "Mine",
    "Claw",
    "Flamethrower",
    "Grenade", -- Grenade Launcher
    "Mine",
    "Revolver",
    "Submachingun",
    "Cannon",
}

function Onos:ModifyDamageTaken(damageTable, attacker, doer, damageType, hitPoint) -- dud

    if hitPoint ~= nil and self:GetIsBoneShieldActive() and self:GetHitsBoneShield(doer, hitPoint) then

        local className = string.lower(doer:GetClassName())
        local reduction = kBoneShieldDamageReduction
        if className == "railgun" then
            reduction = 0
        elseif className == "grenade" then
            reduction = 0.6
        end

        if reduction ~= 0 then
            damageTable.damage = damageTable.damage * reduction
            --TODO Exclude local player and trigger local-player only effect
            self:TriggerEffects("boneshield_blocked", { effecthostcoords = Coords.GetTranslation(hitPoint) } )
        end
        
    end
end


Script.Load("lua/Devour/Devour.lua")

function Onos:GetHasMovementSpecial()
    return true
end

if Server then

    function Onos:GetTierOneTechId()
        return kTechId.Devour
    end
    
end

function Onos:CanBeStampeded(ent)
    
    if ent.nextStampede and Shared.GetTime() < ent.nextStampede then
        return false
    end
    
    if not GetAreEnemies(self, ent) or not ent:GetIsAlive() or ent:isa("DevouredPlayer") then
        return false
    end
    
    return true
end