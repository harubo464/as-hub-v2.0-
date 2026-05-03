-- Orion Library読み込み
local OrionLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/BlizTBr/scripts/main/Orion%20X"))()
task.wait(1)

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

-- ============ Hub設定 ============
local HubConfig = {
    Name = "As Hub",
    Creator = "Asylum",
    Version = "2.0",
    Discord = "discord.gg/example"
}

local Window = OrionLib:MakeWindow({
    Name = HubConfig.Name .. " | v" .. HubConfig.Version,
    HidePremium = false,
    SaveConfig = true,
    ConfigFolder = "AsHub"
})

-- クレジット表示
OrionLib:MakeNotification({
    Name = HubConfig.Name,
    Content = "Created by " .. HubConfig.Creator .. " | " .. HubConfig.Discord,
    Time = 5
})

-- ============ 変数宣言 ============
-- オフェンス系
local pushAuraEnabled = false
local pushAuraRange = 10
local grabEnabled = false
local grabTarget = nil
local remoteCrashEnabled = false
local teleportBlockEnabled = false
local spiderHoldEnabled = false
local spiderHoldTarget = nil

-- セルフ強化
local antiKnockback = false
local airJumpEnabled = false
local airJumpsLeft = 0
local maxAirJumps = 3
local checkpointSaverEnabled = false
local lastPosition = nil
local flyEnabled = false
local flySpeed = 100
local noclipEnabled = false
local speedEnabled = false
local speedValue = 60
local jumpPowerEnabled = false
local jumpPowerValue = 150
local autoRespawnEnabled = false
local safeGuardEnabled = false
local safeGuardInterval = 30
local gliderEnabled = false
local gravityEnabled = false
local gravityValue = 196.2
local superKnockbackResist = false

-- ESP
local espEnabled = false
local espObjects = {}
local trailEspEnabled = false
local trailObjects = {}
local distanceDisplayEnabled = false
local killCounterEnabled = false
local killCount = 0
local stealthModeEnabled = false
local warnAlertEnabled = false
local lastWarnTime = 0

local character = LocalPlayer.Character
local humanoid = nil
local rootPart = nil
local isGliding = false

-- ============ 更新関数 ============
local function updateCharacter()
    character = LocalPlayer.Character
    if character then
        humanoid = character:FindFirstChild("Humanoid")
        rootPart = character:FindFirstChild("HumanoidRootPart")
    end
end

LocalPlayer.CharacterAdded:Connect(updateCharacter)
updateCharacter()

-- ============ キルカウンター ============
local function checkAndAddKill()
    task.spawn(function()
        while killCounterEnabled do
            task.wait(0.5)
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= LocalPlayer then
                    local targetChar = player.Character
                    if targetChar and targetChar:FindFirstChild("HumanoidRootPart") then
                        local targetRoot = targetChar.HumanoidRootPart
                        if targetRoot.Velocity.Y < -80 then
                            killCount = killCount + 1
                            OrionLib:MakeNotification({
                                Name = "💀 KILL!",
                                Content = player.DisplayName .. " を落下させた! (合計: " .. killCount .. ")",
                                Time = 3
                            })
                            task.wait(2)
                        end
                    end
                end
            end
        end
    end)
end

-- ============ 警告アラート ============
local function checkNearbyPlayers()
    task.spawn(function()
        while warnAlertEnabled do
            task.wait(1)
            local nearestDist = math.huge
            local nearestPlayer = nil
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= LocalPlayer then
                    local targetChar = player.Character
                    if targetChar and targetChar:FindFirstChild("HumanoidRootPart") and rootPart then
                        local dist = (rootPart.Position - targetChar.HumanoidRootPart.Position).Magnitude
                        if dist < 15 and dist < nearestDist then
                            nearestDist = dist
                            nearestPlayer = player
                        end
                    end
                end
            end
            if nearestPlayer and tick() - lastWarnTime > 5 then
                OrionLib:MakeNotification({
                    Name = "⚠️ WARNING!",
                    Content = nearestPlayer.DisplayName .. " が近くにいます (" .. math.floor(nearestDist) .. "m)",
                    Time = 2
                })
                lastWarnTime = tick()
            end
        end
    end)
end

