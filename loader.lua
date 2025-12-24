-- ================================================== --
-- Evade Script - Auto Farm & Auto Ticket
-- Version: 1.1.2
-- ================================================== --
-- UPDATE LOGS:
-- v1.0.0 - Initial Release
-- - Added Auto Farm functionality
-- - Added Auto Ticket functionality  
-- - Added Farm+Ticket combined mode
-- - Improved button 3 with continuous loop logic from button 2
-- - Added version system and update logs
-- - Optimized error handling and stability
-- v1.1.0 - UI Improvements
-- - Added Slider UI component
-- - Added Tween Speed slider
-- - Added Wait Time slider
-- - Improved button 3 logic to switch to farm immediately after collecting ticket
-- v1.1.1 - Button 3 Logic Revert
-- - Reverted button 3 to previous logic with mode switching
-- - Maintained slider UI functionality
-- v1.1.2 - Slider Improvements
-- - Added explanatory text for wait time slider
-- - Added new "Ticket Wait Time" slider for waiting after collecting tickets
-- - Improved wait time sliders to support decimal values (0.01s to 2s)
-- - Updated button 3 logic to use new ticket wait time

print("Loading Tween");
local TweenService = {};
local EasingFunctions = {Linear=function(t)
    return t;
end,Sine={In=function(t)
    return 1 - math.cos((t * math.pi) / 2);
end,Out=function(t)
    return math.sin((t * math.pi) / 2);
end,InOut=function(t)
    return -(math.cos(math.pi * t) - 1) / 2;
end},Quad={In=function(t)
    return t * t;
end,Out=function(t)
    return 1 - ((1 - t) * (1 - t));
end,InOut=function(t)
    return ((t < 0.5) and (2 * t * t)) or (1 - ((((-2 * t) + 2) ^ 2) / 2));
end}};
local function getEasingFunction(easingStyle, easingDirection)
    if (easingStyle == "Linear") then
        return EasingFunctions.Linear;
    elseif EasingFunctions[easingStyle] then
        if (easingDirection == "In") then
            return EasingFunctions[easingStyle].In;
        elseif (easingDirection == "Out") then
            return EasingFunctions[easingStyle].Out;
        else
            return EasingFunctions[easingStyle].InOut;
        end
    end
    return EasingFunctions.Linear;
end
local TweenInfo = {};
TweenInfo.__index = TweenInfo;
TweenInfo.new = function(time, easingStyle, easingDirection, repeatCount, reverses, delayTime)
    local self = setmetatable({}, TweenInfo);
    self.Time = time or 1;
    self.EasingStyle = easingStyle or "Quad";
    self.EasingDirection = easingDirection or "Out";
    self.RepeatCount = repeatCount or 0;
    self.Reverses = reverses or false;
    self.DelayTime = delayTime or 0;
    return self;
end;
local Tween = {};
Tween.__index = Tween;
Tween.new = function(instance, tweenInfo, properties)
    local self = setmetatable({}, Tween);
    self.Instance = instance;
    self.TweenInfo = tweenInfo;
    self.Properties = properties;
    self.InitialProperties = {};
    self.IsPlaying = false;
    self.StartTime = 0;
    self.CurrentTime = 0;
    for prop, targetValue in pairs(properties) do
        if (instance[prop] ~= nil) then
            self.InitialProperties[prop] = instance[prop];
        end
    end
    return self;
end;
Tween.Play = function(self)
    if self.IsPlaying then
        return;
    end
    self.IsPlaying = true;
    self.StartTime = os.clock();
    self.CurrentTime = 0;
    TweenService._addActiveTween(self);
end;
Tween.Stop = function(self)
    if not self.IsPlaying then
        return;
    end
    self.IsPlaying = false;
    TweenService._removeActiveTween(self);
