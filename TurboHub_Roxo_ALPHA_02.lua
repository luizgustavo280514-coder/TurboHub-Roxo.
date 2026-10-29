-- Turbo Hub Roxo ALPHA 0.2
-- Ferramenta visual experimental: rastreamento da bola + previsão simples.
-- Cole o código inteiro no editor Lua do Delta. Não carrega código remoto de terceiros.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local player = Players.LocalPlayer

local PURPLE = Color3.fromRGB(185, 90, 255)
local PINK = Color3.fromRGB(255, 90, 220)
local WHITE = Color3.fromRGB(245, 235, 255)

-- Interface
local oldGui = player:WaitForChild("PlayerGui"):FindFirstChild("TurboHubRoxo")
if oldGui then oldGui:Destroy() end

local gui = Instance.new("ScreenGui")
gui.Name = "TurboHubRoxo"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local main = Instance.new("Frame")
main.Size = UDim2.fromOffset(255, 230)
main.Position = UDim2.new(0.5, -127, 0.5, -115)
main.BackgroundColor3 = Color3.fromRGB(20, 13, 31)
main.BorderSizePixel = 0
main.Active = true
main.Draggable = true
main.Parent = gui
Instance.new("UICorner", main).CornerRadius = UDim.new(0, 12)

local stroke = Instance.new("UIStroke", main)
stroke.Color = PURPLE
stroke.Thickness = 1.5

local header = Instance.new("TextLabel")
header.Size = UDim2.new(1, -42, 0, 36)
header.Position = UDim2.fromOffset(12, 3)
header.BackgroundTransparency = 1
header.Text = "TURBO HUB  •  ALPHA 0.2"
header.TextColor3 = WHITE
header.TextSize = 14
header.Font = Enum.Font.GothamBold
header.TextXAlignment = Enum.TextXAlignment.Left
header.Parent = main

local close = Instance.new("TextButton")
close.Size = UDim2.fromOffset(30, 28)
close.Position = UDim2.new(1, -35, 0, 5)
close.BackgroundColor3 = Color3.fromRGB(75, 28, 95)
close.Text = "×"
close.TextColor3 = WHITE
close.TextSize = 22
close.Font = Enum.Font.GothamBold
close.Parent = main
Instance.new("UICorner", close).CornerRadius = UDim.new(0, 8)

local status = Instance.new("TextLabel")
status.Size = UDim2.new(1, -20, 0, 28)
status.Position = UDim2.fromOffset(10, 38)
status.BackgroundTransparency = 1
status.Text = "Procurando a bola..."
status.TextColor3 = Color3.fromRGB(210, 180, 230)
status.TextSize = 12
status.Font = Enum.Font.Gotham
status.Parent = main

local function makeButton(text, y)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1, -20, 0, 34)
    b.Position = UDim2.fromOffset(10, y)
    b.BackgroundColor3 = Color3.fromRGB(54, 28, 75)
    b.TextColor3 = WHITE
    b.TextSize = 13
    b.Font = Enum.Font.GothamSemibold
    b.Text = text
    b.Parent = main
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 8)
    local s = Instance.new("UIStroke", b)
    s.Color = PURPLE
    s.Transparency = 0.45
    return b
end

local trackButton = makeButton("Rastreamento da bola: LIGADO", 72)
local pathButton = makeButton("Previsão visual: LIGADA", 112)
local minimizeButton = makeButton("Minimizar menu", 152)
local note = Instance.new("TextLabel")
note.Size = UDim2.new(1, -20, 0, 30)
note.Position = UDim2.fromOffset(10, 192)
note.BackgroundTransparency = 1
note.Text = "Visual apenas • sem mira automática ou voo"
note.TextColor3 = Color3.fromRGB(175, 155, 190)
note.TextSize = 10
note.Font = Enum.Font.Gotham
note.Parent = main

local minimized = false
local tracking = true
local prediction = true
local ballPart, lastPos, lastTime
local trailParts = {}
local marker

