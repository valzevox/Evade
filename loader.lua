print("Loading Tween")

local TweenService = {}

local EasingFunctions = {
    Linear = function(t)
        return t
    end,
    Sine = {
        In = function(t)
            return 1 - math.cos((t * math.pi) / 2)
        end,
        Out = function(t)
            return math.sin((t * math.pi) / 2)
        end,
        InOut = function(t)
            return -(math.cos(math.pi * t) - 1) / 2
        end
    },
    Quad = {
        In = function(t)
            return t * t
        end,
        Out = function(t)
            return 1 - (1 - t) * (1 - t)
        end,
        InOut = function(t)
            return t < 0.5 and 2 * t * t or 1 - (-2 * t + 2) ^ 2 / 2
        end
    }
}

local function getEasingFunction(easingStyle, easingDirection)
    if easingStyle == "Linear" then
        return EasingFunctions.Linear
    elseif EasingFunctions[easingStyle] then
        if easingDirection == "In" then
            return EasingFunctions[easingStyle].In
        elseif easingDirection == "Out" then
            return EasingFunctions[easingStyle].Out
        else
            return EasingFunctions[easingStyle].InOut
        end
    end
    return EasingFunctions.Linear
end

local TweenInfo = {}
TweenInfo.__index = TweenInfo

function TweenInfo.new(time, easingStyle, easingDirection, repeatCount, reverses, delayTime)
    local self = setmetatable({}, TweenInfo)
    self.Time = time or 1
    self.EasingStyle = easingStyle or "Quad"
    self.EasingDirection = easingDirection or "Out"
    self.RepeatCount = repeatCount or 0
    self.Reverses = reverses or false
    self.DelayTime = delayTime or 0
    return self
end

local Tween = {}
Tween.__index = Tween

function Tween.new(instance, tweenInfo, properties)
    local self = setmetatable({}, Tween)
    self.Instance = instance
    self.TweenInfo = tweenInfo
    self.Properties = properties
    self.InitialProperties = {}
    self.IsPlaying = false
    self.StartTime = 0
    self.CurrentTime = 0

    for prop, targetValue in pairs(properties) do
        if instance[prop] ~= nil then
            self.InitialProperties[prop] = instance[prop]
        end
    end

    return self
end

function Tween:Play()
    if self.IsPlaying then return end
    self.IsPlaying = true
    self.StartTime = os.clock()
    self.CurrentTime = 0
    TweenService._addActiveTween(self)
end

function Tween:Stop()
    if not self.IsPlaying then return end
    self.IsPlaying = false
    TweenService._removeActiveTween(self)
end

function Tween:Update(deltaTime)
    if not self.IsPlaying then return false end
    self.CurrentTime = self.CurrentTime + deltaTime
    local tweenInfo = self.TweenInfo

    if self.CurrentTime >= tweenInfo.Time then
        for prop, targetValue in pairs(self.Properties) do
            self.Instance[prop] = targetValue
        end
        self:Stop()
        return false
    end

    local alpha = getEasingFunction(tweenInfo.EasingStyle, tweenInfo.EasingDirection)(self.CurrentTime / tweenInfo.Time)

    for prop, targetValue in pairs(self.Properties) do
        if self.Instance[prop] ~= nil and self.InitialProperties[prop] ~= nil then
            local initialValue = self.InitialProperties[prop]
            if type(initialValue) == "number" and type(targetValue) == "number" then
                self.Instance[prop] = initialValue + (targetValue - initialValue) * alpha
            else
                self.Instance[prop] = targetValue
            end
        end
    end

    return true
end

local activeTweens = {}

function TweenService._addActiveTween(tween)
    table.insert(activeTweens, tween)
end

function TweenService._removeActiveTween(tween)
    for i, activeTween in ipairs(activeTweens) do
        if activeTween == tween then
            table.remove(activeTweens, i)
            break
        end
    end
end

local originalWait = wait
TweenService._lastUpdateTime = os.clock()

function TweenService._processTweens()
    local currentTime = os.clock()
    local deltaTime = currentTime - TweenService._lastUpdateTime
    TweenService._lastUpdateTime = currentTime
    local i = 1
    while i <= #activeTweens do
        local tween = activeTweens[i]
        local shouldContinue = tween:Update(deltaTime)
        if shouldContinue then
            i = i + 1
        else
            table.remove(activeTweens, i)
        end
    end
end

wait = function(seconds)
    local startTime = os.clock()
    local endTime = startTime + seconds

    while os.clock() < endTime do
        TweenService._processTweens()
        originalWait(0.001)
    end

    return os.clock() - startTime
end

function TweenService:Create(instance, tweenInfo, properties)
    return Tween.new(instance, tweenInfo, properties)