end;
Tween.Update = function(self, deltaTime)
    if not self.IsPlaying then
        return false;
    end
    self.CurrentTime = self.CurrentTime + deltaTime;
    local tweenInfo = self.TweenInfo;
    if (self.CurrentTime >= tweenInfo.Time) then
        for prop, targetValue in pairs(self.Properties) do
            self.Instance[prop] = targetValue;
        end
        self:Stop();
        return false;
    end
    local alpha = getEasingFunction(tweenInfo.EasingStyle, tweenInfo.EasingDirection)(self.CurrentTime / tweenInfo.Time);
    for prop, targetValue in pairs(self.Properties) do
        if ((self.Instance[prop] ~= nil) and (self.InitialProperties[prop] ~= nil)) then
            local initialValue = self.InitialProperties[prop];
            if ((type(initialValue) == "number") and (type(targetValue) == "number")) then
                self.Instance[prop] = initialValue + ((targetValue - initialValue) * alpha);
            else
                self.Instance[prop] = targetValue;
            end
        end
    end
    return true;
end;
local activeTweens = {};
TweenService._addActiveTween = function(tween)
    table.insert(activeTweens, tween);
end;
TweenService._removeActiveTween = function(tween)
    for i, activeTween in ipairs(activeTweens) do
        if (activeTween == tween) then
            table.remove(activeTweens, i);
            break;
        end
    end
end;
local originalWait = wait;
TweenService._lastUpdateTime = os.clock();
TweenService._processTweens = function()
    local currentTime = os.clock();
    local deltaTime = currentTime - TweenService._lastUpdateTime;
    TweenService._lastUpdateTime = currentTime;
    local i = 1;
    while i <= #activeTweens do
        local tween = activeTweens[i];
        local shouldContinue = tween:Update(deltaTime);
        if shouldContinue then
            i = i + 1;
        else
            table.remove(activeTweens, i);
        end
    end
end;
function wait(seconds)
    local startTime = os.clock();
    local endTime = startTime + seconds;
    while os.clock() < endTime do
        TweenService._processTweens();
        originalWait(0.001);
    end
    return os.clock() - startTime;
end
TweenService.Create = function(self, instance, tweenInfo, properties)
    return Tween.new(instance, tweenInfo, properties);
end;
TweenService.TweenInfo = TweenInfo;
_G.TweenService = TweenService;
print("Tween Done");
_G.tweenSpeed = 30;
_G.waitTime = 0.5; -- Default wait time after reaching safezone
_G.ticketWaitTime = 0.1; -- Default wait time after collecting ticket
print("Loading Evade Script v1.1.2");
local buttons = {};
local sliders = {}; -- Store sliders
local Mouse = game:GetService("Players").LocalPlayer:GetMouse();
local function CreateButton(x, y, w, h, text, onClick)
    local bg = Drawing.new("Square");
    bg.Position = Vector2.new(x, y);
    bg.Size = Vector2.new(w, h);
    bg.Color = Color3.fromRGB(60, 120, 220);
    bg.Filled = true;
    bg.Visible = true;
    bg.Transparency = 1;
    bg.ZIndex = 5;
    local txt = Drawing.new("Text");
    txt.Position = Vector2.new(x + 10, y + 8);
    txt.Text = text;
    txt.Color = Color3.fromRGB(255, 255, 255);
    txt.Visible = true;
    txt.Transparency = 1;
    txt.Outline = true;
    txt.ZIndex = 6;
    local btn = {bg=bg,txt=txt,x=x,y=y,w=w,h=h,onClick=onClick};
    table.insert(buttons, btn);
    return btn;
end

