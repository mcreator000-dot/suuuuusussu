local library = {}

local TweenService = game:GetService("TweenService")
local TextService = game:GetService("TextService")
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")

local MACLIB_URL = "https://raw.githubusercontent.com/mcreator000-dot/suuuuusussu/main/mclib?v=configfix-20260719"

local function patchMacLibSource(macSource)
	macSource = macSource:gsub("RunService%.RenderStepped:Connect%(UpdateOrientation%)", "if acrylicBlur then RunService.RenderStepped:Connect(UpdateOrientation) end")
	macSource = macSource:gsub("colorC%.BackgroundTransparency = ColorpickerFunctions%.Alpha or 0", "colorC.BackgroundTransparency = 0")
	macSource = macSource:gsub("colorC%.BackgroundTransparency = isAlpha and %(1 %- ColorpickerFunctions%.Alpha%) or 0", "colorC.BackgroundTransparency = 0")
	macSource = macSource:gsub("colorC%.BackgroundTransparency = alphaToPreviewTransparency%(ColorpickerFunctions%.Alpha%)", "colorC.BackgroundTransparency = 0")
	macSource = macSource:gsub("colorC%.BackgroundTransparency = alpha", "colorC.BackgroundTransparency = 0")
	macSource = macSource:gsub("color1%.BackgroundTransparency = isAlpha and ColorpickerFunctions%.Alpha or 0", "color1.BackgroundTransparency = 0")
	macSource = macSource:gsub("color1%.BackgroundTransparency = isAlpha and alphaToPreviewTransparency%(ColorpickerFunctions%.Alpha%) or 0", "color1.BackgroundTransparency = 0")
	macSource = macSource:gsub("color1%.BackgroundTransparency = alphaToPreviewTransparency%(ColorpickerFunctions%.Alpha%)", "color1.BackgroundTransparency = 0")
	macSource = macSource:gsub("colour%.BackgroundTransparency = clampInput%(modifierInputs%.Alpha%.Text, 0, 1%)", "colour.BackgroundTransparency = 0")
	macSource = macSource:gsub("colour%.BackgroundTransparency = isAlpha and ColorpickerFunctions%.Alpha or 0", "colour.BackgroundTransparency = 0")
	macSource = macSource:gsub("colour%.BackgroundTransparency = isAlpha and alphaToPreviewTransparency%(ColorpickerFunctions%.Alpha%) or 0", "colour.BackgroundTransparency = 0")
	macSource = macSource:gsub("colour%.BackgroundTransparency = alphaToPreviewTransparency%(ColorpickerFunctions%.Alpha%)", "colour.BackgroundTransparency = 0")
	macSource = macSource:gsub("Color3%.fromRGB%(7, 7, 7%)", "Color3.fromRGB(0, 0, 0)")
	macSource = macSource:gsub("Color3%.fromRGB%(12, 13, 15%)", "Color3.fromRGB(0, 0, 0)")
	macSource = macSource:gsub("Color3%.fromRGB%(0, 221, 191%)", "Color3.fromRGB(103, 182, 254)")
	macSource = macSource:gsub("Color3%.fromRGB%(0, 174, 151%)", "Color3.fromRGB(103, 182, 254)")
	macSource = macSource:gsub("Color3%.fromRGB%(82, 82, 88%)", "Color3.fromRGB(11, 13, 15)")
	macSource = macSource:gsub("Color3%.fromRGB%(58, 58, 64%)", "Color3.fromRGB(42, 46, 52)")
	macSource = macSource:gsub("Color3%.fromRGB%(13, 13, 13%)", "Color3.fromRGB(11, 13, 15)")
	macSource = macSource:gsub("Color3%.fromRGB%(9, 12, 13%)", "Color3.fromRGB(17, 19, 20)")
	macSource = macSource:gsub("Color3%.fromRGB%(132, 40, 148%)", "Color3.fromRGB(103, 182, 254)")
	macSource = macSource:gsub("Color3%.fromRGB%(79, 95, 239%)", "Color3.fromRGB(103, 182, 254)")
	macSource = macSource:gsub("Color3%.fromRGB%(56, 67, 163%)", "Color3.fromRGB(103, 182, 254)")
	macSource = macSource:gsub("togglerDot%.Size = UDim2%.fromOffset%(3, 3%)", "togglerDot.Size = UDim2.fromOffset(0, 0)")
	macSource = macSource:gsub("togglerDot%.Parent = togglerHead", "togglerDot.Visible = false\n\t\t\t\t\ttogglerDot.Parent = togglerHead")
	macSource = macSource:gsub("togglerDotUIStroke%.Transparency = 0", "togglerDotUIStroke.Transparency = 1")
	macSource = macSource:gsub("ColorpickerFunctions%.Alpha = %(cX / width%)", "ColorpickerFunctions.Alpha = 1 - (cX / width)")
	macSource = macSource:gsub("local cX = ColorpickerFunctions%.Alpha %* width", "local cX = (1 - ColorpickerFunctions.Alpha) * width")
	macSource = macSource:gsub("local cX = math%.clamp%(alpha or 0, 0, 1%) %* width", "local cX = (1 - ColorpickerFunctions.Alpha) * width")
	macSource = macSource:gsub("modifierInputs%.Alpha%.Text = isAlpha and %(1 %- ColorpickerFunctions%.Alpha%) or 0", "modifierInputs.Alpha.Text = isAlpha and ColorpickerFunctions.Alpha or 0")
	macSource = macSource:gsub("information%.Size = UDim2%.new%(1, 0, 0, 63%)", "information.Size = UDim2.new(1, 0, 0, 74)")
	macSource = macSource:gsub("divider%.Parent = sidebar", "divider.Visible = false\n\tdivider.Parent = sidebar")
	macSource = macSource:gsub("divider2%.Parent = information", "divider2.Visible = false\n\tdivider2.Parent = information")
	macSource = macSource:gsub("sidebarGroup%.Position = UDim2%.fromOffset%(0, 63%)", "sidebarGroup.Position = UDim2.fromOffset(0, 74)")
	macSource = macSource:gsub("sidebarGroup%.Size = UDim2%.new%(1, 0, 1, %-63%)", "sidebarGroup.Size = UDim2.new(1, 0, 1, -74)")
	macSource = macSource:gsub("userInfo%.Size = UDim2%.new%(1, 0, 0, 107%)", "userInfo.Size = UDim2.new(1, 0, 0, 76)")
	macSource = macSource:gsub("informationGroup%.Parent = userInfo", "informationGroup.Visible = false\n\tinformationGroup.Parent = userInfo")
	macSource = macSource:gsub("userInfoUIPadding%.Parent = userInfo", "userInfoUIPadding.Parent = userInfo\n\n\ttitleFrame.Parent = userInfo\n\ttitleFrame.Position = UDim2.new(0, 18, 0, 14)\n\ttitleFrame.Size = UDim2.new(1, -36, 0, 46)\n\ttitle.TextSize = 14\n\tsubtitle.TextSize = 10\n\tsubtitle.TextColor3 = Color3.fromRGB(0, 210, 190)\n\tsubtitle.TextTransparency = 0")
	macSource = macSource:gsub("ghostLogo%.AnchorPoint = Vector2%.new%(0, 1%)", "ghostLogo.AnchorPoint = Vector2.new(0, 0)")
	macSource = macSource:gsub("ghostLogo%.Position = UDim2%.new%(0, 4, 1, %-12%)", "ghostLogo.Position = UDim2.new(0, -8, 0, -8)")
	macSource = macSource:gsub("ghostLogo%.Size = UDim2%.new%(1, %-6, 0, 104%)", "ghostLogo.Size = UDim2.new(1, -14, 0, 96)")
	macSource = macSource:gsub("ghostLogo%.Visible = false", "ghostLogo.Visible = true")
	macSource = macSource:gsub("ghostLogo%.Parent = userInfo", "ghostLogo.Parent = informationHolder")
	macSource = macSource:gsub("ghostSkull%.Position = UDim2%.new%(0, 0, 1, %-45%)", "ghostSkull.Position = UDim2.new(0, 0, 0.5, -2)")
	macSource = macSource:gsub("ghostSkull%.Size = UDim2%.fromOffset%(90, 90%)", "ghostSkull.Size = UDim2.fromOffset(82, 82)")
	macSource = macSource:gsub("ghostWordmark%.Position = UDim2%.new%(0, 68, 1, %-146%)", "ghostWordmark.Position = UDim2.fromOffset(54, -34)")
	macSource = macSource:gsub("ghostWordmark%.Size = UDim2%.fromOffset%(225, 225%)", "ghostWordmark.Size = UDim2.fromOffset(208, 208)")
	macSource = macSource:gsub("ghostLuaL%.Position = UDim2%.new%(0, 68, 1, %-146%)", "ghostLuaL.Position = UDim2.fromOffset(54, -34)")
	macSource = macSource:gsub("ghostLuaL%.Size = UDim2%.fromOffset%(225, 225%)", "ghostLuaL.Size = UDim2.fromOffset(208, 208)")
	macSource = macSource:gsub("ghostLua%.Position = UDim2%.new%(0, 68, 1, %-146%)", "ghostLua.Position = UDim2.fromOffset(54, -34)")
	macSource = macSource:gsub("ghostLua%.Size = UDim2%.fromOffset%(225, 225%)", "ghostLua.Size = UDim2.fromOffset(208, 208)")
	macSource = macSource:gsub("tabSwitchers%.Size = UDim2%.new%(1, 0, 1, %-107%)", "tabSwitchers.Size = UDim2.new(1, 0, 1, -80)")
	macSource = macSource:gsub("tabSwitcherUIStroke%.Color = Color3%.fromRGB%(255, 255, 255%)", "tabSwitcherUIStroke.Color = Color3.fromRGB(103, 182, 254)")
	macSource = macSource:gsub("tabImage%.ImageColor3 = Color3%.fromRGB%(103, 182, 254%)", "tabImage.ImageColor3 = Color3.fromRGB(255, 255, 255)")
	if not macSource:find("ImageColor3 = (i == tabSwitcher and Color3.fromRGB(103, 182, 254)", 1, true) then
		macSource = macSource:gsub("ImageTransparency = %(i == tabSwitcher and 0%.1 or 0%.5%)", "ImageColor3 = (i == tabSwitcher and Color3.fromRGB(103, 182, 254) or Color3.fromRGB(255, 255, 255)),\n\t\t\t\t\t\t\tImageTransparency = (i == tabSwitcher and 0.1 or 0.5)")
	end
	macSource = macSource:gsub("tabSwitcherUIStroke%.Transparency = 1", "tabSwitcherUIStroke.Thickness = 1.25\n\t\t\ttabSwitcherUIStroke.Transparency = 1")
	macSource = macSource:gsub("Transparency = %(i == tabSwitcher and 0%.95 or 1%)", "Transparency = (i == tabSwitcher and 0 or 1)")
	macSource = macSource:gsub("tabSwitchersScrollingFrame%.BackgroundTransparency = 0", "tabSwitchersScrollingFrame.BackgroundTransparency = 1")
	macSource = macSource:gsub("tabSwitchersScrollingFrame%.Size = UDim2%.fromScale%(1, 1%)", "tabSwitchersScrollingFrame.Size = UDim2.fromScale(1, 1)\n\ttabSwitchersScrollingFrame.ZIndex = 2", 1)
	macSource = macSource:gsub("BackgroundTransparency = %(i == tabSwitcher and 0 or 1%)", "BackgroundTransparency = (i == tabSwitcher and 0.62 or 1)")

	if not macSource:find('Name = "TabSwitchersBackground"', 1, true) then
		local tabBackgroundSource = [[
	local themeAccentLineTop = Instance.new("Frame")
	themeAccentLineTop.Name = "ThemeAccentLineTop"
	themeAccentLineTop.BackgroundColor3 = Color3.fromRGB(103, 182, 254)
	themeAccentLineTop.BackgroundTransparency = 0.1
	themeAccentLineTop.BorderSizePixel = 0
	themeAccentLineTop.Position = UDim2.new(0, 0, 0, 74)
	themeAccentLineTop.Size = UDim2.new(1, 0, 0, 1)
	themeAccentLineTop.Visible = false
	themeAccentLineTop.ZIndex = 20
	themeAccentLineTop.Parent = sidebar

	local themeAccentLineRight = Instance.new("Frame")
	themeAccentLineRight.Name = "ThemeAccentLineRight"
	themeAccentLineRight.BackgroundColor3 = Color3.fromRGB(34, 40, 42)
	themeAccentLineRight.BackgroundTransparency = 0.2
	themeAccentLineRight.BorderSizePixel = 0
	themeAccentLineRight.Position = UDim2.new(1, -1, 0, 74)
	themeAccentLineRight.Size = UDim2.new(0, 1, 1, -74)
	themeAccentLineRight.ZIndex = 20
	themeAccentLineRight.Parent = sidebar

	local tabSwitchersBackground = Instance.new("ImageLabel")
	tabSwitchersBackground.Name = "TabSwitchersBackground"
	tabSwitchersBackground.Image = "rbxassetid://139913314515436"
	tabSwitchersBackground.ImageTransparency = 0.35
	tabSwitchersBackground.ScaleType = Enum.ScaleType.Crop
	tabSwitchersBackground.BackgroundTransparency = 1
	tabSwitchersBackground.BorderSizePixel = 0
	tabSwitchersBackground.AnchorPoint = Vector2.new(0.5, 0.5)
	tabSwitchersBackground.Position = UDim2.fromScale(0.62, 0.48)
	tabSwitchersBackground.Size = UDim2.fromScale(0.82, 0.82)
	tabSwitchersBackground.ZIndex = 0
	tabSwitchersBackground.Active = false
	tabSwitchersBackground.Parent = tabSwitchers

	local themeAccentLineBottom = Instance.new("Frame")
	themeAccentLineBottom.Name = "ThemeAccentLineBottom"
	themeAccentLineBottom.BackgroundColor3 = Color3.fromRGB(103, 182, 254)
	themeAccentLineBottom.BackgroundTransparency = 1
	themeAccentLineBottom.BorderSizePixel = 0
	themeAccentLineBottom.Position = UDim2.new(0, 0, 1, -1)
	themeAccentLineBottom.Size = UDim2.new(1, 0, 0, 1)
	themeAccentLineBottom.Visible = false
	themeAccentLineBottom.ZIndex = 20
	themeAccentLineBottom.Parent = tabSwitchers]]
		macSource = macSource:gsub("tabSwitchers%.Size = UDim2%.new%(1, 0, 1, %-80%)[\r\n]", "tabSwitchers.Size = UDim2.new(1, 0, 1, -80)\n\n" .. tabBackgroundSource .. "\n\n", 1)
	end

	local alphaTextReady = macSource:find('Name = "AlphaText"', 1, true) ~= nil
	if not alphaTextReady then
		local alphaTextSource = [[
					local colorAlphaText = Instance.new("TextLabel")
					colorAlphaText.Name = "AlphaText"
					colorAlphaText.AnchorPoint = Vector2.new(0.5, 0.5)
					colorAlphaText.BackgroundTransparency = 1
					colorAlphaText.BorderSizePixel = 0
					colorAlphaText.FontFace = Font.new(assets.interFont, Enum.FontWeight.Medium, Enum.FontStyle.Normal)
					colorAlphaText.Position = UDim2.fromScale(0.5, 0.5)
					colorAlphaText.Size = UDim2.fromScale(1, 1)
					colorAlphaText.Text = ""
					colorAlphaText.TextColor3 = Color3.fromRGB(255, 255, 255)
					colorAlphaText.TextSize = 9
					colorAlphaText.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
					colorAlphaText.TextStrokeTransparency = 0.35
					colorAlphaText.TextXAlignment = Enum.TextXAlignment.Center
					colorAlphaText.TextYAlignment = Enum.TextYAlignment.Center
					colorAlphaText.ZIndex = 7
					colorAlphaText.Parent = colorCbg]]
		local count
		macSource, count = macSource:gsub("colorC%.Parent = colorCbg", "colorC.Parent = colorCbg\n\n" .. alphaTextSource, 1)
		alphaTextReady = count > 0
	end

	local helperSource = [[
					local function formatAlphaLabel(alpha)
						local value = math.clamp(tonumber(alpha) or 0, 0, 1)
						if value == 0 or value == 1 then
							return tostring(value)
						end
						return string.format("%.2f", value):gsub("0+$", ""):gsub("%.$", "")
					end

					local function updateAlphaPreviewText()
						colorAlphaText.Visible = isAlpha
						colorAlphaText.Text = isAlpha and formatAlphaLabel(ColorpickerFunctions.Alpha) or ""
					end]]
	if alphaTextReady and not macSource:find("formatAlphaLabel", 1, true) then
		macSource = macSource:gsub("local function update%(%)[\r\n]", helperSource .. "\n\n					local function update()\n", 1)
	end
	if alphaTextReady and macSource:find("updateAlphaPreviewText", 1, true) then
		macSource = macSource:gsub("update%(%)[\r\n](%s*end)", "update()\n						updateAlphaPreviewText()\n%1")
		macSource = macSource:gsub("(UpdateRingFromHSV%(hue, saturation, value%)[\r\n])", "%1						updateAlphaPreviewText()\n")
	end
	return macSource
