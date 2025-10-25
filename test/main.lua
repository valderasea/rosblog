-------------------------------------------------------------
-- LOAD LIBRARY UI
-------------------------------------------------------------
local Rayfield = loadstring(game:HttpGet('https://raw.githubusercontent.com/valderasea/rosblog/refs/heads/main/UI%20Liblary/Rayfield.lua'))()

-------------------------------------------------------------
-- WINDOW PROCESS
-------------------------------------------------------------
local Window = Rayfield:CreateWindow({
   Name = "ValL | MOUNT FUNNY",
   Icon = "braces",
   LoadingTitle = "Created By Valdera",
   LoadingSubtitle = "Jelek ya maap",
   Theme = "Amethyst",
})

-------------------------------------------------------------
-- TAB MENU
-------------------------------------------------------------
local AutoWalkTab = Window:CreateTab("Auto Walk", "bot")
-------------------------------------------------------------
-- SERVICES
-------------------------------------------------------------
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local StarterGui = game:GetService("StarterGui")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local VirtualUser = game:GetService("VirtualUser")

-------------------------------------------------------------
-- IMPORT
-------------------------------------------------------------
local LocalPlayer = Players.LocalPlayer
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
local setclipboard = setclipboard or toclipboard

-------------------------------------------------------------
-- AUTO WALK
-------------------------------------------------------------
-----| AUTO WALK VARIABLES |-----
-- Setup folder save file json
local mainFolder = "ValL"
local jsonFolder = mainFolder .. "/js_mount_funny_patch_002"
if not isfolder(mainFolder) then
    makefolder(mainFolder)
end
if not isfolder(jsonFolder) then
    makefolder(jsonFolder)
end

-- Server URL and JSON checkpoint file list
local baseURL = "https://raw.githubusercontent.com/valderasea/rosblog-json/refs/heads/main/test/"
local jsonFiles = {
    "spawnpoint.json",
    "checkpoint_1.json",
	"checkpoint_2.json",
	"checkpoint_3.json",
	"checkpoint_4.json",
	"checkpoint_5.json",
    "checkpoint_6.json",
}

-- Variables to control auto walk status
local isPlaying = false
local playbackConnection = nil
local autoLoopEnabled = false
local currentCheckpoint = 0

--Variables for pause and resume features
local isPaused = false
local manualLoopEnabled = false
local pausedTime = 0
local pauseStartTime = 0

-- FPS Independent Playback Variables
local lastPlaybackTime = 0
local accumulatedTime = 0

-- Looping Variables
local loopingEnabled = false
local isManualMode = false
local manualStartCheckpoint = 0

-- NEW: Avatar Size Compensation Variables
local recordedHipHeight = nil
local currentHipHeight = nil
local hipHeightOffset = 0

-- NEW: Speed Control Variables
local playbackSpeed = 1.0

-- NEW: Footstep Sound Variables
local lastFootstepTime = 0
local footstepInterval = 0.35
local leftFootstep = true

-- NEW: Rotate/Flip Variables
local isFlipped = false
local FLIP_SMOOTHNESS = 0.05
local currentFlipRotation = CFrame.new()
-------------------------------------------------------------

-----| AUTO WALK FUNCTIONS |-----
-- Function to convert Vector3 to table
local function vecToTable(v3)
    return {x = v3.X, y = v3.Y, z = v3.Z}
end

-- Function to convert a table to Vector3
local function tableToVec(t)
    return Vector3.new(t.x, t.y, t.z)
end

-- Linear interpolation function for numbers
local function lerp(a, b, t)
    return a + (b - a) * t
end

-- Linear interpolation function for Vector3
local function lerpVector(a, b, t)
    return Vector3.new(lerp(a.X, b.X, t), lerp(a.Y, b.Y, t), lerp(a.Z, b.Z, t))
end

-- Linear interpolation function for rotation angle
local function lerpAngle(a, b, t)
    local diff = (b - a)
    while diff > math.pi do diff = diff - 2*math.pi end
    while diff < -math.pi do diff = diff + 2*math.pi end
    return a + diff * t
end

-- NEW: Function to calculate HipHeight offset
local function calculateHipHeightOffset()
    if not humanoid then return 0 end
    
    currentHipHeight = humanoid.HipHeight
    
    -- If no recorded hip height, assume standard avatar (2.0)
    if not recordedHipHeight then
        recordedHipHeight = 2.0
    end
    
    -- Calculate offset based on hip height difference
    hipHeightOffset = recordedHipHeight - currentHipHeight
    
    return hipHeightOffset
end

-- NEW: Function to adjust position based on avatar size
local function adjustPositionForAvatarSize(position)
    if hipHeightOffset == 0 then return position end
    
    -- Apply vertical offset to compensate for hip height difference
    return Vector3.new(
        position.X,
        position.Y - hipHeightOffset,
        position.Z
    )
end