-- ============ タブ作成 ============
-- タブ1: オフェンス
local OffenseTab = Window:MakeTab({
    Name = "⚔️ OFFENSE",
    Icon = "rbxassetid://4483345998"
})

OffenseTab:AddLabel("🔻 プッシュオーラ")
OffenseTab:AddToggle({
    Name = "プッシュオーラ",
    Default = false,
    Callback = function(value) pushAuraEnabled = value end
})
OffenseTab:AddSlider({
    Name = "プッシュ範囲",
    Min = 5, Max = 30, Default = 10, Increment = 1,
    Callback = function(value) pushAuraRange = value end
})

OffenseTab:AddLabel("🔻 リモートクラッシュ")
OffenseTab:AddToggle({
    Name = "リモートクラッシュ",
    Default = false,
    Callback = function(value)
        remoteCrashEnabled = value
        if value then
            local mouse = LocalPlayer:GetMouse()
            local connection
            connection = mouse.Button1Down:Connect(function()
                if remoteCrashEnabled then
                    local target = mouse.Target
                    if target and target.Parent then
                        local playerChar = target.Parent
                        local humanoidRoot = playerChar:FindFirstChild("HumanoidRootPart")
                        if humanoidRoot then
                            humanoidRoot.Velocity = Vector3.new(0, -150, 0)
                            humanoidRoot.CFrame = humanoidRoot.CFrame + Vector3.new(0, -30, 0)
                        end
                    end
                end
            end)
            getgenv().remoteCrashConnection = connection
        else
            if getgenv().remoteCrashConnection then
                getgenv().remoteCrashConnection:Disconnect()
            end
        end
    end
})

OffenseTab:AddLabel("🔻 グラブ＆スロー")
OffenseTab:AddToggle({
    Name = "グラブ＆スロー [Q:投げる]",
    Default = false,
    Callback = function(value)
        grabEnabled = value
        if not value and grabTarget then grabTarget = nil end
    end
})

OffenseTab:AddLabel("🔻 スパイダーホールド")
OffenseTab:AddToggle({
    Name = "スパイダーホールド [E:落とす]",
    Default = false,
    Callback = function(value)
        spiderHoldEnabled = value
        if not value and spiderHoldTarget then spiderHoldTarget = nil end
    end
})

OffenseTab:AddToggle({
    Name = "テレポート妨害",
    Default = false,
    Callback = function(value) teleportBlockEnabled = value end
})

-- タブ2: セルフ強化
local SelfTab = Window:MakeTab({
    Name = "🛡️ SELF",
    Icon = "rbxassetid://4483345998"
})

SelfTab:AddLabel("🔻 ノックバック対策")
SelfTab:AddToggle({
    Name = "アンチノックバック",
    Default = false,
    Callback = function(value) antiKnockback = value end
})
SelfTab:AddToggle({
    Name = "スーパーノックバック耐性",
    Default = false,
    Callback = function(value) superKnockbackResist = value end
})

SelfTab:AddLabel("🔻 エアジャンプ")
SelfTab:AddToggle({
    Name = "エアジャンプ",
    Default = false,
    Callback = function(value)
        airJumpEnabled = value
        airJumpsLeft = value and maxAirJumps or 0
    end
})
SelfTab:AddSlider({
    Name = "エアジャンプ回数",
    Min = 1, Max = 10, Default = 3, Increment = 1,
    Callback = function(value)
        maxAirJumps = value
        if airJumpEnabled then airJumpsLeft = value end
    end
})

SelfTab:AddLabel("🔻 グライダー")
SelfTab:AddToggle({
    Name = "グライダーモード",
    Default = false,
    Callback = function(value)
        gliderEnabled = value
        if not value and isGliding then isGliding = false end
    end
})

SelfTab:AddLabel("🔻 重力操作")
SelfTab:AddToggle({
    Name = "重力操作",
    Default = false,
    Callback = function(value)
        gravityEnabled = value
        if humanoid then humanoid.UseJumpPower = true end
    end
})
SelfTab:AddSlider({
    Name = "重力値",
    Min = 50, Max = 300, Default = 196, Increment = 5,
    Callback = function(value)
        gravityValue = value
        if gravityEnabled and humanoid then humanoid.Gravity = value end
    end
})

