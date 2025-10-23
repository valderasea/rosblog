-- Services
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RobloxUsername = LocalPlayer.Name

-------------------------------------------------------------
-- FILE SYSTEM CONFIGURATION
-------------------------------------------------------------
local FILE_CONFIG = {
    folder = "ValL",
    subfolder = "auth",
    filename = "token.dat"
}

local function getAuthFilePath()
    return FILE_CONFIG.folder .. "/" .. FILE_CONFIG.subfolder .. "/" .. FILE_CONFIG.filename
end

local function saveToken(token)
    local success, err = pcall(function()
        if not isfolder(FILE_CONFIG.folder) then
            makefolder(FILE_CONFIG.folder)
        end
        
        local authFolder = FILE_CONFIG.folder .. "/" .. FILE_CONFIG.subfolder
        if not isfolder(authFolder) then
            makefolder(authFolder)
        end
        
        local data = {
            token = token,
            username = RobloxUsername,
            saved_at = os.time(),
            version = "1.0"
        }
        
        writefile(getAuthFilePath(), HttpService:JSONEncode(data))
    end)
    
    if not success then
        warn("[AUTH] Failed to save token: " .. tostring(err))
    end
    
    return success
end

local function loadToken()
    local success, result = pcall(function()
        if not isfile(getAuthFilePath()) then
            return nil
        end
        
        local content = readfile(getAuthFilePath())
        local data = HttpService:JSONDecode(content)
        
        if data.username == RobloxUsername then
            return data.token
        else
            return nil
        end
    end)
    
    if success then
        return result
    else
        warn("[AUTH] Failed to load token: " .. tostring(result))
        return nil
    end
end

local function deleteToken()
    pcall(function()
        if isfile(getAuthFilePath()) then
            delfile(getAuthFilePath())
        end
    end)
end
-------------------------------------------------------------
-- FILE SYSTEM CONFIGURATION - END
-------------------------------------------------------------

-------------------------------------------------------------
-- API
-------------------------------------------------------------
local API_CONFIG = {
    base_url = "https://valdera-001-site1.stempurl.com/",
    validate_endpoint = "/validate.php",
    main_script_url = "https://raw.githubusercontent.com/valderasea/rosblog/refs/heads/main/LOADER/main.lua"
}

local function safeHttpRequest(url, method, data, headers)
    method = method or "GET"
    local requestData = {
        Url = url,
        Method = method
    }
    
    if headers then
        requestData.Headers = headers
    end
    
    if data and method == "POST" then
        requestData.Body = data
    end
    
    local ok, res = pcall(function()
        return HttpService:RequestAsync(requestData)
    end)
    
    if ok and res then
        if res.Success and res.StatusCode == 200 then
            return true, res.Body
        else
            return false, "HTTP Error: " .. (res.StatusCode or "Unknown")
        end
    end

    if method == "GET" then
        local ok2, res2 = pcall(function()
            return HttpService:GetAsync(url, false)
        end)
        if ok2 and res2 then 
            return true, res2 
        end

        local ok3, res3 = pcall(function()
            return game:HttpGet(url)
        end)
        if ok3 and res3 then 
            return true, res3 
        end
    end

    return false, tostring(res)
end

local function ValidateToken(token)
    if not token or token == "" then
        return false, "Token cannot be empty"
    end

    local encodedToken = HttpService:UrlEncode(tostring(token))
    local encodedUsername = HttpService:UrlEncode(tostring(RobloxUsername))
    local url = API_CONFIG.base_url .. API_CONFIG.validate_endpoint .. "?token=" .. encodedToken .. "&roblox_username=" .. encodedUsername
    
    local headers = {
        ["Content-Type"] = "application/json",
        ["User-Agent"] = "Roblox/WinInet",
        ["ngrok-skip-browser-warning"] = "true"
    }

    local ok, res = safeHttpRequest(url, "GET", nil, headers)
    if not ok then
        return false, "Connection error: " .. tostring(res)
    end

    local okDecode, data = pcall(function()
        return HttpService:JSONDecode(res)
    end)
    
    if not okDecode then
        return false, "Invalid server response format"
    end
    
    if type(data) ~= "table" then
        return false, "Invalid server response structure"
    end

    if tostring(data.status or ""):lower() == "success" then
        return true, data
    else
        local errorMsg = tostring(data.message or "Authentication failed")
        return false, errorMsg
    end
end
-------------------------------------------------------------
-- API - END
-------------------------------------------------------------

-------------------------------------------------------------
-- CHECK AUTO LOGIN FIRST
-------------------------------------------------------------
local savedToken = loadToken()

if savedToken and tostring(savedToken) ~= "" and #tostring(savedToken) >= 5 then
    
    local valid, result = ValidateToken(savedToken)
    if valid then
        
        -- Save to getgenv for compatibility
        getgenv().UserToken = savedToken
        getgenv().AuthComplete = true
        getgenv().AuthTimestamp = os.time()
        
        -- Load main script
        local ok, res = safeHttpRequest(API_CONFIG.main_script_url)
        if ok then
            local fn, err = loadstring(res)
            if fn then
                local ok2, runErr = pcall(fn)
                if ok2 then
                    return -- Exit auth script
                else
                    warn("[AUTH] Main script runtime error: " .. tostring(runErr))
                end
            else
                warn("[AUTH] Main script compile error: " .. tostring(err))
            end
        else
            warn("[AUTH] Failed to fetch main script: " .. tostring(res))
        end
    else
        deleteToken()
        getgenv().UserToken = nil
    end
end
-------------------------------------------------------------
-- AUTO LOGIN CHECK - END
-------------------------------------------------------------