-- Function to create a slider
local function CreateSlider(x, y, w, h, min, max, defaultValue, text, onChange, description)
    -- Slider background
    local bg = Drawing.new("Square");
    bg.Position = Vector2.new(x, y);
    bg.Size = Vector2.new(w, h);
    bg.Color = Color3.fromRGB(50, 50, 50);
    bg.Filled = true;
    bg.Visible = true;
    bg.Transparency = 1;
    bg.ZIndex = 5;
    
    -- Slider fill (current value)
    local fill = Drawing.new("Square");
    fill.Position = Vector2.new(x, y);
    fill.Size = Vector2.new(w, h);
    fill.Color = Color3.fromRGB(60, 120, 220);
    fill.Filled = true;
    fill.Visible = true;
    fill.Transparency = 1;
    fill.ZIndex = 6;
    
    -- Slider text
    local txt = Drawing.new("Text");
    txt.Position = Vector2.new(x, y - 15);
    txt.Text = text .. ": " .. defaultValue;
    txt.Color = Color3.fromRGB(255, 255, 255);
    txt.Visible = true;
    txt.Transparency = 1;
    txt.Outline = true;
    txt.ZIndex = 7;
    
    -- Description text (if provided)
    local descTxt = nil;
    if description then
        descTxt = Drawing.new("Text");
        descTxt.Position = Vector2.new(x, y + 15);
        descTxt.Text = description;
        descTxt.Color = Color3.fromRGB(200, 200, 200);
        descTxt.Visible = true;
        descTxt.Transparency = 1;
        descTxt.Outline = false;
        descTxt.ZIndex = 7;
    end
    
    -- Calculate initial fill width
    local fillWidth = (defaultValue - min) / (max - min) * w;
    fill.Size = Vector2.new(fillWidth, h);
    
    local slider = {
        bg = bg,
        fill = fill,
        txt = txt,
        descTxt = descTxt,
        x = x,
        y = y,
        w = w,
        h = h,
        min = min,
        max = max,
        value = defaultValue,
        onChange = onChange,
        isDragging = false
    };
    
    table.insert(sliders, slider);
    return slider;
end

-- Function to update slider value
local function UpdateSlider(slider, mouseX)
    if mouseX < slider.x then
        slider.value = slider.min;
    elseif mouseX > slider.x + slider.w then
        slider.value = slider.max;
    else
        local ratio = (mouseX - slider.x) / slider.w;
        slider.value = slider.min + ratio * (slider.max - slider.min);
    end
    
    -- Round to 2 decimal places for precision
    slider.value = math.floor(slider.value * 100) / 100;
    
    -- Update fill width
    local fillWidth = (slider.value - slider.min) / (slider.max - slider.min) * slider.w;
    slider.fill.Size = Vector2.new(fillWidth, slider.h);
    
    -- Update text
    slider.txt.Text = slider.txt.Text:gsub(":.+$", ": " .. slider.value);
    
    -- Call onChange callback
    if slider.onChange then
        slider.onChange(slider.value);
    end
end

local uiX = 300;
local uiY = 200;
local bg = Drawing.new("Square");
bg.Position = Vector2.new(uiX, uiY);
bg.Size = Vector2.new(400, 380); -- Increased height for sliders
bg.Color = Color3.fromRGB(30, 30, 35);
bg.Filled = true;
bg.Visible = true;
bg.Transparency = 1;
local header = Drawing.new("Square");
header.Position = Vector2.new(uiX, uiY);
header.Size = Vector2.new(400, 35);
header.Color = Color3.fromRGB(25, 25, 30);
header.Filled = true;
bg.Visible = true;
bg.Transparency = 1;
header.ZIndex = 2;
local title = Drawing.new("Text");
title.Position = Vector2.new(uiX + 10, uiY + 10);
title.Text = "Evade Script v1.1.2";
title.Color = Color3.fromRGB(255, 255, 255);
title.Visible = true;
title.Transparency = 1;
title.Outline = true;
title.ZIndex = 3;

-- Create sliders
local tweenSpeedSlider = CreateSlider(uiX + 20, uiY + 60, 150, 10, 5, 100, _G.tweenSpeed, "Tween Speed", function(value)
    _G.tweenSpeed = value;
end);

local waitTimeSlider = CreateSlider(uiX + 20, uiY + 110, 150, 10, 0.01, 2, _G.waitTime, "Safezone Wait", function(value)
    _G.waitTime = value;
end, "Wait time after reaching safezone");

local ticketWaitTimeSlider = CreateSlider(uiX + 20, uiY + 160, 150, 10, 0.01, 2, _G.ticketWaitTime, "Ticket Wait", function(value)
    _G.ticketWaitTime = value;
end, "Wait time after collecting ticket");