end

local macOk, MacLib = pcall(function()
	local macSource = game:HttpGet(MACLIB_URL)
	macSource = patchMacLibSource(macSource)
	return loadstring(macSource)()
end)

if not macOk or type(MacLib) ~= "table" then
	error("MacLib failed to load: " .. tostring(MacLib))
end

function library:tween(...)
	TweenService:Create(...):Play()
end

function library:create(objectType, properties, parent)
	local object = Instance.new(objectType)
	for property, value in pairs(properties or {}) do
		object[property] = value
	end
	if parent ~= nil then
		object.Parent = parent
	end
	return object
end

function library:get_text_size(...)
	return TextService:GetTextSize(...)
end

function library:console(callback)
	callback(("\n"):rep(57))
end

local ENABLE_TRACEBACK = false

local Signal = {}
Signal.__index = Signal
Signal.ClassName = "Signal"

function Signal.new()
	local self = setmetatable({}, Signal)
	self._bindableEvent = Instance.new("BindableEvent")
	self._argMap = {}
	self._source = ENABLE_TRACEBACK and debug.traceback() or ""

	self._bindableEvent.Event:Connect(function(key)
		self._argMap[key] = nil

		if not self._bindableEvent and not next(self._argMap) then
			self._argMap = nil
		end
	end)

	return self
end

function Signal:Fire(...)
	if not self._bindableEvent then
		warn(("Signal is already destroyed. %s"):format(self._source))
		return
	end

	local args = table.pack(...)
	local key = HttpService:GenerateGUID(false)
	self._argMap[key] = args
	self._bindableEvent:Fire(key)
end

function Signal:Connect(handler)
	if type(handler) ~= "function" then
		error(("connect(%s)"):format(typeof(handler)), 2)
	end

	return self._bindableEvent.Event:Connect(function(key)
		local args = self._argMap and self._argMap[key]
		if not args then
			error("Missing arg data, probably due to reentrance.")
		end
		handler(table.unpack(args, 1, args.n))
	end)
end

function Signal:Wait()
	if not self._bindableEvent then
		warn(("Signal is already destroyed. %s"):format(self._source))
		return nil
	end

	local key = self._bindableEvent.Event:Wait()
	local args = self._argMap and self._argMap[key]
	if not args then
		error("Missing arg data, probably due to reentrance.")
	end
	return table.unpack(args, 1, args.n)
end

function Signal:Destroy()
	if self._bindableEvent then
		self._bindableEvent:Destroy()
		self._bindableEvent = nil
	end
	setmetatable(self, nil)
end

local function createSignal()
	return Signal.new()
end

local function ensureFolder(path)
	if type(path) ~= "string" or path == "" then
		return
	end
	if isfolder and makefolder and not isfolder(path) then
		makefolder(path)
	end
end

local function configPath(prefix, name)
	name = tostring(name or "Default")
	if not name:match("%.txt$") then
		name = name .. ".txt"
	end

	prefix = tostring(prefix or "")
	if prefix ~= "" and not prefix:match("[/\\]$") then
		prefix = prefix .. "/"
	end

	return prefix .. name
end

local function legacyConfigPath(prefix, name)
	name = tostring(name or "Default")
	if not name:match("%.txt$") then
		name = name .. ".txt"
	end
	return tostring(prefix or "") .. name
end

local function serialize(value)
	if typeof(value) == "Color3" then
		return {
			__type = "Color3",
			R = value.R,
			G = value.G,
			B = value.B,
		}
	end

	if type(value) ~= "table" then
		return value
	end

	local copy = {}
	for key, child in pairs(value) do
		copy[key] = serialize(child)
	end
	return copy
end

local function deserialize(value)
	if type(value) ~= "table" then
		return value
	end

	if value.__type == "Color3" or (value.R ~= nil and value.G ~= nil and value.B ~= nil) then
		return Color3.new(tonumber(value.R) or 0, tonumber(value.G) or 0, tonumber(value.B) or 0)
	end

	local copy = {}
	for key, child in pairs(value) do
		copy[key] = deserialize(child)
	end
	return copy
end

local function deepCopy(value)
	if type(value) ~= "table" then
		return value
	end

	local copy = {}
	for key, child in pairs(value) do
		copy[key] = deepCopy(child)
	end
	return copy
end

local function getUiParents()
	local parents = {}
	local seen = {}

	local function add(parent)
		if parent and not seen[parent] then
			seen[parent] = true
			table.insert(parents, parent)
		end
	end

	add(CoreGui)

	if gethui then
		pcall(function()
			add(gethui())
		end)
	end

	local localPlayer = Players.LocalPlayer
	if localPlayer then
		local playerGui = localPlayer:FindFirstChildOfClass("PlayerGui")
		add(playerGui)
	end

	return parents
end

local function snapshotChildren(parents)
	local snapshot = {}
	for _, parent in ipairs(parents) do
		snapshot[parent] = {}
		for _, child in ipairs(parent:GetChildren()) do
			snapshot[parent][child] = true
		end
	end
	return snapshot
end

local function findCreatedGui(snapshot)
	for parent, knownChildren in pairs(snapshot) do
		for _, child in ipairs(parent:GetChildren()) do
			if not knownChildren[child] and child:IsA("ScreenGui") then
				return child
			end
		end
	end

	for _, child in ipairs(CoreGui:GetChildren()) do
		if child:IsA("ScreenGui") and child:FindFirstChild("Base") and child:FindFirstChild("Notifications") then
			return child
		end
	end
