local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "CustomConfirmationGUI"
screenGui.Parent = game.CoreGui
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.ResetOnSpawn = false

local function createConfirmationGUI(options)
    local title = options.name or "Script"
    local description = options.description or "Are you sure you want to run the script?"
    local confirmAction = options.action or function() print("Confirmed!") end
    
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "ConfirmationFrame"
    mainFrame.Parent = screenGui
    mainFrame.BackgroundColor3 = Color3.fromRGB(32, 32, 36)
    mainFrame.BorderSizePixel = 0
    mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    mainFrame.Size = UDim2.new(0, 320, 0, 140)
    mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    mainFrame.ZIndex = 101
    mainFrame.BackgroundTransparency = 1
    
    local mainCorner = Instance.new("UICorner")
    mainCorner.CornerRadius = UDim.new(0, 15)
    mainCorner.Parent = mainFrame
    
    local mainStroke = Instance.new("UIStroke")
    mainStroke.Color = Color3.fromRGB(46, 46, 51)
    mainStroke.Thickness = 1.5
    mainStroke.Parent = mainFrame
    mainStroke.Transparency = 1

    local function makeDraggable(frame)
	local dragging = false
	local dragInput
	local dragStart
	local startPos

	local function update(input)
		local delta = input.Position - dragStart
		frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, 
			startPos.Y.Scale, startPos.Y.Offset + delta.Y)
	end

	frame.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or 
			input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = frame.Position

			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)

	frame.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement or 
			input.UserInputType == Enum.UserInputType.Touch then
			dragInput = input
		end
	end)

	UIS.InputChanged:Connect(function(input)
		if input == dragInput and dragging then
			update(input)
		end
	end)
