-- Services
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = game.Players.LocalPlayer

-- Multi-track URLs
local tracksURLs = {
    ["1"] = "https://raw.githubusercontent.com/fyywannafly-sudo/YahayukOnly/refs/heads/main/YNT_P1.json",
    ["2"] = "https://raw.githubusercontent.com/fyywannafly-sudo/YahayukOnly/refs/heads/main/YNT_P2.json",
    ["3"] = "https://raw.githubusercontent.com/fyywannafly-sudo/YahayukOnly/refs/heads/main/YNT_P3.json",
    ["4"] = "https://raw.githubusercontent.com/fyywannafly-sudo/YahayukOnly/refs/heads/main/YNT_P4.json",
    ["5"] = "https://raw.githubusercontent.com/fyywannafly-sudo/YahayukOnly/refs/heads/main/YNT_P5.json",
    ["6"] = "https://raw.githubusercontent.com/fyywannafly-sudo/YahayukOnly/refs/heads/main/YNT_P6.json",    
}

local savedTracks = {}
local orderedTrackNames = {"1", "2", "3", "4", "5", "6"}

-- Load Tracks
for _, name in ipairs(orderedTrackNames) do
    local url = tracksURLs[name]
    local success, data = pcall(function()
        return HttpService:JSONDecode(game:HttpGet(url))
    end)

    if success and data and data.points then
        savedTracks[name] = {}
        for _, p in ipairs(data.points) do
            table.insert(savedTracks[name], Vector3.new(p[1], p[2], p[3]))
        end
        print("Track loaded:", name, "Points:", #savedTracks[name])
    else
        warn("Failed to load track:", name)
        savedTracks[name] = {}
    end
end

-- Variables
local running = false
local speed = 16  -- default speed

-- Resume state variables
local resumeData = {
    trackName = nil,
    trackIndex = 1,
    pointIndex = 1,
    lastFlatDir = Vector3.new(0, 0, 1)
}

local function getHRP()
    local char = player.Character or player.CharacterAdded:Wait()
    return char:WaitForChild("HumanoidRootPart")
end

local function findNearestTrackAndPoint()
    local hrp = getHRP()
    local currentPos = hrp.Position
    
    local nearestTrack = 1
    local nearestPoint = 1
    local nearestDistance = math.huge
    
    -- Cek semua track dan semua titik di track
    for trackIdx, name in ipairs(orderedTrackNames) do
        local track = savedTracks[name]
        if track then
            for pointIdx, point in ipairs(track) do
                local distance = (currentPos - point).Magnitude
                
                if distance < nearestDistance then
                    nearestDistance = distance
                    nearestTrack = trackIdx
                    nearestPoint = pointIdx
                end
            end
        end
    end
    
    print("Nearest position: Track " .. nearestTrack .. " Point " .. nearestPoint .. " (Distance: " .. math.floor(nearestDistance) .. ")")
    return nearestTrack, nearestPoint
end

local function respawnPlayer()
    local char = player.Character or player.CharacterAdded:Wait()
    local hrp = char:WaitForChild("HumanoidRootPart")

    -- Teleport ke SummitReturnPad
    local pad = workspace:WaitForChild("SummitReturnPad")
    hrp.CFrame = pad.CFrame + Vector3.new(0, 5, 0) -- offset supaya ga nancep di part
end
--------------
-- === Jump Animation Loader ===
local function getJumpAnim(humanoid)
    local animate = humanoid.Parent:FindFirstChild("Animate")
    if animate and animate:FindFirstChild("jump") then
        local anim = animate.jump:FindFirstChildOfClass("Animation")
        if anim then
            local animator = humanoid:FindFirstChildOfClass("Animator")
            if animator then
                return animator:LoadAnimation(anim)
            end
        end
    end
    return nil
end

local jumpTrack = nil

-- FUNCTION TRIGGERJUMP
------------
local lastLanding = 0
local landingCooldown = 0.2 -- cuma buat cegah auto-jump pas landing

local function triggerJump(humanoid, isClimb)
    if humanoid then
        local state = humanoid:GetState()

        -- Kalau turun & baru landing → kasih cooldown
        if not isClimb and state == Enum.HumanoidStateType.Landed then
            lastLanding = tick()
            return
        end

        -- Kalau lagi climb (deltaY > 3), selalu boleh lompat
        -- Kalau bukan climb (misal jatuh), tetap pake cooldown biar ga auto jump
        if (isClimb or state == Enum.HumanoidStateType.Running or state == Enum.HumanoidStateType.Freefall)
            and (isClimb or tick() - lastLanding > landingCooldown) then

            humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end
end


-- FUNCTION PLAYTRACK
function playTrack(track, trackName)
    if not track or #track < 2 then 
        print("Track tidak valid atau terlalu pendek")
        return false
    end
    
    local hrp = getHRP()
    local char = player.Character or player.CharacterAdded:Wait()
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if humanoid then humanoid.AutoRotate = false end

    for i = 2, #track do
        if not running then 
            resumeData.pointIndex = i - 1
            resumeData.lastFlatDir = resumeData.lastFlatDir or Vector3.new(0, 0, 1)
            
            -- Restore AutoRotate when stopping
            if humanoid then humanoid.AutoRotate = true end
            return false
        end

        local startPos = track[i-1]
        local targetPos = track[i]

        local distance = (targetPos - startPos).Magnitude
 local deltaY = targetPos.Y - startPos.Y
if deltaY > 3 then
    triggerJump(humanoid, true) -- spam jump untuk climb
end




 local duration = math.max(distance / speed, 0.05)

-- Hanya percepat saat turun, naik tetap normal
if deltaY < -5 then  -- Hanya saat turun curam
    duration = duration * 0.3
elseif deltaY < -2 then  -- Hanya saat turun sedang
    duration = duration * 0.5
end

        local elapsed = 0
while elapsed < duration and running do
    elapsed += RunService.Heartbeat:Wait()

    local t = math.clamp(elapsed / duration, 0, 1)
    local alpha
if deltaY > 2 then
    alpha = t ^ 2 -- Naik → awal lambat, akhir cepat
elseif deltaY < -2 then
    alpha = 1 - (1 - t) ^ 2 -- Turun → awal cepat, akhir lambat
else
    alpha = t -- Rata → linear
end


local currentPos
if math.abs(deltaY) > 5 then
    -- Smooth pakai easing curve biar natural (loncat/jatuh)
    local easedT
    if deltaY > 0 then
        -- Naik → awal lambat, akhir cepat
        easedT = t ^ 2
    else
        -- Turun → awal cepat, akhir melambat
        easedT = 1 - (1 - t) ^ 2
    end
    currentPos = startPos:Lerp(targetPos, easedT)
else
    currentPos = startPos:Lerp(targetPos, alpha)
end


-- SIMPLE FIX: Hanya update lastFlatDir jika bukan vertical murni
local direction = Vector3.new(targetPos.X - startPos.X, 0, targetPos.Z - startPos.Z)

-- Hanya update arah jika ada movement horizontal signifikan
if direction.Magnitude > 2.0 then  -- Threshold lebih besar
    resumeData.lastFlatDir = direction.Unit
end

-- Selalu pakai lastFlatDir, jangan pernah reset
local lookDir = resumeData.lastFlatDir
if lookDir.Magnitude < 0.1 then
    lookDir = Vector3.new(0, 0, 1)
end

local blend = 0.10
local targetCFrame = CFrame.new(currentPos, currentPos + lookDir)
local lerped = hrp.CFrame:Lerp(targetCFrame, blend)
hrp.CFrame = CFrame.new(currentPos) * (lerped - lerped.Position)

-- Posisi target
local targetCFrame = CFrame.new(currentPos, currentPos + lookDir)

-- Lerp biar smooth
local lerped = hrp.CFrame:Lerp(targetCFrame, blend)

-- Hard-lock posisi (supaya ga jatoh / offset)
hrp.CFrame = CFrame.new(currentPos) * (lerped - lerped.Position)
        end
    end

    if humanoid then humanoid.AutoRotate = true end
    resumeData.pointIndex = 1
    resumeData.lastFlatDir = Vector3.new(0, 0, 1)

    return true
end

-- FUNCTION PLAYTRACKFROMPOINT
function playTrackFromPoint(track, trackName, startPointIndex, lastDirection)
    if not track or #track < 2 or startPointIndex >= #track then 
        print("Track tidak valid atau start point tidak valid")
        return false
    end
    
    local hrp = getHRP()
    local char = player.Character or player.CharacterAdded:Wait()
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if humanoid then humanoid.AutoRotate = false end

    resumeData.lastFlatDir = lastDirection or Vector3.new(0, 0, 1)

    for i = startPointIndex + 1, #track do
        if not running then 
            -- Save the current position for resume
            resumeData.pointIndex = i - 1
            
            -- Restore AutoRotate when stopping
            if humanoid then humanoid.AutoRotate = true end
            return false -- Track dihentikan
        end

        local startPos = track[i-1]
        local targetPos = track[i]

        local distance = (targetPos - startPos).Magnitude
 local deltaY = targetPos.Y - startPos.Y
if deltaY > 3 then
    triggerJump(humanoid, true) -- spam jump untuk climb
end




local duration = math.max(distance / speed, 0.05)

-- Hanya percepat saat turun, naik tetap normal
if deltaY < -5 then  -- Hanya saat turun curam
    duration = duration * 0.3
elseif deltaY < -2 then  -- Hanya saat turun sedang
    duration = duration * 0.5
end

        local elapsed = 0
while elapsed < duration and running do
    elapsed += RunService.Heartbeat:Wait()

    local t = math.clamp(elapsed / duration, 0, 1)
  local alpha
if deltaY > 2 then
    alpha = t ^ 2
elseif deltaY < -2 then
    alpha = 1 - (1 - t) ^ 2
else
    alpha = t
end


local currentPos
if math.abs(deltaY) > 5 then
    local easedT
    if deltaY > 0 then
        easedT = t ^ 2
    else
        easedT = 1 - (1 - t) ^ 2
    end
    currentPos = startPos:Lerp(targetPos, easedT)
else
    currentPos = startPos:Lerp(targetPos, alpha)
end


-- SIMPLE FIX: Hanya update lastFlatDir jika bukan vertical murni
local direction = Vector3.new(targetPos.X - startPos.X, 0, targetPos.Z - startPos.Z)

-- Hanya update arah jika ada movement horizontal signifikan
if direction.Magnitude > 2.0 then  -- Threshold lebih besar
    resumeData.lastFlatDir = direction.Unit
end

-- Selalu pakai lastFlatDir, jangan pernah reset
local lookDir = resumeData.lastFlatDir
if lookDir.Magnitude < 0.1 then
    lookDir = Vector3.new(0, 0, 1)
end

local blend = 0.10
local targetCFrame = CFrame.new(currentPos, currentPos + lookDir)
local lerped = hrp.CFrame:Lerp(targetCFrame, blend)
hrp.CFrame = CFrame.new(currentPos) * (lerped - lerped.Position)

-- Posisi target
local targetCFrame = CFrame.new(currentPos, currentPos + lookDir)

-- Lerp biar smooth
local lerped = hrp.CFrame:Lerp(targetCFrame, blend)

-- Hard-lock posisi (supaya ga jatoh / offset)
hrp.CFrame = CFrame.new(currentPos) * (lerped - lerped.Position)
        end
    end

    if humanoid then humanoid.AutoRotate = true end
    return true -- Track selesai
end

-- FUNCTION RESUMETRACKLOOP (YANG DIPERBAIKI)
local function resumeTrackLoop()
    if not resumeData.trackName or not resumeData.trackIndex then
        print("No resume data available")
        return
    end
    
    -- Cari index dimulai dari track yang dipause
    local startIndex = resumeData.trackIndex
    for i = startIndex, #orderedTrackNames do
        if not running then break end
        
        local name = orderedTrackNames[i]
        print("Resuming track:", name)
        resumeData.trackName = name
        resumeData.trackIndex = i
        
        local track = savedTracks[name]
        if track and #track > 1 then
            local success, finished
            if i == startIndex then
                -- Resume dari titik terhenti
                success, finished = pcall(function()
                    return playTrackFromPoint(track, name, resumeData.pointIndex, resumeData.lastFlatDir)
                end)
            else
                -- Mulai dari awal untuk track berikutnya
                resumeData.pointIndex = 1
                resumeData.lastFlatDir = Vector3.new(0, 0, 1)
                success, finished = pcall(function()
                    return playTrack(track, name)
                end)
            end
            
            if not success then
                print("Error resuming track '" .. name .. "':", finished)
                finished = false
            end
            
            if not running then break end
            if not finished then
                print("Resumed track stopped:", name)
                break
            end
        end
    end
    
if running then
    print("Completed all tracks, teleporting to SummitReturnPad...")
    respawnPlayer()
    task.wait(1)

    -- Reset supaya mulai lagi dari awal
    resumeData = {
        trackName = orderedTrackNames[1],
        trackIndex = 1,
        pointIndex = 1,
        lastFlatDir = Vector3.new(0, 0, 1)
    }

    -- Lanjutkan loop setelah teleport
    if running then
        resumeTrackLoop()
    end
end
end

local function runAutoSummitLoop()
    -- Cari track DAN titik terdekat dari posisi sekarang
    local startTrackIndex, startPointIndex = findNearestTrackAndPoint()
    
    while running do
        -- Mulai dari track terdekat, dari titik terdekat
        for trackIdx = startTrackIndex, #orderedTrackNames do
            if not running then break end

            local name = orderedTrackNames[trackIdx]
            local track = savedTracks[name]
            
            if track and #track > 1 then
                print("Playing track:", name, "starting from point", startPointIndex)
                resumeData.trackName = name
                resumeData.trackIndex = trackIdx
                
                local success, finished
                
                if trackIdx == startTrackIndex then
                    -- Track pertama: mulai dari titik terdekat
                    success, finished = pcall(function()
                        return playTrackFromPoint(track, name, startPointIndex, resumeData.lastFlatDir)
                    end)
                else
                    -- Track berikutnya: mulai dari awal
                    resumeData.pointIndex = 1
                    resumeData.lastFlatDir = Vector3.new(0, 0, 1)
                    success, finished = pcall(function()
                        return playTrack(track, name)
                    end)
                end
                
                if not success then
                    print("Error playing track '" .. name .. "':", finished)
                    finished = false
                end

                if not running then break end
                if not finished then
                    print("Track dihentikan:", name)
                    break
                end
                
                -- Reset startPointIndex untuk track berikutnya
                startPointIndex = 1
            end
        end

        if running then
            print("Completed all tracks, teleporting to SummitReturnPad...")
            respawnPlayer()
            task.wait(1)

            -- Cari lagi track terdekat setelah respawn
            startTrackIndex, startPointIndex = findNearestTrackAndPoint()
            resumeData.trackIndex = startTrackIndex
        end
    end
    print("Auto summit loop stopped")
end

-- GUI Setup
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "MT_YAHAYUK"
ScreenGui.Parent = CoreGui

local Frame = Instance.new("Frame", ScreenGui)
Frame.Size = UDim2.new(0, 300, 0, 240)
Frame.Position = UDim2.new(0.5, -150, 0.2, 0)
Frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
Frame.BackgroundTransparency = 0.3
Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 8)