end

local function ensureLegacyMain(gui)
	if not gui then
		return
	end

	local main = gui:FindFirstChild("Main")
	if not main then
		main = Instance.new("ImageButton")
		main.Name = "Main"
		main.BackgroundTransparency = 1
		main.BorderSizePixel = 0
		main.Image = ""
		main.ImageTransparency = 1
		main.Size = UDim2.fromOffset(0, 0)
		main.Visible = false
		main.Parent = gui
	end

	local title = main:FindFirstChild("Title")
	if not title then
		title = Instance.new("TextLabel")
		title.Name = "Title"
		title.BackgroundTransparency = 1
		title.BorderSizePixel = 0
		title.Size = UDim2.fromOffset(0, 0)
		title.Visible = false
		title.Parent = main
	end
	title.Text = "Project Delta | KT.RK"

	return main
end

local function connectDragHandle(handle, base)
	if not handle or not base or not handle:IsA("GuiObject") then
		return
	end

	if handle:GetAttribute("FullTopbarDrag") then
		return
	end

	if handle:IsA("GuiButton") or handle:IsA("TextBox") or handle:IsA("ScrollingFrame") then
		return
	end

	handle:SetAttribute("FullTopbarDrag", true)
	pcall(function()
		handle.Active = true
	end)

	local dragging = false
	local dragInput = nil
	local dragStart = nil
	local startPos = nil

	local function update(input)
		local delta = input.Position - dragStart
		base.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
	end

	handle.InputBegan:Connect(function(input)
		if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then
			return
		end

		dragging = true
		dragStart = input.Position
		startPos = base.Position

		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				dragging = false
			end
		end)
	end)

	handle.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			dragInput = input
		end
	end)

	handle.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if input == dragInput and dragging then
			update(input)
		end
	end)
end

local function makeTopbarDraggable(gui)
	local base = gui and gui:FindFirstChild("Base", true)
	if not base then
		return
	end

	for _, name in ipairs({ "WindowControls", "Topbar", "Information" }) do
		local topbar = base:FindFirstChild(name, true)
		if topbar then
			connectDragHandle(topbar, base)
			for _, child in ipairs(topbar:GetDescendants()) do
				connectDragHandle(child, base)
			end
		end
	end
end

local function hideMacWindowControls(gui)
	local base = gui and gui:FindFirstChild("Base", true)
	local windowControls = base and base:FindFirstChild("WindowControls", true)
	local controls = windowControls and windowControls:FindFirstChild("Controls")

	if windowControls then
		windowControls.Visible = false
		windowControls.Size = UDim2.new(1, 0, 0, 0)
		for _, child in ipairs(windowControls:GetDescendants()) do
			if child:IsA("GuiObject") then
				child.Visible = false
				child.Active = false
				pcall(function()
					child.Interactable = false
				end)
			end
		end
	end

	if controls then
		controls.Visible = false
	end

	local information = base and base:FindFirstChild("Information", true)
	if information then
		information.Position = UDim2.fromOffset(0, 0)
		information.Size = UDim2.new(1, 0, 0, 63)
	end

	local sidebarGroup = base and base:FindFirstChild("SidebarGroup", true)
	if sidebarGroup then
		sidebarGroup.Position = UDim2.fromOffset(0, 63)
		sidebarGroup.Size = UDim2.new(1, 0, 1, -63)
	end

	local globalSettingsButton = information and information:FindFirstChild("GlobalSettingsButton", true)
	if globalSettingsButton then
		globalSettingsButton.Visible = false
		globalSettingsButton.Active = false
		globalSettingsButton.ImageTransparency = 1
		globalSettingsButton.Size = UDim2.fromOffset(0, 0)
		pcall(function()
			globalSettingsButton.Interactable = false
		end)
	end
end

local function tuneMacSidebarLayout(gui)
	local base = gui and gui:FindFirstChild("Base", true)
	local sidebar = base and base:FindFirstChild("Sidebar", true)
	local information = sidebar and sidebar:FindFirstChild("Information")
	local informationHolder = information and information:FindFirstChild("InformationHolder")
	local content = base and base:FindFirstChild("Content", true)
	local topbar = content and content:FindFirstChild("Topbar")
	local sidebarGroup = sidebar and sidebar:FindFirstChild("SidebarGroup")
	local tabSwitchers = sidebarGroup and sidebarGroup:FindFirstChild("TabSwitchers")
	local userInfo = sidebarGroup and sidebarGroup:FindFirstChild("UserInfo")
	local headerHeight = 74

	if information then
		information.Size = UDim2.new(1, 0, 0, headerHeight)
		local oldHeaderBackground = information:FindFirstChild("HeaderBackground")
		if oldHeaderBackground then
			oldHeaderBackground:Destroy()
		end
		for _, child in ipairs(information:GetChildren()) do
			if child.Name == "Divider" and child:IsA("GuiObject") then
				child.Visible = false
			end
		end
	end
	if topbar then
		topbar.ClipsDescendants = true
		local topbarBackground = topbar:FindFirstChild("TopbarBackground")
		if not topbarBackground then
			topbarBackground = Instance.new("ImageLabel")
			topbarBackground.Name = "TopbarBackground"
			topbarBackground.Image = ""
			topbarBackground.ImageTransparency = 1
			topbarBackground.BackgroundTransparency = 1
			topbarBackground.BorderSizePixel = 0
			topbarBackground.ScaleType = Enum.ScaleType.Crop
			topbarBackground.Parent = topbar
		end
		topbarBackground.AnchorPoint = Vector2.new(0, 0)
		topbarBackground.Position = UDim2.new(0, -30, 0, -7)
		topbarBackground.Size = UDim2.new(1, 60, 0, 72)
		topbarBackground.ZIndex = 1
		topbarBackground.Visible = false
		for _, child in ipairs(topbar:GetChildren()) do
			if child.Name == "Divider" and child:IsA("GuiObject") then
				child.BackgroundColor3 = Color3.fromRGB(103, 182, 254)
				child.BackgroundTransparency = 0.1
				child.ZIndex = 3
			elseif child.Name == "Elements" and child:IsA("GuiObject") then
				child.BackgroundTransparency = 1
				child.ZIndex = 2
			end
		end
	end
	if informationHolder then
		informationHolder.ZIndex = 2
	end
	local divider = sidebar and sidebar:FindFirstChild("Divider")
	if divider and divider:IsA("GuiObject") then
		divider.Visible = false
	end
	if sidebarGroup then
		sidebarGroup.Position = UDim2.fromOffset(0, headerHeight)
		sidebarGroup.Size = UDim2.new(1, 0, 1, -headerHeight)
	end
	if tabSwitchers then
		tabSwitchers.Size = UDim2.new(1, 0, 1, -80)
	end

	local titleFrame = informationHolder and informationHolder:FindFirstChild("TitleFrame")
	if userInfo then
		userInfo.Visible = true
		userInfo.Size = UDim2.new(1, 0, 0, 76)
		userInfo.Position = UDim2.fromScale(0, 1)
		local informationGroup = userInfo:FindFirstChild("InformationGroup")
		if informationGroup then
			informationGroup.Visible = false
		end
	end
	if titleFrame and userInfo then
		titleFrame.Parent = userInfo
		titleFrame.Position = UDim2.new(0, 18, 0, 14)
		titleFrame.Size = UDim2.new(1, -36, 0, 46)
		for _, textObject in ipairs(titleFrame:GetDescendants()) do
			if textObject:IsA("TextLabel") then
				textObject.TextSize = textObject.Name == "Title" and 14 or 10
				if textObject.Name == "Subtitle" then
					textObject.Text = "Credits - KT.RK.JD"
					textObject.TextColor3 = Color3.fromRGB(0, 210, 190)
					textObject.TextTransparency = 0
				end
			end
		end
	end

	local ghostLogo = userInfo and userInfo:FindFirstChild("GhostLogo")
	if ghostLogo and informationHolder then
		ghostLogo.Parent = informationHolder
		ghostLogo.Visible = true
		ghostLogo.AnchorPoint = Vector2.new(0, 0)
		ghostLogo.Position = UDim2.new(0, -8, 0, -8)
		ghostLogo.Size = UDim2.new(1, -14, 0, 96)
		ghostLogo.ClipsDescendants = true
		ghostLogo.ZIndex = 3
		local skull = ghostLogo:FindFirstChild("Skull")
		if skull then
			skull.AnchorPoint = Vector2.new(0, 0.5)
			skull.Position = UDim2.new(0, 0, 0.5, -2)
			skull.Size = UDim2.fromOffset(82, 82)
		end
		for _, name in ipairs({ "Wordmark", "LuaL", "Lua" }) do
			local logoPart = ghostLogo:FindFirstChild(name)
			if logoPart then
				logoPart.AnchorPoint = Vector2.new(0, 0)
				logoPart.Position = UDim2.fromOffset(54, -34)
				logoPart.Size = UDim2.fromOffset(208, 208)
			end
		end
	end

	local function ensureAccentLine(parent, name, position, size)
		if not parent then
			return
		end
		local line = parent:FindFirstChild(name)
		if not line then
			line = Instance.new("Frame")
			line.Name = name
			line.BorderSizePixel = 0
			line.BackgroundColor3 = Color3.fromRGB(103, 182, 254)
			line.BackgroundTransparency = 0.1
			line.ZIndex = 20
			line.Parent = parent
		end
		line.Position = position
		line.Size = size
		line.Visible = true
		return line
	end

	local topLine = sidebar and sidebar:FindFirstChild("ThemeAccentLineTop")
	if topLine and topLine:IsA("GuiObject") then
		topLine.Visible = false
	end
	local rightLine = ensureAccentLine(sidebar, "ThemeAccentLineRight", UDim2.new(1, -1, 0, headerHeight), UDim2.new(0, 1, 1, -headerHeight))
	if rightLine then
		rightLine.BackgroundColor3 = Color3.fromRGB(34, 40, 42)
		rightLine.BackgroundTransparency = 0.2
	end
	local bottomLine = ensureAccentLine(tabSwitchers, "ThemeAccentLineBottom", UDim2.new(0, 0, 1, -1), UDim2.new(1, 0, 0, 1))
	if bottomLine then
		bottomLine.Visible = false
		bottomLine.BackgroundTransparency = 1
	end

	for _, object in ipairs(gui:GetDescendants()) do
		if object:IsA("UIStroke") and object.Name == "TabSwitcherUIStroke" then
			object.Thickness = 1
			local parent = object.Parent
			object.Transparency = (parent and parent:IsA("GuiObject") and parent.BackgroundTransparency < 1) and 0.2 or 1
		end
	end
end

