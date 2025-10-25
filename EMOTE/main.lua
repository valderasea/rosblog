if _G.EmotesGUIRunning then
    getgenv().Notify({
        Title = 'ValL | Emote',
        Content = '⚠️ It works It actually works',
        Duration = 5
    })
    return
end
_G.EmotesGUIRunning = true

loadstring(game:HttpGet("https://raw.githubusercontent.com/7yd7/Menu-7yd7/refs/heads/Script/GUIS/Off-site/Notify.lua"))()

getgenv().Notify({
    Title = 'ValL | Emote',
    Content = '⚠️ Script loading...',
    Duration = 5
})

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")

local emoteClickConnections = {}
local isMonitoringClicks = false
local currentTimer = nil

local currentMode = "emote"
local animationsData = {}
local originalAnimationsData = {}
local filteredAnimations = {}
local favoriteAnimations = {}
local favoriteAnimationsFileName = "FavoriteAnimations.json"

getgenv().lastPlayedAnimation = getgenv().lastPlayedAnimation or nil
getgenv().autoReloadEnabled = getgenv().autoReloadEnabled or false

RunService.Heartbeat:Connect(function()
    if player.Character and player.Character.Humanoid.RigType == Enum.HumanoidRigType.R6 then
        local errorMsg = CoreGui.RobloxGui.EmotesMenu.Children.ErrorMessage
        if errorMsg.Visible then
            errorMsg.ErrorText.Text = "Only r15 does not work r6"
        end
    end
end)

function ErrorMessage(text, duration)

    if currentTimer then
        task.cancel(currentTimer)
        currentTimer = nil
    end
    
    local errorMessage = CoreGui.RobloxGui.EmotesMenu.Children.ErrorMessage
    local errorText = errorMessage.ErrorText
    
    errorText.Text = text
    
    errorMessage.Visible = true
    
    currentTimer = task.delay(duration, function()
        errorMessage.Visible = false
        currentTimer = nil
    end)
end

local function stopEmotes()
    for _, track in ipairs(humanoid:GetPlayingAnimationTracks()) do
        track:Stop()
    end
end

local emotesData = {}
local currentPage = 1
local itemsPerPage = 8
local totalPages = 1
local filteredEmotes = {}
local isLoading = false
local originalEmotesData = {}
local totalEmotesLoaded = 0
local scannedEmotes = {}
local favoriteEmotes = {}
local favoriteEnabled = false
local favoriteFileName = "FavoriteEmotes.json"
local emotesWalkEnabled = false
local currentEmoteTrack = nil
local currentCharacter = nil
local isGUICreated = false
local speedEmoteEnabled = false
local speedEmoteConfigFile = "SpeedEmoteConfig.json"

local Under, UIListLayout, _1left, _9right, _4pages, _3TextLabel, _2Routenumber, Top, EmoteWalkButton, UICorner1,
    UIListLayout_2, UICorner, Search, Favorite, UICorner2, UICorner_2, SpeedEmote, UICorner_4, SpeedBox, UICorner_5, Changepage,
    Reload, UICorner_6

local defaultButtonImage = "rbxassetid://71408678974152"
local enabledButtonImage = "rbxassetid://106798555684020"

local favoriteIconId = "rbxassetid://97307461910825" 
local notFavoriteIconId = "rbxassetid://124025954365505"

local function getCharacterAndHumanoid()
    local character = player.Character
    if not character then
        return nil, nil
    end
    local humanoid = character:FindFirstChild("Humanoid")
    if not humanoid then
        return nil, nil
    end
    return character, humanoid
end

local function checkEmotesMenuExists()
    local coreGui = game:GetService("CoreGui")
    local robloxGui = coreGui:FindFirstChild("RobloxGui")
    if not robloxGui then
        return false
    end

    local emotesMenu = robloxGui:FindFirstChild("EmotesMenu")
    if not emotesMenu then
        return false
    end

    local children = emotesMenu:FindFirstChild("Children")
    if not children then
        return false
    end

    local main = children:FindFirstChild("Main")
    if not main then
        return false
    end

    local emotesWheel = main:FindFirstChild("EmotesWheel")
    if not emotesWheel then
        return false
    end

    return true, emotesWheel
end

local function getBackgroundOverlay()
    local success, result = pcall(function()
        return game:GetService("CoreGui").RobloxGui.EmotesMenu.Children.Main.EmotesWheel.Back.Background
                   .BackgroundCircleOverlay
    end)
    if success then
        return result
    end
    return nil
end

local function updateGUIColors()
    local backgroundOverlay = getBackgroundOverlay()
    if not backgroundOverlay then
        return
    end

    local bgColor = backgroundOverlay.BackgroundColor3
    local bgTransparency = backgroundOverlay.BackgroundTransparency

    if _1left then
        _1left.ImageColor3 = bgColor
        _1left.ImageTransparency = bgTransparency
    end

    if _9right then
        _9right.ImageColor3 = bgColor
        _9right.ImageTransparency = bgTransparency
    end

    if _4pages then
        _4pages.TextColor3 = bgColor
        _4pages.TextTransparency = bgTransparency
    end

    if _3TextLabel then
        _3TextLabel.TextColor3 = bgColor
        _3TextLabel.TextTransparency = bgTransparency
    end

    if _2Routenumber then
        _2Routenumber.TextColor3 = bgColor
        _2Routenumber.TextTransparency = bgTransparency
    end

    if Top then
        Top.BackgroundColor3 = bgColor
        Top.BackgroundTransparency = bgTransparency
    end

    if EmoteWalkButton then
        EmoteWalkButton.BackgroundColor3 = bgColor
        EmoteWalkButton.BackgroundTransparency = bgTransparency
    end

    if SpeedEmote then
        SpeedEmote.BackgroundColor3 = bgColor
        SpeedEmote.BackgroundTransparency = bgTransparency
    end

     if Changepage then
        Changepage.BackgroundColor3 = bgColor
        Changepage.BackgroundTransparency = bgTransparency
    end

    if SpeedBox then
        SpeedBox.BackgroundColor3 = bgColor
        SpeedBox.BackgroundTransparency = bgTransparency
    end

    if Favorite then
        Favorite.BackgroundColor3 = bgColor
        Favorite.BackgroundTransparency = bgTransparency
    end

if Reload then
    Reload.BackgroundColor3 = bgColor
    Reload.BackgroundTransparency = bgTransparency
    Reload.Visible = (currentMode == "animation")
end
end

local function urlToId(animationId)
    animationId = string.gsub(animationId, "http://www%.roblox%.com/asset/%?id=", "")
    animationId = string.gsub(animationId, "rbxassetid://", "")
    return animationId
end

local function saveFavorites()
    if writefile then
        local jsonData = HttpService:JSONEncode(favoriteEmotes)
        writefile(favoriteFileName, jsonData)
    end
end

local function loadFavorites()
    if readfile and isfile and isfile(favoriteFileName) then
        local success, result = pcall(function()
            local fileContent = readfile(favoriteFileName)
            return HttpService:JSONDecode(fileContent)
        end)
        if success and result then
            favoriteEmotes = result
        end
    end
end

local function loadFavoritesAnimations()
    if readfile and isfile and isfile(favoriteAnimationsFileName) then
        local success, result = pcall(function()
            local fileContent = readfile(favoriteAnimationsFileName)
            return HttpService:JSONDecode(fileContent)
        end)
        if success and result then
            favoriteAnimations = result
        end
    end