SelfTab:AddLabel("🔻 移動速度")
SelfTab:AddToggle({
    Name = "スピードハック",
    Default = false,
    Callback = function(value)
        speedEnabled = value
        if humanoid then humanoid.WalkSpeed = value and speedValue or 16 end
    end
})
SelfTab:AddSlider({
    Name = "歩行速度",
    Min = 16, Max = 250, Default = 60, Increment = 1,
    Callback = function(value)
        speedValue = value
        if speedEnabled and humanoid then humanoid.WalkSpeed = value end
    end
})

SelfTab:AddLabel("🔻 ジャンプ力")
SelfTab:AddToggle({
    Name = "ジャンプ力強化",
    Default = false,
    Callback = function(value)
        jumpPowerEnabled = value
        if humanoid then humanoid.JumpPower = value and jumpPowerValue or 50 end
    end
})
SelfTab:AddSlider({
    Name = "ジャンプ力",
    Min = 50, Max = 500, Default = 150, Increment = 5,
    Callback = function(value)
        jumpPowerValue = value
        if jumpPowerEnabled and humanoid then humanoid.JumpPower = value end
    end
})

SelfTab:AddLabel("🔻 セーブ機能")
SelfTab:AddToggle({
    Name = "チェックポイントセーバー",
    Default = false,
    Callback = function(value) checkpointSaverEnabled = value end
})
SelfTab:AddToggle({
    Name = "オートリスポーン",
    Default = false,
    Callback = function(value) autoRespawnEnabled = value end
})
SelfTab:AddToggle({
    Name = "セーフガード",
    Default = false,
    Callback = function(value) 
        safeGuardEnabled = value
        if value then
            task.spawn(function()
                while safeGuardEnabled do
                    task.wait(safeGuardInterval)
                    if rootPart and humanoid and humanoid.FloorMaterial ~= Enum.Material.Air then
                        lastPosition = rootPart.CFrame
                        OrionLib:MakeNotification({
                            Name = "🛡️ セーフガード",
                            Content = "チェックポイント保存しました",
                            Time = 1
                        })
                    end
                end
            end)
        end
    end
})
SelfTab:AddSlider({
    Name = "セーフガード間隔(秒)",
    Min = 10, Max = 120, Default = 30, Increment = 5,
    Callback = function(value) safeGuardInterval = value end
})

-- タブ3: 移動
local MovementTab = Window:MakeTab({
    Name = "✈️ MOVEMENT",
    Icon = "rbxassetid://4483345998"
})

MovementTab:AddLabel("🔻 フライト")
MovementTab:AddToggle({
    Name = "フライトモード [Ctrl:上 / Shift:下]",
    Default = false,
    Callback = function(value)
        flyEnabled = value
        if not value and character and rootPart then
            rootPart.Velocity = Vector3.new(0, 0, 0)
        end
    end
})
MovementTab:AddSlider({
    Name = "飛行速度",
    Min = 30, Max = 500, Default = 100, Increment = 5,
    Callback = function(value) flySpeed = value end
})