-- NEW: Function to play footstep sounds
local function playFootstepSound()
    if not humanoid or not character then return end
    
    pcall(function()
        -- Get the HumanoidRootPart for raycasting
        local hrp = character:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        
        -- Raycast downward to detect floor material
        local rayOrigin = hrp.Position
        local rayDirection = Vector3.new(0, -5, 0)
        local raycastParams = RaycastParams.new()
        raycastParams.FilterDescendantsInstances = {character}
        raycastParams.FilterType = Enum.RaycastFilterType.Exclude
        
        local rayResult = workspace:Raycast(rayOrigin, rayDirection, raycastParams)
        
        if rayResult and rayResult.Instance then
            local material = rayResult.Material
            
            -- Create a sound instance for footstep
            local sound = Instance.new("Sound")
            sound.Volume = 0.8
            sound.RollOffMaxDistance = 100
            sound.RollOffMinDistance = 10
            
            local soundId = "rbxasset://sounds/action_footsteps_plastic.mp3"
            
            sound.SoundId = soundId
            sound.Parent = hrp
            sound:Play()
            
            -- Cleanup sound after it finishes
            game:GetService("Debris"):AddItem(sound, 1)
        end
    end)
end

-- NEW: Function to simulate natural movement for footsteps
local function simulateNaturalMovement(moveDirection, velocity)
    if not humanoid or not character then return end
    
    -- Calculate horizontal movement speed (ignore Y axis)
    local horizontalVelocity = Vector3.new(velocity.X, 0, velocity.Z)
    local speed = horizontalVelocity.Magnitude
    
    -- Check if character is on ground
    local onGround = false
    pcall(function()
        local state = humanoid:GetState()
        onGround = (state == Enum.HumanoidStateType.Running or 
                   state == Enum.HumanoidStateType.RunningNoPhysics or 
                   state == Enum.HumanoidStateType.Landed)
    end)
    
    -- Only play footsteps if moving and on ground
    if speed > 0.5 and onGround then
        local currentTime = tick()
        
        -- Adjust footstep interval based on speed and playback speed
        local speedMultiplier = math.clamp(speed / 16, 0.3, 2)
        local adjustedInterval = footstepInterval / (speedMultiplier * playbackSpeed)
        
        if currentTime - lastFootstepTime >= adjustedInterval then
            playFootstepSound()
            lastFootstepTime = currentTime
            leftFootstep = not leftFootstep
        end
    end
end

-- Function to ensure the JSON file is available (download if it does not exist)
local function EnsureJsonFile(fileName)
    local savePath = jsonFolder .. "/" .. fileName
    if isfile(savePath) then return true, savePath end
    local ok, res = pcall(function() return game:HttpGet(baseURL..fileName) end)
    if ok and res and #res > 0 then
        writefile(savePath, res)
        return true, savePath
    end
    return false, nil
end

-- Function to read and decode JSON checkpoint files
local function loadCheckpoint(fileName)
    local filePath = jsonFolder .. "/" .. fileName
    
    if not isfile(filePath) then
        warn("File not found:", filePath)
        return nil
    end
    
    local success, result = pcall(function()
        local jsonData = readfile(filePath)
        if not jsonData or jsonData == "" then
            error("Empty file")
        end
        return HttpService:JSONDecode(jsonData)
    end)
    
    if success and result then
        if result[1] and result[1].hipHeight then
            recordedHipHeight = result[1].hipHeight
        end
        return result
    else
        warn("❌ Load error for", fileName, ":", result)
        return nil
    end
end