local Title = Instance.new("TextLabel", Frame)
Title.Size = UDim2.new(1, 0, 0, 30)
Title.Text = "MT YAHAYUK"
Title.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
Title.TextColor3 = Color3.fromRGB(180, 180, 180)
Title.TextScaled = true
Instance.new("UICorner", Title).CornerRadius = UDim.new(0, 8)

local speedBox = Instance.new("TextBox", Frame)
speedBox.Size = UDim2.new(0.9, 0, 0, 40)
speedBox.Position = UDim2.new(0.05, 0, 0, 40)
speedBox.PlaceholderText = "Speed (default 16)"
speedBox.Text = tostring(speed)
speedBox.TextColor3 = Color3.fromRGB(180, 180, 180)
speedBox.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
speedBox.TextScaled = true
speedBox.ClearTextOnFocus = false
Instance.new("UICorner", speedBox).CornerRadius = UDim.new(0, 6)

speedBox.FocusLost:Connect(function(enterPressed)
    if enterPressed then
        local val = tonumber(speedBox.Text)
        if val and val > 0 then
            speed = val
        else
            speedBox.Text = tostring(speed)
        end
    end
end)

-- === Auto Summit Loop Button ===
local autoBtn = Instance.new("TextButton", Frame)
autoBtn.Size = UDim2.new(0.9, 0, 0, 40)
autoBtn.Position = UDim2.new(0.05, 0, 0, 90)
autoBtn.Text = "AUTO SUMMIT (Loop)"
autoBtn.BackgroundColor3 = Color3.fromRGB(0, 60, 100)
autoBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
autoBtn.TextScaled = true
Instance.new("UICorner", autoBtn).CornerRadius = UDim.new(0, 6)