MovementTab:AddLabel("🔻 Noclip")
MovementTab:AddToggle({
    Name = "Noclip",
    Default = false,
    Callback = function(value)
        noclipEnabled = value
        if character then
            for _, part in ipairs(character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = not value
                end
            end
        end
    end
})

-- タブ4: ESP
local ESPTab = Window:MakeTab({
    Name = "👁️ ESP",
    Icon = "rbxassetid://4483345998"
})

ESPTab:AddToggle({
    Name = "プレイヤーESP",
    Default = false,
    Callback = function(value)
        espEnabled = value
        if not value then
            for _, obj in pairs(espObjects) do pcall(function() obj:Destroy() end) end
            table.clear(espObjects)
        end
    end
})

ESPTab:AddToggle({
    Name = "トレイルESP",
    Default = false,
    Callback = function(value)
        trailEspEnabled = value
        if not value then
            for _, obj in pairs(trailObjects) do pcall(function() obj:Destroy() end) end
            table.clear(trailObjects)
        end
    end
})

ESPTab:AddToggle({
    Name = "距離表示",
    Default = false,
    Callback = function(value) distanceDisplayEnabled = value end
})

ESPTab:AddToggle({
    Name = "キルカウンター",
    Default = false,
    Callback = function(value)
        killCounterEnabled = value
        if value then
            killCount = 0
            checkAndAddKill()
        end
    end
})

ESPTab:AddToggle({
    Name = "ステルスモード",
    Default = false,
    Callback = function(value) stealthModeEnabled = value end
})

ESPTab:AddToggle({
    Name = "警告アラート",
    Default = false,
    Callback = function(value)
        warnAlertEnabled = value
        if value then checkNearbyPlayers() end
    end
})

-- タブ5: クレジット
local CreditTab = Window:MakeTab({
    Name = "📋 CREDIT",
    Icon = "rbxassetid://4483345998"
})

CreditTab:AddLabel("━━━━━━━━━━━━━━━━━━━")
CreditTab:AddLabel(HubConfig.Name)
CreditTab:AddLabel("Version: " .. HubConfig.Version)
CreditTab:AddLabel("Created by: " .. HubConfig.Creator)
CreditTab:AddLabel("━━━━━━━━━━━━━━━━━━━")
CreditTab:AddLabel("Discord: " .. HubConfig.Discord)
CreditTab:AddLabel("━━━━━━━━━━━━━━━━━━━")
CreditTab:AddLabel("操作方法:")
CreditTab:AddLabel("【Q】グラブした相手を投げる")
CreditTab:AddLabel("【E】スパイダーホールド中に落とす")
CreditTab:AddLabel("【Ctrl】飛行中に上昇")
CreditTab:AddLabel("【Shift】飛行中に下降")

-- ============ メインループ ============
task.spawn(function()
    while true do
        task.wait()
        updateCharacter()
        if not character or not humanoid or not rootPart then continue end
        
        -- スーパーノックバック耐性
        if superKnockbackResist then
            humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
            humanoid:SetStateEnabled(Enum.HumanoidStateType.GettingUp, false)
            humanoid:SetStateEnabled(Enum.HumanoidStateType.Physics, false)
        elseif antiKnockback then
            humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
            humanoid:SetStateEnabled(Enum.HumanoidStateType.GettingUp, false)
        else
            humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, true)
            humanoid:SetStateEnabled(Enum.HumanoidStateType.GettingUp, true)
            humanoid:SetStateEnabled(Enum.HumanoidStateType.Physics, true)
        end
        
        -- 重力操作
        if gravityEnabled and humanoid.Gravity ~= gravityValue then
            humanoid.Gravity = gravityValue
        end
        
        -- スピード / ジャンプ力
        if speedEnabled and humanoid.WalkSpeed ~= speedValue then humanoid.WalkSpeed = speedValue end
        if jumpPowerEnabled and humanoid.JumpPower ~= jumpPowerValue then humanoid.JumpPower = jumpPowerValue end
        
        -- エアジャンプリセット
        if airJumpEnabled and humanoid.FloorMaterial ~= Enum.Material.Air then
            airJumpsLeft = maxAirJumps
        end
        
        -- グライダーモード
        if gliderEnabled and humanoid.FloorMaterial == Enum.Material.Air and rootPart.Velocity.Y < 0 then
            isGliding = true
            rootPart.Velocity = Vector3.new(rootPart.Velocity.X, -10, rootPart.Velocity.Z)
        else
            isGliding = false
        end
        
        -- チェックポイントセーバー / オートリスポーン
        if checkpointSaverEnabled or autoRespawnEnabled then
            if humanoid.FloorMaterial ~= Enum.Material.Air then
                lastPosition = rootPart.CFrame
            elseif lastPosition and rootPart.Position.Y < lastPosition.Position.Y - 15 then
                if autoRespawnEnabled then
                    rootPart.CFrame = lastPosition
                    rootPart.Velocity = Vector3.new(0, 0, 0)
                elseif checkpointSaverEnabled then
                    rootPart.CFrame = lastPosition
                end
            end
        end
        
        -- プッシュオーラ
        if pushAuraEnabled then
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= LocalPlayer then
                    local targetChar = player.Character
                    if targetChar and targetChar:FindFirstChild("HumanoidRootPart") then
                        local targetRoot = targetChar.HumanoidRootPart
                        if (rootPart.Position - targetRoot.Position).Magnitude <= pushAuraRange then
                            local pushDir = (targetRoot.Position - rootPart.Position).Unit * 40
                            targetRoot.Velocity = Vector3.new(pushDir.X, 25, pushDir.Z)
                        end
                    end
                end
            end
        end
        
        -- グラブ＆スロー
        if grabEnabled then
            if not grabTarget then
                for _, player in ipairs(Players:GetPlayers()) do
                    if player ~= LocalPlayer then
                        local targetChar = player.Character
                        if targetChar and targetChar:FindFirstChild("HumanoidRootPart") then
                            if (rootPart.Position - targetChar.HumanoidRootPart.Position).Magnitude <= 5 then
                                grabTarget = targetChar.HumanoidRootPart
                                break
                            end
                        end
                    end
                end
            else
                grabTarget.CFrame = rootPart.CFrame + rootPart.CFrame.LookVector * 3
                if UserInputService:IsKeyDown(Enum.KeyCode.Q) then
                    grabTarget.Velocity = rootPart.CFrame.LookVector * 100 + Vector3.new(0, 40, 0)
                    grabTarget = nil
                end
            end
        end
        
        -- スパイダーホールド
        if spiderHoldEnabled then
            if not spiderHoldTarget then
                for _, player in ipairs(Players:GetPlayers()) do
                    if player ~= LocalPlayer then
                        local targetChar = player.Character
                        if targetChar and targetChar:FindFirstChild("HumanoidRootPart") then
                            if (rootPart.Position - targetChar.HumanoidRootPart.Position).Magnitude <= 5 then
                                spiderHoldTarget = targetChar.HumanoidRootPart
                                break
                            end
                        end
                    end
                end
            else
                spiderHoldTarget.CFrame = rootPart.CFrame + rootPart.CFrame.LookVector * 2
                spiderHoldTarget.Velocity = Vector3.new(0, 0, 0)
                if UserInputService:IsKeyDown(Enum.KeyCode.E) then
                    spiderHoldTarget.Velocity = Vector3.new(0, -200, 0)
                    spiderHoldTarget = nil
                end
            end
        end
        
        -- Noclip
        if noclipEnabled then
            for _, part in ipairs(character:GetDescendants()) do
                if part:IsA("BasePart") then part.CanCollide = false end
            end
        end
        
        -- テレポート妨害
        if teleportBlockEnabled then
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= LocalPlayer then
                    local targetChar = player.Character
                    if targetChar and targetChar:FindFirstChild("HumanoidRootPart") then
                        local targetRoot = targetChar.HumanoidRootPart
                        if targetRoot.Velocity.Y < -50 then
                            targetRoot.Velocity = Vector3.new(0, 40, 0)
                        end
                    end
                end
            end
        end
        
        -- ESP
        if espEnabled then
            for _, obj in pairs(espObjects) do pcall(function() obj:Destroy() end) end
            table.clear(espObjects)
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= LocalPlayer then
                    local targetChar = player.Character
                    if targetChar and targetChar:FindFirstChild("Head") then
                        local head = targetChar.Head
                        local boxColor = player.TeamColor or Color3.fromRGB(255, 50, 50)
                        if stealthModeEnabled then
                            boxColor = Color3.fromRGB(255, 255, 255)
                        end
                        local espBox = Instance.new("BoxHandleAdornment")
                        espBox.Size = Vector3.new(4, 4.5, 2)
                        espBox.Color3 = boxColor
                        espBox.Transparency = 0.4
                        espBox.AlwaysOnTop = true
                        espBox.ZIndex = 10
                        espBox.Adornee = head
                        espBox.Parent = head
                        table.insert(espObjects, espBox)
                        
                        local textGui = Instance.new("BillboardGui")
                        textGui.Size = UDim2.new(0, 200, 0, 60)
                        textGui.StudsOffset = Vector3.new(0, 2.5, 0)
                        textGui.AlwaysOnTop = true
                        
                        local textLabel = Instance.new("TextLabel")
                        local displayText = player.DisplayName
                        if distanceDisplayEnabled and rootPart then
                            local dist = (rootPart.Position - head.Position).Magnitude
                            displayText = displayText .. " [" .. math.floor(dist) .. "m]"
                        end
                        textLabel.Text = displayText
                        textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
                        textLabel.BackgroundTransparency = 1
                        textLabel.TextStrokeTransparency = 0
                        textLabel.TextSize = 13
                        textLabel.Size = UDim2.new(1, 0, 1, 0)
                        textLabel.Parent = textGui
                        textGui.Parent = head
                        table.insert(espObjects, textGui)
                    end
                end
            end
        end
        
        -- トレイルESP
        if trailEspEnabled then
            for _, obj in pairs(trailObjects) do
                pcall(function() 
                    if obj and obj.Parent then
                        local trail = obj:FindFirstChild("Trail")
                        if trail then trail:Destroy() end
                    end
                    obj:Destroy() 
                end)
            end
            table.clear(trailObjects)
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= LocalPlayer then
                    local targetChar = player.Character
                    if targetChar and targetChar:FindFirstChild("HumanoidRootPart") then
                        local trailPart = Instance.new("Part")
                        trailPart.Size = Vector3.new(0.5, 0.5, 0.5)
                        trailPart.CanCollide = false
                        trailPart.Anchored = true
                        trailPart.Transparency = 0.7
                        trailPart.Color = Color3.fromRGB(255, 100, 100)
                        trailPart.Material = Enum.Material.Neon
                        trailPart.Parent = targetChar.HumanoidRootPart
                        
                        local trail = Instance.new("Trail")
                        trail.Color = ColorSequence.new(Color3.fromRGB(255, 100, 100))
                        trail.Transparency = NumberSequence.new(0, 1)
                        trail.Lifetime = 0.8
                        trail.Parent = trailPart
                        table.insert(trailObjects, trailPart)
                    end
                end
            end
        end
    end
end)

