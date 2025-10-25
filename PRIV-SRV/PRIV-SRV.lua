local md5 = {} 
local hmac = {} 
local base64 = {}

do 
    do 
        local T = { 
            0xd76aa478, 0xe8c7b756, 0x242070db, 0xc1bdceee, 0xf57c0faf, 0x4787c62a, 0xa8304613, 0xfd469501, 
            0x698098d8, 0x8b44f7af, 0xffff5bb1, 0x895cd7be, 0x6b901122, 0xfd987193, 0xa679438e, 0x49b40821, 
            0xf61e2562, 0xc040b340, 0x265e5a51, 0xe9b6c7aa, 0xd62f105d, 0x02441453, 0xd8a1e681, 0xe7d3fbc8, 
            0x21e1cde6, 0xc33707d6, 0xf4d50d87, 0x455a14ed, 0xa9e3e905, 0xfcefa3f8, 0x676f02d9, 0x8d2a4c8a, 
            0xfffa3942, 0x8771f681, 0x6d9d6122, 0xfde5380c, 0xa4beea44, 0x4bdecfa9, 0xf6bb4b60, 0xbebfbc70, 
            0x289b7ec6, 0xeaa127fa, 0xd4ef3085, 0x04881d05, 0xd9d4d039, 0xe6db99e5, 0x1fa27cf8, 0xc4ac5665, 
            0xf4292244, 0x432aff97, 0xab9423a7, 0xfc93a039, 0x655b59c3, 0x8f0ccc92, 0xffeff47d, 0x85845dd1, 
            0x6fa87e4f, 0xfe2ce6e0, 0xa3014314, 0x4e0811a1, 0xf7537e82, 0xbd3af235, 0x2ad7d2bb, 0xeb86d391, 
        }

        local function add(a, b)
            local lsw = bit32.band(a, 0xFFFF) + bit32.band(b, 0xFFFF)
            local msw = bit32.rshift(a, 16) + bit32.rshift(b, 16) + bit32.rshift(lsw, 16)
            return bit32.bor(bit32.lshift(msw, 16), bit32.band(lsw, 0xFFFF))
        end
        
        local function rol(x, n)
            return bit32.bor(bit32.lshift(x, n), bit32.rshift(x, 32 - n))
        end
        
        local function F(x, y, z)
            return bit32.bor(bit32.band(x, y), bit32.band(bit32.bnot(x), z))
        end
        
        local function G(x, y, z)
            return bit32.bor(bit32.band(x, z), bit32.band(y, bit32.bnot(z)))
        end
        
        local function H(x, y, z)
            return bit32.bxor(x, bit32.bxor(y, z))
        end
        
        local function I(x, y, z)
            return bit32.bxor(y, bit32.bor(x, bit32.bnot(z)))
        end
        
        function md5.sum(message)
            local a, b, c, d = 0x67452301, 0xefcdab89, 0x98badcfe, 0x10325476
            local message_len = #message
            local padded_message = message .. "\128"
            while #padded_message % 64 ~= 56 do
                padded_message = padded_message .. "\0"
            end
            local len_bytes = ""
            local len_bits = message_len * 8
            for i = 0, 7 do
                len_bytes = len_bytes .. string.char(bit32.band(bit32.rshift(len_bits, i * 8), 0xFF))
            end
            padded_message = padded_message .. len_bytes
            for i = 1, #padded_message, 64 do
                local chunk = padded_message:sub(i, i + 63)
                local X = {}
                for j = 0, 15 do
                    local b1, b2, b3, b4 = chunk:byte(j * 4 + 1, j * 4 + 4)
                    X[j] = bit32.bor(b1, bit32.lshift(b2, 8), bit32.lshift(b3, 16), bit32.lshift(b4, 24))
                end
                local aa, bb, cc, dd = a, b, c, d
                local s = { 7, 12, 17, 22, 5, 9, 14, 20, 4, 11, 16, 23, 6, 10, 15, 21 }
                for j = 0, 63 do
                    local f, k, shift_index
                    if j < 16 then
                        f = F(b, c, d)
                        k = j
                        shift_index = j % 4
                    elseif j < 32 then
                        f = G(b, c, d)
                        k = (1 + 5 * j) % 16
                        shift_index = 4 + (j % 4)
                    elseif j < 48 then
                        f = H(b, c, d)
                        k = (5 + 3 * j) % 16
                        shift_index = 8 + (j % 4)
                    else
                        f = I(b, c, d)
                        k = (7 * j) % 16
                        shift_index = 12 + (j % 4)
                    end
                    local temp = add(a, f)
                    temp = add(temp, X[k])
                    temp = add(temp, T[j + 1])
                    temp = rol(temp, s[shift_index + 1])
                    local new_b = add(b, temp)
                    a, b, c, d = d, new_b, b, c
                end
                a = add(a, aa)
                b = add(b, bb)
                c = add(c, cc)
                d = add(d, dd)
            end
            local function to_le_hex(n)
                local s = ""
                for i = 0, 3 do
                    s = s .. string.char(bit32.band(bit32.rshift(n, i * 8), 0xFF))
                end
                return s
            end
            return to_le_hex(a) .. to_le_hex(b) .. to_le_hex(c) .. to_le_hex(d)
        end
    end 
    
    do 
        function hmac.new(key, msg, hash_func)
            if #key > 64 then
                key = hash_func(key)
            end
            local o_key_pad = ""
            local i_key_pad = ""
            for i = 1, 64 do
                local byte = (i <= #key and string.byte(key, i)) or 0
                o_key_pad = o_key_pad .. string.char(bit32.bxor(byte, 0x5C))
                i_key_pad = i_key_pad .. string.char(bit32.bxor(byte, 0x36))
            end
            return hash_func(o_key_pad .. hash_func(i_key_pad .. msg))
        end
    end 
    
    do 
        local b = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
        function base64.encode(data)
            return ((data:gsub(".", function(x)
                local r, b_val = "", x:byte()
                for i = 8, 1, -1 do
                    r = r .. (b_val % 2 ^ i - b_val % 2 ^ (i - 1) > 0 and "1" or "0")
                end
                return r
            end) .. "0000"):gsub("%d%d%d?%d?%d?%d?", function(x)
                if #x < 6 then
                    return ""
                end
                local c = 0
                for i = 1, 6 do
                    c = c + (x:sub(i, i) == "1" and 2 ^ (6 - i) or 0)
                end
                return b:sub(c + 1, c + 1)
            end) .. ({ "", "==", "=" })[#data % 3 + 1])
        end
    end 
end

local ImportantKey = "e4Yn8ckbCJtw2sv7qmbg"

local function GenerateReservedServerCode(placeId)
    local uuid = {}
    for i = 1, 16 do
        uuid[i] = math.random(0, 255)
    end
    uuid[7] = bit32.bor(bit32.band(uuid[7], 0x0F), 0x40)
    uuid[9] = bit32.bor(bit32.band(uuid[9], 0x3F), 0x80)
    local firstBytes = ""
    for i = 1, 16 do
        firstBytes = firstBytes .. string.char(uuid[i])
    end
    local gameCode = string.format("%02x%02x%02x%02x-%02x%02x-%02x%02x-%02x%02x-%02x%02x%02x%02x%02x%02x", table.unpack(uuid))
    local placeIdBytes = ""
    local pIdRec = placeId
    for _ = 1, 8 do
        placeIdBytes = placeIdBytes .. string.char(pIdRec % 256)
        pIdRec = math.floor(pIdRec / 256)
    end
    local content = firstBytes .. placeIdBytes
    local signature = hmac.new(ImportantKey, content, md5.sum)
    local accessCodeBytes = signature .. content
    local accessCode = base64.encode(accessCodeBytes)
    accessCode = accessCode:gsub("+", "-"):gsub("/", "_")
    local pdding = 0
    accessCode, _ = accessCode:gsub("=", function()
        pdding = pdding + 1
        return ""
    end)
    accessCode = accessCode .. tostring(pdding)
    return accessCode, gameCode
end

local Players = game:GetService("Players")
local CoreGui = cloneref(game:GetService("CoreGui"))
local HttpService = game:GetService("HttpService")
local player = Players.LocalPlayer

local gui = Instance.new("ScreenGui")
local mainFrame = Instance.new("Frame")
local header = Instance.new("Frame")
local title = Instance.new("TextLabel")
local underline = Instance.new("Frame")
local closeBtn = Instance.new("TextButton")
local content = Instance.new("Frame")
local generateBtn = Instance.new("TextButton")
local codeBox = Instance.new("TextBox")
local copyBtn = Instance.new("TextButton")
local joinBtn = Instance.new("TextButton")
local scriptBtn = Instance.new("TextButton")

-- Notification system
local notificationFrame = Instance.new("Frame")
local notificationLabel = Instance.new("TextLabel")

local Colors = {
    Background = Color3.fromRGB(15, 15, 15),
    Card = Color3.fromRGB(25, 25, 25),
    Primary = Color3.fromRGB(0, 170, 255),
    Secondary = Color3.fromRGB(85, 170, 85),
    Text = Color3.fromRGB(240, 240, 240),
    Border = Color3.fromRGB(50, 50, 50),
    Gray = Color3.fromRGB(100, 100, 100),
    DarkGray = Color3.fromRGB(60, 60, 60),
    Success = Color3.fromRGB(85, 170, 85),
    Warning = Color3.fromRGB(255, 170, 0),
    Error = Color3.fromRGB(255, 85, 85)
}

gui.Name = "SimpleServerGUI"
gui.ResetOnSpawn = false
gui.Parent = CoreGui

mainFrame.Size = UDim2.new(0, 320, 0, 200)
mainFrame.Position = UDim2.new(0.5, -160, 0.5, -100)
mainFrame.BackgroundColor3 = Colors.Card
mainFrame.BackgroundTransparency = 0.1
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.Parent = gui

local shadow = Instance.new("Frame")
shadow.Size = UDim2.new(1, 6, 1, 6)
shadow.Position = UDim2.new(0, -3, 0, -3)
shadow.BackgroundColor3 = Color3.new(0, 0, 0)
shadow.BackgroundTransparency = 0.8
shadow.BorderSizePixel = 0
shadow.ZIndex = 0
shadow.Parent = mainFrame

header.Size = UDim2.new(1, 0, 0, 32)
header.BackgroundColor3 = Colors.Background
header.BackgroundTransparency = 0.1
header.BorderSizePixel = 0
header.Parent = mainFrame

title.Size = UDim2.new(1, -40, 1, 0)
title.Position = UDim2.new(0, 12, 0, 0)
title.BackgroundTransparency = 1
title.Text = "RESERVED SERVER GENERATOR"
title.TextColor3 = Colors.Text
title.Font = Enum.Font.GothamBold
title.TextSize = 14
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = header

underline.Size = UDim2.new(1, -24, 0, 1)
underline.Position = UDim2.new(0, 12, 1, -2)
underline.BackgroundColor3 = Colors.Primary
underline.BorderSizePixel = 0
underline.Parent = header

closeBtn.Size = UDim2.new(0, 24, 0, 24)
closeBtn.Position = UDim2.new(1, -28, 0, 4)
closeBtn.BackgroundColor3 = Colors.DarkGray
closeBtn.BackgroundTransparency = 0.3
closeBtn.BorderSizePixel = 0
closeBtn.Text = "×"
closeBtn.TextColor3 = Colors.Text
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 16
closeBtn.Parent = header

content.Size = UDim2.new(1, -16, 1, -48)
content.Position = UDim2.new(0, 8, 0, 40)
content.BackgroundTransparency = 1
content.Parent = mainFrame

generateBtn.Size = UDim2.new(1, 0, 0, 32)
generateBtn.Position = UDim2.new(0, 0, 0, 0)
generateBtn.BackgroundColor3 = Colors.Primary
generateBtn.BackgroundTransparency = 0.2
generateBtn.BorderSizePixel = 0
generateBtn.Text = "Generate Server ID"
generateBtn.TextColor3 = Colors.Text
generateBtn.Font = Enum.Font.GothamBold
generateBtn.TextSize = 13
generateBtn.Parent = content

local genUnderline = Instance.new("Frame")
genUnderline.Size = UDim2.new(1, 0, 0, 2)
genUnderline.Position = UDim2.new(0, 0, 1, -2)
genUnderline.BackgroundColor3 = Colors.Primary
genUnderline.BackgroundTransparency = 0.5
genUnderline.BorderSizePixel = 0
genUnderline.Parent = generateBtn

codeBox.Size = UDim2.new(1, 0, 0, 32)
codeBox.Position = UDim2.new(0, 0, 0, 38)
codeBox.BackgroundColor3 = Colors.DarkGray
codeBox.BackgroundTransparency = 0.2
codeBox.BorderSizePixel = 0
codeBox.PlaceholderText = "Server ID will appear here..."
codeBox.PlaceholderColor3 = Color3.fromRGB(150, 150, 150)
codeBox.ClearTextOnFocus = false
codeBox.Text = ""
codeBox.TextSize = 12
codeBox.TextColor3 = Colors.Text
codeBox.Font = Enum.Font.Gotham
codeBox.TextXAlignment = Enum.TextXAlignment.Left
codeBox.Parent = content

local codePadding = Instance.new("Frame")
codePadding.Size = UDim2.new(1, -68, 1, -8)
codePadding.Position = UDim2.new(0, 8, 0, 4)
codePadding.BackgroundTransparency = 1
codePadding.Parent = codeBox

codeBox.Text = codePadding:FindFirstChildWhichIsA("TextLabel") and "" or ""

copyBtn.Size = UDim2.new(0, 60, 0, 28)
copyBtn.Position = UDim2.new(1, -62, 0, 40)
copyBtn.BackgroundColor3 = Colors.Gray
copyBtn.BackgroundTransparency = 0.2
copyBtn.BorderSizePixel = 0
copyBtn.Text = "COPY"
copyBtn.TextColor3 = Colors.Text
copyBtn.Font = Enum.Font.GothamBold
copyBtn.TextSize = 11
copyBtn.Parent = content

local copyUnderline = Instance.new("Frame")
copyUnderline.Size = UDim2.new(1, 0, 0, 1)
copyUnderline.Position = UDim2.new(0, 0, 1, -1)
copyUnderline.BackgroundColor3 = Colors.Gray
copyUnderline.BackgroundTransparency = 0.5
copyUnderline.BorderSizePixel = 0
copyUnderline.Parent = copyBtn

joinBtn.Size = UDim2.new(1, 0, 0, 32)
joinBtn.Position = UDim2.new(0, 0, 0, 76)
joinBtn.BackgroundColor3 = Colors.Secondary
joinBtn.BackgroundTransparency = 0.2
joinBtn.BorderSizePixel = 0
joinBtn.Text = "Join Server"
joinBtn.TextColor3 = Colors.Text
joinBtn.Font = Enum.Font.GothamBold
joinBtn.TextSize = 13
joinBtn.Parent = content

local joinUnderline = Instance.new("Frame")
joinUnderline.Size = UDim2.new(1, 0, 0, 2)
joinUnderline.Position = UDim2.new(0, 0, 1, -2)
joinUnderline.BackgroundColor3 = Colors.Secondary
joinUnderline.BackgroundTransparency = 0.5
joinUnderline.BorderSizePixel = 0
joinUnderline.Parent = joinBtn

scriptBtn.Size = UDim2.new(1, 0, 0, 32)
scriptBtn.Position = UDim2.new(0, 0, 0, 114)
scriptBtn.BackgroundColor3 = Colors.Gray
scriptBtn.BackgroundTransparency = 0.2
scriptBtn.BorderSizePixel = 0
scriptBtn.Text = "Copy Join Server Script"
scriptBtn.TextColor3 = Colors.Text
scriptBtn.Font = Enum.Font.GothamBold
scriptBtn.TextSize = 13
scriptBtn.Parent = content

local scriptUnderline = Instance.new("Frame")
scriptUnderline.Size = UDim2.new(1, 0, 0, 2)
scriptUnderline.Position = UDim2.new(0, 0, 1, -2)
scriptUnderline.BackgroundColor3 = Colors.Gray
scriptUnderline.BackgroundTransparency = 0.5
scriptUnderline.BorderSizePixel = 0
scriptUnderline.Parent = scriptBtn

-- Notification system
notificationFrame.Size = UDim2.new(1, -20, 0, 36)
notificationFrame.Position = UDim2.new(0, 10, 1, 10)
notificationFrame.BackgroundColor3 = Colors.DarkGray
notificationFrame.BackgroundTransparency = 0.9
notificationFrame.BorderSizePixel = 0
notificationFrame.Visible = false
notificationFrame.Parent = mainFrame

notificationLabel.Size = UDim2.new(1, 0, 1, 0)
notificationLabel.Position = UDim2.new(0, 0, 0, 0)
notificationLabel.BackgroundTransparency = 1
notificationLabel.Text = ""
notificationLabel.TextColor3 = Colors.Text
notificationLabel.Font = Enum.Font.GothamBold
notificationLabel.TextSize = 12
notificationLabel.TextWrapped = true
notificationLabel.Parent = notificationFrame

local function showNotification(message, color, duration)
    duration = duration or 3
    notificationLabel.Text = message
    notificationFrame.BackgroundColor3 = color or Colors.Primary
    notificationFrame.Visible = true
    
    -- Animate in
    notificationFrame.Position = UDim2.new(0, 10, 1, 10)
    for i = 0, 1, 0.1 do
        notificationFrame.BackgroundTransparency = 0.9 - (i * 0.4)
        task.wait(0.01)
    end
    
    task.wait(duration)
    
    -- Animate out
    for i = 0, 1, 0.1 do
        notificationFrame.BackgroundTransparency = 0.5 + (i * 0.4)
        task.wait(0.01)
    end
    notificationFrame.Visible = false
end

local latestAccess = ""

generateBtn.MouseButton1Click:Connect(function()
    local placeId = game.PlaceId
    local ok, code = pcall(function()
        return GenerateReservedServerCode(placeId)
    end)
    if ok then
        latestAccess = code
        codeBox.Text = code
        showNotification("Server ID generated successfully!", Colors.Success, 2)
    else
        codeBox.Text = "Error generating code"
        showNotification("Failed to generate Server ID", Colors.Error, 3)
    end
end)

copyBtn.MouseButton1Click:Connect(function()
    if codeBox.Text ~= "" and codeBox.Text ~= "Error generating code" then
        pcall(function()
            setclipboard(codeBox.Text)
        end)
        local originalText = copyBtn.Text
        copyBtn.Text = "COPIED!"
        showNotification("Server ID copied to clipboard!", Colors.Success, 1.5)
        task.wait(1)
        copyBtn.Text = originalText
    else
        showNotification("No Server ID to copy", Colors.Warning, 2)
    end
end)

joinBtn.MouseButton1Click:Connect(function()
    if latestAccess == "" then 
        showNotification("Generate a Server ID first", Colors.Warning, 2)
        return 
    end
    
    showNotification("Joining Server...", Colors.Primary, 1.5)
    
    local scriptText = [[
local placeId = ]] .. tostring(game.PlaceId) .. [[;
local accessCode = "]] .. latestAccess .. [[";
pcall(function()
    game:GetService("RobloxReplicatedStorage").ContactListIrisInviteTeleport:FireServer(placeId, "", accessCode)
end)
]]
    loadstring(scriptText)()
    
    -- Show success message after a short delay
    task.wait(1.2)
    showNotification("Server join request sent!", Colors.Success, 2)
end)

scriptBtn.MouseButton1Click:Connect(function()
    if latestAccess == "" then 
        showNotification("Generate a Server ID first", Colors.Warning, 2)
        return 
    end
    
    local scriptText = [[
local placeId = ]] .. tostring(game.PlaceId) .. [[;
local accessCode = "]] .. latestAccess .. [[";
pcall(function()
    game:GetService("RobloxReplicatedStorage").ContactListIrisInviteTeleport:FireServer(placeId, "", accessCode)
end)
]]
    pcall(function()
        setclipboard(scriptText)
    end)
    local originalText = scriptBtn.Text
    scriptBtn.Text = "SCRIPT COPIED!"
    showNotification("Join script copied to clipboard!", Colors.Success, 2)
    task.wait(1.5)
    scriptBtn.Text = originalText
end)

closeBtn.MouseButton1Click:Connect(function()
    gui:Destroy()
end)

generateBtn.MouseEnter:Connect(function()
    generateBtn.BackgroundTransparency = 0.1
end)

generateBtn.MouseLeave:Connect(function()
    generateBtn.BackgroundTransparency = 0.2
end)

joinBtn.MouseEnter:Connect(function()
    joinBtn.BackgroundTransparency = 0.1
end)

joinBtn.MouseLeave:Connect(function()
    joinBtn.BackgroundTransparency = 0.2
end)

scriptBtn.MouseEnter:Connect(function()
    scriptBtn.BackgroundTransparency = 0.1
end)

scriptBtn.MouseLeave:Connect(function()
    scriptBtn.BackgroundTransparency = 0.2
end)

copyBtn.MouseEnter:Connect(function()
    copyBtn.BackgroundTransparency = 0.1
end)

copyBtn.MouseLeave:Connect(function()
    copyBtn.BackgroundTransparency = 0.2
end)

closeBtn.MouseEnter:Connect(function()
    closeBtn.BackgroundColor3 = Color3.fromRGB(255, 60, 60)
end)

closeBtn.MouseLeave:Connect(function()
    closeBtn.BackgroundColor3 = Colors.DarkGray
end)