-- ANIMATION Button
local animBtn = Instance.new("TextButton", Frame)
animBtn.Size = UDim2.new(0.9, 0, 0, 40)
animBtn.Position = UDim2.new(0.05, 0, 0, 140)
animBtn.Text = "ANIMASI: OFF"
animBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
animBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
animBtn.TextScaled = true
Instance.new("UICorner", animBtn).CornerRadius = UDim.new(0, 8)

-- STOP/RESUME Button
local stopResumeBtn = Instance.new("TextButton", Frame)
stopResumeBtn.Size = UDim2.new(0.44, 0, 0, 40)
stopResumeBtn.Position = UDim2.new(0.05, 0, 0, 190)
stopResumeBtn.Text = "PAUSE"
stopResumeBtn.BackgroundColor3 = Color3.fromRGB(80, 0, 0)
stopResumeBtn.TextColor3 = Color3.fromRGB(180, 180, 180)
stopResumeBtn.TextScaled = true
Instance.new("UICorner", stopResumeBtn).CornerRadius = UDim.new(0, 8)

-- STOP ALL Button
local stopAllBtn = Instance.new("TextButton", Frame)
stopAllBtn.Size = UDim2.new(0.44, 0, 0, 40)
stopAllBtn.Position = UDim2.new(0.51, 0, 0, 190)
stopAllBtn.Text = "STOP ALL"
stopAllBtn.BackgroundColor3 = Color3.fromRGB(120, 0, 0)
stopAllBtn.TextColor3 = Color3.fromRGB(180, 180, 180)
stopAllBtn.TextScaled = true
Instance.new("UICorner", stopAllBtn).CornerRadius = UDim.new(0, 8)