-- エアジャンプ入力
UserInputService.JumpRequest:Connect(function()
    if airJumpEnabled and airJumpsLeft > 0 and humanoid and humanoid.FloorMaterial == Enum.Material.Air then
        humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        airJumpsLeft = airJumpsLeft - 1
    end
end)

-- グライダー視覚効果
local function gliderEffect()
    while true do
        task.wait()
        if gliderEnabled and isGliding and character and rootPart then
            local attachment = Instance.new("Attachment")
            attachment.Parent = rootPart
            local smoke = Instance.new("Smoke")
            smoke.Color = Color3.fromRGB(200, 200, 255)
            smoke.Opacity = 0.3
            smoke.RiseVelocity = -5
            smoke.Size = 2
            smoke.Parent = attachment
            task.wait(0.3)
            smoke:Destroy()
            attachment:Destroy()
        end
    end
end
task.spawn(gliderEffect)

-- フライト制御
local function fly()
    local flying = false
    RunService.RenderStepped:Connect(function()
        if flyEnabled and character and rootPart then
            flying = true
            local bodyVel = rootPart:FindFirstChild("BodyVelocity") or Instance.new("BodyVelocity")
            bodyVel.MaxForce = Vector3.new(100000, 100000, 100000)
            bodyVel.Velocity = Vector3.new(0, 0, 0)
            bodyVel.Parent = rootPart
            local camera = workspace.CurrentCamera
            local moveDirection = Vector3.new()
            local forward = camera.CFrame.LookVector
            local right = camera.CFrame.RightVector
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDirection = moveDirection + forward end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDirection = moveDirection - forward end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDirection = moveDirection + right end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDirection = moveDirection - right end
            local up = UserInputService:IsKeyDown(Enum.KeyCode.LeftControl)
            local down = UserInputService:IsKeyDown(Enum.KeyCode.LeftShift)
            if moveDirection.Magnitude > 0 then moveDirection = moveDirection.Unit end
            bodyVel.Velocity = moveDirection * flySpeed + Vector3.new(0, (up and flySpeed or (down and -flySpeed or 0)), 0)
            rootPart.CFrame = CFrame.new(rootPart.Position)
        elseif flying then
            local vel = rootPart:FindFirstChild("BodyVelocity")
            if vel then vel:Destroy() end
            flying = false
        end
    end)
end
fly()

OrionLib:Init()