-- Binary search for better performance
local function findSurroundingFrames(data, t)
    if #data == 0 then return nil, nil, 0 end
    if t <= data[1].time then return 1, 1, 0 end
    if t >= data[#data].time then return #data, #data, 0 end
    
    local left, right = 1, #data
    while left < right - 1 do
        local mid = math.floor((left + right) / 2)
        if data[mid].time <= t then
            left = mid
        else
            right = mid
        end
    end
    
    local i0, i1 = left, right
    local span = data[i1].time - data[i0].time
    local alpha = span > 0 and math.clamp((t - data[i0].time) / span, 0, 1) or 0
    
    return i0, i1, alpha
end

-- Function to stop auto walk playback
local function stopPlayback()
    isPlaying = false
    isPaused = false
    pausedTime = 0
    accumulatedTime = 0
    lastPlaybackTime = 0
    lastFootstepTime = 0
    recordedHipHeight = nil
    hipHeightOffset = 0
    isFlipped = false
    currentFlipRotation = CFrame.new()
    if playbackConnection then
        playbackConnection:Disconnect()
        playbackConnection = nil
    end
end

-- IMPROVED: FPS-independent playback with avatar size compensation and rotate feature
local function startPlayback(data, onComplete)
    if not data or #data == 0 then
        warn("No data to play!")
        if onComplete then onComplete() end
        return
    end
    
    if isPlaying then stopPlayback() end
    
    isPlaying = true
    isPaused = false
    pausedTime = 0
    accumulatedTime = 0
    local playbackStartTime = tick()
    lastPlaybackTime = playbackStartTime
    local lastJumping = false
    
    calculateHipHeightOffset()
    
    if playbackConnection then
        playbackConnection:Disconnect()
        playbackConnection = nil
    end

    -- Teleport directly to the starting point JSON with size adjustment
    local first = data[1]
    if character and character:FindFirstChild("HumanoidRootPart") then
        local hrp = character.HumanoidRootPart
        local firstPos = tableToVec(first.position)
        firstPos = adjustPositionForAvatarSize(firstPos)
        local firstYaw = first.rotation or 0
        local startCFrame = CFrame.new(firstPos) * CFrame.Angles(0, firstYaw, 0)
        hrp.CFrame = startCFrame
        hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
        hrp.AssemblyAngularVelocity = Vector3.new(0, 0, 0)

        if humanoid then
            humanoid:Move(tableToVec(first.moveDirection or {x=0,y=0,z=0}), false)
        end
    end

    -- FPS-INDEPENDENT PLAYBACK LOOP
    playbackConnection = RunService.Heartbeat:Connect(function(deltaTime)
        if not isPlaying then return end
        
        -- Handle pause
        if isPaused then
            if pauseStartTime == 0 then
                pauseStartTime = tick()
            end
            lastPlaybackTime = tick()
            return
        else
            if pauseStartTime > 0 then
                pausedTime = pausedTime + (tick() - pauseStartTime)
                pauseStartTime = 0
                lastPlaybackTime = tick()
            end
        end
        
        if not character or not character:FindFirstChild("HumanoidRootPart") then return end
        if not humanoid or humanoid.Parent ~= character then
            humanoid = character:FindFirstChild("Humanoid")
            calculateHipHeightOffset()
        end
        
        local currentTime = tick()
        local actualDelta = currentTime - lastPlaybackTime
        lastPlaybackTime = currentTime
        
        actualDelta = math.min(actualDelta, 0.1)
        
        accumulatedTime = accumulatedTime + (actualDelta * playbackSpeed)
        
        local totalDuration = data[#data].time
        
        -- Check if playback is complete
        if accumulatedTime > totalDuration then
            local final = data[#data]
            if character and character:FindFirstChild("HumanoidRootPart") then
                local hrp = character.HumanoidRootPart
                local finalPos = tableToVec(final.position)
                finalPos = adjustPositionForAvatarSize(finalPos)
                local finalYaw = final.rotation or 0
                local targetCFrame = CFrame.new(finalPos) * CFrame.Angles(0, finalYaw, 0)
                
                -- Apply flip rotation if enabled
                local targetFlipRotation = isFlipped and CFrame.Angles(0, math.pi, 0) or CFrame.new()
                currentFlipRotation = currentFlipRotation:Lerp(targetFlipRotation, FLIP_SMOOTHNESS)
                
                hrp.CFrame = targetCFrame * currentFlipRotation
                if humanoid then
                    humanoid:Move(tableToVec(final.moveDirection or {x=0,y=0,z=0}), false)
                end
            end
            stopPlayback()
            if onComplete then onComplete() end
            return
        end
        
        -- Interpolation with binary search
        local i0, i1, alpha = findSurroundingFrames(data, accumulatedTime)
        local f0, f1 = data[i0], data[i1]
        if not f0 or not f1 then return end
        
        local pos0 = tableToVec(f0.position)
        local pos1 = tableToVec(f1.position)
        local vel0 = tableToVec(f0.velocity or {x=0,y=0,z=0})
        local vel1 = tableToVec(f1.velocity or {x=0,y=0,z=0})
        local move0 = tableToVec(f0.moveDirection or {x=0,y=0,z=0})
        local move1 = tableToVec(f1.moveDirection or {x=0,y=0,z=0})
        local yaw0 = f0.rotation or 0
        local yaw1 = f1.rotation or 0
        
        local interpPos = lerpVector(pos0, pos1, alpha)
        interpPos = adjustPositionForAvatarSize(interpPos)
        
        local interpVel = lerpVector(vel0, vel1, alpha)
        local interpMove = lerpVector(move0, move1, alpha)
        local interpYaw = lerpAngle(yaw0, yaw1, alpha)
        
        local hrp = character.HumanoidRootPart
        local targetCFrame = CFrame.new(interpPos) * CFrame.Angles(0, interpYaw, 0)
        
        -- NEW: Apply flip/rotate transformation
        local targetFlipRotation = isFlipped and CFrame.Angles(0, math.pi, 0) or CFrame.new()
        currentFlipRotation = currentFlipRotation:Lerp(targetFlipRotation, FLIP_SMOOTHNESS)
        
        local lerpFactor = math.clamp(1 - math.exp(-10 * actualDelta), 0, 1)
        hrp.CFrame = hrp.CFrame:Lerp(targetCFrame * currentFlipRotation, lerpFactor)
        
        pcall(function()
            hrp.AssemblyLinearVelocity = interpVel
        end)
        
        if humanoid then
            humanoid:Move(interpMove, false)
        end
        
        simulateNaturalMovement(interpMove, interpVel)
        
        -- Handle jumping
        local jumpingNow = f0.jumping or false
        if f1.jumping then jumpingNow = true end
        if jumpingNow and not lastJumping then
            if humanoid then
                humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end
        lastJumping = jumpingNow
    end)
end

-- Function to run the auto walk sequence from start to finish
local function startAutoWalkSequence()
    currentCheckpoint = 0

    local function playNext()
        if not autoLoopEnabled then return end
        
        currentCheckpoint = currentCheckpoint + 1
        if currentCheckpoint > #jsonFiles then
            if loopingEnabled then
                Rayfield:Notify({
                    Title = "Auto Walk",
                    Content = "Semua checkpoint selesai! Looping dari awal...",
                    Duration = 3,
                    Image = "repeat"
                })
                task.wait(1)
                startAutoWalkSequence()
            else
                autoLoopEnabled = false
                Rayfield:Notify({
                    Title = "Auto Walk",
                    Content = "Auto walk selesai! Semua checkpoint sudah dilewati.",
                    Duration = 5,
                    Image = "check-check"
                })
            end
            return
        end

        local checkpointFile = jsonFiles[currentCheckpoint]

        local ok, path = EnsureJsonFile(checkpointFile)
        if not ok then
            Rayfield:Notify({
                Title = "Error",
                Content = "Failed to download: ",
                Duration = 5,
                Image = "ban"
            })
            autoLoopEnabled = false
            return
        end

        local data = loadCheckpoint(checkpointFile)
        if data and #data > 0 then
            Rayfield:Notify({
                Title = "Auto Walk (Automatic)",
                Content = "Auto walk berhasil di jalankan",
                Duration = 2,
                Image = "bot"
            })
            task.wait(0.5)
            startPlayback(data, playNext)
        else
            Rayfield:Notify({
                Title = "Error",
                Content = "Error loading: " .. checkpointFile,
                Duration = 5,
                Image = "ban"
            })
            autoLoopEnabled = false
        end
    end

    playNext()
end

-- Function to run manual auto walk with looping
local function startManualAutoWalkSequence(startCheckpoint)
    currentCheckpoint = startCheckpoint - 1
    isManualMode = true
    autoLoopEnabled = true

    local function walkToStartIfNeeded(data)
        if not character or not character:FindFirstChild("HumanoidRootPart") then
            Rayfield:Notify({
                Title = "Auto Walk (Manual)",
                Content = "Character belum siap (HRP tidak ditemukan).",
                Duration = 3,
                Image = "ban"
            })
            return false
        end

        local hrp = character.HumanoidRootPart
        if not data or not data[1] or not data[1].position then
            return true
        end

        local startPos = tableToVec(data[1].position)
        local distance = (hrp.Position - startPos).Magnitude

        if distance > 100 then
            Rayfield:Notify({
                Title = "Auto Walk (Manual)",
                Content = string.format("Terlalu jauh (%.0f studs). Maks 100 studs untuk memulai.", distance),
                Duration = 4,
                Image = "alert-triangle"
            })
            autoLoopEnabled = false
            isManualMode = false
            return false
        end

        Rayfield:Notify({
            Title = "Auto Walk (Manual)",
            Content = string.format("Menuju titik awal... (%.0f studs)", distance),
            Duration = 3,
            Image = "walk"
        })

        local humanoidLocal = character:FindFirstChildOfClass("Humanoid")
        if not humanoidLocal then
            Rayfield:Notify({
                Title = "Auto Walk (Manual)",
                Content = "Humanoid tidak ditemukan, gagal berjalan.",
                Duration = 3,
                Image = "ban"
            })
            autoLoopEnabled = false
            isManualMode = false
            return false
        end

        local reached = false
        local reachedConnection
        reachedConnection = humanoidLocal.MoveToFinished:Connect(function(r)
            reached = r
            if reachedConnection then
                reachedConnection:Disconnect()
                reachedConnection = nil
            end
        end)

        humanoidLocal:MoveTo(startPos)

        local timeout = 20
        local waited = 0
        while not reached and waited < timeout and autoLoopEnabled do
            task.wait(0.25)
            waited = waited + 0.25
        end

        if reached then
            Rayfield:Notify({
                Title = "Auto Walk (Manual)",
                Content = "Sudah sampai titik awal. Memulai playback...",
                Duration = 1.5,
                Image = "play"
            })
            return true
        else
            if reachedConnection then
                reachedConnection:Disconnect()
                reachedConnection = nil
            end
            Rayfield:Notify({
                Title = "Auto Walk (Manual)",
                Content = "Gagal mencapai titik awal (timeout atau dibatalkan).",
                Duration = 3,
                Image = "ban"
            })
            autoLoopEnabled = false
            isManualMode = false
            return false
        end
    end

    local function playNext()
        if not autoLoopEnabled then return end

        currentCheckpoint = currentCheckpoint + 1
        if currentCheckpoint > #jsonFiles then
            if loopingEnabled then
                Rayfield:Notify({
                    Title = "Auto Walk (Manual)",
                    Content = "Semua checkpoint selesai! Looping dari awal...",
                    Duration = 3,
                    Image = "repeat"
                })
				task.wait(1)
                startManualAutoWalkSequence(1)
            else
                autoLoopEnabled = false
                isManualMode = false
                Rayfield:Notify({
                    Title = "Auto Walk (Manual)",
                    Content = "Auto walk selesai!",
                    Duration = 2,
                    Image = "check-check"
                })
            end
            return
        end

        local checkpointFile = jsonFiles[currentCheckpoint]
        local ok, path = EnsureJsonFile(checkpointFile)
        if not ok then
            Rayfield:Notify({
                Title = "Error",
                Content = "Failed to download checkpoint",
                Duration = 5,
                Image = "ban"
            })
            autoLoopEnabled = false
            isManualMode = false
            return
        end

        local data = loadCheckpoint(checkpointFile)
        if data and #data > 0 then
            if isManualMode and currentCheckpoint == startCheckpoint then
                local okWalk = walkToStartIfNeeded(data)
                if not okWalk then
                    return
                end
            end
            -- Langsung mulai playback tanpa jeda
            startPlayback(data, playNext)
        else
            Rayfield:Notify({
                Title = "Error",
                Content = "Error loading: " .. checkpointFile,
                Duration = 5,
                Image = "ban"
            })
            autoLoopEnabled = false
            isManualMode = false
        end
    end

    playNext()
end

-- Function to rotate a single checkpoint (manual)
local function playSingleCheckpointFile(fileName, checkpointIndex)
    if loopingEnabled then
        stopPlayback()
        startManualAutoWalkSequence(checkpointIndex)
        return
    end

    autoLoopEnabled = false
    isManualMode = false
    stopPlayback()

    local ok, path = EnsureJsonFile(fileName)
    if not ok then
        Rayfield:Notify({
            Title = "Error",
            Content = "Failed to ensure JSON checkpoint",
            Duration = 4,
            Image = "ban"
        })
        return
    end

    local data = loadCheckpoint(fileName)
    if not data or #data == 0 then
        Rayfield:Notify({
            Title = "Error",
            Content = "File invalid / kosong",
            Duration = 4,
            Image = "ban"
        })
        return
    end

    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then
        Rayfield:Notify({
            Title = "Error",
            Content = "HumanoidRootPart tidak ditemukan!",
            Duration = 4,
            Image = "ban"
        })
        return
    end

    local startPos = tableToVec(data[1].position)
    local distance = (hrp.Position - startPos).Magnitude

    if distance > 100 then
        Rayfield:Notify({
            Title = "Auto Walk (Manual)",
            Content = string.format("Terlalu jauh (%.0f studs)! Harus dalam jarak 100.", distance),
            Duration = 4,
            Image = "alert-triangle"
        })
        return
    end

    Rayfield:Notify({
        Title = "Auto Walk (Manual)",
        Content = string.format("Menuju ke titik awal... (%.0f studs)", distance),
        Duration = 3,
        Image = "walk"
    })

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local moving = true
    humanoid:MoveTo(startPos)

    local reachedConnection
    reachedConnection = humanoid.MoveToFinished:Connect(function(reached)
        if reached then
            moving = false
            reachedConnection:Disconnect()

            Rayfield:Notify({
                Title = "Auto Walk (Manual)",
                Content = "Sudah sampai di titik awal, mulai playback...",
                Duration = 2,
                Image = "play"
            })

            task.wait(0.5)
            startPlayback(data, function()
                Rayfield:Notify({
                    Title = "Auto Walk (Manual)",
                    Content = "Auto walk selesai!",
                    Duration = 2,
                    Image = "check-check"
                })
            end)
        else
            Rayfield:Notify({
                Title = "Auto Walk (Manual)",
                Content = "Gagal mencapai titik awal!",
                Duration = 3,
                Image = "ban"
            })
            moving = false
            reachedConnection:Disconnect()
        end
    end)

    task.spawn(function()
        local timeout = 20
        local elapsed = 0
        while moving and elapsed < timeout do
            task.wait(1)
            elapsed += 1
        end
        if moving then
            Rayfield:Notify({
                Title = "Auto Walk (Manual)",
                Content = "Tidak bisa mencapai titik awal (timeout)!",
                Duration = 3,
                Image = "ban"
            })
            humanoid:Move(Vector3.new(0,0,0))
            moving = false
            if reachedConnection then reachedConnection:Disconnect() end
        end
    end)
end

-- Event listener when the player respawns
player.CharacterAdded:Connect(function(newChar)
    character = newChar
    humanoid = character:WaitForChild("Humanoid")
    humanoidRootPart = character:WaitForChild("HumanoidRootPart")
    
    if isPlaying then stopPlayback() end
end)

-------------------------------------------------------------

-----| MENU 1 > AUTO WALK SETTINGS |-----
local Section = AutoWalkTab:CreateSection("Auto Walk (Settings)")

-------------------------------------------------------------
-- PAUSE/ROTATE UI (MOBILE FRIENDLY & DRAGGABLE - EMOJI ONLY)
-------------------------------------------------------------
local BTN_COLOR = Color3.fromRGB(38, 38, 38)
local BTN_HOVER = Color3.fromRGB(55, 55, 55)
local TEXT_COLOR = Color3.fromRGB(230, 230, 230)
local WARN_COLOR = Color3.fromRGB(255, 140, 0)
local SUCCESS_COLOR = Color3.fromRGB(0, 170, 85)
local ROTATE_COLOR = Color3.fromRGB(100, 100, 255)

local function createPauseRotateUI()
    local ui = Instance.new("ScreenGui")
    ui.Name = "PauseRotateUI"
    ui.IgnoreGuiInset = true
    ui.ResetOnSpawn = false
    ui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ui.Parent = CoreGui

    -- Background container with semi-transparent black background
    local bgFrame = Instance.new("Frame")
    bgFrame.Name = "PR_Background"
    bgFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    bgFrame.BackgroundTransparency = 0.4
    bgFrame.BorderSizePixel = 0
    bgFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    bgFrame.Position = UDim2.new(0.5, 0, 0.85, 0)
    bgFrame.Size = UDim2.new(0, 130, 0, 70)
    bgFrame.Visible = false
    bgFrame.Parent = ui

    -- Rounded corners for background
    local bgCorner = Instance.new("UICorner", bgFrame)
    bgCorner.CornerRadius = UDim.new(0, 20)

    -- Drag indicator (3 dots at top)
    local dragIndicator = Instance.new("Frame")
    dragIndicator.Name = "DragIndicator"
    dragIndicator.BackgroundTransparency = 1
    dragIndicator.Position = UDim2.new(0.5, 0, 0, 8)
    dragIndicator.Size = UDim2.new(0, 40, 0, 6)
    dragIndicator.AnchorPoint = Vector2.new(0.5, 0)
    dragIndicator.Parent = bgFrame

    local dotLayout = Instance.new("UIListLayout", dragIndicator)
    dotLayout.FillDirection = Enum.FillDirection.Horizontal
    dotLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    dotLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    dotLayout.Padding = UDim.new(0, 6)

    -- Create 3 dots
    for i = 1, 3 do
        local dot = Instance.new("Frame")
        dot.Name = "Dot" .. i
        dot.BackgroundColor3 = Color3.fromRGB(150, 150, 150)
        dot.BackgroundTransparency = 0.3
        dot.BorderSizePixel = 0
        dot.Size = UDim2.new(0, 6, 0, 6)
        dot.Parent = dragIndicator

        local dotCorner = Instance.new("UICorner", dot)
        dotCorner.CornerRadius = UDim.new(1, 0)
    end

    -- Main draggable frame (transparent, sits on top of background)
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "PR_Main"
    mainFrame.BackgroundTransparency = 1
    mainFrame.BorderSizePixel = 0
    mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    mainFrame.Position = UDim2.new(0.5, 0, 0.6, 0)
    mainFrame.Size = UDim2.new(1, -10, 0, 50)
    mainFrame.Parent = bgFrame

    -- Make it draggable (improved system)
    local dragging = false
    local dragInput, dragStart, startPos
    local UserInputService = game:GetService("UserInputService")

    local function update(input)
        local delta = input.Position - dragStart
        local newPos = UDim2.new(
            startPos.X.Scale,
            startPos.X.Offset + delta.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
        )
        bgFrame.Position = newPos
    end

    bgFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = bgFrame.Position

            -- Animate dots when dragging starts
            for i, dot in ipairs(dragIndicator:GetChildren()) do
                if dot:IsA("Frame") then
                    TweenService:Create(dot, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
                        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                        BackgroundTransparency = 0
                    }):Play()
                end
            end

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                    -- Reset dots color when dragging ends
                    for i, dot in ipairs(dragIndicator:GetChildren()) do
                        if dot:IsA("Frame") then
                            TweenService:Create(dot, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
                                BackgroundColor3 = Color3.fromRGB(150, 150, 150),
                                BackgroundTransparency = 0.3
                            }):Play()
                        end
                    end
                end
            end)
        end
    end)

    bgFrame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            update(input)
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            if dragging then
                dragging = false
                -- Reset dots color
                for i, dot in ipairs(dragIndicator:GetChildren()) do
                    if dot:IsA("Frame") then
                        TweenService:Create(dot, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
                            BackgroundColor3 = Color3.fromRGB(150, 150, 150),
                            BackgroundTransparency = 0.3
                        }):Play()
                    end
                end
            end
        end
    end)

    -- Layout
    local layout = Instance.new("UIListLayout", mainFrame)
    layout.FillDirection = Enum.FillDirection.Horizontal
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layout.VerticalAlignment = Enum.VerticalAlignment.Center
    layout.Padding = UDim.new(0, 10)

    -- Helper: create circular button with emoji only
    local function createButton(emoji, color)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, 50, 0, 50)
        btn.BackgroundColor3 = BTN_COLOR
        btn.BackgroundTransparency = 0.1
        btn.TextColor3 = TEXT_COLOR
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 24
        btn.Text = emoji
        btn.AutoButtonColor = false
        btn.BorderSizePixel = 0
        btn.Parent = mainFrame

        -- Circular shape
        local c = Instance.new("UICorner", btn)
        c.CornerRadius = UDim.new(1, 0)
        
        -- Hover effects
        btn.MouseEnter:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.12, Enum.EasingStyle.Quad), {
                BackgroundColor3 = BTN_HOVER,
                Size = UDim2.new(0, 54, 0, 54)
            }):Play()
        end)
        btn.MouseLeave:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.12, Enum.EasingStyle.Quad), {
                BackgroundColor3 = color or BTN_COLOR,
                Size = UDim2.new(0, 50, 0, 50)
            }):Play()
        end)

        return btn
    end

    local pauseResumeBtn = createButton("⏸️", BTN_COLOR)
    local rotateBtn = createButton("🔄", BTN_COLOR)

    -- State tracking
    local currentlyPaused = false

    -- Animation functions
    local tweenTime = 0.25
    local showScale = 1
    local hideScale = 0

    local function showUI()
        bgFrame.Visible = true
        bgFrame.Size = UDim2.new(0, 130 * hideScale, 0, 70 * hideScale)
        TweenService:Create(bgFrame, TweenInfo.new(tweenTime, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Size = UDim2.new(0, 130 * showScale, 0, 70 * showScale)
        }):Play()
    end

    local function hideUI()
        TweenService:Create(bgFrame, TweenInfo.new(tweenTime, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
            Size = UDim2.new(0, 130 * hideScale, 0, 70 * hideScale)
        }):Play()
        task.delay(tweenTime, function()
            bgFrame.Visible = false
        end)
    end

    -- Pause/Resume button logic
    pauseResumeBtn.MouseButton1Click:Connect(function()
        if not isPlaying then
            Rayfield:Notify({
                Title = "Auto Walk",
                Content = "❌ Tidak ada auto walk yang sedang berjalan!",
                Duration = 3,
                Image = "alert-triangle"
            })
            return
        end

        if not currentlyPaused then
            -- Pause the auto walk
            isPaused = true
            currentlyPaused = true
            pauseResumeBtn.Text = "▶️"
            pauseResumeBtn.BackgroundColor3 = SUCCESS_COLOR
            Rayfield:Notify({
                Title = "Auto Walk",
                Content = "⏸️ Auto walk dijeda.",
                Duration = 2,
                Image = "pause"
            })
        else
            -- Resume the auto walk
            isPaused = false
            currentlyPaused = false
            pauseResumeBtn.Text = "⏸️"
            pauseResumeBtn.BackgroundColor3 = BTN_COLOR
            Rayfield:Notify({
                Title = "Auto Walk",
                Content = "▶️ Auto walk dilanjutkan.",
                Duration = 2,
                Image = "play"
            })
        end
    end)

    -- Rotate button logic
    rotateBtn.MouseButton1Click:Connect(function()
        if not isPlaying then
            Rayfield:Notify({
                Title = "Rotate",
                Content = "❌ Auto walk harus berjalan terlebih dahulu!",
                Duration = 3,
                Image = "alert-triangle"
            })
            return
        end

        isFlipped = not isFlipped
        
        if isFlipped then
            rotateBtn.Text = "🔃"
            rotateBtn.BackgroundColor3 = SUCCESS_COLOR
            Rayfield:Notify({
                Title = "Rotate",
                Content = "🔄 Mode rotate AKTIF (jalan mundur)",
                Duration = 2,
                Image = "rotate-cw"
            })
        else
            rotateBtn.Text = "🔄"
            rotateBtn.BackgroundColor3 = BTN_COLOR
            Rayfield:Notify({
                Title = "Rotate",
                Content = "🔄 Mode rotate NONAKTIF",
                Duration = 2,
                Image = "rotate-ccw"
            })
        end
    end)

    -- Reset UI state when auto walk stops
    local function resetUIState()
        currentlyPaused = false
        pauseResumeBtn.Text = "⏸️"
        pauseResumeBtn.BackgroundColor3 = BTN_COLOR
        isFlipped = false
        rotateBtn.Text = "🔄"
        rotateBtn.BackgroundColor3 = BTN_COLOR
    end

    return {
        mainFrame = bgFrame,
        showUI = showUI,
        hideUI = hideUI,
        resetUIState = resetUIState
    }