end

TweenService.TweenInfo = TweenInfo
_G.TweenService = TweenService

print("Tween Done")

_G.tweenSpeed = 100

print("Loading")

local buttons = {}
local Mouse = game:GetService("Players").LocalPlayer:GetMouse()

local function CreateButton(x, y, w, h, text, onClick)
    local bg = Drawing.new("Square")
    bg.Position = Vector2.new(x, y)
    bg.Size = Vector2.new(w, h)
    bg.Color = Color3.fromRGB(60, 120, 220)
    bg.Filled = true
    bg.Visible = true
    bg.Transparency = 1
    bg.ZIndex = 5
    
    local txt = Drawing.new("Text")
    txt.Position = Vector2.new(x + 10, y + 8)
    txt.Text = text
    txt.Color = Color3.fromRGB(255, 255, 255)
    txt.Visible = true
    txt.Transparency = 1
    txt.Outline = true
    txt.ZIndex = 6
    
    local btn = {bg = bg, txt = txt, x = x, y = y, w = w, h = h, onClick = onClick}
    table.insert(buttons, btn)
    return btn
end

local uiX = 300
local uiY = 200
local bg = Drawing.new("Square")
bg.Position = Vector2.new(uiX, uiY)
bg.Size = Vector2.new(400, 300)
bg.Color = Color3.fromRGB(30, 30, 35)
bg.Filled = true
bg.Visible = true
bg.Transparency = 1

local header = Drawing.new("Square")
header.Position = Vector2.new(uiX, uiY)
header.Size = Vector2.new(400, 35)
header.Color = Color3.fromRGB(25, 25, 30)
header.Filled = true
bg.Visible = true
bg.Transparency = 1
header.ZIndex = 2

local title = Drawing.new("Text")
title.Position = Vector2.new(uiX + 10, uiY + 10)
title.Text = "Evade Script"
title.Color = Color3.fromRGB(255, 255, 255)
title.Visible = true
title.Transparency = 1
title.Outline = true
title.ZIndex = 3

local autoFarmEnabled = false
local autoFarmRunning = false

local button1 = CreateButton(uiX + 20, uiY + 60, 150, 30, "Auto Farm: OFF", nil)