-- Variabel untuk menandai apakah ini pause atau stop all
local isPaused = false

-- ANIMATION variables
local bypassIsActive = false
local bypassConn

-- Function to restore character control
local function restoreCharacterControl()
    local char = player.Character
    if char then
        local humanoid = char:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.AutoRotate = true
        end
    end
end

-- Setup animation handler
local function setupBypass(char)
    local humanoid = char:WaitForChild("Humanoid")
    local hrp = char:WaitForChild("HumanoidRootPart")
    local lastPos = hrp.Position

    if bypassConn then bypassConn:Disconnect() end
    bypassConn = RunService.RenderStepped:Connect(function()
        if not hrp or not hrp.Parent then return end

        if bypassIsActive and running then -- Hanya aktif ketika auto summit berjalan
            local direction = (hrp.Position - lastPos)
            local dist = direction.Magnitude
            if dist > 0.01 then
                local moveVector = direction.Unit * math.clamp(dist * 5, 0, 1)
                humanoid:Move(moveVector, false)
            else
                humanoid:Move(Vector3.zero, false)
            end
        end

        lastPos = hrp.Position
    end)
end

player.CharacterAdded:Connect(function(char)
    setupBypass(char)
    -- Pastikan AutoRotate aktif ketika karakter baru muncul
    task.wait(1)
    restoreCharacterControl()
end)
if player.Character then 
    setupBypass(player.Character)
    restoreCharacterControl()