end

-- Create UI instance
local pauseRotateUI = createPauseRotateUI()

-- Override stopPlayback to reset UI state
local originalStopPlayback = stopPlayback
stopPlayback = function()
    originalStopPlayback()
    pauseRotateUI.resetUIState()
end

-------------------------------------------------------------
-- TOGGLE
-------------------------------------------------------------
local Toggle = AutoWalkTab:CreateToggle({
    Name = "Pause/Rotate Menu",
    CurrentValue = false,
    Callback = function(Value)
        if Value then
            pauseRotateUI.showUI()
        else
            pauseRotateUI.hideUI()
        end
    end,
})

-- Slider Speed Auto
local SpeedSlider = AutoWalkTab:CreateSlider({
    Name = "⚡ Set Speed",
    Range = {0.5, 1.2},
    Increment = 0.10,
    Suffix = "x Speed",
    CurrentValue = 1.0,
    Callback = function(Value)
        playbackSpeed = Value

        local speedText = "Normal"
        if Value < 1.0 then
            speedText = "Lambat (" .. string.format("%.1f", Value) .. "x)"
        elseif Value > 1.0 then
            speedText = "Cepat (" .. string.format("%.1f", Value) .. "x)"
        else
            speedText = "Normal (" .. Value .. "x)"
        end
    end,
})
-------------------------------------------------------------