local autoFarmEnabled = false;
local autoFarmRunning = false;
local button1 = CreateButton(uiX + 20, uiY + 200, 150, 30, "Auto Farm: OFF", nil); -- Adjusted position
button1.onClick = function()
    autoFarmEnabled = not autoFarmEnabled;
    if autoFarmEnabled then
        button1.txt.Text = "Auto Farm: ON";
        button1.bg.Color = Color3.fromRGB(60, 220, 120);
        if not autoFarmRunning then
            autoFarmRunning = true;
            spawn(function()
                while autoFarmEnabled do
                    local player = game.Players.LocalPlayer;
                    local character = player.Character;
                    if character then
                        local hrp = character:FindFirstChild("HumanoidRootPart");
                        if hrp then
                            local workspace = game.Workspace;
                            local gameFolder = workspace:FindFirstChild("Game");
                            local mapFolder = nil;
                            if gameFolder then
                                mapFolder = gameFolder:FindFirstChild("Map");
                            end
                            local safeZonesFolder = nil;
                            if mapFolder then
                                safeZonesFolder = mapFolder:FindFirstChild("SafeZones");
                            end
                            local damageTriggers = {};
                            local mapLogic = nil;
                            if mapFolder then
                                mapLogic = mapFolder:FindFirstChild("MapLogic");
                            end
                            if mapLogic then
                                local damageInstant = mapLogic:FindFirstChild("DamageInstant");
                                if damageInstant then
                                    local trigger = damageInstant:FindFirstChild("Trigger");
                                    if trigger then
                                        for _, part in pairs(trigger:GetChildren()) do
                                            if part:IsA("BasePart") then
                                                local success, pos = pcall(function()
                                                    return part.Position;
                                                end);
                                                local success2, size = pcall(function()
                                                    return part.Size;
                                                end);
                                                if (success and success2) then
                                                    table.insert(damageTriggers, {Position=pos,Size=size,MinBounds=Vector3.new(pos.X - (size.X / 2), pos.Y - (size.Y / 2), pos.Z - (size.Z / 2)),MaxBounds=Vector3.new(pos.X + (size.X / 2), pos.Y + (size.Y / 2), pos.Z + (size.Z / 2))});
                                                end
                                            end
                                        end
                                    end
                                end
                            end
                            local safeZones = {};
                            if safeZonesFolder then
                                for _, obj in pairs(safeZonesFolder:GetDescendants()) do
                                    if ((obj.ClassName == "Part") or obj:IsA("BasePart")) then
                                        local success, pos = pcall(function()
                                            return obj.Position;
                                        end);
                                        local success2, size = pcall(function()
                                            return obj.Size;
                                        end);
                                        if (success and (pos.Y > 5)) then
                                            local isSafe = true;
                                            local safeZoneInfo = {Position=pos,Size=(size or Vector3.new(10, 10, 10)),SafePosition=Vector3.new(pos.X + 15, pos.Y + 10, pos.Z)};
                                            local safeZoneMinBounds = Vector3.new(pos.X - ((size or Vector3.new(10, 10, 10)).X / 2), pos.Y - ((size or Vector3.new(10, 10, 10)).Y / 2), pos.Z - ((size or Vector3.new(10, 10, 10)).Z / 2));
                                            local safeZoneMaxBounds = Vector3.new(pos.X + ((size or Vector3.new(10, 10, 10)).X / 2), pos.Y + ((size or Vector3.new(10, 10, 10)).Y / 2), pos.Z + ((size or Vector3.new(10, 10, 10)).Z / 2));
                                            for _, trigger in pairs(damageTriggers) do
                                                if ((safeZoneMinBounds.X <= trigger.MaxBounds.X) and (safeZoneMaxBounds.X >= trigger.MinBounds.X) and (safeZoneMinBounds.Y <= trigger.MaxBounds.Y) and (safeZoneMaxBounds.Y >= trigger.MinBounds.Y) and (safeZoneMinBounds.Z <= trigger.MaxBounds.Z) and (safeZoneMaxBounds.Z >= trigger.MinBounds.Z)) then
                                                    isSafe = false;
                                                    break;
                                                end
                                            end
                                            if isSafe then
                                                table.insert(safeZones, safeZoneInfo);
                                            end
                                        end
                                    end
                                end
                                if (#safeZones > 0) then
                                    while autoFarmEnabled and character.Parent do
                                        for i, safeZoneInfo in ipairs(safeZones) do
                                            if (not autoFarmEnabled or not character.Parent) then
                                                break;
                                            end
                                            local targetPosition = safeZoneInfo.SafePosition;
                                            local currentPosition = hrp.Position;
                                            local distance = math.sqrt(((targetPosition.X - currentPosition.X) ^ 2) + ((targetPosition.Y - currentPosition.Y) ^ 2) + ((targetPosition.Z - currentPosition.Z) ^ 2));
                                            local duration = distance / _G.tweenSpeed;
                                            local startTime = os.clock();
                                            while autoFarmEnabled and character.Parent do
                                                local isCurrentPathSafe = true;
                                                for _, trigger in pairs(damageTriggers) do
                                                    if ((hrp.Position.X >= trigger.MinBounds.X) and (hrp.Position.X <= trigger.MaxBounds.X) and (hrp.Position.Y >= trigger.MinBounds.Y) and (hrp.Position.Y <= trigger.MaxBounds.Y) and (hrp.Position.Z >= trigger.MinBounds.Z) and (hrp.Position.Z <= trigger.MaxBounds.Z)) then
                                                        isCurrentPathSafe = false;
                                                        break;
                                                    end
                                                end
                                                if not isCurrentPathSafe then
                                                    break;
                                                end
                                                local elapsed = os.clock() - startTime;
                                                local alpha = math.min(elapsed / duration, 1);
                                                local easedAlpha = alpha;
                                                local newX = currentPosition.X + ((targetPosition.X - currentPosition.X) * easedAlpha);
                                                local newY = currentPosition.Y + ((targetPosition.Y - currentPosition.Y) * easedAlpha);
                                                local newZ = currentPosition.Z + ((targetPosition.Z - currentPosition.Z) * easedAlpha);
                                                hrp.Position = Vector3.new(newX, newY, newZ);
                                                hrp.Velocity = Vector3.new(0, 0, 0);
                                                hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0);
                                                if (alpha >= 1) then
                                                    wait(_G.waitTime); -- Use configurable wait time
                                                    break;
                                                end
                                                wait(0.001);
                                            end
                                        end
                                    end
                                else
                                    wait(5);
                                end
                            else
                                wait(5);
                            end
                            if not character.Parent then
                                wait(5);
                            end
                        else
                            wait(1);
                        end
                    else
                        wait(1);
                    end
                end
                autoFarmRunning = false;
            end);
        end
    else
        button1.txt.Text = "Auto Farm: OFF";
        button1.bg.Color = Color3.fromRGB(60, 120, 220);
    end