button1.onClick = function()
    autoFarmEnabled = not autoFarmEnabled
    
    if autoFarmEnabled then
        button1.txt.Text = "Auto Farm: ON"
        button1.bg.Color = Color3.fromRGB(60, 220, 120)
        print(" AUTO FARM ENABLED ")
        
        if not autoFarmRunning then
            autoFarmRunning = true
            
            spawn(function()
                while autoFarmEnabled do
                    local player = game.Players.LocalPlayer
                    local character = player.Character
                    
                    if character then
                        local hrp = character:FindFirstChild("HumanoidRootPart")
                        
                        if hrp then
                            local workspace = game.Workspace
                            local gameFolder = workspace:FindFirstChild("Game")
                            local mapFolder = nil
                            if gameFolder then
                                mapFolder = gameFolder:FindFirstChild("Map")
                            end
                            
                            local safeZonesFolder = nil
                            if mapFolder then
                                safeZonesFolder = mapFolder:FindFirstChild("SafeZones")
                            end
                            
                            -- Get damage trigger parts with improved logic
                            local damageTriggers = {}
                            local damageInstantParts = {}
                            local mapLogic = nil
                            if mapFolder then
                                mapLogic = mapFolder:FindFirstChild("MapLogic")
                            end
                            
                            if mapLogic then
                                local damageInstant = mapLogic:FindFirstChild("DamageInstant")
                                if damageInstant then
                                    local trigger = damageInstant:FindFirstChild("Trigger")
                                    if trigger then
                                        for _, part in pairs(trigger:GetChildren()) do
                                            if part:IsA("BasePart") then
                                                local success, pos = pcall(function() return part.Position end)
                                                local success2, size = pcall(function() return part.Size end)
                                                if success and success2 then
                                                    table.insert(damageTriggers, {
                                                        Position = pos,
                                                        Size = size,
                                                        MaxDistance = math.max(size.X, size.Y, size.Z) + 20 -- Increased buffer to 20 studs
                                                    })
                                                    
                                                    -- Store for advanced detection
                                                    table.insert(damageInstantParts, {
                                                        Position = pos,
                                                        Size = size,
                                                        MinBounds = Vector3.new(
                                                            pos.X - size.X/2 - 20,
                                                            pos.Y - size.Y/2 - 20,
                                                            pos.Z - size.Z/2 - 20
                                                        ),
                                                        MaxBounds = Vector3.new(
                                                            pos.X + size.X/2 + 20,
                                                            pos.Y + size.Y/2 + 20,
                                                            pos.Z + size.Z/2 + 20
                                                        )
                                                    })
                                                end
                                            end
                                        end
                                    end
                                end
                            end
                            
                            print("Found " .. #damageTriggers .. " damage trigger parts")
                            
                            local safeZones = {}
                            
                            if safeZonesFolder then
                                for _, obj in pairs(safeZonesFolder:GetDescendants()) do
                                    if obj.ClassName == "Part" or obj:IsA("BasePart") then
                                        local success, pos = pcall(function() return obj.Position end)
                                        local success2, size = pcall(function() return obj.Size end)
                                        if success and pos.Y > 5 then -- Only include safezones with Y > 5
                                            -- Check if this safezone is safe from damage triggers
                                            local isSafe = true
                                            local safeZoneInfo = {
                                                Position = pos,
                                                Size = size or Vector3.new(10, 10, 10),
                                                HasDamageInstant = false,
                                                Priority = 0,
                                                SafePosition = Vector3.new(pos.X + 15, pos.Y + 10, pos.Z)
                                            }
                                            
                                            -- Check if safezone center is in damage area
                                            for _, trigger in pairs(damageInstantParts) do
                                                if pos.X >= trigger.MinBounds.X and pos.X <= trigger.MaxBounds.X and
                                                   pos.Y >= trigger.MinBounds.Y and pos.Y <= trigger.MaxBounds.Y and
                                                   pos.Z >= trigger.MinBounds.Z and pos.Z <= trigger.MaxBounds.Z then
                                                    isSafe = false
                                                    safeZoneInfo.HasDamageInstant = true
                                                    break
                                                end
                                            end
                                            
                                            -- Check all 8 corners of the safezone
                                            if isSafe then
                                                local halfSize = (size or Vector3.new(10, 10, 10)) / 2
                                                local corners = {
                                                    Vector3.new(pos.X - halfSize.X, pos.Y - halfSize.Y, pos.Z - halfSize.Z),
                                                    Vector3.new(pos.X - halfSize.X, pos.Y - halfSize.Y, pos.Z + halfSize.Z),
                                                    Vector3.new(pos.X - halfSize.X, pos.Y + halfSize.Y, pos.Z - halfSize.Z),
                                                    Vector3.new(pos.X - halfSize.X, pos.Y + halfSize.Y, pos.Z + halfSize.Z),
                                                    Vector3.new(pos.X + halfSize.X, pos.Y - halfSize.Y, pos.Z - halfSize.Z),
                                                    Vector3.new(pos.X + halfSize.X, pos.Y - halfSize.Y, pos.Z + halfSize.Z),
                                                    Vector3.new(pos.X + halfSize.X, pos.Y + halfSize.Y, pos.Z - halfSize.Z),
                                                    Vector3.new(pos.X + halfSize.X, pos.Y + halfSize.Y, pos.Z + halfSize.Z)
                                                }
                                                
                                                for _, corner in pairs(corners) do
                                                    for _, trigger in pairs(damageInstantParts) do
                                                        if corner.X >= trigger.MinBounds.X and corner.X <= trigger.MaxBounds.X and
                                                           corner.Y >= trigger.MinBounds.Y and corner.Y <= trigger.MaxBounds.Y and
                                                           corner.Z >= trigger.MinBounds.Z and corner.Z <= trigger.MaxBounds.Z then
                                                            isSafe = false
                                                            safeZoneInfo.HasDamageInstant = true
                                                            break
                                                        end
                                                    end
                                                    if not isSafe then break end
                                                end
                                            end
                                            
                                            -- If safezone has damage instant, calculate safe position above it
                                            if safeZoneInfo.HasDamageInstant then
                                                -- Find the highest damage trigger at this position
                                                local highestTrigger = 0
                                                for _, trigger in pairs(damageInstantParts) do
                                                    if pos.X >= trigger.MinBounds.X and pos.X <= trigger.MaxBounds.X and
                                                       pos.Z >= trigger.MinBounds.Z and pos.Z <= trigger.MaxBounds.Z then
                                                        if trigger.MaxBounds.Y > highestTrigger then
                                                            highestTrigger = trigger.MaxBounds.Y
                                                        end
                                                    end
                                                end
                                                
                                                -- Set safe position above the highest trigger
                                                safeZoneInfo.SafePosition = Vector3.new(pos.X, highestTrigger + 10, pos.Z)
                                                safeZoneInfo.Priority = 1 -- Lower priority for safezones with damage instant
                                            else
                                                safeZoneInfo.Priority = 2 -- Higher priority for safezones without damage instant
                                            end
                                            
                                            if isSafe or safeZoneInfo.HasDamageInstant then
                                                table.insert(safeZones, safeZoneInfo)
                                            end
                                        end
                                    end
                                end
                                
                                if #safeZones > 0 then
                                    -- Sort safezones by priority
                                    table.sort(safeZones, function(a, b)
                                        if a.Priority ~= b.Priority then
                                            return a.Priority > b.Priority
                                        elseif a.Position.Y ~= b.Position.Y then
                                            return a.Position.Y > b.Position.Y
                                        else
                                            return a.SafePosition.Y > b.SafePosition.Y
                                        end
                                    end)
                                    
                                    print("Found " .. #safeZones .. " SafeZones with Y > 5")
                                    
                                    while autoFarmEnabled and character.Parent do
                                        for i, safeZoneInfo in ipairs(safeZones) do
                                            if not autoFarmEnabled or not character.Parent then
                                                break
                                            end
                                            
                                            local targetPosition = safeZoneInfo.SafePosition
                                            
                                            local currentPosition = hrp.Position
                                            local distance = math.sqrt(
                                                (targetPosition.X - currentPosition.X)^2 + 
                                                (targetPosition.Y - currentPosition.Y)^2 + 
                                                (targetPosition.Z - currentPosition.Z)^2
                                            )
                                            
                                            local duration = distance / _G.tweenSpeed
                                            local startTime = os.clock()
                                            
                                            while autoFarmEnabled and character.Parent do
                                                -- Check current position during movement
                                                local isCurrentPathSafe = true
                                                for _, trigger in pairs(damageInstantParts) do
                                                    if hrp.Position.X >= trigger.MinBounds.X and hrp.Position.X <= trigger.MaxBounds.X and
                                                       hrp.Position.Y >= trigger.MinBounds.Y and hrp.Position.Y <= trigger.MaxBounds.Y and
                                                       hrp.Position.Z >= trigger.MinBounds.Z and hrp.Position.Z <= trigger.MaxBounds.Z then
                                                        isCurrentPathSafe = false
                                                        break
                                                    end
                                                end
                                                
                                                if not isCurrentPathSafe then
                                                    print("Current path is unsafe, stopping movement...")
                                                    break
                                                end
                                                
                                                local elapsed = os.clock() - startTime
                                                local alpha = math.min(elapsed / duration, 1)
                                                
                                                local easedAlpha = alpha
                                                
                                                local newX = currentPosition.X + (targetPosition.X - currentPosition.X) * easedAlpha
                                                local newY = currentPosition.Y + (targetPosition.Y - currentPosition.Y) * easedAlpha
                                                local newZ = currentPosition.Z + (targetPosition.Z - currentPosition.Z) * easedAlpha
                                                
                                                hrp.Position = Vector3.new(newX, newY, newZ)
                                                hrp.Velocity = Vector3.new(0, 0, 0)
                                                hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                                                
                                                if alpha >= 1 then
                                                    wait(0.5)
                                                    break
                                                end
                                                
                                                wait(0.001)
                                            end
                                        end
                                    end
                                else
                                    print("No SafeZones with Y > 5 found! Waiting 5 seconds...")
                                    wait(5)
                                end
                            else
                                print("SafeZones folder not found! Waiting 5 seconds...")
                                wait(5)
                            end
                            
                            if not character.Parent then
                                print("Player died. Waiting for respawn...")
                                wait(5)
                                print("Restarting farm loop")
                            end
                        else
                            wait(1)
                        end
                    else
                        wait(1)
                    end
                end
                
                autoFarmRunning = false
                print(" AUTO FARM DISABLED ")
            end);
        end
    else
        button1.txt.Text = "Auto Farm: OFF"
        button1.bg.Color = Color3.fromRGB(60, 120, 220)
        print(" AUTO FARM DISABLED ")
    end
end

-- Auto Ticket Farm variables
local autoTicketFarmEnabled = false
local autoTicketFarmRunning = false

local button2 = CreateButton(uiX + 20, uiY + 110, 150, 30, "Auto Ticket: OFF", nil)

button2.onClick = function()
    autoTicketFarmEnabled = not autoTicketFarmEnabled
    
    if autoTicketFarmEnabled then
        button2.txt.Text = "Auto Ticket: ON"
        button2.bg.Color = Color3.fromRGB(60, 220, 120)
        print(" AUTO TICKET FARM ENABLED ")
        
        if not autoTicketFarmRunning then
            autoTicketFarmRunning = true
            
            spawn(function()
                local player = game.Players.LocalPlayer
                local teleportedToSky = false
                
                repeat wait(0.1) until game.Workspace
                
                local function getCharacter()
                    local char = player.Character
                    while not char do
                        wait(0.1)
                        char = player.Character
                    end
                    local hrp = char:FindFirstChild("HumanoidRootPart")
                    while not hrp do
                        wait(0.1)
                        hrp = char:FindFirstChild("HumanoidRootPart")
                    end
                    return char
                end
                
                local function getTicketsFolder()
                    while true do
                        local gameFolder = game.Workspace:FindFirstChild("Game")
                        if gameFolder then
                            local effectsFolder = gameFolder:FindFirstChild("Effects")
                            if effectsFolder then
                                local ticketsFolder = effectsFolder:FindFirstChild("Tickets")
                                if ticketsFolder then
                                    printl("Found Tickets folder")
                                    return ticketsFolder
                                end
                            end
                        end
                        wait(1)
                    end
                end
                
                local function teleportToTicket(ticket)
                    local character = getCharacter()
                    if character then
                        local rootPart = ticket:FindFirstChild("HumanoidRootPart")
                        if rootPart and rootPart.Position then
                            printl("Teleporting to ticket: " .. ticket.Name)
                            local offset = Vector3.new(0, 0, 0)
                            character.HumanoidRootPart.Position = rootPart.Position + offset
                            teleportedToSky = false
                        end
                    end
                end
                
                local function teleportToSky()
                    if not teleportedToSky then
                        local character = getCharacter()
                        if character and character.HumanoidRootPart.Position then
                            printl("Teleporting to sky")
                            local offset = Vector3.new(0, 10000, 0)
                            character.HumanoidRootPart.Position = character.HumanoidRootPart.Position + offset
                            teleportedToSky = true
                        end
                    end
                end
                
                local function checkForNewTickets()
                    while autoTicketFarmEnabled do
                        local ticketsFolder = getTicketsFolder()
                        local tickets = ticketsFolder:GetChildren()
                        printl("Number of tickets: " .. #tickets)
                        
                        if #tickets == 0 then
                            teleportToSky()
                        else
                            for _, ticket in pairs(tickets) do
                                if ticket:IsA("Model") then
                                    teleportToTicket(ticket)
                                    break
                                end
                            end
                        end
                        
                        wait(0.5)
                    end
                end
                
                checkForNewTickets()
                autoTicketFarmRunning = false
                print(" AUTO TICKET FARM DISABLED ")
            end);
        end
    else
        button2.txt.Text = "Auto Ticket: OFF"
        button2.bg.Color = Color3.fromRGB(60, 120, 220)
        print(" AUTO TICKET FARM DISABLED ")
    end
end

-- Auto Farm + Ticket variables
local autoFarmTicketEnabled = false
local autoFarmTicketRunning = false

local button3 = CreateButton(uiX + 20, uiY + 160, 150, 30, "Farm+Ticket: OFF", nil)

button3.onClick = function()
    autoFarmTicketEnabled = not autoFarmTicketEnabled
    
    if autoFarmTicketEnabled then
        button3.txt.Text = "Farm+Ticket: ON"
        button3.bg.Color = Color3.fromRGB(60, 220, 120)
        print(" AUTO FARM + TICKET ENABLED ")
        
        if not autoFarmTicketRunning then
            autoFarmTicketRunning = true
            
            spawn(function()
                local player = game.Players.LocalPlayer
                local currentMode = "Ticket" -- Start with ticket mode
                local lastCharacterCheck = os.clock()
                local lastModeSwitch = os.clock()
                
                repeat wait(0.1) until game.Workspace
                
                local function getCharacter()
                    local char = player.Character
                    while not char do
                        wait(0.1)
                        char = player.Character
                    end
                    local hrp = char:FindFirstChild("HumanoidRootPart")
                    while not hrp do
                        wait(0.1)
                        hrp = char:FindFirstChild("HumanoidRootPart")
                    end
                    return char
                end
                
                local function getTicketsFolder()
                    while true do
                        local gameFolder = game.Workspace:FindFirstChild("Game")
                        if gameFolder then
                            local effectsFolder = gameFolder:FindFirstChild("Effects")
                            if effectsFolder then
                                local ticketsFolder = effectsFolder:FindFirstChild("Tickets")
                                if ticketsFolder then
                                    return ticketsFolder
                                end
                            end
                        end
                        wait(1)
                    end
                end
                
                -- Get damage trigger parts with improved logic
                local function getDamageTriggers()
                    local damageTriggers = {}
                    local damageInstantParts = {}
                    local workspace = game.Workspace
                    local gameFolder = workspace:FindFirstChild("Game")
                    local mapFolder = nil
                    if gameFolder then
                        mapFolder = gameFolder:FindFirstChild("Map")
                    end
                    
                    local mapLogic = nil
                    if mapFolder then
                        mapLogic = mapFolder:FindFirstChild("MapLogic")
                    end
                    
                    if mapLogic then
                        local damageInstant = mapLogic:FindFirstChild("DamageInstant")
                        if damageInstant then
                            local trigger = damageInstant:FindFirstChild("Trigger")
                            if trigger then
                                for _, part in pairs(trigger:GetChildren()) do
                                    if part:IsA("BasePart") then
                                        local success, pos = pcall(function() return part.Position end)
                                        local success2, size = pcall(function() return part.Size end)
                                        if success and success2 then
                                            table.insert(damageTriggers, {
                                                Position = pos,
                                                Size = size,
                                                MaxDistance = math.max(size.X, size.Y, size.Z) + 20 -- Increased buffer to 20 studs
                                            })
                                            
                                            -- Store for advanced detection
                                            table.insert(damageInstantParts, {
                                                Position = pos,
                                                Size = size,
                                                MinBounds = Vector3.new(
                                                    pos.X - size.X/2 - 20,
                                                    pos.Y - size.Y/2 - 20,
                                                    pos.Z - size.Z/2 - 20
                                                ),
                                                MaxBounds = Vector3.new(
                                                    pos.X + size.X/2 + 20,
                                                    pos.Y + size.Y/2 + 20,
                                                    pos.Z + size.Z/2 + 20
                                                )
                                            })
                                        end
                                    end
                                end
                            end
                        end
                    end
                    
                    return damageTriggers, damageInstantParts
                end
                
                local function getSafeZones(damageInstantParts)
                    local safeZones = {}
                    local workspace = game.Workspace
                    local gameFolder = workspace:FindFirstChild("Game")
                    local mapFolder = nil
                    if gameFolder then
                        mapFolder = gameFolder:FindFirstChild("Map")
                    end
                    
                    local safeZonesFolder = nil
                    if mapFolder then
                        safeZonesFolder = mapFolder:FindFirstChild("SafeZones")
                    end
                    
                    if safeZonesFolder then
                        for _, obj in pairs(safeZonesFolder:GetDescendants()) do
                            if obj.ClassName == "Part" or obj:IsA("BasePart") then
                                local success, pos = pcall(function() return obj.Position end)
                                local success2, size = pcall(function() return obj.Size end)
                                if success and pos.Y > 5 then -- Only include safezones with Y > 5
                                    -- Check if this safezone is safe from damage triggers
                                    local isSafe = true
                                    local safeZoneInfo = {
                                        Position = pos,
                                        Size = size or Vector3.new(10, 10, 10),
                                        HasDamageInstant = false,
                                        Priority = 0,
                                        SafePosition = Vector3.new(pos.X + 15, pos.Y + 10, pos.Z)
                                    }
                                    
                                    -- Check if safezone center is in damage area
                                    for _, trigger in pairs(damageInstantParts) do
                                        if pos.X >= trigger.MinBounds.X and pos.X <= trigger.MaxBounds.X and
                                           pos.Y >= trigger.MinBounds.Y and pos.Y <= trigger.MaxBounds.Y and
                                           pos.Z >= trigger.MinBounds.Z and pos.Z <= trigger.MaxBounds.Z then
                                            isSafe = false
                                            safeZoneInfo.HasDamageInstant = true
                                            break
                                        end
                                    end
                                    
                                    -- Check all 8 corners of the safezone
                                    if isSafe then
                                        local halfSize = (size or Vector3.new(10, 10, 10)) / 2
                                        local corners = {
                                            Vector3.new(pos.X - halfSize.X, pos.Y - halfSize.Y, pos.Z - halfSize.Z),
                                            Vector3.new(pos.X - halfSize.X, pos.Y - halfSize.Y, pos.Z + halfSize.Z),
                                            Vector3.new(pos.X - halfSize.X, pos.Y + halfSize.Y, pos.Z - halfSize.Z),
                                            Vector3.new(pos.X - halfSize.X, pos.Y + halfSize.Y, pos.Z + halfSize.Z),
                                            Vector3.new(pos.X + halfSize.X, pos.Y - halfSize.Y, pos.Z - halfSize.Z),
                                            Vector3.new(pos.X + halfSize.X, pos.Y - halfSize.Y, pos.Z + halfSize.Z),
                                            Vector3.new(pos.X + halfSize.X, pos.Y + halfSize.Y, pos.Z - halfSize.Z),
                                            Vector3.new(pos.X + halfSize.X, pos.Y + halfSize.Y, pos.Z + halfSize.Z)
                                        }
                                        
                                        for _, corner in pairs(corners) do
                                            for _, trigger in pairs(damageInstantParts) do
                                                if corner.X >= trigger.MinBounds.X and corner.X <= trigger.MaxBounds.X and
                                                   corner.Y >= trigger.MinBounds.Y and corner.Y <= trigger.MaxBounds.Y and
                                                   corner.Z >= trigger.MinBounds.Z and corner.Z <= trigger.MaxBounds.Z then
                                                    isSafe = false
                                                    safeZoneInfo.HasDamageInstant = true
                                                    break
                                                end
                                            end
                                            if not isSafe then break end
                                        end
                                    end
                                    
                                    -- If safezone has damage instant, calculate safe position above it
                                    if safeZoneInfo.HasDamageInstant then
                                        -- Find the highest damage trigger at this position
                                        local highestTrigger = 0
                                        for _, trigger in pairs(damageInstantParts) do
                                            if pos.X >= trigger.MinBounds.X and pos.X <= trigger.MaxBounds.X and
                                               pos.Z >= trigger.MinBounds.Z and pos.Z <= trigger.MaxBounds.Z then
                                                if trigger.MaxBounds.Y > highestTrigger then
                                                    highestTrigger = trigger.MaxBounds.Y
                                                end
                                            end
                                        end
                                        
                                        -- Set safe position above the highest trigger
                                        safeZoneInfo.SafePosition = Vector3.new(pos.X, highestTrigger + 10, pos.Z)
                                        safeZoneInfo.Priority = 1 -- Lower priority for safezones with damage instant
                                    else
                                        safeZoneInfo.Priority = 2 -- Higher priority for safezones without damage instant
                                    end
                                    
                                    if isSafe or safeZoneInfo.HasDamageInstant then
                                        table.insert(safeZones, safeZoneInfo)
                                    end
                                end
                            end
                        end
                    end
                    
                    return safeZones
                end
                
                local function teleportToTicket(ticket)
                    local character = getCharacter()
                    if character then
                        local rootPart = ticket:FindFirstChild("HumanoidRootPart")
                        if rootPart and rootPart.Position then
                            printl("Teleporting to ticket: " .. ticket.Name)
                            local offset = Vector3.new(0, 0, 0)
                            character.HumanoidRootPart.Position = rootPart.Position + offset
                        end
                    end
                end
                
                local function teleportToSky()
                    local character = getCharacter()
                    if character and character.HumanoidRootPart.Position then
                        printl("Teleporting to sky to wait for tickets")
                        local offset = Vector3.new(0, 10000, 0)
                        character.HumanoidRootPart.Position = character.HumanoidRootPart.Position + offset
                        character.HumanoidRootPart.Velocity = Vector3.new(0, 0, 0)
                        character.HumanoidRootPart.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                    end
                end
                
                -- Fixed farm mode to properly alternate with ticket mode
                local function farmMode(damageInstantParts)
                    printl("Switching to Farm Mode")
                    local safeZones = getSafeZones(damageInstantParts)
                    
                    if #safeZones > 0 then
                        -- Sort safezones by priority
                        table.sort(safeZones, function(a, b)
                            if a.Priority ~= b.Priority then
                                return a.Priority > b.Priority
                            elseif a.Position.Y ~= b.Position.Y then
                                return a.Position.Y > b.Position.Y
                            else
                                return a.SafePosition.Y > b.SafePosition.Y
                            end
                        end)
                        
                        local character = getCharacter()
                        if character then
                            local hrp = character:FindFirstChild("HumanoidRootPart")
                            if hrp then
                                -- Pick the highest priority safe zone
                                local safeZoneInfo = safeZones[1]
                                local targetPosition = safeZoneInfo.SafePosition
                                
                                -- Teleport directly to the safe position
                                hrp.Position = targetPosition
                                hrp.Velocity = Vector3.new(0, 0, 0)
                                hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                                
                                -- Wait a moment at each safe zone
                                wait(0.5)
                                
                                -- Check for tickets while farming
                                local ticketsFolder = getTicketsFolder()
                                local tickets = ticketsFolder:GetChildren()
                                if #tickets > 0 then
                                    printl("New ticket detected! Switching to ticket mode.")
                                    currentMode = "Ticket"
                                    lastModeSwitch = os.clock()
                                    return
                                end
                            end
                        end
                    else
                        -- If no safe zones, teleport to sky and check for tickets
                        teleportToSky()
                        wait(1)
                        
                        -- Check for tickets
                        local ticketsFolder = getTicketsFolder()
                        local tickets = ticketsFolder:GetChildren()
                        if #tickets > 0 then
                            printl("Found tickets in sky! Switching to ticket mode.")
                            currentMode = "Ticket"
                            lastModeSwitch = os.clock()
                            return
                        end
                    end
                    
                    -- Always switch back to ticket mode after farming
                    currentMode = "Ticket"
                    lastModeSwitch = os.clock()
                end
                
                -- Fixed ticket mode to properly switch to farm mode
                local function ticketMode()
                    printl("Switching to Ticket Mode")
                    local ticketsFolder = getTicketsFolder()
                    local tickets = ticketsFolder:GetChildren()
                    
                    if #tickets > 0 then
                        for _, ticket in pairs(tickets) do
                            if ticket:IsA("Model") then
                                teleportToTicket(ticket)
                                wait(0.1) -- Reduced wait time from 0.5 to 0.1 for faster response
                                break
                            end
                        end
                    else
                        -- No tickets found, switch to farm mode
                        printl("No tickets found. Switching to farm mode.")
                        currentMode = "Farm"
                        lastModeSwitch = os.clock()
                    end
                end
                
                -- Main loop with character respawn handling and error recovery
                while autoFarmTicketEnabled do
                    -- Add error handling to prevent crashes
                    local success, errorMsg = pcall(function()
                        -- Check if character exists every 2 seconds
                        if os.clock() - lastCharacterCheck >= 2 then
                            local character = getCharacter()
                            if not character then
                                print("Character not found, waiting for respawn...")
                                wait(2)
                                lastCharacterCheck = os.clock()
                                return
                            end
                            lastCharacterCheck = os.clock()
                        end
                        
                        -- Force mode switch if stuck in one mode for too long
                        if os.clock() - lastModeSwitch >= 10 then
                            print("Mode stuck for too long, forcing switch...")
                            if currentMode == "Ticket" then
                                currentMode = "Farm"
                            else
                                currentMode = "Ticket"
                            end
                            lastModeSwitch = os.clock()
                        end
                        
                        -- Get fresh damage triggers each round
                        local damageTriggers, damageInstantParts = getDamageTriggers()
                        print("Found " .. #damageTriggers .. " damage trigger parts")
                        
                        if currentMode == "Ticket" then
                            ticketMode()
                        else
                            farmMode(damageInstantParts)
                        end
                        
                        wait(0.1) -- Reduced wait time from 1 to 0.1 for faster response
                    end)
                    
                    -- If an error occurred, print it and continue
                    if not success then
                        print("Error in Farm+Ticket loop: " .. tostring(errorMsg))
                        wait(1)
                    end
                end
                
                autoFarmTicketRunning = false
                print(" AUTO FARM + TICKET DISABLED ")
            end);
        end
    else
        button3.txt.Text = "Farm+Ticket: OFF"
        button3.bg.Color = Color3.fromRGB(60, 120, 220)
        print(" AUTO FARM + TICKET DISABLED ")
    end
end

-- Button 4 placeholder for future functionality
local button4 = CreateButton(uiX + 200, uiY + 60, 150, 30, "Button 4", function()
    print("Button 4 clicked!")
end)

CreateButton(uiX + 200, uiY + 110, 150, 30, "Button 5", function()
    print("Button 5 clicked!")
end)

CreateButton(uiX + 200, uiY + 160, 150, 30, "Button 6", function()
    print("Button 6 clicked!")
end)

local isDragging = false
local dragOffsetX = 0
local dragOffsetY = 0

spawn(function()
    local lastClick = false
    print("Input loop started")
    while true do
        local clicked = ismouse1pressed()
        local mx, my = Mouse.X, Mouse.Y
        
        if clicked and not lastClick then
            if mx >= uiX and mx <= uiX + 400 and my >= uiY and my <= uiY + 35 then
                isDragging = true
                dragOffsetX = mx - uiX
                dragOffsetY = my - uiY
                print("Started dragging")
            else
                for _, btn in ipairs(buttons) do
                    if mx >= btn.x and mx <= btn.x + btn.w and my >= btn.y and my <= btn.y + btn.h then
                        if btn.onClick then
                            btn.onClick()
                        end
                        break
                    end
                end
            end
        end
        
        if not clicked and lastClick then
            isDragging = false
        end
        
        if isDragging and clicked then
            local newX = mx - dragOffsetX
            local newY = my - dragOffsetY
            local deltaX = newX - uiX
            local deltaY = newY - uiY
            
            uiX = newX
            uiY = newY
            
            bg.Position = Vector2.new(uiX, uiY)
            header.Position = Vector2.new(uiX, uiY)
            title.Position = Vector2.new(uiX + 10, uiY + 10)
            
            for _, btn in ipairs(buttons) do
                btn.x = btn.x + deltaX
                btn.y = btn.y + deltaY
                btn.bg.Position = Vector2.new(btn.x, btn.y)
                btn.txt.Position = Vector2.new(btn.x + 10, btn.y + 8)
            end
        end
        
        lastClick = clicked
        wait(0.001)
    end
end)

print(" UI LOADED ")
print("Tween speed: " .. _G.tweenSpeed .. " studs/sec")