-----| MENU 1.5 > AUTO WALK LOOPING |-----
local Section = AutoWalkTab:CreateSection("Auto Walk (Looping)")

local LoopingToggle = AutoWalkTab:CreateToggle({
   Name = "🔄 Enable Looping",
   CurrentValue = false,
   Callback = function(Value)
       loopingEnabled = Value
       if Value then
           Rayfield:Notify({
               Title = "Looping",
               Content = "Fitur looping diaktifkan!",
               Duration = 3,
               Image = "repeat"
           })
       else
           Rayfield:Notify({
               Title = "Looping",
               Content = "Fitur looping dinonaktifkan!",
               Duration = 3,
               Image = "x"
           })
       end
   end,
})

-------------------------------------------------------------

-----| MENU 3 > AUTO WALK (MANUAL) |-----
local Section = AutoWalkTab:CreateSection("Auto Walk (Manual)")

-- Toggle Auto Walk (Spawnpoint)
local SCPToggle = AutoWalkTab:CreateToggle({
    Name = "Auto Walk (Spawnpoint)",
    CurrentValue = false,
    Callback = function(Value)
        if Value then
            playSingleCheckpointFile("spawnpoint.json", 1)
        else
            autoLoopEnabled = false
            isManualMode = false
            stopPlayback()
        end
    end,
})

