-- ============================================
-- C4 DUPLA FALSA (Duas bombas no inventário)
-- ============================================
local Players  = game:GetService("Players")
local Debris   = game:GetService("Debris")
local player   = Players.LocalPlayer

local GEAR_ID = 104642566

-- ⚙️ CONFIGURAÇÃO DAS DUAS C4s
local C4_CONFIGS = {
    {
        Name         = "FakeC4_A",
        IconTexture  = "rbxassetid://120892597032321", -- ícone na mochila
        MeshId       = "rbxassetid://104516854",
        MeshTexture  = "rbxassetid://120892597032321", -- textura no mundo
    },
    {
        Name         = "FakeC4_B",
        IconTexture  = "rbxassetid://104516910",
        MeshId       = "rbxassetid://104516854",
        MeshTexture  = "rbxassetid://104516981",
    },
}

-- ============================================
local function loadFakeC4(config)
    local backpack  = player:WaitForChild("Backpack")
    local character = player.Character or player.CharacterAdded:Wait()
    local humanoid  = character:WaitForChild("Humanoid")

    -- 🧹 Limpa SOMENTE a C4 com o MESMO nome (a outra fica intacta)
    for _, item in pairs(backpack:GetChildren()) do
        if item.Name == config.Name then item:Destroy() end
    end
    for _, item in pairs(character:GetChildren()) do
        if item.Name == config.Name then item:Destroy() end
    end

    -- 📦 Carrega a ferramenta original
    local ok, tool = pcall(function()
        return game:GetObjects("rbxassetid://" .. GEAR_ID)[1]
    end)
    if not ok or not tool or not tool:IsA("Tool") then
        warn("❌ Falha ao carregar: " .. config.Name)
        return
    end

    tool.Name          = config.Name
    tool.TextureId     = config.IconTexture
    tool.RequiresHandle = true
    tool.CanBeDropped  = false

    -- 🖐️ Handle visível, grande
    local handle = tool:FindFirstChild("Handle")
                or tool:FindFirstChildWhichIsA("BasePart")
    if handle then
        handle.Transparency = 0
        handle.Color        = Color3.fromRGB(45, 45, 45)
        handle.CanCollide   = false
        handle.Massless     = true
        handle.Size         = Vector3.new(2.5, 2.5, 2.5)

        local handMesh      = Instance.new("SpecialMesh")
        handMesh.MeshId     = config.MeshId
        handMesh.TextureId  = config.MeshTexture
        handMesh.Scale      = Vector3.new(1.5, 1.5, 1.5)
        handMesh.Parent     = handle
    end

    -- ❌ Remove scripts/animações internos
    for _, child in ipairs(tool:GetDescendants()) do
        if child:IsA("Script")
        or child:IsA("LocalScript")
        or child:IsA("Animation") then
            child:Destroy()
        end
    end

    tool.Parent = backpack
    humanoid:EquipTool(tool)

    -- ============================================
    -- 💥 LÓGICA DE SOLTAR
    -- ============================================
    local canUse = true

    tool.Activated:Connect(function()
        if not canUse then return end
        canUse = false

        if handle then handle.Transparency = 1 end

        -- Cria a bomba física
        local c4Part = Instance.new("Part")
        c4Part.Name         = "DroppedC4"
        c4Part.Size         = Vector3.new(3, 3, 3)
        c4Part.Color        = Color3.fromRGB(45, 45, 45)
        c4Part.Material     = Enum.Material.SmoothPlastic
        c4Part.CanCollide   = true
        c4Part.Anchored     = false

        local mesh      = Instance.new("SpecialMesh")
        mesh.MeshId     = config.MeshId
        mesh.TextureId  = config.MeshTexture
        mesh.Scale      = Vector3.new(1.5, 1.5, 1.5)
        mesh.Parent     = c4Part

        local root = character:FindFirstChild("HumanoidRootPart")
        c4Part.CFrame = root.CFrame * CFrame.new(0, -3, -1)
        c4Part.Parent = workspace

        -- Física: cai "em pé" e depois tomba
        local gyro         = Instance.new("BodyGyro")
        gyro.MaxTorque     = Vector3.new(40000, 40000, 40000)
        gyro.P             = 3000
        gyro.CFrame        = c4Part.CFrame
        gyro.Parent        = c4Part

        task.delay(0.5, function()
            if gyro and gyro.Parent then
                gyro:Destroy()
                c4Part.AssemblyAngularVelocity =
                    Vector3.new(math.random(-5, 5), 0, math.random(-5, 5))
            end
        end)

        -- Bip de armar
        local beep      = Instance.new("Sound")
        beep.SoundId    = "rbxassetid://131961136"
        beep.Volume     = 1
        beep.Parent     = c4Part
        beep:Play()

        -- Explosão + confetes
        task.delay(3, function()
            local confetti       = Instance.new("ParticleEmitter")
            confetti.Texture     = "rbxassetid://396242399"
            confetti.Color       = ColorSequence.new({
                ColorSequenceKeypoint.new(0.0, Color3.fromRGB(255, 0, 0)),
                ColorSequenceKeypoint.new(0.2, Color3.fromRGB(0, 255, 0)),
                ColorSequenceKeypoint.new(0.4, Color3.fromRGB(0, 0, 255)),
                ColorSequenceKeypoint.new(0.6, Color3.fromRGB(255, 255, 0)),
                ColorSequenceKeypoint.new(0.8, Color3.fromRGB(255, 0, 255)),
                ColorSequenceKeypoint.new(1.0, Color3.fromRGB(0, 255, 255)),
            })
            confetti.Size        = NumberSequence.new(0.8)
            confetti.Speed       = NumberRange.new(30, 60)
            confetti.SpreadAngle = Vector2.new(180, 180)
            confetti.Lifetime    = NumberRange.new(2, 4)
            confetti.Rate        = 0
            confetti.Parent      = c4Part
            confetti:Emit(200)

            local boom      = Instance.new("Sound")
            boom.SoundId    = "rbxassetid://138186576"
            boom.Volume     = 1.5
            boom.Parent     = c4Part
            boom:Play()

            c4Part.Transparency = 1
            c4Part.CanCollide   = false
            Debris:AddItem(c4Part, 4)
        end)

        task.wait(1)

        if handle then handle.Transparency = 0 end
        canUse = true
    end)

    print("✅ " .. config.Name .. " carregada!")
end

-- ============================================
local function loadAll()
    for _, config in ipairs(C4_CONFIGS) do
        loadFakeC4(config)
    end
end

loadAll()

player.CharacterAdded:Connect(function()
    task.wait(1.2)
    loadAll()
end)