local function forceOpaqueMacUi(gui)
	if not gui then
		return
	end

	local windowFill = Color3.fromRGB(0, 0, 0)
	local panelFill = Color3.fromRGB(17, 19, 20)
	local controlFill = Color3.fromRGB(11, 13, 15)
	local overlayFill = Color3.fromRGB(0, 0, 0)
	local dividerFill = Color3.fromRGB(34, 40, 42)
	local topbarAccentFill = Color3.fromRGB(103, 182, 254)

	local fills = {
		Base = windowFill,
		Sidebar = windowFill,
		SidebarGroup = windowFill,
		UserInfo = windowFill,
		Information = windowFill,
		TabSwitchers = windowFill,
		TabSwitchersScrollingFrame = windowFill,
		Content = windowFill,
		Topbar = windowFill,
		Elements = windowFill,
		ElementsScrolling = windowFill,
		Left = windowFill,
		Right = windowFill,
		Section = panelFill,
		Dropdown = Color3.fromRGB(12, 12, 12),
		Search = controlFill,
		SliderValue = controlFill,
		InputBox = controlFill,
		BinderBox = controlFill,
		ColorPicker = overlayFill,
		Dialog = overlayFill,
		Divider = dividerFill,
		Line = dividerFill,
	}

	for _, object in ipairs(gui:GetDescendants()) do
		if object:IsA("GuiObject") then
			local fill = fills[object.Name]
			if fill then
				object.BackgroundColor3 = fill
				object.BackgroundTransparency = 0
			end
			if object.Name == "Divider" and object.Parent and object.Parent.Name == "Topbar" then
				object.BackgroundColor3 = topbarAccentFill
				object.BackgroundTransparency = 0.1
			end
		end
	end

	local base = gui:FindFirstChild("Base", true)
	if base and base:IsA("GuiObject") then
		base.BackgroundColor3 = windowFill
		base.BackgroundTransparency = 0
	end
end

local function destroyOldMenus()
	for _, parent in ipairs(getUiParents()) do
		for _, child in ipairs(parent:GetChildren()) do
			if child:IsA("ScreenGui") and child.Name == "unknown" and child:FindFirstChild("Base", true) then
				pcall(function()
					child:Destroy()
				end)
			end
		end
	end
end

local function enumItemByName(enumType, name)
	if type(name) ~= "string" then
		return nil
	end

	local ok, item = pcall(function()
		return enumType[name]
	end)
	if ok and typeof(item) == "EnumItem" then
		return item
	end

	for _, item in ipairs(enumType:GetEnumItems()) do
		if item.Name == name then
			return item
		end
	end
end

local function normalizeKeyType(keyType)
	if type(keyType) ~= "string" then
		return keyType
	end

	keyType = keyType:gsub("^Enum%.", ""):match("^%s*(.-)%s*$")
	local lowered = string.lower(keyType)
	if lowered == "userinputtype" then
		return "UserInputType"
	elseif lowered == "keycode" then
		return "KeyCode"
	end
	return keyType
end

local function keyNameToEnum(name, preferredType)
	if typeof(name) == "EnumItem" then
		return name
	end

	if type(name) == "table" then
		preferredType = preferredType or name.KeyType or name.keyType or name.BindType or name.bindType or name.TypeName or name.typeName
		name = name.Key or name.key or name.Bind or name.bind or name.Name or name.name
	end

	if type(name) ~= "string" then
		return nil
	end

	name = name:match("^%s*(.-)%s*$")
	if name == "" or name == "None" or name == "NONE" or name == "Hold" or name == "Toggle" or name == "Always" then
		return nil
	end

	name = name:gsub("^Enum%.KeyCode%.", "")
	name = name:gsub("^Enum%.UserInputType%.", "")
	if #name == 1 then
		name = string.upper(name)
	end

	name = ({
		MB1 = "MouseButton1",
		MB2 = "MouseButton2",
		MB3 = "MouseButton3",
		MB4 = "MouseButton4",
		MB5 = "MouseButton5",
		M1 = "MouseButton1",
		M2 = "MouseButton2",
		M3 = "MouseButton3",
		M4 = "MouseButton4",
		M5 = "MouseButton5",
		LMB = "MouseButton1",
		RMB = "MouseButton2",
		MMB = "MouseButton3",
		MOUSE4 = "MouseButton4",
		MOUSE5 = "MouseButton5",
		X1 = "MouseButton4",
		X2 = "MouseButton5",
		XBUTTON1 = "MouseButton4",
		XBUTTON2 = "MouseButton5",
		SIDEBUTTON1 = "MouseButton4",
		SIDEBUTTON2 = "MouseButton5",
		TOUCH = "Touch",
	})[string.upper(name)] or name

	preferredType = normalizeKeyType(preferredType)
	if preferredType == "UserInputType" then
		return enumItemByName(Enum.UserInputType, name) or enumItemByName(Enum.KeyCode, name)
	elseif preferredType == "KeyCode" then
		return enumItemByName(Enum.KeyCode, name) or enumItemByName(Enum.UserInputType, name)
	end

	return enumItemByName(Enum.KeyCode, name) or enumItemByName(Enum.UserInputType, name)
end

local function keyEnumTypeName(key)
	if typeof(key) ~= "EnumItem" then
		return nil
	end

	local enumPath = tostring(key)
	return enumPath:match("^Enum%.([^%.]+)%.")
end

local bindableUserInputTypes = {
	MouseButton1 = true,
	MouseButton2 = true,
	MouseButton3 = true,
	MouseButton4 = true,
	MouseButton5 = true,
}

local function isBindableEnumItem(key)
	local enumTypeName = keyEnumTypeName(key)
	return enumTypeName == "KeyCode" or (enumTypeName == "UserInputType" and bindableUserInputTypes[key.Name] == true)
end

local function inputMatchesBind(input, bind)
	if typeof(bind) ~= "EnumItem" then
		return false
	end

	local enumTypeName = keyEnumTypeName(bind)
	if enumTypeName == "KeyCode" then
		return input.KeyCode == bind
	elseif enumTypeName == "UserInputType" then
		return input.UserInputType == bind
	end

	return false
end

local keybindModeNames = {
	hold = "Hold",
	toggle = "Toggle",
	always = "Always",
}

local keybindModeIndexes = {
	Hold = 1,
	Toggle = 2,
	Always = 3,
}

local function normalizeKeybindMode(mode)
	if type(mode) ~= "string" then
		return "Hold"
	end
	return keybindModeNames[string.lower(mode)] or "Hold"
end

local function isKeybindMode(value)
	return type(value) == "string" and keybindModeNames[string.lower(value)] ~= nil
end

local function inferKeyTypeName(name, preferredType)
	local resolved = keyNameToEnum(name, preferredType)
	if resolved then
		return keyEnumTypeName(resolved)
	end

	preferredType = normalizeKeyType(preferredType)
	if preferredType == "KeyCode" or preferredType == "UserInputType" then
		return preferredType
	end

	if type(name) ~= "string" then
		return nil
	end

	local normalized = name:gsub("^Enum%.KeyCode%.", "")
	normalized = normalized:gsub("^Enum%.UserInputType%.", "")
	normalized = normalized:gsub("^Enum%.", "")
	normalized = normalized:match("^%s*(.-)%s*$")
	if normalized == "" or normalized == "None" or normalized == "NONE" or isKeybindMode(normalized) then
		return nil
	end

	local userInputAliases = {
		MB1 = true,
		MB2 = true,
		MB3 = true,
		MB4 = true,
		MB5 = true,
		M1 = true,
		M2 = true,
		M3 = true,
		M4 = true,
		M5 = true,
		LMB = true,
		RMB = true,
		MMB = true,
		MOUSE4 = true,
		MOUSE5 = true,
		X1 = true,
		X2 = true,
		XBUTTON1 = true,
		XBUTTON2 = true,
		SIDEBUTTON1 = true,
		SIDEBUTTON2 = true,
		TOUCH = true,
	}

	local upperName = string.upper(normalized)
	if normalized:match("^MouseButton%d+$") or normalized:match("^Touch%d+$") or userInputAliases[upperName] then
		return "UserInputType"
	end

	return "KeyCode"
end

local function normalizeConfigKeybinds(value, parentKey)
	if type(value) ~= "table" then
		return value
	end

	local copy = {}
	for key, child in pairs(value) do
		copy[key] = normalizeConfigKeybinds(child, key)
	end

	local keyName = copy.Key or copy.key or copy.Bind or copy.bind or copy[1]
	local keyType = copy.KeyType or copy.keyType or copy.BindType or copy.bindType or copy.TypeName or copy.typeName
	local hasKeybindShape = keyName ~= nil or keyType ~= nil
	local hasModeShape = copy.Type ~= nil or copy.type ~= nil or copy.Active ~= nil or copy.active ~= nil
	local parentMarksKeybind = type(parentKey) == "string" and parentKey:sub(1, 1) == "$"
	local isKeybind = hasKeybindShape or hasModeShape or parentMarksKeybind
	if not isKeybind then
		return copy
	end

	local mode = normalizeKeybindMode(copy.Type or copy.type or copy.Mode or copy.mode or "Hold")
	local active = copy.Active
	if active == nil then
		active = copy.active
	end

	local fixed = {}
	for key, child in pairs(copy) do
		if key ~= "Key" and key ~= "key" and key ~= "Bind" and key ~= "bind"
			and key ~= "KeyType" and key ~= "keyType" and key ~= "BindType" and key ~= "bindType"
			and key ~= "TypeName" and key ~= "typeName"
			and key ~= "Type" and key ~= "type"
			and key ~= "Active" and key ~= "active"
			and key ~= "Mode" and key ~= "mode"
			and key ~= 1 then
			fixed[key] = child
		end
	end

	local keyString = keyName or "NONE"
	local resolved = keyNameToEnum(keyString, keyType)
	if resolved then
		fixed.Key = resolved.Name
		fixed.KeyType = keyEnumTypeName(resolved)
	elseif type(keyString) == "string" and keyString ~= "" and keyString ~= "None" and keyString ~= "NONE" then
		fixed.Key = keyString
		keyType = normalizeKeyType(keyType)
		if keyType == "KeyCode" or keyType == "UserInputType" then
			fixed.KeyType = keyType
		else
			fixed.KeyType = inferKeyTypeName(keyString, keyType)
		end
	else
		fixed.Key = "NONE"
		fixed.KeyType = nil
	end

	fixed.Type = mode
	fixed.Active = active ~= nil and active == true or mode == "Always"
	return fixed
end

local function asArrayFromSelection(selection, optionOrder)
	if type(selection) ~= "table" then
		return {}
	end

	local selected = {}
	for _, option in ipairs(optionOrder or {}) do
		if selection[option] then
			table.insert(selected, option)
		end
	end

	for option, state in pairs(selection) do
		if state and not table.find(selected, option) then
			table.insert(selected, option)
		end
	end

	return selected
end