-- Toggle Auto Walk (Checkpoint 1)
local CP1Toggle = AutoWalkTab:CreateToggle({
    Name = "Auto Walk (Checkpoint 1)",
    CurrentValue = false,
    Callback = function(Value)
        if Value then
            playSingleCheckpointFile("checkpoint_1.json", 2)
        else
            autoLoopEnabled = false
            isManualMode = false
            stopPlayback()
        end
    end,
})

-- Toggle Auto Walk (Checkpoint 2)
local CP2Toggle = AutoWalkTab:CreateToggle({
    Name = "Auto Walk (Checkpoint 2)",
    CurrentValue = false,
    Callback = function(Value)
        if Value then
            playSingleCheckpointFile("checkpoint_2.json", 3)
        else
            autoLoopEnabled = false
            isManualMode = false
            stopPlayback()
        end
    end,
})

-- Toggle Auto Walk (Checkpoint 3)
local CP3Toggle = AutoWalkTab:CreateToggle({
    Name = "Auto Walk (Checkpoint 3)",
    CurrentValue = false,
    Callback = function(Value)
        if Value then
            playSingleCheckpointFile("checkpoint_3.json", 4)
        else
            autoLoopEnabled = false
            isManualMode = false
            stopPlayback()
        end
    end,
})

-- Toggle Auto Walk (Checkpoint 4)
local CP4Toggle = AutoWalkTab:CreateToggle({
    Name = "Auto Walk (Checkpoint 4)",
    CurrentValue = false,
    Callback = function(Value)
        if Value then
            playSingleCheckpointFile("checkpoint_4.json", 5)
        else
            autoLoopEnabled = false
            isManualMode = false
            stopPlayback()
        end
    end,
})

-- Toggle Auto Walk (Checkpoint 5)
local CP5Toggle = AutoWalkTab:CreateToggle({
    Name = "Auto Walk (Checkpoint 5)",
    CurrentValue = false,
    Callback = function(Value)
        if Value then
            playSingleCheckpointFile("checkpoint_5.json", 6)
        else
            autoLoopEnabled = false
            isManualMode = false
            stopPlayback()
        end
    end,
})

-- Toggle Auto Walk (Checkpoint 6)
local CP6Toggle = AutoWalkTab:CreateToggle({
    Name = "Auto Walk (Checkpoint 6)",
    CurrentValue = false,
    Callback = function(Value)
        if Value then
            playSingleCheckpointFile("checkpoint_6.json", 7)
        else
            autoLoopEnabled = false
            isManualMode = false
            stopPlayback()
        end
    end,
})
-------------------------------------------------------------
-- AUTO WALK - END
-------------------------------------------------------------