end

local function loadSpeedEmoteConfig()
    if readfile and isfile and isfile(speedEmoteConfigFile) then
        local success, result = pcall(function()
            local fileContent = readfile(speedEmoteConfigFile)
            return HttpService:JSONDecode(fileContent)
        end)
        if success and result then
            speedEmoteEnabled = result.Enabled or false
            if SpeedBox then
                SpeedBox.Text = tostring(result.SpeedValue or 1)
                SpeedBox.Visible = speedEmoteEnabled
            end
        end
    end
end

local function extractAssetId(imageUrl)
    local assetId = string.match(imageUrl, "Asset&id=(%d+)")
    return assetId
end

local function getEmoteName(assetId)
    local success, productInfo = pcall(function()
        return game:GetService("MarketplaceService"):GetProductInfo(tonumber(assetId))
    end)
    
    if success and productInfo then
        return productInfo.Name
    else
        return "Emote_" .. tostring(assetId)
    end
end

local function isInFavorites(emoteId)
    for _, favorite in pairs(favoriteEmotes) do
        if favorite.id == tostring(emoteId) then
            return true
        end
    end
    return false
end

local function updateAnimationImages(currentPageAnimations)
    local success, frontFrame = pcall(function()
        return game:GetService("CoreGui").RobloxGui.EmotesMenu.Children.Main.EmotesWheel.Front.EmotesButtons
    end)
    
    if not success or not frontFrame then
        return
    end
    
    local buttonIndex = 1
    for _, child in pairs(frontFrame:GetChildren()) do
        if child:IsA("ImageLabel") and buttonIndex <= #currentPageAnimations then
            local animationData = currentPageAnimations[buttonIndex]
            child.Image = "rbxthumb://type=BundleThumbnail&id=" .. animationData.id .. "&w=420&h=420"
            buttonIndex = buttonIndex + 1
        elseif child:IsA("ImageLabel") then
            child.Image = ""
        end
    end
end