function library.new(libraryTitle, cfgLocation)
	local menu = {}
	menu.values = {}
	menu._elements = {}
	menu.on_load_cfg = createSignal()
	menu.open = true
	menu.cfg_location = cfgLocation or ""
	local menuToggleKey = Enum.KeyCode.RightControl
	local macMenuParkingKey = Enum.KeyCode.Pause
	local blockedMenuToggleKeys = {}

	ensureFolder(menu.cfg_location)
	pcall(function()
		MacLib:SetFolder(menu.cfg_location ~= "" and menu.cfg_location or "Maclib")
	end)

	destroyOldMenus()

	local parents = getUiParents()
	local before = snapshotChildren(parents)

	local window = MacLib:Window({
		Title = libraryTitle or "Window",
		Subtitle = "Credits - KT.RK.JD",
		Size = UDim2.fromOffset(868, 650),
		DragStyle = 1,
		DisabledWindowControls = { "Exit", "Minimize", "Maximize" },
		ShowUserInfo = false,
		Keybind = macMenuParkingKey,
		AcrylicBlur = false,
	})

	pcall(function()
		MacLib:SetFolder(menu.cfg_location ~= "" and menu.cfg_location or "Maclib")
	end)

	menu.window = window
	menu.maclib = MacLib
	menu.tab_group = window:TabGroup()
	menu.gui = findCreatedGui(before)

	local themeAccentEnabled = false
	local themeAccentColor = Color3.fromRGB(103, 182, 254)
	local themeAccentPreviousColor = themeAccentColor
	local themeAccentDefaults = setmetatable({}, { __mode = "k" })
	local themeAccentWatchConnections = setmetatable({}, { __mode = "k" })
	local inlineColorSwatchSyncs = setmetatable({}, { __mode = "k" })
	local applyThemeAccentToObject

	local function syncColorPickerOutlines()
		if not menu.gui then
			return
		end

		local outlineColor = Color3.fromRGB(255, 255, 255)
		local outlineTransparency = 0.65
		for _, object in ipairs(menu.gui:GetDescendants()) do
			if object:IsA("UIStroke") and object.Name == "ColorPickerOutline" then
				pcall(function()
					object.Color = outlineColor
					object.Transparency = outlineTransparency
				end)
			end
		end
	end

	local function syncInlineColorSwatches()
		for _, sync in pairs(inlineColorSwatchSyncs) do
			pcall(sync)
		end
		syncColorPickerOutlines()
	end

	local function isThemeAccentColor(color)
		if typeof(color) ~= "Color3" then
			return false
		end

		local red = color.R * 255
		local green = color.G * 255
		local blue = color.B * 255
		return blue >= 115 and red <= 185 and blue - red >= 25 and (green >= 55 or blue >= 180)
	end

	local function colorsClose(left, right)
		if typeof(left) ~= "Color3" or typeof(right) ~= "Color3" then
			return false
		end

		return math.abs(left.R - right.R) <= 0.01 and math.abs(left.G - right.G) <= 0.01 and math.abs(left.B - right.B) <= 0.01
	end

	local function isToggleTrack(object)
		return object and object:IsA("ImageButton") and object.Name == "Toggle" and object.Parent and object.Parent.Name == "Toggle"
	end

	local function isActiveTabObject(object)
		local tabSwitcher = object and (object.Name == "TabSwitcher" and object or object.Parent)
		return tabSwitcher and tabSwitcher:IsA("GuiObject") and tabSwitcher.Name == "TabSwitcher" and tabSwitcher.BackgroundTransparency < 1
	end

	local function isThemeProtectedObject(object)
		local current = object
		while current and current ~= menu.gui do
			if current.Name == "InlineColor" or current.Name == "ColorPicker" or current.Name == "ColorOptions" or current.Name == "ColorPickerCanvas" then
				return true
			end
			local ok, ignored = pcall(function()
				return current:GetAttribute("ThemeIgnore")
			end)
			if ok and ignored then
				return true
			end
			current = current.Parent
		end
		return false
	end

	local function isDisabledToggleColor(object, property, color)
		if property == "BackgroundColor3" or property == "ImageColor3" then
			return isToggleTrack(object) and colorsClose(color, Color3.fromRGB(11, 13, 15))
		end
		if property == "Color" then
			return object and object:IsA("UIStroke") and object.Name == "ToggleUIStroke" and colorsClose(color, Color3.fromRGB(42, 46, 52))
		end
		return false
	end

	local function isThemeAccentTarget(object, property)
		if not object then
			return false
		end
		if (property == "BackgroundColor3" or property == "ImageColor3") and isToggleTrack(object) then
			return true
		end
		if property == "Color" and object:IsA("UIStroke") and object.Name == "ToggleUIStroke" then
			return true
		end
		if property == "BackgroundColor3" and object.Name == "SliderFrame" then
			return true
		end
		if property == "ImageColor3" and object.Name == "SliderBar" then
			return true
		end
		if property == "Color" and object:IsA("UIGradient") and object.Name == "SliderGradient" then
			return true
		end
		if property == "TextColor3" and object.Name == "TabSwitcherName" then
			return true
		end
		if property == "ImageColor3" and object.Name == "TabImage" then
			return true
		end
		if property == "Color" and object:IsA("UIStroke") and object.Name == "TabSwitcherUIStroke" then
			return true
		end
		return false
	end

	local function isForcedThemeAccentProperty(object, property)
		if not object then
			return false
		end

		if property == "TextColor3" and object.Name == "TabSwitcherName" then
			return true
		end

		if property == "BackgroundColor3" and object.Name == "SliderFrame" then
			return true
		end

		if property == "ImageColor3" and object.Name == "SliderBar" then
			return true
		end

		if property == "Color" and object:IsA("UIStroke") and object.Name == "TabSwitcherUIStroke" then
			return true
		end

		return false
	end

	local themeAccentObjectQueue = {}
	local themeAccentObjectQueued = false
	local function scheduleThemeAccentObject(object)
		if not themeAccentEnabled then
			return
		end

		themeAccentObjectQueue[object] = true
		if themeAccentObjectQueued then
			return
		end
		themeAccentObjectQueued = true
		task.defer(function()
			themeAccentObjectQueued = false
			if themeAccentEnabled then
				for queuedObject in pairs(themeAccentObjectQueue) do
					applyThemeAccentToObject(queuedObject)
					themeAccentObjectQueue[queuedObject] = nil
				end
			else
				themeAccentObjectQueue = {}
			end
		end)
	end

	local function watchThemeAccentObject(object)
		if not object or themeAccentWatchConnections[object] then
			return
		end

		local properties = {}
		if object:IsA("TextLabel") or object:IsA("TextButton") or object:IsA("TextBox") then
			table.insert(properties, "TextColor3")
		end
		if object:IsA("ImageLabel") or object:IsA("ImageButton") then
			table.insert(properties, "ImageColor3")
		end
		if object:IsA("GuiObject") then
			table.insert(properties, "BackgroundColor3")
			table.insert(properties, "BorderColor3")
		end
		if object:IsA("UIStroke") then
			table.insert(properties, "Color")
		end
		if object:IsA("UIGradient") then
			table.insert(properties, "Color")
		end

		if #properties == 0 then
			return
		end

		local connections = {}
		themeAccentWatchConnections[object] = connections
		for _, property in ipairs(properties) do
			pcall(function()
				table.insert(connections, object:GetPropertyChangedSignal(property):Connect(function()
					scheduleThemeAccentObject(object)
				end))
			end)
		end
	end

	local function saveThemeDefault(object, property, value)
		local defaults = themeAccentDefaults[object]
		if not defaults then
			defaults = {}
			themeAccentDefaults[object] = defaults
		end
		if defaults[property] == nil then
			defaults[property] = value
		end
	end

	local function applyThemeAccentProperty(object, property)
		local ok, value = pcall(function()
			return object[property]
		end)
		if not ok or typeof(value) ~= "Color3" then
			return
		end
		if not isThemeAccentTarget(object, property) then
			return
		end
		if isDisabledToggleColor(object, property, value) then
			return
		end

		local defaults = themeAccentDefaults[object]
		if not ((defaults and defaults[property] ~= nil) or isThemeAccentColor(value) or colorsClose(value, themeAccentPreviousColor) or isForcedThemeAccentProperty(object, property)) then
			return
		end

		saveThemeDefault(object, property, value)
		pcall(function()
			object[property] = themeAccentColor
		end)
	end

	local function applyThemeAccentGradientProperty(object, property)
		local ok, value = pcall(function()
			return object[property]
		end)
		if not ok or typeof(value) ~= "ColorSequence" then
			return
		end
		if not isThemeAccentTarget(object, property) then
			return
		end

		local defaults = themeAccentDefaults[object]
		if not ((defaults and defaults[property] ~= nil) or (object:IsA("UIGradient") and object.Name == "SliderGradient")) then
			return
		end

		saveThemeDefault(object, property, value)
		pcall(function()
			object[property] = ColorSequence.new(themeAccentColor)
		end)
	end

	function applyThemeAccentToObject(object)
		if not object then
			return
		end
		if object:IsA("UIStroke") and object.Name == "ColorPickerOutline" then
			pcall(function()
				object.Color = Color3.fromRGB(255, 255, 255)
				object.Transparency = 0.65
			end)
			return
		end
		if object:IsA("UIStroke") and object.Name == "TabSwitcherUIStroke" then
			pcall(function()
				object.Color = themeAccentColor
				object.Thickness = 1
			end)
			return
		end
		if object:IsA("ImageLabel") and object.Name == "TabImage" then
			saveThemeDefault(object, "ImageColor3", object.ImageColor3)
			pcall(function()
				object.ImageColor3 = isActiveTabObject(object) and themeAccentColor or Color3.fromRGB(255, 255, 255)
			end)
			return
		end
		if object:IsA("GuiObject") and object.Name:match("^ThemeAccentLine") then
			pcall(function()
				object.BackgroundColor3 = object.Name == "ThemeAccentLineRight" and Color3.fromRGB(34, 40, 42) or Color3.fromRGB(103, 182, 254)
				object.BackgroundTransparency = object.Name == "ThemeAccentLineRight" and 0.2 or 1
				if object.Name == "ThemeAccentLineBottom" or object.Name == "ThemeAccentLineTop" then
					object.Visible = false
				end
			end)
			return
		end
		if isThemeProtectedObject(object) then
			return
		end
		watchThemeAccentObject(object)

		if object:IsA("TextLabel") or object:IsA("TextButton") or object:IsA("TextBox") then
			applyThemeAccentProperty(object, "TextColor3")
		end
		if object:IsA("ImageLabel") or object:IsA("ImageButton") then
			applyThemeAccentProperty(object, "ImageColor3")
		end
		if object:IsA("GuiObject") then
			applyThemeAccentProperty(object, "BackgroundColor3")
			applyThemeAccentProperty(object, "BorderColor3")
		end
		if object:IsA("UIStroke") then
			applyThemeAccentProperty(object, "Color")
		end
		if object:IsA("UIGradient") then
			applyThemeAccentGradientProperty(object, "Color")
		end
	end

	local function applyThemeAccent()
		if not menu.gui or not themeAccentEnabled then
			return
		end

		applyThemeAccentToObject(menu.gui)
		for _, object in ipairs(menu.gui:GetDescendants()) do
			applyThemeAccentToObject(object)
		end
		syncInlineColorSwatches()
	end

	local function scheduleThemeAccentPasses()
		applyThemeAccent()
		for _, delayTime in ipairs({ 0.05, 0.2, 0.5, 1 }) do
			task.delay(delayTime, function()
				applyThemeAccent()
				syncInlineColorSwatches()
			end)
		end
	end

	local function restoreThemeAccent()
		for object, defaults in pairs(themeAccentDefaults) do
			for property, value in pairs(defaults) do
				pcall(function()
					object[property] = value
				end)
			end
		end
		themeAccentDefaults = setmetatable({}, { __mode = "k" })
		for _, connections in pairs(themeAccentWatchConnections) do
			for _, connection in ipairs(connections) do
				pcall(function()
					connection:Disconnect()
				end)
			end
		end
		themeAccentWatchConnections = setmetatable({}, { __mode = "k" })
	end

	local opaquePassQueued = false
	local function scheduleOpaquePass()
		if opaquePassQueued then
			return
		end

		opaquePassQueued = true
		task.defer(function()
			opaquePassQueued = false
			tuneMacSidebarLayout(menu.gui)
			forceOpaqueMacUi(menu.gui)
			applyThemeAccent()
			syncInlineColorSwatches()
		end)
	end

	if menu.gui then
		pcall(function()
			menu.gui.Name = "unknown"
		end)
		pcall(function()
			menu.gui.Parent = CoreGui
		end)
		ensureLegacyMain(menu.gui)
		hideMacWindowControls(menu.gui)
		tuneMacSidebarLayout(menu.gui)
		makeTopbarDraggable(menu.gui)
		forceOpaqueMacUi(menu.gui)
		applyThemeAccent()
		task.delay(0.1, function()
			tuneMacSidebarLayout(menu.gui)
			forceOpaqueMacUi(menu.gui)
			applyThemeAccent()
		end)
		menu._themeAccentConnection = menu.gui.DescendantAdded:Connect(function(object)
			scheduleThemeAccentObject(object)
		end)
	end

	function menu:GetGui()
		return menu.gui
	end

	function menu.IsOpen()
		return menu.open
	end

	function menu.SetOpen(state)
		menu.open = state and true or false
		if menu.gui then
			menu.gui.Enabled = menu.open
		end
	end

	function menu.SetMenuKeybind(key)
		local nextKey = keyNameToEnum(key)
		if not nextKey or not isBindableEnumItem(nextKey) then
			return false
		end
		if keyEnumTypeName(nextKey) == "KeyCode" and blockedMenuToggleKeys[nextKey.Name] then
			return false
		end

		menuToggleKey = nextKey
		return true
	end

	function menu.GetMenuKeybind()
		return menuToggleKey
	end

	function menu.SetThemeAccent(enabled, color)
		themeAccentEnabled = enabled and true or false
		if typeof(color) == "Color3" then
			themeAccentPreviousColor = themeAccentColor
			themeAccentColor = color
		end

		if themeAccentEnabled then
			scheduleThemeAccentPasses()
		else
			restoreThemeAccent()
			syncInlineColorSwatches()
		end
		return true
	end

	function menu.GetThemeAccent()
		return themeAccentEnabled, themeAccentColor
	end

	function menu.GetPosition()
		local base = menu.gui and menu.gui:FindFirstChild("Base", true)
		return base and base.Position or UDim2.fromScale(0.5, 0.5)
	end

	function menu.copy(original)
		return deepCopy(original)
	end

	function menu.fix_keybinds()
		menu.values = normalizeConfigKeybinds(menu.values)
		return menu.values
	end

	function menu.save_cfg(cfgName)
		if not writefile then
			return false, "writefile unavailable"
		end

		menu.fix_keybinds()
		local ok, encoded = pcall(function()
			return HttpService:JSONEncode(serialize(menu.values))
		end)

		if not ok then
			return false, encoded
		end

		ensureFolder(menu.cfg_location)
		local path = configPath(menu.cfg_location, cfgName)
		writefile(path, encoded)

		local legacyPath = legacyConfigPath(menu.cfg_location, cfgName)
		if legacyPath ~= path then
			pcall(function()
				writefile(legacyPath, encoded)
			end)
		end

		return true
	end

	local getLoadedValue

	local function forceHoldKeybindValue(loaded, element)
		local value = type(loaded) == "table" and deepCopy(loaded) or {}
		if loaded == nil and element and element.get_value then
			local current = element:get_value()
			value = type(current) == "table" and deepCopy(current) or value
		elseif typeof(loaded) == "EnumItem" or type(loaded) == "string" then
			value.Key = typeof(loaded) == "EnumItem" and loaded.Name or loaded
			value.KeyType = typeof(loaded) == "EnumItem" and keyEnumTypeName(loaded) or nil
		end
		value.Type = "Hold"
		value.Active = false
		return value
	end

	local function applyLoadedConfigValues(forceKeybindsHold)
		local processed = 0
		for tabNum, sections in pairs(menu._elements) do
			for sectionName, sectors in pairs(sections) do
				for sectorName, elements in pairs(sectors) do
					for flag, element in pairs(elements) do
						local loaded = getLoadedValue(tabNum, sectionName, sectorName, flag)
						if loaded == nil and element._configKind == "Keybind" and flag == "Toggle Menu Key" then
							loaded = getLoadedValue(tabNum, sectionName, sectorName, "$Toggle Menu Key")
						end
						if forceKeybindsHold and element._configKind == "Keybind" then
							loaded = forceHoldKeybindValue(loaded, element)
						end
						if loaded ~= nil and element.set_value then
							element:set_value(loaded, element._configKind == "Keybind" and "load" or nil)
							processed = processed + 1
							if processed % 20 == 0 then
								task.wait()
							end
						end
					end
				end
			end
		end
	end

	function menu.load_cfg(cfgName)
		if not (isfile and readfile) then
			return false, "readfile unavailable"
		end

		local path = configPath(menu.cfg_location, cfgName)
		local legacyPath = legacyConfigPath(menu.cfg_location, cfgName)
		if not isfile(path) then
			if legacyPath ~= path and isfile(legacyPath) then
				path = legacyPath
			else
				return false, "config not found"
			end
		end

		local ok, decoded = pcall(function()
			return deserialize(HttpService:JSONDecode(readfile(path)))
		end)

		if not ok or type(decoded) ~= "table" then
			return false, decoded
		end

		local loadName = tostring(cfgName or ""):gsub("^%s+", ""):gsub("%s+$", ""):lower()
		menu.values = normalizeConfigKeybinds(decoded)
		applyLoadedConfigValues(loadName == "default")
		menu.on_load_cfg:Fire()
		return true
	end

	local function getValuePath(tabNum, sectionName, sectorName, flag)
		menu.values[tabNum] = menu.values[tabNum] or {}
		menu.values[tabNum][sectionName] = menu.values[tabNum][sectionName] or {}
		menu.values[tabNum][sectionName][sectorName] = menu.values[tabNum][sectionName][sectorName] or {}
		return menu.values[tabNum][sectionName][sectorName], flag
	end

	getLoadedValue = function(tabNum, sectionName, sectorName, flag)
		local tabValues = menu.values[tabNum]
		local sectionValues = tabValues and tabValues[sectionName]
		local sectorValues = sectionValues and sectionValues[sectorName]
		return sectorValues and sectorValues[flag]
	end

	local function registerElement(tabNum, sectionName, sectorName, flag, element)
		menu._elements[tabNum] = menu._elements[tabNum] or {}
		menu._elements[tabNum][sectionName] = menu._elements[tabNum][sectionName] or {}
		menu._elements[tabNum][sectionName][sectorName] = menu._elements[tabNum][sectionName][sectorName] or {}
		menu._elements[tabNum][sectionName][sectorName][flag] = element

	end

	local function makeMacFlag(tabNum, sectionName, sectorName, flag)
		return tostring(tabNum) .. "/" .. tostring(sectionName) .. "/" .. tostring(sectorName) .. "/" .. tostring(flag)
	end

	local tabCount = 0
	local selectedFirstTab = false

	function menu.new_tab(tabImage, tabTitle)
		tabCount = tabCount + 1
		local tab = {
			tab_num = tabCount,
			name = tabTitle or ("Tab " .. tostring(tabCount)),
		}

		menu.values[tab.tab_num] = menu.values[tab.tab_num] or {}

		tab.macTab = menu.tab_group:Tab({
			Name = tab.name,
			Image = tabImage,
		})
		scheduleOpaquePass()

		if not selectedFirstTab then
			selectedFirstTab = true
			pcall(function()
				tab.macTab:Select()
			end)
			scheduleOpaquePass()
		end

		function tab.new_section(sectionName)
			local section = {
				name = sectionName or "Section",
			}

			menu.values[tab.tab_num][section.name] = menu.values[tab.tab_num][section.name] or {}

			function section.new_sector(sectorName, sectorSide)
				local sector = {
					name = sectorName or "Sector",
					side = sectorSide == "Right" and "Right" or "Left",
				}

				local macSection = tab.macTab:Section({
					Side = sector.side,
				})

				sector.macSection = macSection
				menu.values[tab.tab_num][section.name][sector.name] = menu.values[tab.tab_num][section.name][sector.name] or {}

				pcall(function()
					macSection:Header({
						Name = sector.name,
					})
				end)
				scheduleOpaquePass()

				function sector.create_line()
					pcall(function()
						macSection:Divider()
					end)
					scheduleOpaquePass()
				end

				function sector.element(elementType, text, data, callback, dangerous, cFlag)
					if type(data) ~= "table" then
						data = {}
					end
					callback = callback or function() end
					text = text or elementType

					local flag = cFlag and (text .. " " .. tostring(cFlag)) or text
					getValuePath(tab.tab_num, section.name, sector.name, flag)
					local rawDefault = data.default
					local defaults = type(rawDefault) == "table" and rawDefault or {}
					local macFlag = makeMacFlag(tab.tab_num, section.name, sector.name, flag)
					local value = {}
					local element = {}
					element._configKind = "Base"
					local macObject

					local function store(newValue)
						value = newValue
						local values, valueKey = getValuePath(tab.tab_num, section.name, sector.name, flag)
						values[valueKey] = value
					end

					local function fire()
						callback(value)
					end

					function element:get_value()
						return value
					end

					function element:set_visible(state)
						if macObject and macObject.SetVisibility then
							macObject:SetVisibility(state and true or false)
						end
					end

					local function attachInlineColorPicker(colorPicker)
						local targetFrame = macObject and macObject.Instance
						local pickerFrame = colorPicker and colorPicker.Instance
						local swatch = colorPicker and colorPicker.Swatch
						if not (targetFrame and pickerFrame and swatch) then
							return nil
						end

						pickerFrame.AutomaticSize = Enum.AutomaticSize.None
						pickerFrame.Size = UDim2.new(1, 0, 0, 0)
						pickerFrame.Visible = false
						swatch.Name = "InlineColor"
						pcall(function()
							swatch:SetAttribute("ThemeIgnore", true)
						end)
						for _, child in ipairs(swatch:GetDescendants()) do
							pcall(function()
								child:SetAttribute("ThemeIgnore", true)
							end)
						end
						swatch.Parent = targetFrame
						swatch.AnchorPoint = Vector2.new(1, 0.5)
						swatch.Size = UDim2.fromOffset(21, 21)
						swatch.ZIndex = 20

						if macObject.Class == "Toggle" then
							swatch.Position = UDim2.new(1, -44, 0.5, 0)
						elseif macObject.Class == "Slider" then
							swatch.Position = UDim2.new(1, -203, 0.5, 0)
						else
							swatch.Position = UDim2.new(1, -8, 0.5, 0)
						end

						return swatch
					end

					local function attachInlineKeybind(keybind)
						local targetFrame = macObject and macObject.Instance
						local keybindFrame = keybind and keybind.Instance
						if not (targetFrame and keybindFrame) then
							return nil
						end

						local binderBox = keybindFrame:FindFirstChild("BinderBox")
						if not binderBox then
							return nil
						end

						keybindFrame.AutomaticSize = Enum.AutomaticSize.None
						keybindFrame.Size = UDim2.new(1, 0, 0, 0)
						keybindFrame.Visible = false

						binderBox.Parent = targetFrame
						binderBox.AnchorPoint = Vector2.new(1, 0.5)
						binderBox.Position = UDim2.new(1, -44, 0.5, 0)
						binderBox.Size = UDim2.fromOffset(104, 18)
						binderBox.ZIndex = 25
						pcall(function()
							binderBox:SetAttribute("ThemeIgnore", true)
						end)
						for _, child in ipairs(binderBox:GetDescendants()) do
							pcall(function()
								child:SetAttribute("ThemeIgnore", true)
							end)
						end

						local targetLabel = targetFrame:FindFirstChild("ToggleName") or targetFrame:FindFirstChild("KeybindName")
						if targetLabel and targetLabel:IsA("TextLabel") then
							targetLabel.Size = UDim2.new(1, -155, targetLabel.Size.Y.Scale, targetLabel.Size.Y.Offset)
						end

						return binderBox
					end

					local function attachInlineKeybindMode(modeDropdown, keyValue)
						local targetFrame = macObject and macObject.Instance
						local modeFrame = modeDropdown and modeDropdown.Instance
						if not (targetFrame and modeFrame) then
							return nil
						end

						modeFrame.Parent = targetFrame
						targetFrame.ClipsDescendants = false
						modeFrame.AnchorPoint = Vector2.new(1, 0.5)
						modeFrame.Position = UDim2.new(1, -44, 0.5, 0)
						modeFrame.Size = UDim2.fromOffset(86, 20)
						modeFrame.ClipsDescendants = false
						modeFrame.ZIndex = 25
						for _, child in ipairs(modeFrame:GetDescendants()) do
							pcall(function()
								child.ZIndex = 25
								child:SetAttribute("ThemeIgnore", true)
							end)
						end

						local modeLabel = modeFrame:FindFirstChild("DropdownName")
						local function syncModeLabel()
							if modeLabel then
								modeLabel.Text = normalizeKeybindMode(keyValue.Type)
							end
						end
						syncModeLabel()

						return {
							Frame = modeFrame,
							Sync = syncModeLabel,
						}
					end

					if elementType == "Toggle" then
						store({
							Toggle = defaults.Toggle or false,
						})

						macObject = macSection:Toggle({
							Name = text,
							Default = value.Toggle,
							Callback = function(state)
								store({
									Toggle = state and true or false,
								})
								fire()
							end,
						}, macFlag)

						function element:set_value(newValue, cb)
							local nextState = type(newValue) == "table" and newValue.Toggle or newValue
							store({
								Toggle = nextState and true or false,
							})
							if macObject and macObject.UpdateState then
								macObject:UpdateState(value.Toggle, cb and true or false)
							elseif not cb then
								fire()
							end
						end

						function element:add_color(colorDefault, hasTransparency, colorCallback)
							colorCallback = colorCallback or function() end
							if typeof(colorDefault) == "Color3" then
								colorDefault = {
									Color = colorDefault,
								}
							elseif type(colorDefault) ~= "table" then
								colorDefault = {}
							end

							local extraFlag = "$" .. flag
							getValuePath(tab.tab_num, section.name, sector.name, extraFlag)
							local defaultTransparency = colorDefault.Transparency
							if defaultTransparency == nil then
								defaultTransparency = colorDefault.Alpha
							end
							if defaultTransparency == nil then
								defaultTransparency = 0
							end
							local colorValue = {
								Color = colorDefault.Color or Color3.new(1, 1, 1),
								Transparency = defaultTransparency,
							}

							local function storeColor(newValue)
								colorValue = newValue
								local extraValues, extraValueKey = getValuePath(tab.tab_num, section.name, sector.name, extraFlag)
								extraValues[extraValueKey] = colorValue
							end

							storeColor(colorValue)

							local colorObject = {}
							colorObject._configKind = "Extra"
							local inlineSwatch
							local function syncInlineSwatchColor()
								if not inlineSwatch then
									return
								end

								local fill = inlineSwatch:FindFirstChild("Color")
								if fill and fill:IsA("GuiObject") then
									fill.BackgroundColor3 = colorValue.Color
									fill.BackgroundTransparency = 0
								elseif inlineSwatch:IsA("GuiObject") then
									inlineSwatch.BackgroundColor3 = colorValue.Color
								end
								local alphaText = inlineSwatch:FindFirstChild("AlphaText")
								if alphaText and alphaText:IsA("TextLabel") then
									local alpha = math.clamp(tonumber(colorValue.Transparency) or 0, 0, 1)
									alphaText.Visible = hasTransparency
									alphaText.Text = hasTransparency and ((alpha == 0 or alpha == 1) and tostring(alpha) or string.format("%.2f", alpha):gsub("0+$", ""):gsub("%.$", "")) or ""
								end
							end
							local colorPicker = macSection:Colorpicker({
								Name = text .. " Color",
								Default = colorValue.Color,
								Alpha = hasTransparency and colorValue.Transparency or nil,
								Callback = function(color, alpha)
									colorValue = {
										Color = color,
										Transparency = alpha or colorValue.Transparency or 0,
									}
									storeColor(colorValue)
									syncInlineSwatchColor()
									colorCallback(colorValue)
								end,
							}, makeMacFlag(tab.tab_num, section.name, sector.name, extraFlag))
							inlineSwatch = attachInlineColorPicker(colorPicker)
							if inlineSwatch then
								inlineColorSwatchSyncs[inlineSwatch] = syncInlineSwatchColor
							end
							syncInlineSwatchColor()
							scheduleOpaquePass()

							function colorObject:get_value()
								return colorValue
							end

							function colorObject:set_visible(state)
								if inlineSwatch then
									inlineSwatch.Visible = state and true or false
								elseif colorPicker and colorPicker.SetVisibility then
									colorPicker:SetVisibility(state and true or false)
								end
							end

							function colorObject:set_value(newValue, cb)
								if type(newValue) == "table" then
									colorValue = {
										Color = newValue.Color or colorValue.Color,
										Transparency = newValue.Transparency or newValue.Alpha or colorValue.Transparency or 0,
									}
								end

								storeColor(colorValue)
								if colorPicker and colorPicker.SetColor then
									if hasTransparency and colorPicker.SetAlpha then
										colorPicker:SetAlpha(colorValue.Transparency)
									end
									colorPicker:SetColor(colorValue.Color)
									syncInlineSwatchColor()
								elseif not cb then
									colorCallback(colorValue)
								end
							end

							registerElement(tab.tab_num, section.name, sector.name, extraFlag, colorObject)
							return colorObject
						end

						function element:add_keybind(keyDefault, keyCallback)
							keyCallback = keyCallback or function() end

							local extraFlag = "$" .. flag
							getValuePath(tab.tab_num, section.name, sector.name, extraFlag)
							local defaultKey = keyDefault
							local defaultKeyType
							local defaultType = "Hold"
							if type(keyDefault) == "table" then
								defaultKey = keyDefault.Key or keyDefault.key or keyDefault.Bind or keyDefault.bind or keyDefault[1]
								defaultKeyType = keyDefault.KeyType or keyDefault.keyType or keyDefault.BindType or keyDefault.bindType or keyDefault.TypeName or keyDefault.typeName
								defaultType = normalizeKeybindMode(keyDefault.Type or keyDefault.type or keyDefault.Mode or keyDefault.mode or "Hold")
							elseif isKeybindMode(keyDefault) then
								defaultKey = nil
								defaultType = normalizeKeybindMode(keyDefault)
							end
							local defaultBind = keyNameToEnum(defaultKey, defaultKeyType)
							local keyValue = {
								Key = defaultBind and defaultBind.Name or "NONE",
								KeyType = defaultBind and keyEnumTypeName(defaultBind) or nil,
								Type = defaultType,
								Active = defaultType == "Always",
							}

							local function storeKey(newValue)
								newValue.Key = newValue.Key or "NONE"
								keyValue = newValue
								local extraValues, extraValueKey = getValuePath(tab.tab_num, section.name, sector.name, extraFlag)
								extraValues[extraValueKey] = keyValue
							end

							local function applyBindToKeyValue(bind)
								keyValue.Key = bind and bind.Name or "NONE"
								keyValue.KeyType = bind and keyEnumTypeName(bind) or nil
							end

							storeKey(keyValue)

							local keybindObject = {}
							keybindObject._configKind = "Keybind"
							local keybind = macSection:Keybind({
								Name = text .. " Key",
								Default = defaultBind,
								Blacklist = false,
								Callback = function(bind)
									applyBindToKeyValue(bind)
									if keyValue.Type == "Toggle" then
										keyValue.Active = not keyValue.Active
										storeKey(keyValue)
										keyCallback(keyValue)
									elseif keyValue.Type == "Always" then
										keyValue.Active = true
										storeKey(keyValue)
										keyCallback(keyValue)
									end
								end,
								onBindHeld = function(isHeld, bind)
									applyBindToKeyValue(bind)
									if keyValue.Type == "Hold" then
										keyValue.Active = isHeld and true or false
										storeKey(keyValue)
										keyCallback(keyValue)
									end
								end,
								onBinded = function(bind)
									applyBindToKeyValue(bind)
									keyValue.Active = keyValue.Type == "Always"
									storeKey(keyValue)
									keyCallback(keyValue)
								end,
							}, makeMacFlag(tab.tab_num, section.name, sector.name, extraFlag))
							local bindKeybind = keybind and keybind.Bind
							local unbindKeybind = keybind and keybind.Unbind
							local inlineBinder = macObject and macObject.Class == "Toggle" and attachInlineKeybind(keybind) or nil

							local suppressModeCallback = false
							local inlineMode
							local modeDropdown = macSection:Dropdown({
								Name = text .. " Key Mode",
								Multi = false,
								Required = true,
								Options = {
									"Hold",
									"Toggle",
									"Always",
								},
								Default = keybindModeIndexes[defaultType] or 1,
								Callback = function(mode)
									if suppressModeCallback then
										return
									end
									keyValue.Type = normalizeKeybindMode(mode)
									keyValue.Active = keyValue.Type == "Always"
									storeKey(keyValue)
									if inlineMode then
										task.defer(inlineMode.Sync)
									end
									keyCallback(keyValue)
								end,
							}, makeMacFlag(tab.tab_num, section.name, sector.name, extraFlag .. "/mode"))
							inlineMode = inlineBinder and attachInlineKeybindMode(modeDropdown, keyValue) or nil
							if inlineMode then
								inlineBinder.Position = UDim2.new(1, -136, 0.5, 0)
								local targetLabel = macObject.Instance:FindFirstChild("ToggleName")
								if targetLabel and targetLabel:IsA("TextLabel") then
									targetLabel.Size = UDim2.new(1, -245, targetLabel.Size.Y.Scale, targetLabel.Size.Y.Offset)
								end
							end
							scheduleOpaquePass()

							function keybindObject:get_value()
								return keyValue
							end

							function keybindObject:set_visible(state)
								if inlineBinder then
									inlineBinder.Visible = state and true or false
								elseif keybind and keybind.SetVisibility then
									keybind:SetVisibility(state and true or false)
								end
								if modeDropdown and modeDropdown.SetVisibility then
									modeDropdown:SetVisibility(state and true or false)
								end
							end

							function keybindObject:set_value(newValue, cb)
								local isConfigLoad = cb == "load"
								local shouldCallback = isConfigLoad or not cb

								if typeof(newValue) == "EnumItem" or type(newValue) == "string" then
									local stringIsMode = isKeybindMode(newValue)
									local restoredType = stringIsMode and normalizeKeybindMode(newValue) or normalizeKeybindMode(keyValue.Type)
									local restoredKey = typeof(newValue) == "EnumItem" and newValue.Name or newValue or "NONE"
									keyValue = {
										Key = stringIsMode and keyValue.Key or restoredKey,
										KeyType = stringIsMode and keyValue.KeyType or (typeof(newValue) == "EnumItem" and keyEnumTypeName(newValue) or inferKeyTypeName(restoredKey, keyValue.KeyType)),
										Type = restoredType,
										Active = restoredType == "Always",
									}
								elseif type(newValue) == "table" then
									local restoredType = normalizeKeybindMode(newValue.Type or newValue.type or keyValue.Type)
									local restoredActive = newValue.Active
									if restoredActive == nil then
										restoredActive = newValue.active
									end
									keyValue = {
										Key = newValue.Key or newValue.key or newValue.Bind or newValue.bind or newValue[1] or "NONE",
										KeyType = newValue.KeyType or newValue.keyType or newValue.BindType or newValue.bindType or newValue.TypeName or newValue.typeName,
										Type = restoredType,
										Active = restoredActive ~= nil and restoredActive == true or restoredType == "Always",
									}
								end

								local enumBind = keyNameToEnum(keyValue.Key, keyValue.KeyType)
								if enumBind then
									keyValue.Key = enumBind.Name
									keyValue.KeyType = keyEnumTypeName(enumBind)
								elseif type(keyValue.Key) == "string" and keyValue.Key ~= "" and keyValue.Key ~= "None" and keyValue.Key ~= "NONE" then
									keyValue.KeyType = inferKeyTypeName(keyValue.Key, keyValue.KeyType)
									keyValue.Active = keyValue.Type == "Always"
								else
									keyValue.Key = "NONE"
									keyValue.KeyType = nil
									keyValue.Active = keyValue.Type == "Always"
								end

								storeKey(keyValue)

								local restoredKeyValue = {
									Key = keyValue.Key,
									KeyType = keyValue.KeyType,
									Type = keyValue.Type,
									Active = keyValue.Active,
								}

								local function applyBindToWidget()
									if enumBind and type(bindKeybind) == "function" then
										bindKeybind(keybind, enumBind, true)
									elseif type(unbindKeybind) == "function" then
										unbindKeybind(keybind, true)
									end
								end

								if keybind then
									applyBindToWidget()
									task.defer(function()
										storeKey(restoredKeyValue)
										applyBindToWidget()
									end)
								end

								if modeDropdown and modeDropdown.UpdateSelection then
									suppressModeCallback = true
									modeDropdown:UpdateSelection(keyValue.Type)
									suppressModeCallback = false
								end
								if inlineMode then
									task.defer(inlineMode.Sync)
								end

								if shouldCallback then
									keyCallback(keyValue)
								end
							end

							registerElement(tab.tab_num, section.name, sector.name, extraFlag, keybindObject)
							return keybindObject
						end
					elseif elementType == "Slider" then
						local min = tonumber(defaults.min) or 0
						local max = tonumber(defaults.max) or 100
						local default = tonumber(defaults.default) or min

						store({
							Slider = math.clamp(math.floor(default + 0.5), min, max),
						})

						macObject = macSection:Slider({
							Name = text,
							Default = value.Slider,
							Minimum = min,
							Maximum = max,
							Precision = 0,
							Callback = function(numberValue)
								store({
									Slider = math.clamp(math.floor((tonumber(numberValue) or min) + 0.5), min, max),
								})
								fire()
							end,
						}, macFlag)

						function element:set_value(newValue, cb)
							local nextValue = type(newValue) == "table" and newValue.Slider or newValue
							store({
								Slider = math.clamp(math.floor((tonumber(nextValue) or min) + 0.5), min, max),
							})
							if macObject and macObject.UpdateValue then
								macObject:UpdateValue(value.Slider)
								if not cb then
									fire()
								end
							elseif not cb then
								fire()
							end
						end
					elseif elementType == "Dropdown" then
						local options = data.options or {}
						local default = defaults.Dropdown or options[1]

						store({
							Dropdown = default,
						})

						macObject = macSection:Dropdown({
							Name = text,
							Multi = false,
							Required = true,
							Options = options,
							Default = default or 1,
							Callback = function(selected)
								store({
									Dropdown = selected,
								})
								fire()
							end,
						}, macFlag)

						function element:set_value(newValue, cb)
							local nextSelection = type(newValue) == "table" and (newValue.Dropdown or newValue.Value or newValue.value) or newValue
							store({
								Dropdown = nextSelection or default,
							})
							if macObject and macObject.UpdateSelection then
								macObject:UpdateSelection(value.Dropdown)
							elseif not cb then
								fire()
							end
						end
						function element:ClearOptions()
							if macObject and macObject.ClearOptions then
								macObject:ClearOptions()
							end
						end
						function element:InsertOptions(newOptions)
							options = type(newOptions) == "table" and newOptions or {}
							if macObject and macObject.InsertOptions then
								macObject:InsertOptions(options)
							end
						end
					elseif elementType == "Combo" then
						local options = data.options or {}
						local default = defaults.Combo or {}

						store({
							Combo = deepCopy(default),
						})

						macObject = macSection:Dropdown({
							Name = text,
							Multi = true,
							Required = false,
							Search = true,
							Options = options,
							Default = value.Combo,
							Callback = function(selected)
								store({
									Combo = asArrayFromSelection(selected, options),
								})
								fire()
							end,
						}, macFlag)

						function element:set_value(newValue, cb)
							local nextSelection = type(newValue) == "table" and (newValue.Combo or newValue.Value or newValue.value or newValue) or {}
							if type(nextSelection) == "table" and #nextSelection == 0 then
								nextSelection = asArrayFromSelection(nextSelection, options)
							end
							store({
								Combo = type(nextSelection) == "table" and deepCopy(nextSelection) or {},
							})
							if macObject and macObject.UpdateSelection then
								macObject:UpdateSelection(value.Combo)
							elseif not cb then
								fire()
							end
						end
						function element:ClearOptions()
							if macObject and macObject.ClearOptions then
								macObject:ClearOptions()
							end
						end
						function element:InsertOptions(newOptions)
							options = type(newOptions) == "table" and newOptions or {}
							if macObject and macObject.InsertOptions then
								macObject:InsertOptions(options)
							end
						end
					elseif elementType == "TextBox" then
						store({
							Text = defaults.Text or (type(rawDefault) == "string" and rawDefault) or "",
						})

						local function setText(input)
							input = tostring(input or "")
							if value.Text == input then
								return
							end
							store({
								Text = input,
							})
							fire()
						end

						macObject = macSection:Input({
							Name = text,
							Placeholder = text,
							Default = value.Text,
							AcceptedCharacters = "All",
							ClearTextOnFocus = data.clearTextOnFocus == true or data.ClearTextOnFocus == true,
							Callback = setText,
							onChanged = setText,
						}, macFlag)

						function element:GetInput()
							if macObject and macObject.GetInput then
								return macObject:GetInput()
							end
							return value.Text
						end
						function element:set_value(newValue, cb)
							local nextText = type(newValue) == "table" and newValue.Text or newValue
							store({
								Text = tostring(nextText or ""),
							})
							if macObject and macObject.UpdateText then
								macObject:UpdateText(value.Text)
								if not cb then
									fire()
								end
							elseif not cb then
								fire()
							end
						end
					elseif elementType == "Keybind" then
						element._configKind = "Keybind"
						local isMenuToggleKeybind = text == "Toggle Menu Key"
						local defaultBind = keyNameToEnum(type(rawDefault) == "table" and rawDefault or (defaults.Key or defaults.Bind or rawDefault), defaults.KeyType or defaults.keyType or defaults.BindType or defaults.bindType)
						store({
							Key = defaultBind and defaultBind.Name or "NONE",
							KeyType = defaultBind and keyEnumTypeName(defaultBind) or nil,
						})
						local function fireKeybind()
							if isMenuToggleKeybind then
								menu.SetMenuKeybind(value.Key or value.Bind or value)
							end
							fire()
						end

						macObject = macSection:Keybind({
							Name = text,
							Default = defaultBind,
							Blacklist = false,
							Callback = function(bind)
								if bind then
									store({
										Key = bind.Name,
										KeyType = keyEnumTypeName(bind),
									})
								end
								fireKeybind()
							end,
							onBinded = function(bind)
								store({
									Key = bind and bind.Name or "NONE",
									KeyType = bind and keyEnumTypeName(bind) or nil,
								})
								fireKeybind()
							end,
						}, macFlag)
						local bindMacObject = macObject and macObject.Bind
						local unbindMacObject = macObject and macObject.Unbind

						function element:set_value(newValue, cb)
							local isConfigLoad = cb == "load"
							local nextBind
							local keyName
							local keyType
							if type(newValue) == "table" then
								keyName = newValue.Key or newValue.key or newValue.Bind or newValue.bind or newValue.Name or newValue.name or newValue[1]
								keyType = newValue.KeyType or newValue.keyType or newValue.BindType or newValue.bindType or newValue.TypeName or newValue.typeName
								nextBind = keyNameToEnum(keyName, keyType)
							else
								keyName = newValue
								nextBind = keyNameToEnum(newValue)
							end
							store({
								Key = nextBind and nextBind.Name or (type(keyName) == "string" and keyName ~= "" and keyName ~= "None" and keyName ~= "NONE" and keyName or "NONE"),
								KeyType = nextBind and keyEnumTypeName(nextBind) or inferKeyTypeName(keyName, keyType),
							})

							if macObject then
								if nextBind and type(bindMacObject) == "function" then
									bindMacObject(macObject, nextBind, true)
								elseif type(unbindMacObject) == "function" then
									unbindMacObject(macObject, true)
								end
							end

							if isConfigLoad and macObject then
								task.defer(function()
									if nextBind and type(bindMacObject) == "function" then
										bindMacObject(macObject, nextBind, true)
									elseif type(unbindMacObject) == "function" then
										unbindMacObject(macObject, true)
									end
								end)
							end

							if isConfigLoad or not cb then
								fireKeybind()
							end
						end
					elseif elementType == "Button" then
						store({})

						macObject = macSection:Button({
							Name = text,
							Callback = function()
								fire()
							end,
						}, macFlag)

						function element:set_value() end
					else
						store({})
						pcall(function()
							macSection:Label({
								Text = tostring(text),
							})
						end)

						function element:set_value() end
					end

					registerElement(tab.tab_num, section.name, sector.name, flag, element)
					scheduleOpaquePass()
					return element
				end

				return sector
			end

			return section
		end

		return tab
	end

	UserInputService.InputEnded:Connect(function(input, gameProcessed)
		if gameProcessed then
			return
		end

		if inputMatchesBind(input, menuToggleKey) then
			menu.SetOpen(not menu.open)
		end
	end)

	return menu
end

return library