end


    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "TitleLabel"
    titleLabel.Parent = mainFrame
    titleLabel.BackgroundTransparency = 1
    titleLabel.Position = UDim2.new(0, 0, 0, 15)
    titleLabel.Size = UDim2.new(1, 0, 0, 30)
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.Text = title
    titleLabel.TextColor3 = Color3.fromRGB(245, 245, 250)
    titleLabel.TextSize = 19
    titleLabel.TextXAlignment = Enum.TextXAlignment.Center
    titleLabel.ZIndex = 102
    titleLabel.TextTransparency = 1
    
    local descriptionLabel = Instance.new("TextLabel")
    descriptionLabel.Name = "DescriptionLabel"
    descriptionLabel.Parent = mainFrame
    descriptionLabel.BackgroundTransparency = 1
    descriptionLabel.Position = UDim2.new(0, 20, 0, 45)
    descriptionLabel.Size = UDim2.new(1, -40, 0, 30)
    descriptionLabel.Font = Enum.Font.Gotham
    descriptionLabel.Text = description
    descriptionLabel.TextColor3 = Color3.fromRGB(170, 170, 180)
    descriptionLabel.TextSize = 14
    descriptionLabel.TextXAlignment = Enum.TextXAlignment.Center
    descriptionLabel.TextWrapped = true
    descriptionLabel.ZIndex = 102
    descriptionLabel.TextTransparency = 1
    
    local confirmButton = Instance.new("TextButton")
    confirmButton.Name = "ConfirmButton"
    confirmButton.AutoButtonColor = false
    confirmButton.Parent = mainFrame
    confirmButton.BackgroundColor3 = Color3.fromRGB(47,47,47)
    confirmButton.BorderSizePixel = 0
    confirmButton.Position = UDim2.new(0, 25, 0, 90)
    confirmButton.Size = UDim2.new(0.45, -15, 0, 38)
    confirmButton.Font = Enum.Font.GothamSemibold
    confirmButton.Text = "Confirm"
    confirmButton.TextColor3 = Color3.new(1, 1, 1)
    confirmButton.TextSize = 15
    confirmButton.ZIndex = 102
    confirmButton.BackgroundTransparency = 1
    confirmButton.TextTransparency = 1
    
    local confirmCorner = Instance.new("UICorner")
    confirmCorner.CornerRadius = UDim.new(0, 10)
    confirmCorner.Parent = confirmButton
    
    
    local cancelButton = Instance.new("TextButton")
    cancelButton.Name = "CancelButton"
    cancelButton.Parent = mainFrame
    cancelButton.AutoButtonColor = false
    cancelButton.BackgroundColor3 = Color3.fromRGB(47,47,47)
    cancelButton.BorderSizePixel = 0
    cancelButton.Position = UDim2.new(0.55, 15, 0, 90)
    cancelButton.Size = UDim2.new(0.45, -40, 0, 38)
    cancelButton.Font = Enum.Font.GothamSemibold
    cancelButton.Text = "Cancel"
    cancelButton.TextColor3 = Color3.new(1, 1, 1)
    cancelButton.TextSize = 15
    cancelButton.ZIndex = 102
    cancelButton.BackgroundTransparency = 1
    cancelButton.TextTransparency = 1
    
    local cancelCorner = Instance.new("UICorner")
    cancelCorner.CornerRadius = UDim.new(0, 10)
    cancelCorner.Parent = cancelButton
    
    local showTweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out, 0, false, 0)
    local hideTweenInfo = TweenInfo.new(0.15, Enum.EasingStyle.Quart, Enum.EasingDirection.In, 0, false, 0)
    local fadeInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out, 0, false, 0)
    
    local function showGUI()
        mainFrame.Size = UDim2.new(0, 50, 0, 20)
        
        local sizeTween = TweenService:Create(mainFrame, showTweenInfo, {
            Size = UDim2.new(0, 320, 0, 140),
            BackgroundTransparency = 0
        })
        
        local strokeTween = TweenService:Create(mainStroke, fadeInfo, {
            Transparency = 0
        })
        

        
        sizeTween:Play()
        strokeTween:Play()

        
        wait(0.15)
        
        local titleFade = TweenService:Create(titleLabel, fadeInfo, {
            TextTransparency = 0
        })
        
        local descFade = TweenService:Create(descriptionLabel, fadeInfo, {
            TextTransparency = 0
        })
        
        local confirmFade = TweenService:Create(confirmButton, fadeInfo, {
            BackgroundTransparency = 0,
            TextTransparency = 0
        })
        
        local cancelFade = TweenService:Create(cancelButton, fadeInfo, {
            BackgroundTransparency = 0,
            TextTransparency = 0
        })
        
        titleFade:Play()
        descFade:Play()
        confirmFade:Play()
        cancelFade:Play()
    end
    
    local function hideGUI()
        local scaleTween = TweenService:Create(mainFrame, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
            Size = UDim2.new(0, 350, 0, 160),
            BackgroundTransparency = 0.3
        })
        
        scaleTween:Play()
        
        scaleTween.Completed:Connect(function()
            local fadeTween = TweenService:Create(mainFrame, TweenInfo.new(0.15, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
                BackgroundTransparency = 1,
                Size = UDim2.new(0, 10, 0, 5)
            })
            
            fadeTween:Play()
            fadeTween.Completed:Connect(function()
                mainFrame:Destroy()
            end)
        end)
    end
    
    local function confirmHideGUI()
        local dropTween = TweenService:Create(mainFrame, TweenInfo.new(0.15, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
            Position = UDim2.new(0.5, 0, 0.5, 20)
        })
        
        dropTween:Play()
        
        dropTween.Completed:Connect(function()
            local returnTween = TweenService:Create(mainFrame, TweenInfo.new(0.1, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                Position = UDim2.new(0.5, 0, 0.5, 0)
            })
            
            returnTween:Play()
            
            returnTween.Completed:Connect(function()
                wait(0.05)
                hideGUI()
            end)
        end)
    end
    
    local function animateButton(button, isConfirm)
        local originalSize = button.Size
        local originalColor = button.BackgroundColor3
        
        local pressedColor
        if isConfirm then
            pressedColor = Color3.fromRGB(47,47,47)
        else
            pressedColor = Color3.fromRGB(47,47,47)
        end
        
        local clickTween = TweenService:Create(button, TweenInfo.new(0.05), {
            Size = UDim2.new(originalSize.X.Scale * 0.96, originalSize.X.Offset * 0.96, 
                            originalSize.Y.Scale * 0.96, originalSize.Y.Offset * 0.96),
            BackgroundColor3 = pressedColor
        })
        
        clickTween:Play()
        clickTween.Completed:Connect(function()
            local returnTween = TweenService:Create(button, TweenInfo.new(0.05), {
                Size = originalSize,
                BackgroundColor3 = originalColor
            })
            returnTween:Play()
        end)
    end
    
    confirmButton.MouseButton1Click:Connect(function()
        animateButton(confirmButton, true)
        confirmAction()
        confirmHideGUI()
    end)
    
    cancelButton.MouseButton1Click:Connect(function()
        animateButton(cancelButton, false)
        hideGUI()
    end)
    
    confirmButton.MouseEnter:Connect(function()
        local hoverTween = TweenService:Create(confirmButton, TweenInfo.new(0.1), {
            BackgroundColor3 = Color3.fromRGB(40,40,40)
        })
        hoverTween:Play()
    end)
    
    confirmButton.MouseLeave:Connect(function()
        local leaveTween = TweenService:Create(confirmButton, TweenInfo.new(0.1), {
            BackgroundColor3 = Color3.fromRGB(47,47,47)
        })
        leaveTween:Play()
    end)
    
    cancelButton.MouseEnter:Connect(function()
        local hoverTween = TweenService:Create(cancelButton, TweenInfo.new(0.1), {
            BackgroundColor3 = Color3.fromRGB(40,40,40)
        })
        hoverTween:Play()
    end)
    
    cancelButton.MouseLeave:Connect(function()
        local leaveTween = TweenService:Create(cancelButton, TweenInfo.new(0.1), {
            BackgroundColor3 = Color3.fromRGB(47,47,47)
        })
        leaveTween:Play()
    end)
    
    showGUI()
    makeDraggable(mainFrame)

end

getgenv().createConfirmationGUI = function(options)
    createConfirmationGUI(options)
end

getgenv().createConfirmation = function(options)
    createConfirmationGUI({
        name = options.name or "Script Execution",
        description = "Execute " .. (options.name or "this script") .. "?",
        action = options.action or function() end
    })
end