local function updateAnimations()
    local character, humanoid = getCharacterAndHumanoid()
    if not character or not humanoid then
        return
    end

    local humanoidDescription = humanoid.HumanoidDescription
    if not humanoidDescription then
        return
    end

    local currentPageAnimations = {}
    local animationTable = {}
    local equippedAnimations = {}

    local favoritesToUse = _G.filteredFavoritesAnimationsForDisplay or favoriteAnimations
    local hasFavorites = #favoritesToUse > 0
    local favoritePagesCount = hasFavorites and math.ceil(#favoritesToUse / itemsPerPage) or 0
    local isInFavoritesPages = currentPage <= favoritePagesCount

    if isInFavoritesPages and hasFavorites then
        local startIndex = (currentPage - 1) * itemsPerPage + 1
        local endIndex = math.min(startIndex + itemsPerPage - 1, #favoritesToUse)

        for i = startIndex, endIndex do
            if favoritesToUse[i] then
                table.insert(currentPageAnimations, {
                    id = tonumber(favoritesToUse[i].id),
                    name = favoritesToUse[i].name
                })
            end
        end
    else
        local normalAnimations = {}
        for _, animation in pairs(filteredAnimations) do
            if not isInFavorites(animation.id) then
                table.insert(normalAnimations, animation)
            end
        end

        local adjustedPage = currentPage - favoritePagesCount
        local startIndex = (adjustedPage - 1) * itemsPerPage + 1
        local endIndex = math.min(startIndex + itemsPerPage - 1, #normalAnimations)

        for i = startIndex, endIndex do
            if normalAnimations[i] then
                table.insert(currentPageAnimations, normalAnimations[i])
            end
        end
    end

    for _, animation in pairs(currentPageAnimations) do
        local animationName = animation.name
        local animationId = animation.id
        animationTable[animationName] = {animationId}
        table.insert(equippedAnimations, animationName)
    end

    humanoidDescription:SetEmotes(animationTable)
    humanoidDescription:SetEquippedEmotes(equippedAnimations)
    
    task.wait(0.1)
    updateAnimationImages(currentPageAnimations)
end

local function updateEmotes()
    local character, humanoid = getCharacterAndHumanoid()
    if not character or not humanoid then
        return
    end

    if currentMode == "animation" then
        updateAnimations()
        return
    end

    local humanoidDescription = humanoid.HumanoidDescription
    if not humanoidDescription then
        return
    end

    local currentPageEmotes = {}
    local emoteTable = {}
    local equippedEmotes = {}

    local favoritesToUse = _G.filteredFavoritesForDisplay or favoriteEmotes
    local hasFavorites = #favoritesToUse > 0
    local favoritePagesCount = hasFavorites and math.ceil(#favoritesToUse / itemsPerPage) or 0
    local isInFavoritesPages = currentPage <= favoritePagesCount

    if isInFavoritesPages and hasFavorites then
        local startIndex = (currentPage - 1) * itemsPerPage + 1
        local endIndex = math.min(startIndex + itemsPerPage - 1, #favoritesToUse)

        for i = startIndex, endIndex do
            if favoritesToUse[i] then
                table.insert(currentPageEmotes, {
                    id = tonumber(favoritesToUse[i].id),
                    name = favoritesToUse[i].name
                })
            end
        end
    else
        local normalEmotes = {}
        for _, emote in pairs(filteredEmotes) do
            if not isInFavorites(emote.id) then
                table.insert(normalEmotes, emote)
            end
        end

        local adjustedPage = currentPage - favoritePagesCount
        local startIndex = (adjustedPage - 1) * itemsPerPage + 1
        local endIndex = math.min(startIndex + itemsPerPage - 1, #normalEmotes)

        for i = startIndex, endIndex do
            if normalEmotes[i] then
                table.insert(currentPageEmotes, normalEmotes[i])
            end
        end
    end

    for _, emote in pairs(currentPageEmotes) do
        local emoteName = emote.name
        local emoteId = emote.id
        emoteTable[emoteName] = {emoteId}
        table.insert(equippedEmotes, emoteName)
    end

    humanoidDescription:SetEmotes(emoteTable)
    humanoidDescription:SetEquippedEmotes(equippedEmotes)
end

local function calculateTotalPages()
      if currentMode == "animation" then
        local favoritesToUse = _G.filteredFavoritesAnimationsForDisplay or favoriteAnimations
        local hasFavorites = #favoritesToUse > 0
        local normalAnimationsCount = 0

        for _, animation in pairs(filteredAnimations) do
            if not isInFavorites(animation.id) then
                normalAnimationsCount = normalAnimationsCount + 1
            end
        end

        local pages = 0
        if hasFavorites then
            pages = pages + math.ceil(#favoritesToUse / itemsPerPage)
        end
        if normalAnimationsCount > 0 then
            pages = pages + math.ceil(normalAnimationsCount / itemsPerPage)
        end
        return math.max(pages, 1)
    end
    
    local favoritesToUse = _G.filteredFavoritesForDisplay or favoriteEmotes
    local hasFavorites = #favoritesToUse > 0
    local normalEmotesCount = 0

    for _, emote in pairs(filteredEmotes) do
        if not isInFavorites(emote.id) then
            normalEmotesCount = normalEmotesCount + 1
        end
    end

    local pages = 0

    if hasFavorites then
        pages = pages + math.ceil(#favoritesToUse / itemsPerPage)
    end

    if normalEmotesCount > 0 then
        pages = pages + math.ceil(normalEmotesCount / itemsPerPage)
    end

    return math.max(pages, 1)
end

local function isGivenAnimation(animationHolder, animationId)
    for _, animation in animationHolder:GetChildren() do
        if animation:IsA("Animation") and urlToId(animation.AnimationId) == animationId then
            return true
        end
    end
    return false
end

local function isDancing(character, animationTrack)
    local animationId = urlToId(animationTrack.Animation.AnimationId)
    for _, animationHolder in character.Animate:GetChildren() do
        if animationHolder:IsA("StringValue") then
            local sharesAnimationId = isGivenAnimation(animationHolder, animationId)
            if sharesAnimationId then
                return false
            end
        end
    end
    return true
end

local function createGUIElements()
    local exists, emotesWheel = checkEmotesMenuExists()
    if not exists then
        return false
    end

    if emotesWheel:FindFirstChild("Under") then
        emotesWheel.Under:Destroy()
    end
    if emotesWheel:FindFirstChild("Top") then
        emotesWheel.Top:Destroy()
    end
    if emotesWheel:FindFirstChild("EmoteWalkButton") then
        emotesWheel.EmoteWalkButton:Destroy()
    end
    if emotesWheel:FindFirstChild("Favorite") then
        emotesWheel.Favorite:Destroy()
    end
    if emotesWheel:FindFirstChild("SpeedEmote") then
        emotesWheel.SpeedEmote:Destroy()
    end
    if emotesWheel:FindFirstChild("Changepage") then
        emotesWheel.Changepage:Destroy()
    end
    if emotesWheel:FindFirstChild("SpeedBox") then
        emotesWheel.SpeedBox:Destroy()
    end
    if emotesWheel:FindFirstChild("Reload") then
        emotesWheel.Reload:Destroy()
    end

    Under = Instance.new("Frame")
    UIListLayout = Instance.new("UIListLayout")
    _1left = Instance.new("ImageButton")
    _9right = Instance.new("ImageButton")
    _4pages = Instance.new("TextLabel")
    _3TextLabel = Instance.new("TextLabel")
    _2Routenumber = Instance.new("TextBox")
    EmoteWalkButton = Instance.new("ImageButton")
    UICorner1 = Instance.new("UICorner")
    Top = Instance.new("Frame")
    UIListLayout_2 = Instance.new("UIListLayout")
    UICorner = Instance.new("UICorner")
    Search = Instance.new("TextBox")
    Favorite = Instance.new("ImageButton")
    UICorner2 = Instance.new("UICorner")
    SpeedBox = Instance.new("TextBox")
    UICorner_4 = Instance.new("UICorner")
    SpeedEmote = Instance.new("ImageButton")
    UICorner_2 = Instance.new("UICorner")
    Changepage = Instance.new("ImageButton")
     UICorner_5 = Instance.new("UICorner")
     Reload = Instance.new("ImageButton")
     UICorner_6 = Instance.new("UICorner")

    Under.Name = "Under"
    Under.Parent = emotesWheel
    Under.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Under.BackgroundTransparency = 1.000
    Under.BorderColor3 = Color3.fromRGB(0, 0, 0)
    Under.BorderSizePixel = 0
    Under.Position = UDim2.new(0.129999995, 0, 1, 0)
    Under.Size = UDim2.new(0.737500012, 0, 0.132499993, 0)

    UIListLayout.Parent = Under
    UIListLayout.FillDirection = Enum.FillDirection.Horizontal
    UIListLayout.VerticalAlignment = Enum.VerticalAlignment.Center

    _1left.Name = "1left"
    _1left.Parent = Under
    _1left.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    _1left.BackgroundTransparency = 1.000
    _1left.BorderColor3 = Color3.fromRGB(0, 0, 0)
    _1left.BorderSizePixel = 0
    _1left.Position = UDim2.new(0.0289389063, 0, -0.0849056691, 0)
    _1left.Rotation = 7456.000
    _1left.Size = UDim2.new(0.169491529, 0, 0.94339627, 0)
    _1left.Image = "rbxassetid://93111945058621"
    _1left.ImageColor3 = Color3.fromRGB(0, 0, 0)
    _1left.ImageTransparency = 0.400

    _9right.Name = "9right"
    _9right.Parent = Under
    _9right.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    _9right.BackgroundTransparency = 1.000
    _9right.BorderColor3 = Color3.fromRGB(0, 0, 0)
    _9right.BorderSizePixel = 0
    _9right.Position = UDim2.new(0.0289389063, 0, -0.0849056691, 0)
    _9right.Rotation = 7456.000
    _9right.Size = UDim2.new(0.169491529, 0, 0.94339627, 0)
    _9right.Image = "rbxassetid://107938916240738"
    _9right.ImageColor3 = Color3.fromRGB(0, 0, 0)
    _9right.ImageTransparency = 0.400

    _4pages.Name = "4pages"
    _4pages.Parent = Under
    _4pages.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    _4pages.BackgroundTransparency = 1.000
    _4pages.BorderColor3 = Color3.fromRGB(0, 0, 0)
    _4pages.BorderSizePixel = 0
    _4pages.Position = UDim2.new(0.630225062, 0, 0.188679263, 0)
    _4pages.Size = UDim2.new(0.159322038, 0, 0.811320841, 0)
    _4pages.Font = Enum.Font.SourceSansBold
    _4pages.Text = "1"
    _4pages.TextColor3 = Color3.fromRGB(0, 0, 0)
    _4pages.TextScaled = true
    _4pages.TextSize = 14.000
    _4pages.TextTransparency = 0.400
    _4pages.TextWrapped = true

    _3TextLabel.Name = "3TextLabel"
    _3TextLabel.Parent = Under
    _3TextLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    _3TextLabel.BackgroundTransparency = 1.000
    _3TextLabel.BorderColor3 = Color3.fromRGB(0, 0, 0)
    _3TextLabel.BorderSizePixel = 0
    _3TextLabel.Position = UDim2.new(0.363344043, 0, 0.0283018891, 0)
    _3TextLabel.Size = UDim2.new(0.338983059, 0, 0.94339627, 0)
    _3TextLabel.Font = Enum.Font.SourceSansBold
    _3TextLabel.Text = " ------ "
    _3TextLabel.TextColor3 = Color3.fromRGB(0, 0, 0)
    _3TextLabel.TextScaled = true
    _3TextLabel.TextSize = 14.000
    _3TextLabel.TextTransparency = 0.400
    _3TextLabel.TextWrapped = true

    _2Routenumber.Name = "2Route-number"
    _2Routenumber.Parent = Under
    _2Routenumber.Active = true
    _2Routenumber.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    _2Routenumber.BackgroundTransparency = 1.000
    _2Routenumber.BorderColor3 = Color3.fromRGB(0, 0, 0)
    _2Routenumber.BorderSizePixel = 0
    _2Routenumber.Position = UDim2.new(0.138263673, 0, 0.0283018891, 0)
    _2Routenumber.Selectable = true
    _2Routenumber.Size = UDim2.new(0.159322038, 0, 0.811320841, 0)
    _2Routenumber.Font = Enum.Font.SourceSansBold
    _2Routenumber.PlaceholderColor3 = Color3.fromRGB(0, 0, 0)
    _2Routenumber.Text = "1"
    _2Routenumber.TextColor3 = Color3.fromRGB(0, 0, 0)
    _2Routenumber.TextScaled = true
    _2Routenumber.TextSize = 14.000
    _2Routenumber.TextStrokeColor3 = Color3.fromRGB(255, 255, 255)
    _2Routenumber.TextTransparency = 0.400
    _2Routenumber.TextWrapped = true

    Top.Name = "Top"
    Top.Parent = emotesWheel
    Top.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    Top.BackgroundTransparency = 0.400
    Top.BorderColor3 = Color3.fromRGB(0, 0, 0)
    Top.BorderSizePixel = 0
    Top.Position = UDim2.new(0.127499998, 0, -0.109999999, 0)
    Top.Size = UDim2.new(0.737500012, 0, 0.0949999914, 0)

    UIListLayout_2.Parent = Top
    UIListLayout_2.FillDirection = Enum.FillDirection.Horizontal
    UIListLayout_2.HorizontalAlignment = Enum.HorizontalAlignment.Center
    UIListLayout_2.SortOrder = Enum.SortOrder.LayoutOrder
    UIListLayout_2.VerticalAlignment = Enum.VerticalAlignment.Center

    UICorner.CornerRadius = UDim.new(0, 20)
    UICorner.Parent = Top

    Search.Name = "Search"
    Search.Parent = Top
    Search.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Search.BackgroundTransparency = 1.000
    Search.BorderColor3 = Color3.fromRGB(0, 0, 0)
    Search.Position = UDim2.new(0.0677966103, 0, 0)
    Search.Size = UDim2.new(0.864406765, 0, 0.81578958, 0)
    Search.Font = Enum.Font.SourceSansBold
    Search.PlaceholderText = "Search/ID"
    Search.Text = ""
    Search.TextColor3 = Color3.fromRGB(255, 255, 255)
    Search.TextScaled = true
    Search.TextSize = 14.000
    Search.TextWrapped = true

    EmoteWalkButton.Name = "EmoteWalkButton"
    EmoteWalkButton.Parent = emotesWheel
    EmoteWalkButton.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    EmoteWalkButton.BackgroundTransparency = 0.400
    EmoteWalkButton.BorderColor3 = Color3.fromRGB(0, 0, 0)
    EmoteWalkButton.BorderSizePixel = 0
    EmoteWalkButton.Position = UDim2.new(0.889999986, 0, -0.107500002, 0)
    EmoteWalkButton.Size = UDim2.new(0.0874999985, 0, 0.0874999985, 0)
    EmoteWalkButton.Image = defaultButtonImage

    UICorner1.CornerRadius = UDim.new(0, 10)
    UICorner1.Parent = EmoteWalkButton

    Favorite.Name = "Favorite"
    Favorite.Parent = emotesWheel
    Favorite.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    Favorite.BackgroundTransparency = 0.400
    Favorite.BorderColor3 = Color3.fromRGB(0, 0, 0)
    Favorite.BorderSizePixel = 0
    Favorite.Position = UDim2.new(0.0189999994, 0, -0.108000003, 0)
    Favorite.Size = UDim2.new(0.0874999985, 0, 0.0874999985, 0)
    Favorite.Image = "rbxassetid://124025954365505"

    UICorner2.CornerRadius = UDim.new(0, 10)
    UICorner2.Parent = Favorite

    SpeedBox.Name = "SpeedBox"
    SpeedBox.Parent = emotesWheel
    SpeedBox.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    SpeedBox.BackgroundTransparency = 0.400
    SpeedBox.BorderColor3 = Color3.fromRGB(0, 0, 0)
    SpeedBox.BorderSizePixel = 0
    SpeedBox.Position = UDim2.new(0.0189999398, 0, -0.000499992399, 0)
    SpeedBox.Size = UDim2.new(0.0874999985, 0, 0.0874999985, 0)
    SpeedBox.Visible = false
    SpeedBox.Font = Enum.Font.SourceSansBold
    SpeedBox.PlaceholderColor3 = Color3.fromRGB(178, 178, 178)
    SpeedBox.Text = "1"
    SpeedBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    SpeedBox.TextScaled = true
    SpeedBox.TextWrapped = true
    SpeedBox:GetPropertyChangedSignal("Text"):Connect(function()
       SpeedBox.Text = SpeedBox.Text:gsub("[^%d.]", "")
    end)
    SpeedBox.ZIndex = 2

    UICorner_4.CornerRadius = UDim.new(0, 10)
    UICorner_4.Parent = SpeedBox

    SpeedEmote.Name = "SpeedEmote"
    SpeedEmote.Parent = emotesWheel
    SpeedEmote.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    SpeedEmote.BackgroundTransparency = 0.400
    SpeedEmote.BorderColor3 = Color3.fromRGB(0, 0, 0)
    SpeedEmote.BorderSizePixel = 0
    SpeedEmote.Position = UDim2.new(0.888999999, 0, -0, 0)
    SpeedEmote.Size = UDim2.new(0.0874999985, 0, 0.0874999985, 0)
    SpeedEmote.Image = "rbxassetid://116056570415896"
    SpeedEmote.ZIndex = 2

    UICorner_2.CornerRadius = UDim.new(0, 10)
    UICorner_2.Parent = SpeedEmote

Changepage.Name = "Changepage"
Changepage.Parent = emotesWheel
Changepage.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
Changepage.BackgroundTransparency = 0.400
Changepage.BorderColor3 = Color3.fromRGB(0, 0, 0)
Changepage.BorderSizePixel = 0
Changepage.Position = UDim2.new(0.019, 0,1.021, 0)
Changepage.Size = UDim2.new(0.087, 0,0.087, 0)
Changepage.ZIndex = 3
Changepage.Image = "rbxassetid://13285615740"

UICorner_5.CornerRadius = UDim.new(0, 10)
UICorner_5.Parent = Changepage

Reload.Name = "Reload"
Reload.Parent = emotesWheel
Reload.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
Reload.BackgroundTransparency = 0.400
Reload.BorderColor3 = Color3.fromRGB(0, 0, 0)
Reload.BorderSizePixel = 0
Reload.Position = UDim2.new(0.888999999, 0, 1.02100003, 0)
Reload.Size = UDim2.new(0.0869999975, 0, 0.0869999975, 0)
Reload.ZIndex = 3
Reload.Image = "rbxassetid://127493377027615"

UICorner_6.CornerRadius = UDim.new(0, 10)
UICorner_6.Parent = Reload

    loadSpeedEmoteConfig()

    connectEvents()
    isGUICreated = true
    updateGUIColors()
    return true
end

local function updatePageDisplay()
    if _4pages and _2Routenumber then
        _4pages.Text = tostring(totalPages)
        _2Routenumber.Text = tostring(currentPage)
    end
end

local function updateFavoriteIcon(imageLabel, assetId, isFavorite)
    local favoriteIcon = imageLabel:FindFirstChild("FavoriteIcon")
    
    if not favoriteIcon then
        favoriteIcon = Instance.new("ImageLabel")
        favoriteIcon.Name = "FavoriteIcon"
        favoriteIcon.Size = UDim2.new(0.3, 0, 0.3, 0) 
        favoriteIcon.Position = UDim2.new(0.7, 0, 0, 0)
        favoriteIcon.AnchorPoint = Vector2.new(0, 0)
        favoriteIcon.BackgroundTransparency = 1
        favoriteIcon.ZIndex = imageLabel.ZIndex + 5
        favoriteIcon.ScaleType = Enum.ScaleType.Fit
        favoriteIcon.Parent = imageLabel
    end
    
    if isFavorite then
        favoriteIcon.Image = favoriteIconId
    else
        favoriteIcon.Image = notFavoriteIconId 
    end
end

local function updateAllFavoriteIcons()
    local success, frontFrame = pcall(function()
        return game:GetService("CoreGui").RobloxGui.EmotesMenu.Children.Main.EmotesWheel.Front.EmotesButtons
    end)
    
    if success and frontFrame then
        for _, child in pairs(frontFrame:GetChildren()) do
            if child:IsA("ImageLabel") and child.Image ~= "" then
                local imageUrl = child.Image
                local assetId = extractAssetId(imageUrl)
                
                if assetId then
                    local isFavorite = isInFavorites(assetId)
                    updateFavoriteIcon(child, assetId, isFavorite)
                end
            end
        end
    end
end


local function toggleFavorite(emoteId, emoteName)
    local found = false
    local index = 0

    for i, fav in pairs(favoriteEmotes) do
        if fav.id == emoteId then
            found = true
            index = i
            break
        end
    end

    if found then
        table.remove(favoriteEmotes, index)
        getgenv().Notify({
            Title = 'ValL | Favorite System',
            Content = '🚮 Removed "' .. emoteName .. '" from favorites',
            Duration = 3
        })
    else
        table.insert(favoriteEmotes, {
            id = emoteId,
            name = emoteName .. " - ⭐"
        })
        getgenv().Notify({
            Title = 'ValL | Favorite System',
            Content = '✅ Added "' .. emoteName .. '" to favorites',
            Duration = 3
        })
    end

    saveFavorites()
    totalPages = calculateTotalPages()
    updatePageDisplay()
    updateEmotes()
    
    updateAllFavoriteIcons()
end

local function setupEmoteClickDetection()
    if isMonitoringClicks then
        return
    end
   
    local function monitorEmotes()
        while favoriteEnabled do
            local success, frontFrame = pcall(function()
                return game:GetService("CoreGui").RobloxGui.EmotesMenu.Children.Main.EmotesWheel.Front.EmotesButtons
            end)
           
            if success and frontFrame then
                for _, connection in pairs(emoteClickConnections) do
                    if connection then
                        connection:Disconnect()
                    end
                end
                emoteClickConnections = {}
               
                for _, child in pairs(frontFrame:GetChildren()) do
                    if child:IsA("ImageLabel") and child.Image ~= "" then
                        local clickDetector = child:FindFirstChild("ClickDetector") or Instance.new("TextButton")
                        clickDetector.Name = "ClickDetector"
                        clickDetector.Size = UDim2.new(1, 0, 1, 0)
                        clickDetector.Position = UDim2.new(0, 0, 0, 0)
                        clickDetector.BackgroundTransparency = 1
                        clickDetector.Text = ""
                        clickDetector.ZIndex = child.ZIndex + 1
                        clickDetector.Parent = child
                        
                        local imageUrl = child.Image
                        local assetId = extractAssetId(imageUrl)
                        if assetId then
                            local isFavorite = isInFavorites(assetId)
                            updateFavoriteIcon(child, assetId, isFavorite)
                        end
                       
                        local connection = clickDetector.MouseButton1Click:Connect(function()
                            if favoriteEnabled then
                                if assetId then
                                    local emoteName = getEmoteName(assetId)
                                    toggleFavorite(assetId, emoteName)
                                end
                            end
                        end)
                       
                        table.insert(emoteClickConnections, connection)
                    end
                end
            end
           
            task.wait(0.1)
        end
       
        for _, connection in pairs(emoteClickConnections) do
            if connection then
                connection:Disconnect()
            end
        end
        emoteClickConnections = {}
        isMonitoringClicks = false
    end
   
    if favoriteEnabled then
        isMonitoringClicks = true
        task.spawn(monitorEmotes)
    end
end

local function applyAnimation(animationData)
    local player = game.Players.LocalPlayer
    local character = player.Character or player.CharacterAdded:Wait()
    local humanoid = character:FindFirstChild("Humanoid")
    local animate = character:FindFirstChild("Animate")
    
    if not animate or not humanoid then
        getgenv().Notify({
            Title = 'ValL | Animation Error',
            Content = '❌ Animate or Humanoid not found',
            Duration = 3
        })
        return
    end
    
    local bundleId = animationData.id
    local bundledItems = animationData.bundledItems

    getgenv().lastPlayedAnimation = animationData
    
    if not bundledItems then
        getgenv().Notify({
            Title = 'ValL | Animation Error', 
            Content = '❌ No bundled items found',
            Duration = 3
        })
        return
    end
    
    for _, track in pairs(humanoid:GetPlayingAnimationTracks()) do
        track:Stop()
    end
    
    for key, assetIds in pairs(bundledItems) do
        for _, assetId in pairs(assetIds) do
            spawn(function()
                local success, objects = pcall(function()
                    return game:GetObjects("rbxassetid://" .. assetId)
                end)
                
                if success and objects then
                    local function searchForAnimations(parent, parentPath)
                        for _, child in pairs(parent:GetChildren()) do
                            if child:IsA("Animation") then
                                local animationPath = parentPath .. "." .. child.Name
                                local pathParts = animationPath:split(".")
                                
                                if #pathParts >= 2 then
                                    local animateCategory = pathParts[#pathParts - 1]
                                    local animationName = pathParts[#pathParts]
                                    
                                    if animate:FindFirstChild(animateCategory) then
                                        local categoryFolder = animate[animateCategory]
                                        if categoryFolder:FindFirstChild(animationName) then
                                            categoryFolder[animationName].AnimationId = child.AnimationId
                                            
                                            task.wait(0.1)
                                            local animation = Instance.new("Animation")
                                            animation.AnimationId = child.AnimationId
                                            
                                            local animTrack = humanoid.Animator:LoadAnimation(animation)
                                            animTrack.Priority = Enum.AnimationPriority.Action
                                            animTrack:Play()
                                            
                                            task.wait(0.1)
                                            animTrack:Stop()
                                        end
                                    end
                                end
                            elseif #child:GetChildren() > 0 then
                                searchForAnimations(child, parentPath .. "." .. child.Name)
                            end
                        end
                    end
                    
                    for _, obj in pairs(objects) do
                        searchForAnimations(obj, obj.Name)
                        obj.Parent = workspace
                        task.delay(1, function()
                            if obj then obj:Destroy() end
                        end)
                    end
                end
            end)
        end
    end
    
    task.wait(.2)
    spawn(function()
        local humanoidDescription = humanoid:FindFirstChild("HumanoidDescription")
        if humanoidDescription then
            humanoid:ApplyDescription(humanoidDescription)
        end
    end)
end


local function monitorAnimations()
    while currentMode == "animation" do
        local success, frontFrame = pcall(function()
            return game:GetService("CoreGui").RobloxGui.EmotesMenu.Children.Main.EmotesWheel.Front.EmotesButtons
        end)
        
        if success and frontFrame then
            for _, connection in pairs(emoteClickConnections) do
                if connection then
                    connection:Disconnect()
                end
            end
            emoteClickConnections = {}
            
            local favoritesToUse = _G.filteredFavoritesAnimationsForDisplay or favoriteAnimations
            local hasFavorites = #favoritesToUse > 0
            local favoritePagesCount = hasFavorites and math.ceil(#favoritesToUse / itemsPerPage) or 0
            local isInFavoritesPages = currentPage <= favoritePagesCount
            
            local currentPageAnimations = {}
            
            if isInFavoritesPages and hasFavorites then
                local startIndex = (currentPage - 1) * itemsPerPage + 1
                local endIndex = math.min(startIndex + itemsPerPage - 1, #favoritesToUse)
                
                for i = startIndex, endIndex do
                    if favoritesToUse[i] then
                        table.insert(currentPageAnimations, favoritesToUse[i])
                    end
                end
            else
                local normalAnimations = {}
                for _, animation in pairs(filteredAnimations) do
                    if not isInFavorites(animation.id) then
                        table.insert(normalAnimations, animation)
                    end
                end
                
                local adjustedPage = currentPage - favoritePagesCount
                local startIndex = (adjustedPage - 1) * itemsPerPage + 1
                local endIndex = math.min(startIndex + itemsPerPage - 1, #normalAnimations)
                
                for i = startIndex, endIndex do
                    if normalAnimations[i] then
                        table.insert(currentPageAnimations, normalAnimations[i])
                    end
                end
            end
            
            local buttonIndex = 1
            for _, child in pairs(frontFrame:GetChildren()) do
                if child:IsA("ImageLabel") and buttonIndex <= #currentPageAnimations then
                    local clickDetector = child:FindFirstChild("ClickDetector") or Instance.new("TextButton")
                    clickDetector.Name = "ClickDetector"
                    clickDetector.Size = UDim2.new(1, 0, 1, 0)
                    clickDetector.Position = UDim2.new(0, 0, 0, 0)
                    clickDetector.BackgroundTransparency = 1
                    clickDetector.Text = ""
                    clickDetector.ZIndex = child.ZIndex + 1
                    clickDetector.Parent = child
                    
                    local animationData = currentPageAnimations[buttonIndex]
                    
                    local connection = clickDetector.MouseButton1Click:Connect(function()
                        applyAnimation(animationData)
                    end)
                    
                    table.insert(emoteClickConnections, connection)
                    buttonIndex = buttonIndex + 1
                end
            end
        end
        
        task.wait(0.1)
    end
end

local function stopEmoteClickDetection()
    isMonitoringClicks = false
    
    for _, connection in pairs(emoteClickConnections) do
        if connection then
            connection:Disconnect()
        end
    end
    emoteClickConnections = {}
    
    local success, frontFrame = pcall(function()
        return game:GetService("CoreGui").RobloxGui.EmotesMenu.Children.Main.EmotesWheel.Front.EmotesButtons
    end)
    
    if success and frontFrame then
        for _, child in pairs(frontFrame:GetChildren()) do
            if child:IsA("ImageLabel") then
                local clickDetector = child:FindFirstChild("ClickDetector")
                if clickDetector then
                    clickDetector:Destroy()
                end
                
                local favoriteIcon = child:FindFirstChild("FavoriteIcon")
                if favoriteIcon then
                    favoriteIcon:Destroy()
                end
            end
        end
    end
end


local function fetchAllEmotes()
    if isLoading then
        return
    end
    isLoading = true
    emotesData = {}
    totalEmotesLoaded = 0

    local success, result = pcall(function()
        local jsonContent = game:HttpGet("https://raw.githubusercontent.com/7yd7/sniper-Emote/refs/heads/test/EmoteSniper.json")
        
        if jsonContent and jsonContent ~= "" then
            local data = HttpService:JSONDecode(jsonContent)
            return data.data or {}
        else
            return nil
        end
    end)

    if success and result then
        for _, item in pairs(result) do
            local emoteData = {
                id = tonumber(item.id),
                name = item.name or ("Emote_" .. (item.id or "Unknown"))
            }
            if emoteData.id and emoteData.id > 0 then
                table.insert(emotesData, emoteData)
                totalEmotesLoaded = totalEmotesLoaded + 1
            end
        end
    else
        emotesData = {
            {id = 3360686498, name = "Stadium"},
            {id = 3360692915, name = "Tilt"},
            {id = 3576968026, name = "Shrug"},
            {id = 3360689775, name = "Salute"}
        }
        totalEmotesLoaded = #emotesData
    end

    originalEmotesData = emotesData
    filteredEmotes = emotesData

    totalPages = calculateTotalPages()
    currentPage = 1
    updatePageDisplay()
    updateEmotes()
    
    getgenv().Notify({
        Title = 'ValL | Emote',
        Content = "✅ Loaded Successfully! Total Emotes: " .. totalEmotesLoaded,
        Duration = 5
    })
    
    isLoading = false
end

local function fetchAllAnimations()
    if isLoading then
        return
    end
    isLoading = true
    animationsData = {}
    
    local success, result = pcall(function()
        local jsonContent = game:HttpGet("https://raw.githubusercontent.com/7yd7/sniper-Emote/refs/heads/test/AnimationSniper.json")
        
        if jsonContent and jsonContent ~= "" then
            local data = HttpService:JSONDecode(jsonContent)
            return data.data or {}
        else
            return nil
        end
    end)

    if success and result then
        for _, item in pairs(result) do
            local animationData = {
                id = tonumber(item.id),
                name = item.name or ("Animation_" .. (item.id or "Unknown")),
                bundledItems = item.bundledItems
            }
            if animationData.id and animationData.id > 0 then
                table.insert(animationsData, animationData)
            end
        end
    end

    originalAnimationsData = animationsData
    filteredAnimations = animationsData
    isLoading = false
end

local function searchEmotes(searchTerm)
    if isLoading then
        getgenv().Notify({
            Title = 'ValL | Emote',
            Content = '⌛ Loading please wait...',
            Duration = 5
        })
        return
    end

    searchTerm = searchTerm:lower()

    if searchTerm == "" then
        filteredEmotes = originalEmotesData
        if _G.originalFavoritesBackup then
            _G.originalFavoritesBackup = nil
        end
        _G.filteredFavoritesForDisplay = nil
    else
        local isIdSearch = searchTerm:match("^%d%d%d%d%d+$")
        
        local newFilteredList = {}
        
        if isIdSearch then
            for _, emote in pairs(originalEmotesData) do
                if tostring(emote.id) == searchTerm then
                    table.insert(newFilteredList, emote)
                end
            end
            
            if #newFilteredList == 0 then
                local emoteId = tonumber(searchTerm)
                if emoteId then
                    local emoteName = getEmoteName(emoteId)
                    local newEmote = {
                        id = emoteId,
                        name = emoteName
                    }
                    
                    table.insert(originalEmotesData, newEmote)
                    table.insert(newFilteredList, newEmote)
                end
            end
        else
            for _, emote in pairs(originalEmotesData) do
                if emote.name:lower():find(searchTerm) then
                    table.insert(newFilteredList, emote)
                end
            end
        end
        
        filteredEmotes = newFilteredList

        if not isIdSearch then
            if not _G.originalFavoritesBackup then
                _G.originalFavoritesBackup = {}
                for i, favorite in pairs(favoriteEmotes) do
                    _G.originalFavoritesBackup[i] = {
                        id = favorite.id,
                        name = favorite.name
                    }
                end
            end

            _G.filteredFavoritesForDisplay = {}
            for _, favorite in pairs(favoriteEmotes) do
                if favorite.name:lower():find(searchTerm) then
                    table.insert(_G.filteredFavoritesForDisplay, favorite)
                end
            end
        end
    end

    totalPages = calculateTotalPages()
    currentPage = 1
    updatePageDisplay()
    updateEmotes()
end

local function goToPage(pageNumber)
    if pageNumber < 1 then
        currentPage = 1
    elseif pageNumber > totalPages then
        currentPage = totalPages
    else
        currentPage = pageNumber
    end
    updatePageDisplay()
    updateEmotes()
end

local function previousPage()
    if currentPage <= 1 then
        currentPage = totalPages
    else
        currentPage = currentPage - 1
    end
    updatePageDisplay()
    updateEmotes()
end

local function nextPage()
    if currentPage >= totalPages then
        currentPage = 1
    else
        currentPage = currentPage + 1
    end
    updatePageDisplay()
    updateEmotes()
end

local function stopCurrentEmote()
    if currentEmoteTrack then
        currentEmoteTrack:Stop()
        currentEmoteTrack = nil
    end
end

local function playEmote(humanoid, emoteId)
    stopCurrentEmote()
    stopEmotes()

    local animation = Instance.new("Animation")
    animation.AnimationId = "rbxassetid://" .. emoteId

    local success, animTrack = pcall(function()
        return humanoid.Animator:LoadAnimation(animation)
    end)

    if success and animTrack then
        currentEmoteTrack = animTrack
        currentEmoteTrack.Priority = Enum.AnimationPriority.Action
        currentEmoteTrack.Looped = true
        task.wait(0.1)
        if speedEmoteEnabled or emotesWalkEnabled then
            currentEmoteTrack:Play()

            if speedEmoteEnabled then
                local speedValue = tonumber(SpeedBox.Text) or 1
                currentEmoteTrack:AdjustSpeed(speedValue)
            end
        end
    end
end

local function onCharacterAdded(character)
    currentCharacter = character
    stopCurrentEmote()

    local humanoid = character:WaitForChild("Humanoid")
    local animator = humanoid:WaitForChild("Animator")

 if getgenv().autoReloadEnabled and getgenv().lastPlayedAnimation then
    task.wait(.3)
    applyAnimation(getgenv().lastPlayedAnimation)
    getgenv().Notify({
        Title = 'ValL | Auto Reload Animation',
        Content = '🔄 The last animation was automatically \n reapplied',
        Duration = 3
    })
end

    animator.AnimationPlayed:Connect(function(animationTrack)
        if isDancing(character, animationTrack) then
            local playedEmoteId = urlToId(animationTrack.Animation.AnimationId)

            if emotesWalkEnabled then
                if currentEmoteTrack then
                    local currentEmoteId = urlToId(currentEmoteTrack.Animation.AnimationId)
                    if currentEmoteId == playedEmoteId then
                        return
                    else
                        stopCurrentEmote()
                    end
                end

                playEmote(humanoid, playedEmoteId)

                if currentEmoteTrack then
                    currentEmoteTrack.Ended:Connect(function()
                        if currentEmoteTrack == animationTrack then
                            currentEmoteTrack = nil
                        end
                    end)
                end
            end

            if speedEmoteEnabled and not emotesWalkEnabled then
                if currentEmoteTrack then
                    local currentEmoteId = urlToId(currentEmoteTrack.Animation.AnimationId)
                    if currentEmoteId == playedEmoteId then
                        return
                    else
                        stopCurrentEmote()
                    end
                end

                playEmote(humanoid, playedEmoteId)

                if currentEmoteTrack then
                    currentEmoteTrack.Ended:Connect(function()
                        if currentEmoteTrack == animationTrack then
                            currentEmoteTrack = nil
                        end
                    end)
                end
            end
        end
    end)

    humanoid.Died:Connect(function()
    emotesWalkEnabled = false
    speedEmoteEnabled = false
    favoriteEnabled = false
    currentEmoteTrack = nil

    stopEmotes()
        stopCurrentEmote()
    end)
end

local function toggleEmoteWalk()
    emotesWalkEnabled = not emotesWalkEnabled

    if emotesWalkEnabled then
        getgenv().Notify({
            Title = 'ValL | Emote Freeze',
            Content = "🔒 Emote freeze ON",
            Duration = 5
        })

        EmoteWalkButton.Image = enabledButtonImage
        task.wait(0.1)
        stopCurrentEmote()
        if currentEmoteTrack and currentEmoteTrack.IsPlaying then
            currentEmoteTrack:AdjustSpeed(1)
        end
    else
        getgenv().Notify({
            Title = 'ValL | Emote Freeze',
            Content = '🔓 Emote freeze OFF',
            Duration = 5
        })
        EmoteWalkButton.Image = defaultButtonImage
        task.wait(0.1)
        stopCurrentEmote()

        if currentEmoteTrack and currentEmoteTrack.IsPlaying and speedEmoteEnabled then
            local speedValue = tonumber(SpeedBox.Text) or 1
            currentEmoteTrack:AdjustSpeed(speedValue)
        elseif currentEmoteTrack and currentEmoteTrack.IsPlaying then
            currentEmoteTrack:AdjustSpeed(1)
        end
    end
end
print(Players.LocalPlayer.Name)
local function toggleSpeedEmote()
    speedEmoteEnabled = not speedEmoteEnabled

    SpeedBox.Visible = speedEmoteEnabled

    if speedEmoteEnabled then
        getgenv().Notify({
            Title = 'ValL | Speed Emote',
            Content = "⚡ Speed Emote ON",
            Duration = 5
        })
        task.wait(0.1)
        stopCurrentEmote()
    else
        getgenv().Notify({
            Title = 'ValL | Speed Emote',
            Content = '⚡ Speed Emote OFF',
            Duration = 5
        })
        task.wait(0.1)
        stopCurrentEmote()
    end

    if writefile then
        writefile(speedEmoteConfigFile, HttpService:JSONEncode({
            Enabled = speedEmoteEnabled,
            SpeedValue = tonumber(SpeedBox.Text) or 1
        }))
    end
end

local function toggleFavoriteMode()
    favoriteEnabled = not favoriteEnabled

    if favoriteEnabled then
        Favorite.Image = "rbxassetid://97307461910825"
        getgenv().Notify({
            Title = 'ValL | Favorite System',
            Content = "🔒 Emote Favorite ON",
            Duration = 5
        })

        getgenv().Notify({
            Title = 'ValL | Favorite System',
            Content = "⚠️ Click on any emote to add/remove from \n favorites ( Click to image )",
            Duration = 5
        })
        
        setupEmoteClickDetection()
    else
        Favorite.Image = "rbxassetid://124025954365505"
        getgenv().Notify({
            Title = 'ValL | Favorite System',
            Content = '🔓 Emote Favorite OFF',
            Duration = 3
        })
        
        stopEmoteClickDetection()
    end
end

local clickCooldown = {}
local CLICK_COOLDOWN_TIME = 0.1

local function safeButtonClick(buttonName, callback)
    local currentTime = tick()
    if not clickCooldown[buttonName] or (currentTime - clickCooldown[buttonName]) > CLICK_COOLDOWN_TIME then
        clickCooldown[buttonName] = currentTime
        callback()
    end
end

local function setupAnimationClickDetection()
    if isMonitoringClicks then
        return
    end
    
    if currentMode == "animation" then
        isMonitoringClicks = true
        task.spawn(monitorAnimations)
    end
end

local function toggleAutoReload()
    getgenv().autoReloadEnabled = not getgenv().autoReloadEnabled
    
    if getgenv().autoReloadEnabled then
        getgenv().Notify({
            Title = 'ValL | Auto Reload Animation',
            Content = "🔄 Auto Reload ON",
            Duration = 5
        })
    else
        getgenv().Notify({
            Title = 'ValL | Auto Reload Animation',
            Content = '🔄 Auto Reload OFF',
            Duration = 3
        })
    end
end

function connectEvents()
    if _1left then
        _1left.MouseButton1Click:Connect(previousPage)
    end

    if _9right then
        _9right.MouseButton1Click:Connect(nextPage)
    end

      if _2Routenumber then
        _2Routenumber.FocusLost:Connect(function(enterPressed)
            local pageNum = tonumber(_2Routenumber.Text)
            if pageNum then
                goToPage(pageNum)
            else
                _2Routenumber.Text = tostring(currentPage)
            end
        end)
    end

    if Search then
        Search.Changed:Connect(function(property)
            if property == "Text" then
                searchEmotes(Search.Text)
            end
        end)
    end

    if EmoteWalkButton then
        EmoteWalkButton.MouseButton1Click:Connect(function()
            safeButtonClick("EmoteWalk", toggleEmoteWalk)
        end)
    end

    if Favorite then
        Favorite.MouseButton1Click:Connect(function()
            safeButtonClick("Favorite", toggleFavoriteMode)
        end)
    end

    if SpeedEmote then
        SpeedEmote.MouseButton1Click:Connect(function()
            safeButtonClick("SpeedEmote", toggleSpeedEmote)
        end)
    end

    if Reload then
    Reload.MouseButton1Click:Connect(function()
        safeButtonClick("AutoReload", toggleAutoReload)
    end)
end

if Changepage then
    Changepage.MouseButton1Click:Connect(function()
        stopEmoteClickDetection()
        
        if currentMode == "emote" then
            currentMode = "animation"
            
            spawn(function()
                fetchAllAnimations()
                currentPage = 1
                totalPages = calculateTotalPages()
                updatePageDisplay()
                updateEmotes()
                isMonitoringClicks = true
                task.spawn(monitorAnimations)
            end)
            
            getgenv().Notify({
                Title = 'ValL | Animation',
                Content = '🔄 Changed to Emote > Animation Mode',
                Duration = 3
            })

         getgenv().Notify({
            Title = 'ValL | Animation',
            Content = "🔷 Click on any Animation ( Click to image )",
            Duration = 5
        })
        else
            currentMode = "emote"
            currentPage = 1
            totalPages = calculateTotalPages()
            updatePageDisplay() 
            updateEmotes()
            
            getgenv().Notify({
                Title = 'ValL | Emote', 
                Content = '🔄 Changed to Animation > Emote Mode',
                Duration = 3
            })
        end
    end)
end

    if SpeedBox then
        SpeedBox.FocusLost:Connect(function()
            if writefile then
                writefile(speedEmoteConfigFile, HttpService:JSONEncode({
                    Enabled = speedEmoteEnabled,
                    SpeedValue = tonumber(SpeedBox.Text) or 1
                }))
            end
        end)
    end
end

local function checkAndRecreateGUI()
    local exists, emotesWheel = checkEmotesMenuExists()
    if not exists then
        isGUICreated = false
        return
    end

    if not emotesWheel:FindFirstChild("Under") or not emotesWheel:FindFirstChild("Top") or
        not emotesWheel:FindFirstChild("EmoteWalkButton") or not emotesWheel:FindFirstChild("Favorite") or
        not emotesWheel:FindFirstChild("SpeedEmote") or not emotesWheel:FindFirstChild("SpeedBox") or
        not emotesWheel:FindFirstChild("Changepage") or not emotesWheel:FindFirstChild("Reload") then
        isGUICreated = false
        if createGUIElements() then
            updatePageDisplay()
            updateEmotes()
            loadSpeedEmoteConfig()
        end
    end
end

if player.Character then
    onCharacterAdded(player.Character)
end

player.CharacterAdded:Connect(function(character)
    onCharacterAdded(character)
    task.wait(0.3) 
    spawn(function()
        while not checkEmotesMenuExists() do
            task.wait(0.1) 
        end
        task.wait(0.3) 
        stopEmotes()
        if createGUIElements() then
            if #emotesData > 0 then
                updatePageDisplay()
                updateEmotes()
                loadSpeedEmoteConfig()
            end
        end
    end)
end)

player.CharacterAdded:Connect(function(newChar)
    character = newChar
    humanoid = newChar:WaitForChild("Humanoid")
    emotesWalkEnabled = false
    speedEmoteEnabled = false
    favoriteEnabled = false
    currentEmoteTrack = nil
    stopEmotes()
end)


local heartbeatConnection = RunService.Heartbeat:Connect(function()
    if not isGUICreated then
        checkAndRecreateGUI()
    else
        updateGUIColors()
    end
end)


local function safeFind(path, name)
    if not path then return nil end
    local ok, result = pcall(function()
        return path:FindFirstChild(name)
    end)
    if ok then
        return result
    end
    return nil
end

RunService.Stepped:Connect(function()
    if humanoid and currentEmoteTrack and currentEmoteTrack.IsPlaying then
        if humanoid.MoveDirection.Magnitude > 0 then
            if speedEmoteEnabled and not emotesWalkEnabled then
                currentEmoteTrack:Stop()
                currentEmoteTrack = nil
            end
        end
    end
end)

spawn(function()
    while not checkEmotesMenuExists() do
        wait(0.1)
    end
    if createGUIElements() then
        loadFavorites()
        fetchAllEmotes()
        loadSpeedEmoteConfig()
    end
end)

task.spawn(function()
    local StarterGui = game:GetService("StarterGui")
    local CoreGui = game:GetService("CoreGui")

    while true do
        local robloxGui = CoreGui:FindFirstChild("RobloxGui")
        local emotesMenu = robloxGui and robloxGui:FindFirstChild("EmotesMenu")

        if not emotesMenu then
            StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.EmotesMenu, true)

        else
            local exists = emotesMenu:FindFirstChild("Children") and emotesMenu.Children:FindFirstChild("Main") and
                               emotesMenu.Children.Main:FindFirstChild("EmotesWheel")

            if exists then
                local emotesWheel = emotesMenu.Children.Main.EmotesWheel
                if not emotesWheel:FindFirstChild("Under") or not emotesWheel:FindFirstChild("Top") then
                    if createGUIElements then
                        createGUIElements()
                        loadSpeedEmoteConfig()
                    end

                    if updateGUIColors then
                        updateGUIColors()
                        updatePageDisplay()
                        loadFavorites()
                    end
                end
            end
        end

        task.wait(.3)
    end
end)

if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled then
    loadstring(game:HttpGet("https://raw.githubusercontent.com/7yd7/Hub/refs/heads/Branch/GUIS/OpenEmote.lua"))()
    getgenv().Notify({
        Title = 'ValL | Emote Mobile',
        Content = '⭕ Added emote open button for ease of use',
        Duration = 10
    })
end

if UserInputService.KeyboardEnabled then
    getgenv().Notify({
        Title = 'ValL | Emote PC',
        Content = '⭕ Open menu press button "."',
        Duration = 10
    })
end