end

-- Fungsi untuk STOP ALL
local function stopAllTracks()
    running = false
    isPaused = false
    stopResumeBtn.Text = "PAUSE"
    stopResumeBtn.BackgroundColor3 = Color3.fromRGB(80, 0, 0)

    -- Matikan animasi saat stop all
    bypassIsActive = false
    animBtn.Text = "ANIMASI: OFF"
    animBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)

    -- Restore character control
    restoreCharacterControl()

    -- Reset resume data
    resumeData = {
        trackName = nil,
        trackIndex = 1,
        pointIndex = 1,
        lastFlatDir = Vector3.new(0, 0, 1)
    }

    print("All tracks stopped completely")
end

-- Tombol STOP ALL
stopAllBtn.MouseButton1Click:Connect(function()
    stopAllTracks()
end)

-- Tombol PAUSE/RESUME
stopResumeBtn.MouseButton1Click:Connect(function()
    if running then
        -- === PAUSE ===
        running = false
        isPaused = true
        stopResumeBtn.Text = "RESUME"
        stopResumeBtn.BackgroundColor3 = Color3.fromRGB(0, 80, 0)

        -- Matikan animasi saat pause
        bypassIsActive = false
        animBtn.Text = "ANIMASI: OFF"
        animBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)

        -- Restore character control saat pause
        restoreCharacterControl()

        print("Track paused - character can now move freely")
    else
        if isPaused and resumeData.trackName then
            -- === RESUME dari titik terakhir ===
            running = true
            isPaused = false
            stopResumeBtn.Text = "PAUSE"
            stopResumeBtn.BackgroundColor3 = Color3.fromRGB(80, 0, 0)

            -- Hidupin animasi otomatis saat resume
            bypassIsActive = true
            animBtn.Text = "ANIMASI: ON"
            animBtn.BackgroundColor3 = Color3.fromRGB(50, 150, 50)

            coroutine.wrap(function()
                resumeTrackLoop()
                if running then
                    print("Resume completed all tracks")
                else
                    print("Resume stopped early")
                end
            end)()

            print("Resuming from track:", resumeData.trackName, "at point", resumeData.pointIndex)
        else
            print("No track to resume")
        end
    end