end;
local autoTicketFarmEnabled = false;
local autoTicketFarmRunning = false;
local button2 = CreateButton(uiX + 20, uiY + 250, 150, 30, "Auto Ticket: OFF", nil); -- Adjusted position
button2.onClick = function()
    autoTicketFarmEnabled = not autoTicketFarmEnabled;
    if autoTicketFarmEnabled then
        button2.txt.Text = "Auto Ticket: ON";
        button2.bg.Color = Color3.fromRGB(60, 220, 120);
        if not autoTicketFarmRunning then
            autoTicketFarmRunning = true;
            spawn(function()
                local player = game.Players.LocalPlayer;
                local teleportedToSky = false;
                repeat
                    wait(0.1);
                until game.Workspace 
                local function getCharacter()
                    local char = player.Character;
                    while not char do
                        wait(0.1);
                        char = player.Character;
                    end
                    local hrp = char:FindFirstChild("HumanoidRootPart");
                    while not hrp do
                        wait(0.1);
                        hrp = char:FindFirstChild("HumanoidRootPart");
                    end
                    return char;
                end
                local function getTicketsFolder()
                    while true do
                        local gameFolder = game.Workspace:FindFirstChild("Game");
                        if gameFolder then
                            local effectsFolder = gameFolder:FindFirstChild("Effects");
                            if effectsFolder then
                                local ticketsFolder = effectsFolder:FindFirstChild("Tickets");
                                if ticketsFolder then
                                    return ticketsFolder;
                                end
                            end
                        end
                        wait(1);
                    end
                end
                local function teleportToTicket(ticket)
                    local character = getCharacter();
                    if character then
                        local rootPart = ticket:FindFirstChild("HumanoidRootPart");
                        if (rootPart and rootPart.Position) then
                            local offset = Vector3.new(0, 0, 0);
                            character.HumanoidRootPart.Position = rootPart.Position + offset;
                            teleportedToSky = false;
                        end
                    end
                end
                local function teleportToSky()
                    if not teleportedToSky then
                        local character = getCharacter();
                        if (character and character.HumanoidRootPart.Position) then
                            local offset = Vector3.new(0, 10000, 0);
                            character.HumanoidRootPart.Position = character.HumanoidRootPart.Position + offset;
                            teleportedToSky = true;
                        end
                    end
                end
                local function checkForNewTickets()
                    while autoTicketFarmEnabled do
                        local ticketsFolder = getTicketsFolder();
                        local tickets = ticketsFolder:GetChildren();
                        if (#tickets == 0) then
                            teleportToSky();
                        else
                            for _, ticket in pairs(tickets) do
                                if ticket:IsA("Model") then
                                    teleportToTicket(ticket);
                                    break;
                                end
                            end
                        end
                        wait(0.5);
                    end
                end
                checkForNewTickets();
                autoTicketFarmRunning = false;
            end);
        end
    else
        button2.txt.Text = "Auto Ticket: OFF";
        button2.bg.Color = Color3.fromRGB(60, 120, 220);
    end
end;
local autoFarmTicketEnabled = false;
local autoFarmTicketRunning = false;
local button3 = CreateButton(uiX + 20, uiY + 300, 150, 30, "Farm+Ticket: OFF", nil); -- Adjusted position
button3.onClick = function()
    autoFarmTicketEnabled = not autoFarmTicketEnabled;
    if autoFarmTicketEnabled then
        button3.txt.Text = "Farm+Ticket: ON";
        button3.bg.Color = Color3.fromRGB(60, 220, 120);
        if not autoFarmTicketRunning then
            autoFarmTicketRunning = true;
            spawn(function()
                local player = game.Players.LocalPlayer;
                local currentMode = "Ticket";
                local lastCharacterCheck = os.clock();
                local lastModeSwitch = os.clock();
                local teleportedToSky = false;
                
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
                
                local function getDamageTriggers()
                    local damageTriggers = {}
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
                                                MinBounds = Vector3.new(
                                                    pos.X - size.X/2,
                                                    pos.Y - size.Y/2,
                                                    pos.Z - size.Z/2
                                                ),
                                                MaxBounds = Vector3.new(
                                                    pos.X + size.X/2,
                                                    pos.Y + size.Y/2,
                                                    pos.Z + size.Z/2
                                                )
                                            })
                                        end
                                    end
                                end
                            end
                        end
                    end
                    
                    return damageTriggers
                end
                
                local function getSafeZones(damageTriggers)
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
                                if success and pos.Y > 5 then
                                    local isSafe = true
                                    local safeZoneInfo = {
                                        Position = pos,
                                        Size = size or Vector3.new(10,10,10),
                                        SafePosition = Vector3.new(pos.X + 15, pos.Y + 10, pos.Z)
                                    }
                                    
                                    local safeZoneMinBounds = Vector3.new(
                                        pos.X - (size or Vector3.new(10,10,10)).X/2,
                                        pos.Y - (size or Vector3.new(10,10,10)).Y/2,
                                        pos.Z - (size or Vector3.new(10,10,10)).Z/2
                                    )
                                    
                                    local safeZoneMaxBounds = Vector3.new(
                                        pos.X + (size or Vector3.new(10,10,10)).X/2,
                                        pos.Y + (size or Vector3.new(10,10,10)).Y/2,
                                        pos.Z + (size or Vector3.new(10,10,10)).Z/2
                                    )
                                    
                                    for _, trigger in pairs(damageTriggers) do
                                        if safeZoneMinBounds.X <= trigger.MaxBounds.X and
                                           safeZoneMaxBounds.X >= trigger.MinBounds.X and
                                           safeZoneMinBounds.Y <= trigger.MaxBounds.Y and
                                           safeZoneMaxBounds.Y >= trigger.MinBounds.Y and
                                           safeZoneMinBounds.Z <= trigger.MaxBounds.Z and
                                           safeZoneMaxBounds.Z >= trigger.MinBounds.Z then
                                            isSafe = false
                                            break
                                        end
                                    end
                                    
                                    if isSafe then
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
                            local offset = Vector3.new(0, 0, 0)
                            character.HumanoidRootPart.Position = rootPart.Position + offset
                            teleportedToSky = false
                            -- Wait for the configured time after collecting ticket
                            wait(_G.ticketWaitTime)
                        end
                    end
                end
                
                local function teleportToSky()
                    if not teleportedToSky then
                        local character = getCharacter()
                        if character and character.HumanoidRootPart.Position then
                            local offset = Vector3.new(0, 10000, 0)
                            character.HumanoidRootPart.Position = character.HumanoidRootPart.Position + offset
                            teleportedToSky = true
                        end
                    end
                end
                
                local function farmMode(damageTriggers)
                    local safeZones = getSafeZones(damageTriggers)
                    
                    if #safeZones > 0 then
                        local character = getCharacter()
                        if character then
                            local hrp = character:FindFirstChild("HumanoidRootPart")
                            if hrp then
                                local safeZoneInfo = safeZones[math.random(1, #safeZones)]
                                local targetPosition = safeZoneInfo.SafePosition
                                
                                local currentPosition = hrp.Position
                                local distance = math.sqrt(
                                    (targetPosition.X - currentPosition.X)^2 + 
                                    (targetPosition.Y - currentPosition.Y)^2 + 
                                    (targetPosition.Z - currentPosition.Z)^2
                                )
                                
                                local duration = distance / _G.tweenSpeed
                                local startTime = os.clock()
                                
                                while autoFarmTicketEnabled and character.Parent do
                                    local isCurrentPathSafe = true
                                    for _, trigger in pairs(damageTriggers) do
                                        if hrp.Position.X >= trigger.MinBounds.X and hrp.Position.X <= trigger.MaxBounds.X and
                                           hrp.Position.Y >= trigger.MinBounds.Y and hrp.Position.Y <= trigger.MaxBounds.Y and
                                           hrp.Position.Z >= trigger.MinBounds.Z and hrp.Position.Z <= trigger.MaxBounds.Z then
                                            isCurrentPathSafe = false
                                            break
                                        end
                                    end
                                    
                                    if not isCurrentPathSafe then
                                        break
                                    end
                                    
                                    local elapsed = os.clock() - startTime
                                    local alpha = math.min(elapsed / duration, 1)
                                    
                                    local newX = currentPosition.X + (targetPosition.X - currentPosition.X) * alpha
                                    local newY = currentPosition.Y + (targetPosition.Y - currentPosition.Y) * alpha
                                    local newZ = currentPosition.Z + (targetPosition.Z - currentPosition.Z) * alpha
                                    
                                    hrp.Position = Vector3.new(newX, newY, newZ)
                                    hrp.Velocity = Vector3.new(0, 0, 0)
                                    hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                                    
                                    if alpha >= 1 then
                                        wait(_G.waitTime) -- Use configurable wait time
                                        break
                                    end
                                    
                                    wait(0.001)
                                end
                            end
                        end
                    else
                        teleportToSky()
                        wait(1)
                    end
                end
                
                local function ticketMode()
                    local ticketsFolder = getTicketsFolder()
                    local tickets = ticketsFolder:GetChildren()
                    
                    if #tickets > 0 then
                        for _, ticket in pairs(tickets) do
                            if ticket:IsA("Model") then
                                teleportToTicket(ticket)
                                wait(0.1)
                                break
                            end
                        end
                    else
                        currentMode = "Farm"
                        lastModeSwitch = os.clock()
                    end
                end
                
                -- Main continuous loop similar to button 2
                local function checkForNewTicketsAndFarm()
                    while autoFarmTicketEnabled do
                        local success, result = pcall(function()
                            -- Always get tickets folder first (like button 2)
                            local ticketsFolder = getTicketsFolder()
                            local tickets = ticketsFolder:GetChildren()
                            
                            if #tickets > 0 then
                                -- Priority: Collect tickets first
                                currentMode = "Ticket"
                                for _, ticket in pairs(tickets) do
                                    if ticket:IsA("Model") then
                                        teleportToTicket(ticket)
                                        wait(0.1)
                                        break
                                    end
                                end
                            else
                                -- No tickets found, do farming
                                currentMode = "Farm"
                                local damageTriggers = getDamageTriggers()
                                farmMode(damageTriggers)
                            end
                        end)
                        
                        if not success then
                            wait(0.1)
                        end
                        
                        wait(0.5) -- Check every 0.5 seconds like button 2
                    end
                end
                
                checkForNewTicketsAndFarm()
                autoFarmTicketRunning = false
            end);
        end
    else
        button3.txt.Text = "Farm+Ticket: OFF";
        button3.bg.Color = Color3.fromRGB(60, 120, 220);
    end
end;
local button4 = CreateButton(uiX + 200, uiY + 200, 150, 30, "Button 4", function()
    print("Button 4 clicked!");
end);
CreateButton(uiX + 200, uiY + 250, 150, 30, "Button 5", function()
    print("Button 5 clicked!");
end);
CreateButton(uiX + 200, uiY + 300, 150, 30, "Button 6", function()
    print("Button 6 clicked!");
end);
local isDragging = false;
local dragOffsetX = 0;
local dragOffsetY = 0;
spawn(function()
    local lastClick = false;
    while true do
        local clicked = ismouse1pressed();
        local mx, my = Mouse.X, Mouse.Y;
        if (clicked and not lastClick) then
            if ((mx >= uiX) and (mx <= (uiX + 400)) and (my >= uiY) and (my <= (uiY + 35))) then
                isDragging = true;
                dragOffsetX = mx - uiX;
                dragOffsetY = my - uiY;
            else
                -- Check button clicks
                for _, btn in ipairs(buttons) do
                    if ((mx >= btn.x) and (mx <= (btn.x + btn.w)) and (my >= btn.y) and (my <= (btn.y + btn.h))) then
                        if btn.onClick then
                            btn.onClick();
                        end
                        break;
                    end
                end
                
                -- Check slider interactions
                for _, slider in ipairs(sliders) do
                    if ((mx >= slider.x) and (mx <= (slider.x + slider.w)) and (my >= slider.y) and (my <= (slider.y + slider.h))) then
                        slider.isDragging = true;
                        break;
                    end
                end
            end
        end
        
        if (not clicked and lastClick) then
            isDragging = false;
            -- Stop dragging all sliders
            for _, slider in ipairs(sliders) do
                slider.isDragging = false;
            end
        end
        
        -- Handle slider dragging
        for _, slider in ipairs(sliders) do
            if slider.isDragging then
                UpdateSlider(slider, mx);
            end
        end
        
        if (isDragging and clicked) then
            local newX = mx - dragOffsetX;
            local newY = my - dragOffsetY;
            local deltaX = newX - uiX;
            local deltaY = newY - uiY;
            uiX = newX;
            uiY = newY;
            bg.Position = Vector2.new(uiX, uiY);
            header.Position = Vector2.new(uiX, uiY);
            title.Position = Vector2.new(uiX + 10, uiY + 10);
            
            -- Update buttons
            for _, btn in ipairs(buttons) do
                btn.x = btn.x + deltaX;
                btn.y = btn.y + deltaY;
                btn.bg.Position = Vector2.new(btn.x, btn.y);
                btn.txt.Position = Vector2.new(btn.x + 10, btn.y + 8);
            end
            
            -- Update sliders
            for _, slider in ipairs(sliders) do
                slider.x = slider.x + deltaX;
                slider.y = slider.y + deltaY;
                slider.bg.Position = Vector2.new(slider.x, slider.y);
                slider.fill.Position = Vector2.new(slider.x, slider.y);
                slider.txt.Position = Vector2.new(slider.x, slider.y - 15);
                
                -- Update description text position if it exists
                if slider.descTxt then
                    slider.descTxt.Position = Vector2.new(slider.x, slider.y + 15);
                end
            end
        end
        
        lastClick = clicked;
        wait(0.001);
    end
end);
print("Evade Script v1.1.2 LOADED");
print("Tween speed: " .. _G.tweenSpeed .. " studs/sec");
print("Safezone wait time: " .. _G.waitTime .. " seconds");
print("Ticket wait time: " .. _G.ticketWaitTime .. " seconds");