-------------------------------------------------------------
-- SHOW AUTH UI IF NO VALID TOKEN
-------------------------------------------------------------
-- Load Rayfield UI
local Rayfield = loadstring(game:HttpGet('https://raw.githubusercontent.com/valderasea/rosblog/refs/heads/main/UI%20Liblary/Rayfield.lua'))()

local Window = Rayfield:CreateWindow({
   Name = "VLS | ValL Keys",
   Icon = "key",
   LoadingTitle = "Created By Valdera",
   LoadingSubtitle = "Jelek ya maap",
   ConfigurationSaving = {
       Enabled = false
   }
})

local AuthTab = Window:CreateTab("Authentication", "key")

AuthTab:CreateSection("Welcome to ValLSC")

AuthTab:CreateParagraph({
    Title = "Key Authentication Required",
    Content = "Username: " .. RobloxUsername .. "\n\nThe key is only valid for one device and specific to your Roblox username."
})

local enteredToken = ""

local TokenInput = AuthTab:CreateInput({
    Name = "🔒   Enter Your Key",
    PlaceholderText = "Paste your key here...",
    RemoveTextAfterFocusLost = false,
    Callback = function(t) 
        enteredToken = tostring(t or ""):gsub("%s+", ""):gsub("[\n\r\t]", "")
    end
})

local function verifyAndLogin(token)
    local currentToken = token:gsub("%s+", ""):gsub("[\n\r\t]", "")
    
    if currentToken == "" or #currentToken < 5 then
        Rayfield:Notify({ 
            Title = "⚠️ Empty Key", 
            Content = "Please enter your key first.", 
            Duration = 3 
        })
        return false
    end

    Rayfield:Notify({ 
        Title = "🔄 Validating", 
        Content = "Checking key for " .. RobloxUsername .. "...", 
        Duration = 2 
    })

    local valid, result = ValidateToken(currentToken)
    if valid then
        Rayfield:Notify({ 
            Title = "✅ Key Valid", 
            Content = "Welcome! Loading main script...", 
            Duration = 3 
        })
        
        -- Save token
        saveToken(currentToken)
        getgenv().UserToken = currentToken
        getgenv().AuthComplete = true
        getgenv().AuthTimestamp = os.time()
        
        task.wait(1)
        
        -- Load main script
        local ok, res = safeHttpRequest(API_CONFIG.main_script_url)
        if ok then
            local fn, err = loadstring(res)
            if fn then
                -- Destroy auth window BEFORE loading main script
                Rayfield:Destroy()
                
                task.wait(0.5)
                
                local ok2, runErr = pcall(fn)
                if ok2 then
                else
                    warn("[AUTH] Main script error: " .. tostring(runErr))
                end
            else
                Rayfield:Notify({ 
                    Title = "❌ Script Error", 
                    Content = tostring(err), 
                    Duration = 5 
                })
            end
        else
            Rayfield:Notify({ 
                Title = "❌ Failed to Fetch", 
                Content = tostring(res), 
                Duration = 5 
            })
        end
        
        return true
    else
        Rayfield:Notify({ 
            Title = "❌ Invalid Key", 
            Content = tostring(result), 
            Duration = 5 
        })
        return false
    end
end

AuthTab:CreateButton({
    Name = "✅   Verify Key",
    Callback = function()
        verifyAndLogin(enteredToken)
    end
})

AuthTab:CreateSection("Quick Actions")

AuthTab:CreateButton({
    Name = "📋   Paste Key from Clipboard",
    Callback = function()
        if not getclipboard then
            Rayfield:Notify({ 
                Title = "❌ Not Supported", 
                Content = "Your executor doesn't support clipboard.", 
                Duration = 3 
            })
            return
        end
        
        local clipboardContent = getclipboard()
        if not clipboardContent or clipboardContent == "" then
            Rayfield:Notify({ 
                Title = "⚠️ Empty Clipboard", 
                Content = "No key found in clipboard.", 
                Duration = 3 
            })
            return
        end
        
        local cleanedKey = clipboardContent:gsub("%s+", ""):gsub("[\n\r\t]", "")
        
        if #cleanedKey < 5 then
            Rayfield:Notify({ 
                Title = "⚠️ Invalid Key", 
                Content = "Clipboard content too short.", 
                Duration = 3 
            })
            return
        end
        
        enteredToken = cleanedKey
        
        Rayfield:Notify({ 
            Title = "📋 Key Pasted", 
            Content = "Auto-verifying key...", 
            Duration = 2 
        })
        
        task.wait(0.5)
        verifyAndLogin(cleanedKey)
    end
})

AuthTab:CreateSection("Butuh Key?")

AuthTab:CreateButton({
    Name = "Minta ke gw kali dikasih😂",
    Callback = function()
        local inviteLink = "https://discord.gg/BbCsJBea"
        if setclipboard then 
            setclipboard(inviteLink)
            Rayfield:Notify({
                Title = "📋 Copied!",
                Content = "Discord link copied to clipboard.",
                Duration = 3,
            })
        else
            Rayfield:Notify({
                Title = "🌐 Discord Link",
                Content = inviteLink,
                Duration = 5,
            })
        end
    end,
})

AuthTab:CreateSection("Settings")

AuthTab:CreateButton({
    Name = "🗑️   Clear Saved Key",
    Callback = function()
        deleteToken()
        getgenv().UserToken = nil
        Rayfield:Notify({
            Title = "✅ Cleared",
            Content = "Saved key has been deleted.",
            Duration = 3,
        })
    end,
})
-------------------------------------------------------------
-- AUTH UI - END
-------------------------------------------------------------
