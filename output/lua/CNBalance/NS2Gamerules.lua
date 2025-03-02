
if Server then
    function NS2Gamerules:RandomTechPoint(techPoints, teamNumber)
        local chosenIndex = math.random(1,#techPoints)
        local chosenTechPoint = techPoints[chosenIndex]
        -- table.removevalue(techPoints, chosenTechPoint)
        return chosenTechPoint
    end

    -- Find team start with team 0 or for specified team. Remove it from the list so other teams don't start there. Return nil if there are none.
    function NS2Gamerules:ChooseTechPoint(techPoints, teamNumber)
        local validTechPoints = { }
        local totalTechPointWeight = 0
        
        -- Build list of valid starts (marked as "neutral" or for this team in map)
        for _, currentTechPoint in ipairs(techPoints) do
        
            -- Always include tech points with team 0 and never include team 3 into random selection process

            -- Some Test Stuff
            local teamNum = currentTechPoint:GetTeamNumberAllowed()
            if (teamNum == 0 or teamNum == teamNumber) and teamNum ~= 3 then
            
                table.insert(validTechPoints, currentTechPoint)
                totalTechPointWeight = totalTechPointWeight + currentTechPoint:GetChooseWeight()
                
            end
            
        end
        
        local chosenTechPointWeight = self.techPointRandomizer:random(0, totalTechPointWeight)
        local chosenTechPoint
        local currentWeight = 0
        for _, currentTechPoint in ipairs(validTechPoints) do
        
            currentWeight = currentWeight + currentTechPoint:GetChooseWeight()
            if chosenTechPointWeight - currentWeight <= 0 then
            
                chosenTechPoint = currentTechPoint
                break
                
            end
            
        end
        
        -- Remove it from the list so it isn't chosen by other team
        if chosenTechPoint ~= nil then
            table.removevalue(techPoints, chosenTechPoint)
        else
            assert(false, "ChooseTechPoint couldn't find a tech point for team " .. teamNumber)
        end
        
        return chosenTechPoint
        
    end

    function NS2Gamerules:ResetGame()
            
        StatsUI_ResetStats()

        StatsUI_ResetStats()

        self:SetGameState(kGameState.NotStarted)

        TournamentModeOnReset()

        -- save commanders for later re-login
        local team1CommanderClient = self.team1:GetCommander() and self.team1:GetCommander():GetClient()
        local team2CommanderClient = self.team2:GetCommander() and self.team2:GetCommander():GetClient()
        
        -- Cleanup any peeps currently in the commander seat by logging them out
        -- have to do this before we start destroying stuff.
        self:LogoutCommanders()
        
        -- Destroy any map entities that are still around
        DestroyLiveMapEntities()
        
        -- Reset all players, delete other not map entities that were created during 
        -- the game (hives, command structures, initial resource towers, etc)
        -- We need to convert the EntityList to a table since we are destroying entities
        -- within the EntityList here.
        for _, entity in ientitylist(Shared.GetEntitiesWithClassname("Entity")) do
        
            -- Don't reset/delete NS2Gamerules or TeamInfo or ThunderdomeRules.
            -- NOTE!!!
            -- MapBlips are destroyed by their owner which has the MapBlipMixin.
            -- There is a problem with how this reset code works currently. A map entity such as a Hive creates
            -- it's MapBlip when it is first created. Before the entity:isa("MapBlip") condition was added, all MapBlips
            -- would be destroyed on map reset including those owned by map entities. The map entity Hive would still reference
            -- it's original MapBlip and this would cause problems as that MapBlip was long destroyed. The right solution
            -- is to destroy ALL entities when a game ends and then recreate the map entities fresh from the map data
            -- at the start of the next game, including the NS2Gamerules. This is how a map transition would have to work anyway.
            -- Do not destroy any entity that has a parent. The entity will be destroyed when the parent is destroyed or
            -- when the owner manually destroyes the entity.
            local shieldTypes = { "GameInfo", "MapBlip", "NS2Gamerules", "PlayerInfoEntity", "ThunderdomeRules" }
            local allowDestruction = true
            for i = 1, #shieldTypes do
                allowDestruction = allowDestruction and not entity:isa(shieldTypes[i])
            end
            
            if allowDestruction and entity:GetParent() == nil then
                
                -- Reset all map entities and all player's that have a valid Client (not ragdolled players for example).
                local resetEntity = entity:isa("TeamInfo") or entity:GetIsMapEntity() or (entity:isa("Player") and entity:GetClient() ~= nil)
                if resetEntity then
                
                    if entity.Reset then
                        entity:Reset()
                    end
                    
                else
                    DestroyEntity(entity)
                end
                
            end       
            
        end
        
        -- Clear out obstacles from the navmesh before we start repopualating the scene
        RemoveAllObstacles()
        
        -- Build list of tech points
        local techPoints = EntityListToTable(Shared.GetEntitiesWithClassname("TechPoint"))
        if #techPoints < 2 then
            Print("Warning -- Found only %d %s entities.", table.maxn(techPoints), TechPoint.kMapName)
        end
        
        local resourcePoints = Shared.GetEntitiesWithClassname("ResourcePoint")
        if resourcePoints:GetSize() < 2 then
            Print("Warning -- Found only %d %s entities.", resourcePoints:GetSize(), ResourcePoint.kPointMapName)
        end
        
        -- add obstacles for resource points back in
        for _, resourcePoint in ientitylist(resourcePoints) do
            resourcePoint:AddToMesh()        
        end
        
        local team1TechPoint, team2TechPoint
        
        -- if Server.teamSpawnOverride and #Server.teamSpawnOverride > 0 then
        
        --     for t = 1, #techPoints do

        --         local techPointName = string.lower(techPoints[t]:GetLocationName())
        --         local selectedSpawn = Server.teamSpawnOverride[1]
        --         if techPointName == selectedSpawn.marineSpawn then
        --             team1TechPoint = techPoints[t]
        --         elseif techPointName == selectedSpawn.alienSpawn then
        --             team2TechPoint = techPoints[t]
        --         end
                
        --     end
            
        --     if not team1TechPoint or not team2TechPoint then
        --         Shared.Message("Invalid spawns, defaulting to normal spawns")
        --         if Server.spawnSelectionOverrides then
        
        --             local selectedSpawn = self.techPointRandomizer:random(1, #Server.spawnSelectionOverrides)
        --             selectedSpawn = Server.spawnSelectionOverrides[selectedSpawn]
                    
        --             for t = 1, #techPoints do
                    
        --                 local techPointName = string.lower(techPoints[t]:GetLocationName())
        --                 if techPointName == selectedSpawn.marineSpawn then
        --                     team1TechPoint = techPoints[t]
        --                 elseif techPointName == selectedSpawn.alienSpawn then
        --                     team2TechPoint = techPoints[t]
        --                 end
                        
        --             end
                        
        --         else
                    
        --             -- Reset teams (keep players on them)
        --             team1TechPoint = self:ChooseTechPoint(techPoints, kTeam1Index)
        --             team2TechPoint = self:ChooseTechPoint(techPoints, kTeam2Index)

        --         end
            
        --     end
            
        -- elseif Server.spawnSelectionOverrides then
        
        --     local selectedSpawn = self.techPointRandomizer:random(1, #Server.spawnSelectionOverrides)
        --     selectedSpawn = Server.spawnSelectionOverrides[selectedSpawn]
            
        --     for t = 1, #techPoints do
            
        --         local techPointName = string.lower(techPoints[t]:GetLocationName())
        --         if techPointName == selectedSpawn.marineSpawn then
        --             team1TechPoint = techPoints[t]
        --         elseif techPointName == selectedSpawn.alienSpawn then
        --             team2TechPoint = techPoints[t]
        --         end
                
        --     end
            
        -- else
        
            -- Reset teams (keep players on them)

            local value = math.random(1,10)
            if value == 10 then
                team1TechPoint = self:RandomTechPoint(techPoints, kTeam1Index)
                team2TechPoint = self:RandomTechPoint(techPoints, kTeam2Index)
            else
                team1TechPoint = self:ChooseTechPoint(techPoints, kTeam1Index)
                team2TechPoint = self:ChooseTechPoint(techPoints, kTeam2Index)
            end

        -- end
        
        self.team1:ResetPreservePlayers(team1TechPoint)
        self.team2:ResetPreservePlayers(team2TechPoint)
        
        assert(self.team1:GetInitialTechPoint() ~= nil)
        assert(self.team2:GetInitialTechPoint() ~= nil)
        
        -- Save data for end game stats later.
        self.startingLocationNameTeam1 = team1TechPoint:GetLocationName()
        self.startingLocationNameTeam2 = team2TechPoint:GetLocationName()
        self.startingLocationsPathDistance = GetPathDistance(team1TechPoint:GetOrigin(), team2TechPoint:GetOrigin())
        self.initialHiveTechId = nil
        
        self.worldTeam:ResetPreservePlayers(nil)
        self.spectatorTeam:ResetPreservePlayers(nil)    
        
        -- Replace players with their starting classes with default loadouts at spawn locations
        self.team1:ReplaceRespawnAllPlayers()
        self.team2:ReplaceRespawnAllPlayers()
        
        self.clientpres = {}

        -- Create team specific entities
        local commandStructure1 = self.team1:ResetTeam()
        local commandStructure2 = self.team2:ResetTeam()
        
        -- login the commanders again
        local function LoginCommander(commandStructure, client)
            local player = client and client:GetControllingPlayer()
            
            if commandStructure and player and commandStructure:GetIsBuilt() then
                
                -- make up for not manually moving to CS and using it
                commandStructure.occupied = not client:GetIsVirtual()
                
                player:SetOrigin(commandStructure:GetDefaultEntryOrigin())
                
                commandStructure:LoginPlayer( player, true )
            else
                if player then
                    Log("%s| Failed to Login commander[%s - %s(%s)] on ResetGame", self:GetClassName(), player:GetClassName(), player:GetId(),
                        client:GetIsVirtual() and "BOT" or "HUMAN"
                    )
                end
            end
        end
        
        LoginCommander(commandStructure1, team1CommanderClient)
        LoginCommander(commandStructure2, team2CommanderClient)
        
        -- Create living map entities fresh
        CreateLiveMapEntities()
        
        self.forceGameStart = false
        self.preventGameEnd = nil

        -- Reset banned players for new game
        if not self.bannedPlayers then
            self.bannedPlayers = unique_set()
        end
        self.bannedPlayers:Clear()
        
        -- Send scoreboard and tech node update, ignoring other scoreboard updates (clearscores resets everything)
        for _, player in ientitylist(Shared.GetEntitiesWithClassname("Player")) do
            Server.SendCommand(player, "onresetgame")
            player.sendTechTreeBase = true
        end
        
        self.team1:OnResetComplete()
        self.team2:OnResetComplete()

        StatsUI_InitializeTeamStatsAndTechPoints(self)
    end

    function NS2Gamerules:OnUpdate(timePassed)
        
        PROFILE("NS2Gamerules:OnUpdate")
        
        if Server then
            
            if self.justCreated then
                if not self.gameStarted then
                    self:ResetGame()
                end
                self.justCreated = false
            end
            
            if self:GetMapLoaded() then
            
                self:CheckGameStart()
                self:CheckGameEnd()

                self:UpdateWarmUp()
                
                self:UpdatePregame(timePassed)
                self:UpdateToReadyRoom()
                self:UpdateMapCycle()
                self:ServerAgeCheck()
                self:UpdateAutoTeamBalance(timePassed)
                
                self.timeSinceGameStateChanged = self.timeSinceGameStateChanged + timePassed
                
                self.worldTeam:Update(timePassed)
                self.team1:Update(timePassed)
                self.team2:Update(timePassed)
                self.spectatorTeam:Update(timePassed)
                
                self:UpdatePings()
                self:UpdateHealth()
                self:UpdateTechPoints()

                self:CheckForNoCommander(self.team1, "MarineCommander")
                self:CheckForNoCommander(self.team2, "AlienCommander")
                -- self:KillEnemiesNearCommandStructureInPreGame(timePassed)
                
                self:UpdatePlayerSkill()
                self:UpdateNumPlayersForScoreboard()
                
                if Shared.GetThunderdomeEnabled() then
                    GetThunderdomeRules():CheckForAutoConcede(self)
                end

            end
            
        end
        
    end
end