local function findBall()
    local carSoccer = Workspace:FindFirstChild("CarSoccer")
    if carSoccer then
        local matchView = carSoccer:FindFirstChild("MatchView")
        local rankedBall = matchView and matchView:FindFirstChild("Ball")
        local p = rankedBall and rankedBall:FindFirstChild("ball")
        if p and p:IsA("BasePart") then return p end
        local freeBall = carSoccer:FindFirstChild("Ball")
        p = freeBall and freeBall:FindFirstChild("ball")
        if p and p:IsA("BasePart") then return p end
        local indicator = carSoccer:FindFirstChild("BallIndicator")
        if indicator and indicator:IsA("BasePart") then return indicator end
    end
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") and string.lower(obj.Name) == "ball" then
            return obj
        end
    end
    return nil
end

local function neonPart(name, shape)
    local p = Instance.new("Part")
    p.Name = name
    p.Anchored = true
    p.CanCollide = false
    p.CanTouch = false
    p.CanQuery = false
    p.CastShadow = false
    p.Material = Enum.Material.Neon
    p.Color = PURPLE
    p.Transparency = 0.15
    p.Shape = shape or Enum.PartType.Block
    p.Size = Vector3.new(0.5, 0.5, 0.5)
    p.Parent = Workspace
    return p
end

marker = neonPart("TurboHubBallMarker", Enum.PartType.Ball)
marker.Size = Vector3.new(2.2, 2.2, 2.2)
marker.Transparency = 0.35

local function clearTrail()
    for _, p in ipairs(trailParts) do
        if p and p.Parent then p:Destroy() end
    end
    table.clear(trailParts)
end

local function drawPrediction(pos, velocity)
    clearTrail()
    if not prediction or velocity.Magnitude < 4 then return end
    local gravity = Vector3.new(0, -Workspace.Gravity, 0)
    local prev = pos
    for i = 1, 18 do
        local t = i * 0.08
        local nextPos = pos + velocity * t + 0.5 * gravity * t * t
        local delta = nextPos - prev
        if delta.Magnitude > 0.1 then
            local seg = neonPart("TurboHubPrediction")
            seg.Color = PINK
            seg.Transparency = 0.25 + i / 30
            seg.Size = Vector3.new(0.12, 0.12, delta.Magnitude)
            seg.CFrame = CFrame.lookAt((prev + nextPos) / 2, nextPos)
            table.insert(trailParts, seg)
        end
        prev = nextPos
    end
end

trackButton.Activated:Connect(function()
    tracking = not tracking
    trackButton.Text = "Rastreamento da bola: " .. (tracking and "LIGADO" or "DESLIGADO")
end)
pathButton.Activated:Connect(function()
    prediction = not prediction
    pathButton.Text = "Previsão visual: " .. (prediction and "LIGADA" or "DESLIGADA")
    if not prediction then clearTrail() end
end)
minimizeButton.Activated:Connect(function()
    minimized = not minimized
    status.Visible = not minimized
    trackButton.Visible = not minimized
    pathButton.Visible = not minimized
    note.Visible = not minimized
    main.Size = minimized and UDim2.fromOffset(255, 40) or UDim2.fromOffset(255, 230)
    minimizeButton.Text = minimized and "Expandir menu" or "Minimizar menu"
    minimizeButton.Position = minimized and UDim2.fromOffset(10, 3) or UDim2.fromOffset(10, 152)
    header.Visible = not minimized
    close.Visible = not minimized
end)
close.Activated:Connect(function()
    clearTrail()
    if marker then marker:Destroy() end
    gui:Destroy()
end)

local elapsed = 0
local connection
connection = RunService.Heartbeat:Connect(function(dt)
    elapsed += dt
    if elapsed < 0.08 then return end
    elapsed = 0

    if not ballPart or not ballPart.Parent then
        ballPart = findBall()
        lastPos, lastTime = nil, nil
    end

    if not ballPart then
        status.Text = "Bola não encontrada • tentando novamente"
        marker.Transparency = 1
        clearTrail()
        return
    end

    local pos = ballPart.Position
    status.Text = "Bola detectada • " .. tostring(math.floor((pos - (player.Character and player.Character:GetPivot().Position or pos)).Magnitude)) .. " studs"
    marker.Transparency = tracking and 0.35 or 1
    if tracking then marker.Position = pos end

    local now = os.clock()
    if lastPos and lastTime and now > lastTime then
        local velocity = (pos - lastPos) / (now - lastTime)
        if prediction then drawPrediction(pos, velocity) end
    end
    lastPos, lastTime = pos, now
end)

gui.Destroying:Connect(function()
    if connection then connection:Disconnect() end
    clearTrail()
    if marker and marker.Parent then marker:Destroy() end
end)
