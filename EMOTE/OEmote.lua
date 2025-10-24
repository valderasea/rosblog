local UIS = game:GetService("UserInputService") 
local TweenService = game:GetService("TweenService")
local GuiService = game:GetService("GuiService")
local RunService = game:GetService("RunService")

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

local function setupHoverEffect(button)
	local originalSize = button.Size
	
	local tweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	
	button.MouseEnter:Connect(function()
		local newSize = UDim2.new(
			originalSize.X.Scale * 1.1,
			originalSize.X.Offset * 1.1,
			originalSize.Y.Scale * 1.1,
			originalSize.Y.Offset * 1.1
		)
		local tween = TweenService:Create(button, tweenInfo, {Size = newSize})
		tween:Play()
	end)
	
	button.MouseLeave:Connect(function()
		local tween = TweenService:Create(button, tweenInfo, {Size = originalSize})
		tween:Play()
	end)
	
	button.MouseButton1Click:Connect(function()
		local success, emotesMenu = pcall(function()
			return game:GetService("CoreGui").RobloxGui.EmotesMenu.Children.Main.EmotesWheel
		end)
		
		if success and emotesMenu then
			local isVisible = emotesMenu.Visible
			GuiService:SetEmotesMenuOpen(not isVisible)
		else
			GuiService:SetEmotesMenuOpen(true)
		end
	end)
end

local OpenEmoteMobile = Instance.new("ScreenGui")
local button = Instance.new("TextButton")
local UICorner = Instance.new("UICorner")
local ImageLabel = Instance.new("ImageLabel")
local UIListLayout = Instance.new("UIListLayout")
local UIAspectRatioConstraint = Instance.new("UIAspectRatioConstraint")

OpenEmoteMobile.IgnoreGuiInset = true
OpenEmoteMobile.Name = "OpenEmote (Mobile)"
OpenEmoteMobile.Parent = game.CoreGui
OpenEmoteMobile.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

button.Name = "button"
button.Parent = OpenEmoteMobile
button.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
button.BackgroundTransparency = 0.400
button.BorderSizePixel = 0
button.Position = UDim2.new(0.500268757, 0, 0, 30)
button.AnchorPoint = Vector2.new(0.5, 0.5)
button.Size = UDim2.new(0.0390930399, 0, 0.0694444478, 0)
button.ZIndex = 99999999
button.AutoButtonColor = false
button.Text = ""

UICorner.CornerRadius = UDim.new(0, 99999)
UICorner.Parent = button

ImageLabel.Parent = button
ImageLabel.BackgroundTransparency = 1.000
ImageLabel.Position = UDim2.new(0.1, 0, 0.1, 0)
ImageLabel.Size = UDim2.new(0.8, 0, 0.8, 0)
ImageLabel.Image = "rbxassetid://85867483111516"

UIListLayout.Parent = button
UIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout.VerticalAlignment = Enum.VerticalAlignment.Center

UIAspectRatioConstraint.Parent = button
UIAspectRatioConstraint.AspectRatio = 1.000

makeDraggable(button)
setupHoverEffect(button)

RunService.Heartbeat:Connect(function()
	local success, mainMenu = pcall(function()
		return game:GetService("CoreGui").RobloxGui.EmotesMenu.Children.Main.EmotesWheel
	end)

	if success and mainMenu then
		if mainMenu.Visible then
			button.Visible = false
		else
			button.Visible = true 
		end
	else
		button.Visible = true 
	end
end)