end)

-- Animation button
animBtn.MouseButton1Click:Connect(function()
    if running then -- Hanya bisa diubah ketika auto summit berjalan
        bypassIsActive = not bypassIsActive
        if bypassIsActive then
            animBtn.Text = "ANIMASI: ON"
            animBtn.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
        else
            animBtn.Text = "ANIMASI: OFF"
            animBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
        end
    else
        -- Jika auto summit tidak berjalan, matikan animasi
        bypassIsActive = false
        animBtn.Text = "ANIMASI: OFF"
        animBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
        print("Animation can only be toggled when auto summit is running")
    end
end)

-- Auto Summit Button
autoBtn.MouseButton1Click:Connect(function()
    if running then return end
    running = true
    isPaused = false
    stopResumeBtn.Text = "PAUSE"
    stopResumeBtn.BackgroundColor3 = Color3.fromRGB(80, 0, 0)
    
    -- Aktifkan animasi secara default saat memulai
    bypassIsActive = true
    animBtn.Text = "ANIMASI: ON"
    animBtn.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
    
    coroutine.wrap(runAutoSummitLoop)()
end)

-- Minimize Button
local closeBtn = Instance.new("TextButton", Frame)
closeBtn.Size = UDim2.new(0, 30, 0, 30)
closeBtn.Position = UDim2.new(1, -35, 0, 0)
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
closeBtn.TextScaled = true
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(1, 0)

closeBtn.MouseButton1Click:Connect(function()
    Frame.Visible = false
    local logoBtn = Instance.new("TextButton", ScreenGui)
    logoBtn.Size = UDim2.new(0, 40, 0, 40)
    logoBtn.Position = UDim2.new(0, 50, 0, 50)
    logoBtn.Text = "Fyy"
    logoBtn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    logoBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    logoBtn.TextScaled = true
    Instance.new("UICorner", logoBtn).CornerRadius = UDim.new(1, 0)

    logoBtn.MouseButton1Click:Connect(function()
        Frame.Visible = true
        logoBtn:Destroy()
    end)
end)

-- Drag Function
local function setupDrag(target)
    local dragging, dragStart, startPos
    target.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = target.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    target.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            if dragging then
                local delta = input.Position - dragStart
                target.Position = UDim2.new(
                    startPos.X.Scale, startPos.X.Offset + delta.X,
                    startPos.Y.Scale, startPos.Y.Offset + delta.Y
                )
            end
        end
    end)
end
setupDrag(Frame)
