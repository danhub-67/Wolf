local Wolf = { Themes = {}, Windows = {}, Flags = {}, ConfigFolder = "Wolf_Configs", CurrentTheme = nil, Icons = {} }

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer and LocalPlayer:GetMouse()

Wolf.IconSources = {
	"https://raw.githubusercontent.com/danhub-67/Wolf/refs/heads/main/Icons1",
	"https://raw.githubusercontent.com/danhub-67/Wolf/refs/heads/main/Icons2",
	"https://raw.githubusercontent.com/danhub-67/Wolf/refs/heads/main/Icons3",
	"https://raw.githubusercontent.com/danhub-67/Wolf/refs/heads/main/Icons4",
}

function Wolf:LoadIcons()
	for _, url in ipairs(Wolf.IconSources) do
		local ok, data = pcall(function()
			return loadstring(game:HttpGet(url))()
		end)
		if ok and type(data) == "table" then
			for name, id in pairs(data) do
				Wolf.Icons[name] = id
			end
		end
	end
	return Wolf.Icons
end

Wolf:LoadIcons()

local function GetUrlExtension(url, allowed, fallback)
	local clean = string.match(url, "^[^%?#]+") or url
	local ext = string.match(clean, "%.([%a%d]+)$")
	if ext then
		ext = string.lower(ext)
		for _, a in ipairs(allowed) do
			if a == ext then return ext end
		end
	end
	return fallback
end

local function NormalizeImageSource(input)
	if input == nil then return "" end
	if type(input) == "number" then return "rbxassetid://" .. tostring(input) end
	if type(input) ~= "string" or input == "" then return "" end
	if string.match(input, "^rbxassetid://") or string.match(input, "^rbxthumb://") or string.match(input, "^rbxasset://") then return input end
	if string.match(input, "^%d+$") then return "rbxassetid://" .. input end
	if string.match(input, "^https?://") then
		if writefile and isfile and getcustomasset and makefolder and isfolder then
			local ext = GetUrlExtension(input, {"png", "jpg", "jpeg", "gif", "webp", "bmp"}, "png")
			local safeName = string.gsub(input, "[^%w]", "_")
			local cacheFolder = "Wolf_Cache"
			local cachePath = cacheFolder .. "/" .. safeName .. "." .. ext
			local ok = pcall(function()
				if not isfolder(cacheFolder) then makefolder(cacheFolder) end
				if not isfile(cachePath) then
					local data = game:HttpGet(input)
					writefile(cachePath, data)
				end
			end)
			if ok then
				local assetOk, assetId = pcall(function() return getcustomasset(cachePath) end)
				if assetOk and assetId then return assetId end
			end
		end
		return ""
	end
	return input
end

local function ResolveIcon(key)
	if not key then return "", false end
	if type(key) == "number" then return "rbxassetid://" .. tostring(key), true end
	if type(key) == "string" then
		if string.match(key, "^rbxassetid://") or string.match(key, "^%d+$") then
			return NormalizeImageSource(key), true
		end
		if string.match(key, "^https?://") then
			return NormalizeImageSource(key), true
		end
		if Wolf.Icons[key] then
			return NormalizeImageSource(Wolf.Icons[key]), true
		end
		return key, false
	end
	return "", false
end

local function Round(radius, parent)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius)
	c.Parent = parent
	return c
end

local function Outline(parent, color, thickness, transparency)
	local s = Instance.new("UIStroke")
	s.Color = color or Color3.fromRGB(60, 60, 65)
	s.Thickness = thickness or 1
	s.Transparency = transparency or 0.2
	s.Parent = parent
	return s
end

local function Shade(color, amount)
	if typeof(color) ~= "Color3" then return Color3.fromRGB(20, 20, 24) end
	amount = amount or 0.07
	local lum = 0.299 * color.R + 0.587 * color.G + 0.114 * color.B
	if lum > 0.5 then
		return Color3.new(math.max(0, color.R - amount), math.max(0, color.G - amount), math.max(0, color.B - amount))
	end
	return Color3.new(math.min(1, color.R + amount), math.min(1, color.G + amount), math.min(1, color.B + amount))
end

local function Tween(obj, t, props)
	local anim = TweenService:Create(obj, TweenInfo.new(t, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), props)
	anim:Play()
	return anim
end

local function Ripple(button, color)
	button.ClipsDescendants = true
	local ok = pcall(function()
		button.MouseButton1Click:Connect(function()
			local mx, my = Mouse and Mouse.X or 0, Mouse and Mouse.Y or 0
			local circle = Instance.new("Frame")
			circle.BackgroundColor3 = color or Color3.new(1, 1, 1)
			circle.BackgroundTransparency = 0.7
			circle.BorderSizePixel = 0
			circle.AnchorPoint = Vector2.new(0.5, 0.5)
			circle.ZIndex = (button.ZIndex or 1) + 5
			circle.Size = UDim2.fromOffset(0, 0)
			circle.Position = UDim2.fromOffset(mx - button.AbsolutePosition.X, my - button.AbsolutePosition.Y)
			circle.Parent = button
			Round(200, circle)
			local target = math.max(button.AbsoluteSize.X, button.AbsoluteSize.Y) * 1.8
			Tween(circle, 0.45, { Size = UDim2.fromOffset(target, target), BackgroundTransparency = 1 })
			task.delay(0.45, function()
				if circle.Parent then circle:Destroy() end
			end)
		end)
	end)
	return ok
end

local function Img(parent, source, size, color, transparency, z)
	local resolved, isCustom = ResolveIcon(source)
	if resolved == "" then return nil end
	local image = Instance.new("ImageLabel")
	image.Size = size or UDim2.fromOffset(16, 16)
	image.BackgroundTransparency = 1
	image.Image = resolved
	image.ScaleType = isCustom and Enum.ScaleType.Crop or Enum.ScaleType.Stretch
	image.ImageColor3 = isCustom and Color3.new(1, 1, 1) or (color or Color3.new(1, 1, 1))
	image.ImageTransparency = transparency or 0
	image.ZIndex = z or 8
	image.Parent = parent
	if isCustom then image:SetAttribute("WolfCustomIcon", true) end
	return image
end

local function OpenLink(url)
	if not url or url == "" then return false end
	local opened = pcall(function()
		game:GetService("GuiService"):OpenBrowserWindow(url)
	end)
	if opened then return "opened" end
	if setclipboard then
		local ok = pcall(function() setclipboard(url) end)
		if ok then return "clipboard" end
	end
	return false
end

local function TintIfAllowed(img, color)
	if img and not img:GetAttribute("WolfCustomIcon") then
		img.ImageColor3 = color
	end
end

local function NormalizeArgs(first, ...)
	if type(first) == "table" then return first end
	return nil, first, ...
end

local function BuildTheme(name, accent, outline, toggle, slider, text, placeholder, bg, elemBg, icon)
	return {
		Name = name,
		Accent = Color3.fromHex(accent),
		Outline = Color3.fromHex(outline or accent),
		Text = Color3.fromHex(text or "#EBEBEB"),
		Placeholder = Color3.fromHex(placeholder or "#919191"),
		Icon = Color3.fromHex(icon or outline or accent),
		Toggle = Color3.fromHex(toggle or accent),
		Slider = Color3.fromHex(slider or accent),
		ElementBackground = Color3.fromHex(elemBg or "#0A0A0D"),
		Background = Color3.fromHex(bg or "#050507"),
	}
end

Wolf.Themes["67"] = BuildTheme("67", "#FF1A1A", "#FF2A2A", "#FF1A1A", "#FF1A1A", "#F0F0F0", "#9A9A9A", "#000000", "#0A0A0A", "#FF1A1A")
Wolf.Themes.Sovereign = BuildTheme("Sovereign", "#D4AF37", "#F0D580", "#D4AF37", "#F0D580", "#FFF8E7", "#C9B98A", "#0A0805", "#15110A", "#F0D580")

Wolf.ThemeOrder = {"67", "Sovereign"}

local MainGui = Instance.new("ScreenGui")
MainGui.Name = "WolfLibrary"
MainGui.ResetOnSpawn = false
MainGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
MainGui.Parent = (gethui and gethui()) or CoreGui

local NotificationHolder = Instance.new("Frame")
NotificationHolder.Size = UDim2.new(0, 270, 1, -20)
NotificationHolder.Position = UDim2.new(1, -280, 0, 10)
NotificationHolder.BackgroundTransparency = 1
NotificationHolder.ZIndex = 100
NotificationHolder.Parent = MainGui

local NotifList = Instance.new("UIListLayout")
NotifList.VerticalAlignment = Enum.VerticalAlignment.Bottom
NotifList.Padding = UDim.new(0, 8)
NotifList.Parent = NotificationHolder

local ActiveNotifications = {}

function Wolf:GetThemes()
	return Wolf.Themes
end

function Wolf:SetTheme(name)
	for _, window in ipairs(Wolf.Windows) do
		if window and window.SetTheme then
			window:SetTheme(name)
		end
	end
end

function Wolf:GetFlag(name)
	return Wolf.Flags[name]
end

function Wolf:SetFlag(name, value)
	Wolf.Flags[name] = value
end

function Wolf:SaveConfig(name)
	name = tostring(name or "default")
	if not (writefile and HttpService) then return false end
	pcall(function()
		if makefolder and isfolder and not isfolder(Wolf.ConfigFolder) then
			makefolder(Wolf.ConfigFolder)
		end
	end)
	local payload = {}
	for k, v in pairs(Wolf.Flags) do
		if typeof(v) == "Color3" then
			payload[k] = { __color = true, R = v.R, G = v.G, B = v.B }
		elseif typeof(v) == "EnumItem" then
			payload[k] = { __enum = true, EnumType = tostring(v.EnumType), Name = v.Name }
		else
			payload[k] = v
		end
	end
	local ok, encoded = pcall(function() return HttpService:JSONEncode(payload) end)
	if not ok then return false end
	local path = Wolf.ConfigFolder .. "/" .. name .. ".json"
	local wOk = pcall(function() writefile(path, encoded) end)
	return wOk == true
end

function Wolf:LoadConfig(name)
	name = tostring(name or "default")
	if not (readfile and isfile and HttpService) then return false end
	local path = Wolf.ConfigFolder .. "/" .. name .. ".json"
	if not isfile(path) then return false end
	local ok, raw = pcall(function() return readfile(path) end)
	if not ok or not raw then return false end
	local dOk, data = pcall(function() return HttpService:JSONDecode(raw) end)
	if not dOk or type(data) ~= "table" then return false end
	for k, v in pairs(data) do
		if type(v) == "table" and v.__color then
			Wolf.Flags[k] = Color3.new(v.R, v.G, v.B)
		elseif type(v) == "table" and v.__enum then
			local root = Enum[v.EnumType]
			Wolf.Flags[k] = (root and root[v.Name]) or v
		else
			Wolf.Flags[k] = v
		end
	end
	return true
end

function Wolf:Notify(config)
	config = config or {}
	local title = config.Title or "Notification"
	local content = config.Content or config.Text or ""
	local duration = config.Duration or 3.5
	local ntype = config.Type or "Info"
	local buttons = config.Buttons
	local iconKey = config.Icon

	local colors = {
		Success = Color3.fromRGB(52, 199, 89),
		Error = Color3.fromRGB(235, 64, 52),
		Warning = Color3.fromRGB(255, 176, 32),
		Info = Color3.fromRGB(80, 140, 255),
	}
	local accent = colors[ntype] or colors.Info
	local T = Wolf.CurrentTheme or Wolf.Themes["67"]

	local slot = Instance.new("Frame")
	slot.Size = UDim2.new(1, 0, 0, 0)
	slot.BackgroundTransparency = 1
	slot.ClipsDescendants = false
	slot.Parent = NotificationHolder

	local frame = Instance.new("Frame")
	frame.AnchorPoint = Vector2.new(0, 0)
	frame.Position = UDim2.new(1, 40, 0, 0)
	frame.Size = UDim2.new(1, 0, 1, 0)
	frame.BackgroundColor3 = T.ElementBackground
	frame.BackgroundTransparency = 0.08
	frame.ClipsDescendants = true
	frame.Parent = slot
	Round(16, frame)
	local stroke = Outline(frame, T.Outline, 1.2, 0.4)

	local bar = Instance.new("Frame")
	bar.Size = UDim2.new(0, 4, 1, -16)
	bar.Position = UDim2.new(0, 0, 0, 8)
	bar.BackgroundColor3 = accent
	bar.ZIndex = 2
	bar.Parent = frame
	Round(2, bar)

	local iconBadge
	local icon
	local resolvedIconCheck = ResolveIcon(iconKey)
	if resolvedIconCheck ~= "" then
		iconBadge = Instance.new("Frame")
		iconBadge.Size = UDim2.fromOffset(32, 32)
		iconBadge.Position = UDim2.new(0, 16, 0, 14)
		iconBadge.BackgroundColor3 = accent
		iconBadge.BackgroundTransparency = 0.82
		iconBadge.ZIndex = 3
		iconBadge.Parent = frame
		Round(16, iconBadge)

		icon = Img(iconBadge, iconKey, UDim2.fromOffset(16, 16), accent, 0, 4)
		if icon then
			icon.AnchorPoint = Vector2.new(0.5, 0.5)
			icon.Position = UDim2.new(0.5, 0, 0.5, 0)
		end
	end

	local tLbl = Instance.new("TextLabel")
	tLbl.Text = title
	tLbl.Font = Enum.Font.GothamBold
	tLbl.TextSize = 13
	tLbl.TextColor3 = T.Text
	tLbl.Position = UDim2.new(0, icon and 58 or 20, 0, 14)
	tLbl.Size = UDim2.new(1, icon and -70 or -34, 0, 18)
	tLbl.BackgroundTransparency = 1
	tLbl.TextXAlignment = Enum.TextXAlignment.Left
	tLbl.Parent = frame

	local cLbl = Instance.new("TextLabel")
	cLbl.Text = content
	cLbl.Font = Enum.Font.Gotham
	cLbl.TextSize = 11
	cLbl.TextColor3 = T.Placeholder
	cLbl.Position = UDim2.new(0, icon and 58 or 20, 0, 34)
	cLbl.Size = UDim2.new(1, icon and -70 or -34, 0, 30)
	cLbl.BackgroundTransparency = 1
	cLbl.TextXAlignment = Enum.TextXAlignment.Left
	cLbl.TextYAlignment = Enum.TextYAlignment.Top
	cLbl.TextWrapped = true
	cLbl.Parent = frame

	if buttons and #buttons > 0 then
		local row = Instance.new("Frame")
		row.Size = UDim2.new(1, -34, 0, 26)
		row.Position = UDim2.new(0, icon and 58 or 20, 0, 66)
		row.BackgroundTransparency = 1
		row.Parent = frame
		local rl = Instance.new("UIListLayout")
		rl.FillDirection = Enum.FillDirection.Horizontal
		rl.Padding = UDim.new(0, 6)
		rl.Parent = row
		for _, b in ipairs(buttons) do
			local nb = Instance.new("TextButton")
			nb.Size = UDim2.fromOffset(0, 24)
			nb.AutomaticSize = Enum.AutomaticSize.X
			nb.BackgroundColor3 = b.Primary and accent or Shade(T.ElementBackground)
			nb.Text = "  " .. (b.Text or "Ok") .. "  "
			nb.Font = Enum.Font.GothamBold
			nb.TextSize = 11
			nb.TextColor3 = T.Text
			nb.Parent = row
			Round(12, nb)
			Ripple(nb, Color3.new(1, 1, 1))
			nb.MouseButton1Click:Connect(function()
				if b.Callback then pcall(b.Callback) end
				if b.CloseOnClick ~= false and slot.Parent then slot:Destroy() end
			end)
		end
	end

	table.insert(ActiveNotifications, { Frame = frame, Slot = slot, Stroke = stroke, Icon = icon, Title = tLbl, Content = cLbl, Bar = bar })

	local cardHeight = (buttons and #buttons > 0) and 94 or 68
	Tween(slot, 0.3, { Size = UDim2.new(1, 0, 0, cardHeight) })
	Tween(frame, 0.35, { Position = UDim2.new(0, 0, 0, 0) })

	if not (buttons and #buttons > 0) then
		task.delay(duration, function()
			if not slot.Parent then return end
			Tween(frame, 0.25, { Position = UDim2.new(1, 40, 0, 0), BackgroundTransparency = 1 })
			local out = Tween(slot, 0.25, { Size = UDim2.new(1, 0, 0, 0) })
			out.Completed:Connect(function()
				for i, item in ipairs(ActiveNotifications) do
					if item.Slot == slot then table.remove(ActiveNotifications, i) break end
				end
				slot:Destroy()
			end)
		end)
	end
end

function Wolf:CreateWindow(config)
	config = config or {}
	local themeName = config.Theme or "67"
	local title = config.Title or "67"
	local description = config.Description or ""
	local iconKey = config.Logo or config.Icon
	local size = config.Size or Vector2.new(720, 480)
	if typeof(size) == "UDim2" then size = Vector2.new(size.X.Offset, size.Y.Offset) end
	local toggleKey = config.ToggleKey or Enum.KeyCode.RightShift
	local showThemeSelector = config.ThemeSelector == true
	local bgImage = config.BackgroundImage or "https://cdn.discordapp.com/attachments/1521705447781044287/1549962059649912873/grok_1789610023592.jpg?ex=6aac9a27&is=6aab48a7&hm=d748df37d714a5c3d6cde5922782cd6eca54dcd6189b1600013623bb5d9a505f&"
	local bgTransparency = math.clamp(config.BackgroundImageTransparency or config.BackgroundTransparency or 0, 0, 1)
	local panelTransparency = math.clamp(config.Transparency or 0.08, 0.02, 0.6)
	local openButtonIcon = config.OpenButtonIcon or "https://cdn.discordapp.com/attachments/1521705447781044287/1550262143704760473/1789680518902-removebg-preview_1.png?ex=6aadb1a1&is=6aac6021&hm=3c16d7c7d6bb64238c13cc5ff71324c7142f68e224447cf4b2173be6d8caee69&"
	local openButtonText = config.OpenButtonText or "Open Window"

	local Theme = Wolf.Themes[themeName] or Wolf.Themes["67"]
	Wolf.CurrentTheme = Theme
	local Registered = {}
	local DependentRows = {}

	local function CheckDependents()
		for _, dep in ipairs(DependentRows) do
			local ok = true
			if dep.Check then
				local co, cr = pcall(dep.Check)
				ok = co and cr
			end
			dep.Row.Visible = ok and true or false
		end
	end

	local function ApplyDependsOn(row, cfg)
		if not cfg or not cfg.DependsOn then return end
		local dep = cfg.DependsOn
		local toggleObj = dep.Toggle or dep[1]
		local expected = dep.Value
		if expected == nil then expected = dep[2] end
		if expected == nil then expected = true end
		local check
		if type(dep) == "function" then
			check = dep
		elseif toggleObj and toggleObj.Get then
			check = function() return toggleObj:Get() == expected end
		end
		if check then
			table.insert(DependentRows, { Row = row, Check = check })
			row.Visible = check() and true or false
		end
	end

	local OpenPopups = {}
	local function RegisterPopup(frame, trigger)
		table.insert(OpenPopups, { Frame = frame, Trigger = trigger })
	end
	local function CloseAllPopups(exceptTrigger)
		for _, p in ipairs(OpenPopups) do
			if p.Frame.Visible and p.Trigger ~= exceptTrigger then
				p.Frame.Visible = false
			end
		end
	end

	local resolvedIcon, resolvedIconIsCustom = ResolveIcon(iconKey)
	local resolvedBgImage = NormalizeImageSource(bgImage)
	local hasBackground = resolvedBgImage ~= ""
	local mainBgTrans = hasBackground and 0.92 or panelTransparency
	local elementTrans = hasBackground and 0.82 or 0.22
	local elevatedTrans = hasBackground and 0.7 or 0.16
	local overlayTrans = hasBackground and 0.75 or 1

	local Window = { Tabs = {}, Connections = {} }
	local function Track(conn)
		table.insert(Window.Connections, conn)
		return conn
	end

	local WindowGui = Instance.new("ScreenGui")
	WindowGui.Name = "WolfWindow"
	WindowGui.ResetOnSpawn = false
	WindowGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	WindowGui.DisplayOrder = MainGui.DisplayOrder
	WindowGui.Parent = (gethui and gethui()) or CoreGui

	local MainFrame = Instance.new("Frame")
	MainFrame.Size = UDim2.fromOffset(0, 0)
	MainFrame.Position = UDim2.fromScale(0.5, 0.5)
	MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	MainFrame.BackgroundColor3 = Theme.Background
	MainFrame.BackgroundTransparency = mainBgTrans
	MainFrame.ClipsDescendants = true
	local SizeConstraint = Instance.new("UISizeConstraint")
	SizeConstraint.MinSize = Vector2.new(420, 300)
	SizeConstraint.MaxSize = Vector2.new(1000, 700)
	SizeConstraint.Parent = MainFrame
	MainFrame.Visible = false
	MainFrame.Parent = WindowGui
	Round(6, MainFrame)

	local WindowScale = Instance.new("UIScale")
	WindowScale.Parent = MainFrame

	local function GetViewport()
		local cam = workspace.CurrentCamera
		return cam and cam.ViewportSize or Vector2.new(1280, 720)
	end

	local function RecalculateScale()
		local viewport = GetViewport()
		local marginX = math.max(viewport.X * 0.9, 1)
		local marginY = math.max(viewport.Y * 0.85, 1)
		local scaleX = marginX / size.X
		local scaleY = marginY / size.Y
		local target = math.clamp(math.min(scaleX, scaleY, 1), 0.45, 1)
		WindowScale.Scale = target
	end
	RecalculateScale()
	Track(workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(RecalculateScale))
	local WindowStroke = Outline(MainFrame, Theme.Accent, 1.5, 0.25)

	local BgImageLabel = Instance.new("ImageLabel")
	BgImageLabel.Size = UDim2.fromScale(1, 1)
	BgImageLabel.BackgroundTransparency = 1
	BgImageLabel.Image = resolvedBgImage
	BgImageLabel.ImageTransparency = bgTransparency
	BgImageLabel.ScaleType = Enum.ScaleType.Crop
	BgImageLabel.ZIndex = 0
	BgImageLabel.Visible = hasBackground
	BgImageLabel.Parent = MainFrame

	local BgTint = Instance.new("Frame")
	BgTint.Size = UDim2.fromScale(1, 1)
	BgTint.BackgroundColor3 = Theme.Accent
	BgTint.BackgroundTransparency = 0.55
	BgTint.BorderSizePixel = 0
	BgTint.ZIndex = 0
	BgTint.Visible = hasBackground and themeName ~= "67"
	BgTint.Parent = MainFrame

	local Overlay = Instance.new("Frame")
	Overlay.Size = UDim2.fromScale(1, 1)
	Overlay.BackgroundColor3 = Color3.fromRGB(6, 6, 9)
	Overlay.BackgroundTransparency = overlayTrans
	Overlay.BorderSizePixel = 0
	Overlay.ZIndex = 1
	Overlay.Parent = MainFrame

	local CornerFlag = Instance.new("Frame")
	CornerFlag.Size = UDim2.fromOffset(64, 4)
	CornerFlag.Position = UDim2.fromOffset(0, 0)
	CornerFlag.BackgroundColor3 = Theme.Accent
	CornerFlag.BorderSizePixel = 0
	CornerFlag.ZIndex = 3
	CornerFlag.Parent = MainFrame
	local cfCorner = Instance.new("UICorner")
	cfCorner.CornerRadius = UDim.new(0, 6)
	cfCorner.Parent = CornerFlag

	local HeaderBar = Instance.new("Frame")
	HeaderBar.Size = UDim2.new(1, 0, 0, 46)
	HeaderBar.BackgroundTransparency = 1
	HeaderBar.ZIndex = 5
	HeaderBar.Parent = MainFrame

	local HeaderScan = Instance.new("Frame")
	HeaderScan.Size = UDim2.new(0, 110, 0, 2)
	HeaderScan.Position = UDim2.new(0, 0, 1, -1)
	HeaderScan.BorderSizePixel = 0
	HeaderScan.BackgroundColor3 = Theme.Accent
	HeaderScan.ZIndex = 8
	HeaderScan.Parent = HeaderBar

	local HeaderScanGrad = Instance.new("UIGradient")
	HeaderScanGrad.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Theme.Accent),
		ColorSequenceKeypoint.new(0.5, Color3.new(1, 1, 1)),
		ColorSequenceKeypoint.new(1, Theme.Accent),
	})
	HeaderScanGrad.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.45, 0),
		NumberSequenceKeypoint.new(0.55, 0),
		NumberSequenceKeypoint.new(1, 1),
	})
	HeaderScanGrad.Parent = HeaderScan

	task.spawn(function()
		while HeaderScan and HeaderScan.Parent do
			local tw1 = TweenService:Create(HeaderScan, TweenInfo.new(2.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), { Position = UDim2.new(1, -110, 1, -1) })
			tw1:Play()
			tw1.Completed:Wait()
			if not HeaderScan or not HeaderScan.Parent then break end
			local tw2 = TweenService:Create(HeaderScan, TweenInfo.new(2.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), { Position = UDim2.new(0, 0, 1, -1) })
			tw2:Play()
			tw2.Completed:Wait()
		end
	end)

	local SideScan = Instance.new("Frame")
	SideScan.Size = UDim2.new(0, 2, 0, 90)
	SideScan.Position = UDim2.new(0, 0, 0, 46)
	SideScan.BorderSizePixel = 0
	SideScan.BackgroundColor3 = Theme.Accent
	SideScan.ZIndex = 8
	SideScan.Parent = MainFrame

	local SideScanGrad = Instance.new("UIGradient")
	SideScanGrad.Rotation = 90
	SideScanGrad.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Theme.Accent),
		ColorSequenceKeypoint.new(0.5, Color3.new(1, 1, 1)),
		ColorSequenceKeypoint.new(1, Theme.Accent),
	})
	SideScanGrad.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.45, 0),
		NumberSequenceKeypoint.new(0.55, 0),
		NumberSequenceKeypoint.new(1, 1),
	})
	SideScanGrad.Parent = SideScan

	task.spawn(function()
		while SideScan and SideScan.Parent do
			local h = MainFrame.AbsoluteSize.Y - 50
			local tw1 = TweenService:Create(SideScan, TweenInfo.new(2.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), { Position = UDim2.new(0, 0, 0, h - 90) })
			tw1:Play()
			tw1.Completed:Wait()
			if not SideScan or not SideScan.Parent then break end
			local tw2 = TweenService:Create(SideScan, TweenInfo.new(2.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), { Position = UDim2.new(0, 0, 0, 46) })
			tw2:Play()
			tw2.Completed:Wait()
		end
	end)

	local avatarHolder = Instance.new("Frame")
	avatarHolder.Size = UDim2.fromOffset(28, 28)
	avatarHolder.Position = UDim2.new(0, 16, 0.5, -14)
	avatarHolder.BackgroundColor3 = Theme.ElementBackground
	avatarHolder.ClipsDescendants = true
	avatarHolder.ZIndex = 6
	avatarHolder.Parent = HeaderBar
	Round(14, avatarHolder)
	Outline(avatarHolder, Theme.Accent, 1.2, 0.3)

	local avatarImg = Instance.new("ImageLabel")
	avatarImg.Size = UDim2.fromScale(1, 1)
	avatarImg.BackgroundTransparency = 1
	avatarImg.ScaleType = Enum.ScaleType.Crop
	avatarImg.ZIndex = 7
	avatarImg.Parent = avatarHolder

	local lp = game:GetService("Players").LocalPlayer
	if lp then
		avatarImg.Image = string.format("rbxthumb://type=AvatarHeadShot&id=%d&w=150&h=150", lp.UserId)
	elseif resolvedIcon ~= "" then
		avatarImg.Image = resolvedIcon
	end

	local TitleLabel = Instance.new("TextLabel")
	TitleLabel.Text = title
	TitleLabel.Font = Enum.Font.GothamBold
	TitleLabel.TextSize = 16
	TitleLabel.TextColor3 = Theme.Text
	TitleLabel.Position = UDim2.new(0, 52, 0, 0)
	TitleLabel.Size = UDim2.new(0, 220, 1, 0)
	TitleLabel.BackgroundTransparency = 1
	TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
	TitleLabel.ZIndex = 6
	TitleLabel.Parent = HeaderBar

	local DescLabel = Instance.new("TextLabel")
	DescLabel.Text = description
	DescLabel.Font = Enum.Font.Gotham
	DescLabel.TextSize = 10
	DescLabel.TextColor3 = Theme.Placeholder
	DescLabel.Position = UDim2.new(0, 52, 1, -18)
	DescLabel.Size = UDim2.new(0, 240, 0, 14)
	DescLabel.BackgroundTransparency = 1
	DescLabel.TextXAlignment = Enum.TextXAlignment.Left
	DescLabel.Visible = description ~= ""
	DescLabel.ZIndex = 6
	DescLabel.Parent = HeaderBar

	local Controls = Instance.new("Frame")
	Controls.Size = UDim2.fromOffset(showThemeSelector and 132 or 30, 26)
	Controls.Position = UDim2.new(1, showThemeSelector and -150 or -46, 0.5, -13)
	Controls.BackgroundTransparency = 1
	Controls.ZIndex = 6
	Controls.Parent = HeaderBar

	local ControlsLayout = Instance.new("UIListLayout")
	ControlsLayout.FillDirection = Enum.FillDirection.Horizontal
	ControlsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
	ControlsLayout.Padding = UDim.new(0, 6)
	ControlsLayout.Parent = Controls

	local ThemeBtn
	if showThemeSelector then
		ThemeBtn = Instance.new("TextButton")
		ThemeBtn.Size = UDim2.fromOffset(92, 26)
		ThemeBtn.BackgroundColor3 = Shade(Theme.ElementBackground)
		ThemeBtn.BackgroundTransparency = 0.05
		ThemeBtn.AutoButtonColor = false
		ThemeBtn.Text = themeName
		ThemeBtn.Font = Enum.Font.GothamSemibold
		ThemeBtn.TextSize = 11
		ThemeBtn.TextColor3 = Theme.Text
		ThemeBtn.ZIndex = 7
		ThemeBtn.Parent = Controls
		Round(4, ThemeBtn)
		Outline(ThemeBtn, Theme.Outline, 1, 0.4)
	end

	local MinBtn = Instance.new("TextButton")
	MinBtn.Size = UDim2.fromOffset(30, 26)
	MinBtn.BackgroundTransparency = 1
	MinBtn.Text = "—"
	MinBtn.Font = Enum.Font.GothamBlack
	MinBtn.TextSize = 22
	MinBtn.TextColor3 = Theme.Text
	MinBtn.ZIndex = 7
	MinBtn.Parent = Controls

	local ThemePopup = Instance.new("Frame")
	ThemePopup.Size = UDim2.fromOffset(180, 280)
	ThemePopup.BackgroundColor3 = Theme.ElementBackground
	ThemePopup.BackgroundTransparency = hasBackground and 0.5 or 0.05
	ThemePopup.Visible = false
	ThemePopup.ZIndex = 50
	ThemePopup.Parent = WindowGui
	Round(4, ThemePopup)
	Outline(ThemePopup, Theme.Outline, 1, hasBackground and 0.25 or 0.15)

	local ThemeScroll = Instance.new("ScrollingFrame")
	ThemeScroll.Size = UDim2.new(1, -8, 1, -8)
	ThemeScroll.Position = UDim2.new(0, 4, 0, 4)
	ThemeScroll.BackgroundTransparency = 1
	ThemeScroll.ScrollBarThickness = 3
	ThemeScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	ThemeScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	ThemeScroll.ZIndex = 51
	ThemeScroll.Parent = ThemePopup

	local ThemeListLayout = Instance.new("UIListLayout")
	ThemeListLayout.Padding = UDim.new(0, 4)
	ThemeListLayout.Parent = ThemeScroll

	local Sidebar = Instance.new("ScrollingFrame")
	Sidebar.Size = UDim2.new(0, 150, 1, -74)
	Sidebar.Position = UDim2.new(0, 16, 0, 58)
	Sidebar.BackgroundTransparency = 1
	Sidebar.BorderSizePixel = 0
	Sidebar.ClipsDescendants = true
	Sidebar.ScrollingDirection = Enum.ScrollingDirection.Y
	Sidebar.ScrollBarThickness = 3
	Sidebar.ScrollBarImageColor3 = Theme.Accent
	Sidebar.CanvasSize = UDim2.new(0, 0, 0, 0)
	Sidebar.AutomaticCanvasSize = Enum.AutomaticSize.Y
	Sidebar.ZIndex = 5
	Sidebar.Parent = MainFrame
	Round(8, Sidebar)
	local TabStripGlow = Outline(Sidebar, Theme.Accent, 1.2, 0.4)

	local SidebarPad = Instance.new("UIPadding")
	SidebarPad.PaddingTop = UDim.new(0, 8)
	SidebarPad.PaddingBottom = UDim.new(0, 8)
	SidebarPad.PaddingLeft = UDim.new(0, 6)
	SidebarPad.PaddingRight = UDim.new(0, 6)
	SidebarPad.Parent = Sidebar

	local TabList = Instance.new("UIListLayout")
	TabList.FillDirection = Enum.FillDirection.Vertical
	TabList.HorizontalAlignment = Enum.HorizontalAlignment.Center
	TabList.Padding = UDim.new(0, 4)
	TabList.Parent = Sidebar

	local TabStrip = Sidebar

	local PageHost = Instance.new("Frame")
	PageHost.Size = UDim2.new(1, -182, 1, -74)
	PageHost.Position = UDim2.new(0, 182, 0, 58)
	PageHost.BackgroundTransparency = 1
	PageHost.ZIndex = 5
	PageHost.Parent = MainFrame

	local resolvedOpenIcon, resolvedOpenIconIsCustom = ResolveIcon(openButtonIcon)
	local hasOpenIcon = resolvedOpenIcon ~= ""

	local FloatBtn = Instance.new("TextButton")
	FloatBtn.Size = UDim2.fromOffset(300, 80)
	FloatBtn.Position = UDim2.new(0, 24, 0.5, -40)
	FloatBtn.BackgroundColor3 = Color3.fromRGB(6, 6, 6)
	FloatBtn.BackgroundTransparency = 1
	FloatBtn.Text = ""
	FloatBtn.Visible = false
	FloatBtn.ClipsDescendants = true
	FloatBtn.ZIndex = 10
	FloatBtn.Parent = WindowGui
	Round(28, FloatBtn)
	local FloatStroke = Outline(FloatBtn, Theme.Accent, 0, 1)
	local FloatGlow = Instance.new("UIStroke")
	FloatGlow.Color = Theme.Accent
	FloatGlow.Thickness = 0
	FloatGlow.Transparency = 1
	FloatGlow.Parent = FloatBtn

	local FloatHit = Instance.new("TextButton")
	FloatHit.BackgroundTransparency = 1
	FloatHit.AutoButtonColor = false
	FloatHit.Text = ""
	FloatHit.ZIndex = 13
	FloatHit.Parent = FloatBtn

	if hasOpenIcon then
		local fullImg = Instance.new("ImageLabel")
		fullImg.Size = UDim2.fromScale(1, 1)
		fullImg.BackgroundTransparency = 1
		fullImg.Image = resolvedOpenIcon
		fullImg.ScaleType = Enum.ScaleType.Fit
		fullImg.ImageColor3 = Color3.new(1, 1, 1)
		fullImg.ZIndex = 12
		fullImg.Parent = FloatBtn

		FloatHit.AnchorPoint = Vector2.new(0.5, 0.5)
		FloatHit.Position = UDim2.new(0.5, 0, 0.5, 0)
		FloatHit.Size = UDim2.fromOffset(84, 84)
	else
		local fIconHolder = Instance.new("Frame")
		fIconHolder.Size = UDim2.fromOffset(30, 30)
		fIconHolder.Position = UDim2.new(0, 10, 0.5, -15)
		fIconHolder.BackgroundTransparency = 1
		fIconHolder.ZIndex = 11
		fIconHolder.Parent = FloatBtn
		local cross = Instance.new("TextLabel")
		cross.Size = UDim2.fromScale(1, 1)
		cross.BackgroundTransparency = 1
		cross.Text = "✥"
		cross.Font = Enum.Font.GothamBold
		cross.TextSize = 26
		cross.TextColor3 = Theme.Accent
		cross.ZIndex = 12
		cross.Parent = fIconHolder
		local fTxt = Instance.new("TextLabel")
		fTxt.Size = UDim2.new(1, -48, 1, 0)
		fTxt.Position = UDim2.new(0, 44, 0, 0)
		fTxt.BackgroundTransparency = 1
		fTxt.Text = openButtonText
		fTxt.Font = Enum.Font.GothamBlack
		fTxt.TextSize = 16
		fTxt.TextColor3 = Color3.fromRGB(255, 255, 255)
		fTxt.TextXAlignment = Enum.TextXAlignment.Left
		fTxt.ZIndex = 12
		fTxt.Parent = FloatBtn

		FloatHit.Position = UDim2.new(0, 0, 0, 0)
		FloatHit.Size = UDim2.new(1, -30, 1, 0)
	end

	local winOpen = true
	local isAnimating = false

	local function OpenWindow()
		if isAnimating then return end
		isAnimating = true
		FloatBtn.Visible = false
		MainFrame.Visible = true
		MainFrame.Size = UDim2.fromOffset(0, 0)
		MainFrame.BackgroundTransparency = 1
		local t = Tween(MainFrame, 0.28, { Size = UDim2.fromOffset(size.X, size.Y), BackgroundTransparency = mainBgTrans })
		t.Completed:Connect(function() isAnimating = false end)
		winOpen = true
	end

	local function CloseWindow()
		if isAnimating then return end
		isAnimating = true
		CloseAllPopups()
		local t = Tween(MainFrame, 0.2, { Size = UDim2.fromOffset(0, 0), BackgroundTransparency = 1 })
		t.Completed:Connect(function()
			MainFrame.Visible = false
			FloatBtn.Visible = true
			isAnimating = false
		end)
		winOpen = false
	end

	local function ToggleWindow()
		if winOpen then CloseWindow() else OpenWindow() end
	end

	MinBtn.MouseButton1Click:Connect(CloseWindow)
	FloatHit.MouseButton1Click:Connect(OpenWindow)

	Track(UserInputService.InputBegan:Connect(function(input, gpe)
		if not gpe and input.KeyCode == toggleKey then
			ToggleWindow()
		end
	end))

	Track(UserInputService.InputBegan:Connect(function(input, gpe)
		if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
		task.defer(function()
			local pos = input.Position
			for _, p in ipairs(OpenPopups) do
				if p.Frame.Visible then
					local abs = p.Frame.AbsolutePosition
					local sz = p.Frame.AbsoluteSize
					local inFrame = pos.X >= abs.X and pos.X <= abs.X + sz.X and pos.Y >= abs.Y and pos.Y <= abs.Y + sz.Y
					local inTrigger = false
					if p.Trigger then
						local tabs = p.Trigger.AbsolutePosition
						local tsz = p.Trigger.AbsoluteSize
						inTrigger = pos.X >= tabs.X and pos.X <= tabs.X + tsz.X and pos.Y >= tabs.Y and pos.Y <= tabs.Y + tsz.Y
					end
					if not inFrame and not inTrigger then
						p.Frame.Visible = false
					end
				end
			end
		end)
	end))

	local function EnableDrag(handle, target)
		local dragging, startPos, startInput
		Track(handle.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				dragging = true
				startPos = target.Position
				startInput = input.Position
			end
		end))
		Track(UserInputService.InputChanged:Connect(function(input)
			if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
				local delta = input.Position - startInput
				target.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
			end
		end))
		Track(UserInputService.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				dragging = false
			end
		end))
	end
	EnableDrag(HeaderBar, MainFrame)
	EnableDrag(FloatBtn, FloatBtn)

	local ResizeGrip = Instance.new("TextButton")
	ResizeGrip.AnchorPoint = Vector2.new(1, 1)
	ResizeGrip.Position = UDim2.new(1, 0, 1, 0)
	ResizeGrip.Size = UDim2.fromOffset(22, 22)
	ResizeGrip.BackgroundTransparency = 1
	ResizeGrip.Text = ""
	ResizeGrip.AutoButtonColor = false
	ResizeGrip.ZIndex = 20
	ResizeGrip.Parent = MainFrame

	local gripVisual = Instance.new("Frame")
	gripVisual.AnchorPoint = Vector2.new(1, 1)
	gripVisual.Position = UDim2.new(1, -5, 1, -5)
	gripVisual.Size = UDim2.fromOffset(9, 9)
	gripVisual.Rotation = 45
	gripVisual.BackgroundColor3 = Theme.Accent
	gripVisual.BackgroundTransparency = 0.4
	gripVisual.BorderSizePixel = 0
	gripVisual.ZIndex = 20
	gripVisual.Parent = ResizeGrip
	Round(2, gripVisual)

	local function EnableResize(handle)
		local resizing, startSize, startInput
		Track(handle.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				resizing = true
				startSize = size
				startInput = input.Position
			end
		end))
		Track(UserInputService.InputChanged:Connect(function(input)
			if resizing and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
				local delta = input.Position - startInput
				local newX = math.clamp(startSize.X + delta.X, 400, 1000)
				local newY = math.clamp(startSize.Y + delta.Y, 320, 760)
				size = Vector2.new(newX, newY)
				MainFrame.Size = UDim2.fromOffset(size.X, size.Y)
				RecalculateScale()
			end
		end))
		Track(UserInputService.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				resizing = false
			end
		end))
		Track(handle.MouseEnter:Connect(function()
			Tween(gripVisual, 0.12, { BackgroundTransparency = 0 })
		end))
		Track(handle.MouseLeave:Connect(function()
			if not resizing then Tween(gripVisual, 0.12, { BackgroundTransparency = 0.4 }) end
		end))
	end
	EnableResize(ResizeGrip)

	local function UpdateTheme(name, animate)
		local T = Wolf.Themes[name] or Wolf.Themes["67"]
		Wolf.CurrentTheme = T
		Theme = T

		MainFrame.BackgroundColor3 = T.Background
		MainFrame.BackgroundTransparency = mainBgTrans
		CornerFlag.BackgroundColor3 = T.Accent
		BgTint.BackgroundColor3 = T.Accent
		BgTint.Visible = hasBackground and T.Name ~= "67"
		TabStripGlow.Color = T.Accent
		Sidebar.ScrollBarImageColor3 = T.Accent
		ThemePopup.BackgroundColor3 = T.ElementBackground
		TitleLabel.TextColor3 = T.Text
		DescLabel.TextColor3 = T.Placeholder
		MinBtn.TextColor3 = T.Text
		if ThemeBtn then
			ThemeBtn.Text = T.Name
			ThemeBtn.TextColor3 = T.Text
			ThemeBtn.BackgroundColor3 = Shade(T.ElementBackground)
		end
		if WindowStroke then WindowStroke.Color = T.Accent end
		if FloatStroke then FloatStroke.Color = T.Accent end
		if FloatGlow then FloatGlow.Color = T.Accent end

		if HeaderScan then HeaderScan.BackgroundColor3 = T.Accent end
		if SideScan then SideScan.BackgroundColor3 = T.Accent end

		FloatBtn.BackgroundColor3 = Color3.fromRGB(8, 8, 8)
		local fHolder = FloatBtn:FindFirstChildOfClass("Frame")
		if fHolder then
			local img = fHolder:FindFirstChildOfClass("ImageLabel")
			if img then TintIfAllowed(img, T.Accent) end
			local cross = fHolder:FindFirstChildOfClass("TextLabel")
			if cross then cross.TextColor3 = T.Accent end
		end
		for _, ch in ipairs(FloatBtn:GetChildren()) do
			if ch:IsA("TextLabel") and ch.Text ~= openButtonText then

			elseif ch:IsA("TextLabel") then
				ch.TextColor3 = Color3.fromRGB(255, 255, 255)
			end
		end
		for _, item in ipairs(Registered) do
			if item.Type == "TabBtn" then
				if item.Active then
					item.Label.TextColor3 = T.Text
					item.Instance.BackgroundColor3 = T.Accent
					item.Stroke.Color = T.Accent
					if item.Icon then TintIfAllowed(item.Icon, T.Accent) end
				else
					item.Label.TextColor3 = T.Placeholder
					item.Instance.BackgroundColor3 = T.Accent
					item.Stroke.Color = T.Accent
					if item.Icon then TintIfAllowed(item.Icon, T.Placeholder) end
				end
			elseif item.Type == "Element" then
				if item.CustomButtonColor then
					item.Instance.BackgroundColor3 = item.CustomButtonColor
				else
					item.Instance.BackgroundColor3 = T.ElementBackground
				end
				item.Instance.BackgroundTransparency = elementTrans
				if item.Stroke then
					item.Stroke.Color = T.Outline
					item.Stroke.Transparency = hasBackground and 0.35 or 0.2
				end
				if item.Label then item.Label.TextColor3 = T.Text end
				if item.Icon then TintIfAllowed(item.Icon, T.Icon) end
				if item.AccentBar then item.AccentBar.BackgroundColor3 = T.Accent end
				if item.SubColor then
					item.SubColor.BackgroundColor3 = item.SubRole == "Slider" and T.Slider or (item.State and item.State() and T.Toggle or Color3.fromRGB(60, 60, 65))
				end
				if item.SubBg then
					item.SubBg.BackgroundColor3 = Shade(T.ElementBackground)
				end
				if item.SubText then
					item.SubText.TextColor3 = T.Text
					if item.SubText:IsA("TextBox") then item.SubText.PlaceholderColor3 = T.Placeholder end
				end
				if item.Extras then
					for _, extra in ipairs(item.Extras) do
						if extra.Kind == "Text" then extra.Object.TextColor3 = T.Text
						elseif extra.Kind == "Placeholder" and extra.Object:IsA("TextBox") then extra.Object.PlaceholderColor3 = T.Placeholder
						elseif extra.Kind == "Icon" then TintIfAllowed(extra.Object, T.Icon)
						elseif extra.Kind == "Elevated" then extra.Object.BackgroundColor3 = Shade(T.ElementBackground)
						elseif extra.Kind == "Outline" and extra.Object:IsA("UIStroke") then extra.Object.Color = T.Outline
						elseif extra.Kind == "Accent" then extra.Object.BackgroundColor3 = T.Accent end
					end
				end
			elseif item.Type == "Section" then
				item.Label.TextColor3 = T.Placeholder
				if item.Icon then TintIfAllowed(item.Icon, T.Icon) end
			end
		end

		for _, notification in ipairs(ActiveNotifications) do
			if notification.Frame and notification.Frame.Parent then
				notification.Frame.BackgroundColor3 = T.ElementBackground
				if notification.Stroke then notification.Stroke.Color = T.Outline end
				if notification.Icon then TintIfAllowed(notification.Icon, T.Icon) end
				if notification.Title then notification.Title.TextColor3 = T.Text end
				if notification.Content then notification.Content.TextColor3 = T.Placeholder end
			end
		end

		if animate then
			Tween(MainFrame, 0.18, { BackgroundColor3 = T.Background })
		end
	end

	if showThemeSelector then
		for _, tName in ipairs(Wolf.ThemeOrder) do
			if Wolf.Themes[tName] then
				local btn = Instance.new("TextButton")
				btn.Size = UDim2.new(1, -8, 0, 30)
				btn.BackgroundColor3 = Wolf.Themes[tName].Accent
				btn.BackgroundTransparency = 0.78
				btn.AutoButtonColor = false
				btn.Text = tName
				btn.Font = Enum.Font.GothamMedium
				btn.TextSize = 12
				btn.TextColor3 = Wolf.Themes[tName].Text
				btn.TextXAlignment = Enum.TextXAlignment.Left
				btn.ZIndex = 52
				btn.Parent = ThemeScroll
				Round(4, btn)
				local pad = Instance.new("UIPadding")
				pad.PaddingLeft = UDim.new(0, 10)
				pad.Parent = btn
				btn.MouseEnter:Connect(function() Tween(btn, 0.12, { BackgroundTransparency = 0.55 }) end)
				btn.MouseLeave:Connect(function() Tween(btn, 0.12, { BackgroundTransparency = 0.78 }) end)
				btn.MouseButton1Click:Connect(function()
					UpdateTheme(tName, true)
					ThemePopup.Visible = false
				end)
			end
		end
		RegisterPopup(ThemePopup, ThemeBtn)
		ThemeBtn.MouseButton1Click:Connect(function()
			if ThemePopup.Visible then
				ThemePopup.Visible = false
				return
			end
			CloseAllPopups(ThemeBtn)
			local abs = ThemeBtn.AbsolutePosition
			local asz = ThemeBtn.AbsoluteSize
			local viewport = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1920, 1080)
			local x = math.clamp(abs.X + asz.X - 180, 6, math.max(6, viewport.X - 186))
			local belowY = abs.Y + asz.Y + 5
			local y = belowY + 280 <= viewport.Y - 6 and belowY or math.max(6, abs.Y - 285)
			ThemePopup.Position = UDim2.fromOffset(x, y)
			ThemePopup.Visible = true
		end)
	end

	function Window:SetSize(newSize)
		if typeof(newSize) == "Vector2" then
			size = Vector2.new(math.clamp(newSize.X, 400, 1000), math.clamp(newSize.Y, 320, 760))
			MainFrame.Size = UDim2.fromOffset(size.X, size.Y)
			RecalculateScale()
		end
	end

	function Window:SetBackgroundImage(src, transparency)
		local resolved = NormalizeImageSource(src)
		BgImageLabel.Image = resolved
		BgImageLabel.Visible = resolved ~= ""
		if transparency then BgImageLabel.ImageTransparency = transparency end
		hasBackground = resolved ~= ""
		BgTint.Visible = hasBackground and Theme.Name ~= "67"
		mainBgTrans = hasBackground and 0.92 or panelTransparency
		elementTrans = hasBackground and 0.82 or 0.22
		elevatedTrans = hasBackground and 0.7 or 0.16
		overlayTrans = hasBackground and 0.75 or 1
		MainFrame.BackgroundTransparency = mainBgTrans
		Overlay.BackgroundTransparency = overlayTrans
		UpdateTheme(Theme.Name, false)
	end

	function Window:SetTheme(name)
		UpdateTheme(name, true)
	end

	function Window:Minimize()
		CloseWindow()
	end

	function Window:Restore()
		OpenWindow()
	end

	function Window:Destroy()
		for _, c in ipairs(self.Connections) do
			pcall(function() c:Disconnect() end)
		end
		for i, w in ipairs(Wolf.Windows) do
			if w == self then table.remove(Wolf.Windows, i) break end
		end
		WindowGui:Destroy()
	end

	function Window:Dialog(config)
		config = config or {}
		local dTitle = config.Title or "Dialog"
		local dContent = config.Content or config.Text or ""
		local buttons = config.Buttons or { { Title = "Confirmar", Callback = nil } }

		local Overlay2 = Instance.new("Frame")
		Overlay2.Size = UDim2.fromScale(1, 1)
		Overlay2.BackgroundColor3 = Color3.new(0, 0, 0)
		Overlay2.BackgroundTransparency = 0.45
		Overlay2.ZIndex = 200
		Overlay2.Parent = MainFrame

		local Popup = Instance.new("Frame")
		Popup.Size = UDim2.fromOffset(300, 0)
		Popup.AutomaticSize = Enum.AutomaticSize.Y
		Popup.Position = UDim2.fromScale(0.5, 0.5)
		Popup.AnchorPoint = Vector2.new(0.5, 0.5)
		Popup.BackgroundColor3 = Theme.ElementBackground
		Popup.BackgroundTransparency = 0.03
		Popup.ZIndex = 201
		Popup.Parent = Overlay2
		Round(5, Popup)
		Outline(Popup, Theme.Outline, 1, 0.15)

		local pad = Instance.new("UIPadding")
		pad.PaddingTop = UDim.new(0, 16)
		pad.PaddingBottom = UDim.new(0, 16)
		pad.PaddingLeft = UDim.new(0, 16)
		pad.PaddingRight = UDim.new(0, 16)
		pad.Parent = Popup

		local layout = Instance.new("UIListLayout")
		layout.Padding = UDim.new(0, 10)
		layout.Parent = Popup

		local dTitleLbl = Instance.new("TextLabel")
		dTitleLbl.Size = UDim2.new(1, 0, 0, 22)
		dTitleLbl.BackgroundTransparency = 1
		dTitleLbl.Text = dTitle
		dTitleLbl.Font = Enum.Font.GothamBold
		dTitleLbl.TextSize = 16
		dTitleLbl.TextColor3 = Theme.Text
		dTitleLbl.TextXAlignment = Enum.TextXAlignment.Left
		dTitleLbl.ZIndex = 202
		dTitleLbl.Parent = Popup

		local dContentLbl = Instance.new("TextLabel")
		dContentLbl.Size = UDim2.new(1, 0, 0, 0)
		dContentLbl.AutomaticSize = Enum.AutomaticSize.Y
		dContentLbl.BackgroundTransparency = 1
		dContentLbl.Text = dContent
		dContentLbl.Font = Enum.Font.Gotham
		dContentLbl.TextSize = 13
		dContentLbl.TextColor3 = Theme.Placeholder
		dContentLbl.TextWrapped = true
		dContentLbl.TextXAlignment = Enum.TextXAlignment.Left
		dContentLbl.ZIndex = 202
		dContentLbl.Parent = Popup

		local btnRow = Instance.new("Frame")
		btnRow.Size = UDim2.new(1, 0, 0, 34)
		btnRow.BackgroundTransparency = 1
		btnRow.ZIndex = 202
		btnRow.Parent = Popup

		local btnLayout = Instance.new("UIListLayout")
		btnLayout.FillDirection = Enum.FillDirection.Horizontal
		btnLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
		btnLayout.Padding = UDim.new(0, 8)
		btnLayout.Parent = btnRow

		local function CloseDialog()
			Overlay2:Destroy()
		end

		for _, b in ipairs(buttons) do
			local bBtn = Instance.new("TextButton")
			bBtn.Size = UDim2.fromOffset(0, 34)
			bBtn.AutomaticSize = Enum.AutomaticSize.X
			bBtn.BackgroundColor3 = b.Primary and Theme.Accent or Shade(Theme.ElementBackground)
			bBtn.Text = "   " .. (b.Title or "Button") .. "   "
			bBtn.Font = Enum.Font.GothamBold
			bBtn.TextSize = 13
			bBtn.TextColor3 = Theme.Text
			bBtn.ZIndex = 203
			bBtn.Parent = btnRow
			Round(4, bBtn)
			if not b.Primary then Outline(bBtn, Theme.Outline, 1, 0.3) end
			bBtn.MouseButton1Click:Connect(function()
				if b.Callback then pcall(b.Callback) end
				if b.CloseOnClick ~= false then CloseDialog() end
			end)
		end

		return { Close = CloseDialog }
	end

	function Window:CreateTab(tabConfig, maybeIcon)
		local cfg = NormalizeArgs(tabConfig)
		local tabName, tabIcon
		if cfg then
			tabName = cfg.Name or cfg.Title or "Tab"
			tabIcon = cfg.Icon
		else
			tabName = tabConfig or "Tab"
			tabIcon = maybeIcon
		end

		local page = Instance.new("ScrollingFrame")
		page.Size = UDim2.fromScale(1, 1)
		page.BackgroundTransparency = 1
		page.Visible = false
		page.ScrollBarThickness = 3
		page.CanvasSize = UDim2.new(0, 0, 0, 0)
		page.AutomaticCanvasSize = Enum.AutomaticSize.Y
		page.ZIndex = 5
		page.Parent = PageHost

		local pageLayout = Instance.new("UIListLayout")
		pageLayout.Padding = UDim.new(0, 8)
		pageLayout.SortOrder = Enum.SortOrder.LayoutOrder
		pageLayout.Parent = page

		local pagePad = Instance.new("UIPadding")
		pagePad.PaddingBottom = UDim.new(0, 10)
		pagePad.PaddingRight = UDim.new(0, 6)
		pagePad.Parent = page

		local tabBtn = Instance.new("TextButton")
		tabBtn.Size = UDim2.new(1, 0, 0, 38)
		tabBtn.BackgroundColor3 = Theme.Accent
		tabBtn.BackgroundTransparency = 1
		tabBtn.Text = ""
		tabBtn.AutoButtonColor = false
		tabBtn.ZIndex = 6
		tabBtn.Parent = TabStrip
		Round(6, tabBtn)
		local tabStroke = Outline(tabBtn, Theme.Accent, 1, 1)

		local tabPad = Instance.new("UIPadding")
		tabPad.PaddingLeft = UDim.new(0, 10)
		tabPad.PaddingRight = UDim.new(0, 10)
		tabPad.Parent = tabBtn

		local tabRow = Instance.new("Frame")
		tabRow.Size = UDim2.fromScale(1, 1)
		tabRow.BackgroundTransparency = 1
		tabRow.ZIndex = 7
		tabRow.Parent = tabBtn

		local tabRowLayout = Instance.new("UIListLayout")
		tabRowLayout.FillDirection = Enum.FillDirection.Horizontal
		tabRowLayout.VerticalAlignment = Enum.VerticalAlignment.Center
		tabRowLayout.Padding = UDim.new(0, 8)
		tabRowLayout.Parent = tabRow

		local tIcon
		local resolvedTabIcon, resolvedTabIconIsCustom = ResolveIcon(tabIcon)
		if resolvedTabIcon ~= "" then
			tIcon = Instance.new("ImageLabel")
			tIcon.Size = UDim2.fromOffset(17, 17)
			tIcon.BackgroundTransparency = 1
			tIcon.Image = resolvedTabIcon
			tIcon.ScaleType = Enum.ScaleType.Crop
			tIcon.ImageColor3 = resolvedTabIconIsCustom and Color3.new(1, 1, 1) or Theme.Placeholder
			tIcon.ZIndex = 8
			tIcon.Parent = tabRow
		end

		local tLabel = Instance.new("TextLabel")
		tLabel.Size = UDim2.fromOffset(0, 38)
		tLabel.AutomaticSize = Enum.AutomaticSize.X
		tLabel.BackgroundTransparency = 1
		tLabel.Text = tabName
		tLabel.Font = Enum.Font.GothamSemibold
		tLabel.TextSize = 13
		tLabel.TextColor3 = Theme.Placeholder
		tLabel.TextXAlignment = Enum.TextXAlignment.Left
		tLabel.ZIndex = 8
		tLabel.Parent = tabRow

		local tabData = { Type = "TabBtn", Instance = tabBtn, Stroke = tabStroke, Label = tLabel, Icon = tIcon, Active = false, Page = page }
		table.insert(Registered, tabData)

		local function Activate()
			for _, item in ipairs(Registered) do
				if item.Type == "TabBtn" then
					item.Active = false
					item.Page.Visible = false
					item.Label.TextColor3 = Theme.Placeholder
					Tween(item.Instance, 0.15, { BackgroundTransparency = 1 })
					Tween(item.Stroke, 0.15, { Transparency = 1 })
					if item.Icon then TintIfAllowed(item.Icon, Theme.Placeholder) end
				end
			end
			tabData.Active = true
			page.Visible = true
			tLabel.TextColor3 = Theme.Text
			Tween(tabBtn, 0.15, { BackgroundTransparency = 0.88 })
			Tween(tabStroke, 0.15, { Transparency = 0.25 })
			if tIcon then TintIfAllowed(tIcon, Theme.Accent) end
		end

		tabBtn.MouseButton1Click:Connect(Activate)
		Ripple(tabBtn, Theme.Accent)

		if #Window.Tabs == 0 then
			task.defer(Activate)
		end

		local Tab = {}
		Window.Tabs[tabName] = Tab

		local function RegisterRow(height)
			local frame = Instance.new("Frame")
			frame.Size = UDim2.new(1, 0, 0, height or 52)
			frame.BackgroundColor3 = Theme.ElementBackground
			frame.BackgroundTransparency = elementTrans
			frame.ClipsDescendants = true
			frame.ZIndex = 6
			frame.Parent = page
			Round(8, frame)
			if hasBackground and resolvedBgImage ~= "" then
				local rowBg = Instance.new("ImageLabel")
				rowBg.Size = UDim2.fromScale(1, 1)
				rowBg.BackgroundTransparency = 1
				rowBg.Image = resolvedBgImage
				rowBg.ImageTransparency = 0.55
				rowBg.ScaleType = Enum.ScaleType.Crop
				rowBg.ZIndex = 6
				rowBg.Parent = frame
			end
			local stroke = Outline(frame, Theme.Accent, 1.2, 0.55)
			local accentBar = Instance.new("Frame")
			accentBar.Size = UDim2.new(0, 0, 1, 0)
			accentBar.BackgroundColor3 = Theme.Accent
			accentBar.BorderSizePixel = 0
			accentBar.ZIndex = 7
			accentBar.Parent = frame

			local rowScan = Instance.new("Frame")
			rowScan.Size = UDim2.new(0, 60, 0, 2)
			rowScan.Position = UDim2.new(0, 0, 1, -1)
			rowScan.BorderSizePixel = 0
			rowScan.BackgroundColor3 = Theme.Accent
			rowScan.ZIndex = 9
			rowScan.Parent = frame
			local rowScanGrad = Instance.new("UIGradient")
			rowScanGrad.Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 1),
				NumberSequenceKeypoint.new(0.4, 0),
				NumberSequenceKeypoint.new(0.6, 0),
				NumberSequenceKeypoint.new(1, 1),
			})
			rowScanGrad.Parent = rowScan
			task.spawn(function()
				while rowScan and rowScan.Parent do
					local tw1 = TweenService:Create(rowScan, TweenInfo.new(2.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), { Position = UDim2.new(1, -60, 1, -1) })
					tw1:Play()
					tw1.Completed:Wait()
					if not rowScan or not rowScan.Parent then break end
					local tw2 = TweenService:Create(rowScan, TweenInfo.new(2.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), { Position = UDim2.new(0, 0, 1, -1) })
					tw2:Play()
					tw2.Completed:Wait()
				end
			end)

			return frame, stroke, accentBar
		end

		local function AttachIcon(row, cfg, label)
			local icon = cfg and cfg.Icon
			if not icon then return nil end
			local position = cfg.IconPosition or "Left"
			local image = Img(row, icon, UDim2.fromOffset(16, 16), Theme.Icon, 0, 8)
			if not image then return nil end
			image.AnchorPoint = Vector2.new(position == "Right" and 1 or 0, 0.5)
			image.Position = position == "Right" and UDim2.new(1, -12, 0.5, 0) or UDim2.new(0, 14, 0.5, 0)
			if label and position == "Left" then
				label.Position = UDim2.new(0, 38, label.Position.Y.Scale, label.Position.Y.Offset)
				label.Size = UDim2.new(label.Size.X.Scale, label.Size.X.Offset - 30, label.Size.Y.Scale, label.Size.Y.Offset)
			elseif label and position == "Right" then
				label.Size = UDim2.new(label.Size.X.Scale, label.Size.X.Offset - 30, label.Size.Y.Scale, label.Size.Y.Offset)
			end
			return image
		end

		function Tab:CreateSection(secConfig)
			local cfg = NormalizeArgs(secConfig)
			local name = cfg and (cfg.Name or cfg.Title) or secConfig or "Section"

			local container = Instance.new("Frame")
			container.Size = UDim2.new(1, 0, 0, 0)
			container.AutomaticSize = Enum.AutomaticSize.Y
			container.BackgroundTransparency = 1
			container.ZIndex = 6
			container.Parent = page

			local layout = Instance.new("UIListLayout")
			layout.Padding = UDim.new(0, 6)
			layout.Parent = container

			local header = Instance.new("Frame")
			header.Size = UDim2.new(1, 0, 0, 22)
			header.BackgroundTransparency = 1
			header.ZIndex = 6
			header.Parent = container

			local hLabel = Instance.new("TextLabel")
			hLabel.Size = UDim2.new(1, -12, 1, 0)
			hLabel.Position = UDim2.new(0, 2, 0, 0)
			hLabel.BackgroundTransparency = 1
			hLabel.Text = string.upper(tostring(name))
			hLabel.Font = Enum.Font.GothamBold
			hLabel.TextSize = 11
			hLabel.TextColor3 = Theme.Placeholder
			hLabel.TextXAlignment = Enum.TextXAlignment.Left
			hLabel.ZIndex = 7
			hLabel.Parent = header
			local sectionIcon = cfg and AttachIcon(header, cfg, hLabel)

			table.insert(Registered, { Type = "Section", Label = hLabel, Icon = sectionIcon })

			local Section = {}

			function Section:CreateToggle(tConfig)
				local c = NormalizeArgs(tConfig) or {}
				local name = c.Name or c.Title or "Toggle"
				local desc = c.Desc or c.Description or c.Content or ""
				local default = c.Default or c.Value or false
				local callback = c.Callback or function() end
				local flag = c.Flag
				if flag and Wolf.Flags[flag] ~= nil then default = Wolf.Flags[flag] end

				local rowH = (desc ~= "" and 78 or 46)
				local row, stroke, accentBar = RegisterRow(rowH)
				row.Parent = container
				ApplyDependsOn(row, c)

				local lbl = Instance.new("TextLabel")
				lbl.Size = UDim2.new(1, -78, 0, 18)
				lbl.Position = UDim2.new(0, 14, 0, 10)
				lbl.BackgroundTransparency = 1
				lbl.Text = name
				lbl.Font = Enum.Font.GothamBold
				lbl.TextSize = 13
				lbl.TextColor3 = Theme.Text
				lbl.TextXAlignment = Enum.TextXAlignment.Left
				lbl.ZIndex = 7
				lbl.Parent = row
				local elementIcon = AttachIcon(row, c, lbl)

				if desc ~= "" then
					local dLbl = Instance.new("TextLabel")
					dLbl.Size = UDim2.new(1, -24, 0, 28)
					dLbl.Position = UDim2.new(0, 14, 0, 34)
					dLbl.BackgroundTransparency = 1
					dLbl.Text = desc
					dLbl.Font = Enum.Font.Gotham
					dLbl.TextSize = 11
					dLbl.TextColor3 = Theme.Placeholder
					dLbl.TextXAlignment = Enum.TextXAlignment.Left
					dLbl.TextYAlignment = Enum.TextYAlignment.Top
					dLbl.TextWrapped = true
					dLbl.ZIndex = 7
					dLbl.Parent = row
				end

				local switchW, switchH, knobSize, inset = 42, 22, 18, 2
				local track = Instance.new("TextButton")
				track.AnchorPoint = Vector2.new(1, 0)
				track.Position = UDim2.new(1, -14, 0, 8)
				track.Size = UDim2.fromOffset(switchW, switchH)
				track.BackgroundColor3 = default and Theme.Toggle or Color3.fromRGB(60, 60, 65)
				track.Text = ""
				track.AutoButtonColor = false
				track.ZIndex = 8
				track.Parent = row
				Round(switchH, track)

				local knob = Instance.new("Frame")
				knob.AnchorPoint = Vector2.new(0, 0.5)
				knob.Position = UDim2.new(0, inset, 0.5, 0)
				knob.Size = UDim2.fromOffset(knobSize, knobSize)
				knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
				knob.BorderSizePixel = 0
				knob.ZIndex = 9
				knob.Parent = track
				Round(knobSize, knob)

				local state = default
				if flag then Wolf.Flags[flag] = state end

				local function refresh(animate)
					local knobPos = state and UDim2.new(1, -(inset + knobSize), 0.5, 0) or UDim2.new(0, inset, 0.5, 0)
					local trackColor = state and Theme.Toggle or Color3.fromRGB(60, 60, 65)
					if animate then
						Tween(knob, 0.16, { Position = knobPos })
						Tween(track, 0.16, { BackgroundColor3 = trackColor })
					else
						knob.Position = knobPos
						track.BackgroundColor3 = trackColor
					end
				end
				refresh(false)

				track.MouseButton1Click:Connect(function()
					state = not state
					if flag then Wolf.Flags[flag] = state end
					refresh(true)
					callback(state)
					CheckDependents()
				end)

				table.insert(Registered, { Type = "Element", Instance = row, Stroke = stroke, AccentBar = accentBar, Label = lbl, Icon = elementIcon, SubColor = track, State = function() return state end })

				local obj = {}
				function obj:Set(v)
					state = v
					if flag then Wolf.Flags[flag] = state end
					refresh(true)
					callback(state)
					CheckDependents()
				end
				function obj:Get() return state end
				return obj
			end

			function Section:CreateSlider(sConfig)
				local c = NormalizeArgs(sConfig) or {}
				local name = c.Name or c.Title or "Slider"
				local min = c.Min or 0
				local max = c.Max or 100
				local default = c.Default or c.Value or min
				local callback = c.Callback or function() end

				local row, stroke, accentBar = RegisterRow(54)
				row.Parent = container
				ApplyDependsOn(row, c)

				local lbl = Instance.new("TextLabel")
				lbl.Size = UDim2.new(1, -20, 0, 18)
				lbl.Position = UDim2.new(0, 14, 0, 4)
				lbl.BackgroundTransparency = 1
				lbl.Text = name
				lbl.Font = Enum.Font.GothamMedium
				lbl.TextSize = 12
				lbl.TextColor3 = Theme.Text
				lbl.TextXAlignment = Enum.TextXAlignment.Left
				lbl.ZIndex = 7
				lbl.Parent = row
				local elementIcon = AttachIcon(row, c, lbl)

				local valLbl = Instance.new("TextLabel")
				valLbl.Size = UDim2.fromOffset(50, 18)
				valLbl.Position = UDim2.new(1, -62, 0, 4)
				valLbl.BackgroundTransparency = 1
				valLbl.Text = tostring(default)
				valLbl.Font = Enum.Font.GothamBold
				valLbl.TextSize = 12
				valLbl.TextColor3 = Theme.Accent
				valLbl.TextXAlignment = Enum.TextXAlignment.Right
				valLbl.ZIndex = 7
				valLbl.Parent = row

				local track = Instance.new("Frame")
				track.Size = UDim2.new(1, -28, 0, 3)
				track.Position = UDim2.new(0, 14, 0, 34)
				track.BackgroundColor3 = Shade(Theme.ElementBackground)
				track.ZIndex = 7
				track.Parent = row

				local fill = Instance.new("Frame")
				local t0 = (default - min) / math.max(max - min, 1)
				fill.Size = UDim2.new(t0, 0, 1, 0)
				fill.BackgroundColor3 = Theme.Slider
				fill.ZIndex = 8
				fill.Parent = track

				local handle = Instance.new("Frame")
				handle.Size = UDim2.fromOffset(10, 10)
				handle.AnchorPoint = Vector2.new(0.5, 0.5)
				handle.Position = UDim2.new(t0, 0, 0.5, 0)
				handle.Rotation = 45
				handle.BackgroundColor3 = Theme.Slider
				handle.ZIndex = 9
				handle.Parent = track
				Outline(handle, Color3.new(1, 1, 1), 1, 0.3)

				local dragging = false
				local function apply(v)
					v = math.clamp(math.floor(v + 0.5), min, max)
					valLbl.Text = tostring(v)
					local t = (v - min) / math.max(max - min, 1)
					fill.Size = UDim2.new(t, 0, 1, 0)
					handle.Position = UDim2.new(t, 0, 0.5, 0)
					callback(v)
				end

				local function fromX(x)
					local abs = track.AbsolutePosition.X
					local sz = track.AbsoluteSize.X
					if sz <= 0 then return end
					local t = math.clamp((x - abs) / sz, 0, 1)
					apply(min + t * (max - min))
				end

				track.InputBegan:Connect(function(i)
					if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
						dragging = true
						fromX(i.Position.X)
					end
				end)
				Track(UserInputService.InputChanged:Connect(function(i)
					if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
						fromX(i.Position.X)
					end
				end))
				Track(UserInputService.InputEnded:Connect(function() dragging = false end))

				table.insert(Registered, { Type = "Element", Instance = row, Stroke = stroke, AccentBar = accentBar, Label = lbl, Icon = elementIcon, SubColor = fill, SubRole = "Slider", Extras = {{Kind = "Accent", Object = handle}} })

				local obj = {}
				function obj:Set(v) apply(v) end
				function obj:Get() return tonumber(valLbl.Text) end
				return obj
			end

			function Section:CreateButton(bConfig)
				local c = NormalizeArgs(bConfig) or {}
				local name = c.Name or c.Title or "Button"
				local description = c.Description or c.Desc
				local bannerSrc = c.Image or c.Banner
				local bannerHeight = c.ImageHeight or 84
				local icon = c.Icon
				local callback = c.Callback or function() end
				local customColor = c.Color or c.ButtonColor
				if type(customColor) == "string" then
					local ok, col = pcall(function() return Color3.fromHex(customColor) end)
					customColor = ok and col or nil
				elseif typeof(customColor) ~= "Color3" then
					customColor = nil
				end
				local baseColor = customColor or Theme.ElementBackground
				local hoverColor = customColor and Shade(customColor, 0.12) or Shade(Theme.ElementBackground, 0.06)

				local resolvedBanner = ResolveIcon(bannerSrc)
				local hasBanner = resolvedBanner ~= ""
				local hasIcon = icon ~= nil
				local textTop = hasBanner and (bannerHeight + 10) or 8
				local textLeft = hasIcon and 42 or 16
				local textBlockHeight = description and 36 or 18
				local totalHeight = textTop + textBlockHeight + 10

				local btn = Instance.new("TextButton")
				btn.Size = UDim2.new(1, 0, 0, totalHeight)
				btn.BackgroundColor3 = baseColor
				btn.Text = ""
				btn.AutoButtonColor = false
				btn.ClipsDescendants = true
				btn.ZIndex = 6
				btn.Parent = container
				ApplyDependsOn(btn, c)
				Round(4, btn)
				local stroke = Outline(btn, Theme.Outline, 1, 0.35)

				local accentBar = Instance.new("Frame")
				accentBar.Size = UDim2.new(0, 2, 1, -12)
				accentBar.Position = UDim2.new(0, 0, 0, 6)
				accentBar.BackgroundColor3 = Theme.Accent
				accentBar.BorderSizePixel = 0
				accentBar.ZIndex = 7
				accentBar.Parent = btn

				if hasBanner then
					local bannerImg = Instance.new("ImageLabel")
					bannerImg.Size = UDim2.new(1, 0, 0, bannerHeight)
					bannerImg.BackgroundTransparency = 1
					bannerImg.Image = resolvedBanner
					bannerImg.ScaleType = Enum.ScaleType.Crop
					bannerImg.ZIndex = 7
					bannerImg.Parent = btn
				end

				local iconImg
				if hasIcon then
					iconImg = Img(btn, icon, UDim2.fromOffset(18, 18), Theme.Icon, 0, 8)
					if iconImg then
						iconImg.Position = UDim2.new(0, 14, 0, textTop + math.floor(textBlockHeight / 2) - 9)
					end
				end

				local titleLbl = Instance.new("TextLabel")
				titleLbl.Position = UDim2.new(0, textLeft, 0, textTop)
				titleLbl.Size = UDim2.new(1, -(textLeft + 14), 0, description and 18 or textBlockHeight)
				titleLbl.BackgroundTransparency = 1
				titleLbl.Text = name
				titleLbl.Font = Enum.Font.GothamBold
				titleLbl.TextSize = 13
				titleLbl.TextColor3 = Theme.Text
				titleLbl.TextXAlignment = Enum.TextXAlignment.Left
				titleLbl.ZIndex = 7
				titleLbl.Parent = btn

				local descLbl
				if description then
					descLbl = Instance.new("TextLabel")
					descLbl.Position = UDim2.new(0, textLeft, 0, textTop + 18)
					descLbl.Size = UDim2.new(1, -(textLeft + 14), 0, 18)
					descLbl.BackgroundTransparency = 1
					descLbl.Text = description
					descLbl.Font = Enum.Font.Gotham
					descLbl.TextSize = 11
					descLbl.TextColor3 = Theme.Placeholder
					descLbl.TextXAlignment = Enum.TextXAlignment.Left
					descLbl.TextWrapped = true
					descLbl.ZIndex = 7
					descLbl.Parent = btn
				end

				btn.MouseEnter:Connect(function() Tween(btn, 0.12, { BackgroundColor3 = hoverColor }) end)
				btn.MouseLeave:Connect(function() Tween(btn, 0.12, { BackgroundColor3 = baseColor }) end)
				btn.MouseButton1Click:Connect(function() callback() end)
				Ripple(btn, Theme.Accent)

				local extras = {}
				if descLbl then table.insert(extras, { Kind = "Text", Object = descLbl }) end
				if iconImg then table.insert(extras, { Kind = "Icon", Object = iconImg }) end

				table.insert(Registered, { Type = "Element", Instance = btn, Stroke = stroke, AccentBar = accentBar, Label = titleLbl, CustomButtonColor = customColor, Extras = #extras > 0 and extras or nil })
			end

			function Section:CreateBanner(bnConfig)
				local c = NormalizeArgs(bnConfig) or {}
				local image = c.Image or c.Banner
				local height = c.Height or 120
				local bTitle = c.Title or c.Name
				local caption = c.Caption or c.Description

				local resolved = ResolveIcon(image)
				local frame = Instance.new("Frame")
				frame.Size = UDim2.new(1, 0, 0, height)
				frame.BackgroundColor3 = Theme.ElementBackground
				frame.BackgroundTransparency = elementTrans
				frame.ClipsDescendants = true
				frame.ZIndex = 6
				frame.Parent = container
				ApplyDependsOn(frame, c)
				Round(4, frame)
				local stroke = Outline(frame, Theme.Outline, 1, hasBackground and 0.35 or 0.2)

				local img = Instance.new("ImageLabel")
				img.Size = UDim2.fromScale(1, 1)
				img.BackgroundTransparency = 1
				img.Image = resolved
				img.ScaleType = Enum.ScaleType.Crop
				img.ZIndex = 7
				img.Parent = frame

				if bTitle or caption then
					local overlay = Instance.new("Frame")
					overlay.Size = UDim2.fromScale(1, 1)
					overlay.BackgroundColor3 = Color3.new(0, 0, 0)
					overlay.BackgroundTransparency = 0.4
					overlay.ZIndex = 8
					overlay.Parent = frame

					local grad = Instance.new("UIGradient")
					grad.Rotation = 90
					grad.Transparency = NumberSequence.new({
						NumberSequenceKeypoint.new(0, 1),
						NumberSequenceKeypoint.new(0.55, 0.85),
						NumberSequenceKeypoint.new(1, 0.25),
					})
					grad.Parent = overlay

					local accentTag = Instance.new("Frame")
					accentTag.Size = UDim2.new(0, 24, 0, 3)
					accentTag.Position = UDim2.new(0, 12, 1, -(caption and 58 or 42))
					accentTag.BackgroundColor3 = Theme.Accent
					accentTag.BorderSizePixel = 0
					accentTag.ZIndex = 9
					accentTag.Parent = frame

					if bTitle then
						local titleLbl = Instance.new("TextLabel")
						titleLbl.Position = UDim2.new(0, 12, 1, -(caption and 44 or 28))
						titleLbl.Size = UDim2.new(1, -24, 0, 22)
						titleLbl.BackgroundTransparency = 1
						titleLbl.Text = bTitle
						titleLbl.Font = Enum.Font.GothamBold
						titleLbl.TextSize = 15
						titleLbl.TextColor3 = Color3.new(1, 1, 1)
						titleLbl.TextXAlignment = Enum.TextXAlignment.Left
						titleLbl.ZIndex = 9
						titleLbl.Parent = frame
					end

					if caption then
						local captionLbl = Instance.new("TextLabel")
						captionLbl.Position = UDim2.new(0, 12, 1, -22)
						captionLbl.Size = UDim2.new(1, -24, 0, 18)
						captionLbl.BackgroundTransparency = 1
						captionLbl.Text = caption
						captionLbl.Font = Enum.Font.Gotham
						captionLbl.TextSize = 12
						captionLbl.TextColor3 = Color3.fromRGB(225, 225, 230)
						captionLbl.TextXAlignment = Enum.TextXAlignment.Left
						captionLbl.TextWrapped = true
						captionLbl.ZIndex = 9
						captionLbl.Parent = frame
					end
				end

				table.insert(Registered, { Type = "Element", Instance = frame, Stroke = stroke })

				local obj = {}
				function obj:SetImage(src)
					img.Image = ResolveIcon(src)
				end
				return obj
			end

			function Section:CreateHero(hConfig)
				local c = NormalizeArgs(hConfig) or {}
				local hTitle = c.Title or c.Name or ""
				local content = c.Content or c.Description or c.Text or ""
				local image = c.Image
				local imageWidth = c.ImageWidth or 150
				local height = c.Height or 176

				local frame = Instance.new("Frame")
				frame.Size = UDim2.new(1, 0, 0, height)
				frame.BackgroundColor3 = Theme.ElementBackground
				frame.BackgroundTransparency = elementTrans
				frame.ClipsDescendants = true
				frame.ZIndex = 6
				frame.Parent = container
				ApplyDependsOn(frame, c)
				Round(6, frame)
				local stroke = Outline(frame, Theme.Outline, 1, hasBackground and 0.35 or 0.25)

				local accentBar = Instance.new("Frame")
				accentBar.Size = UDim2.new(1, 0, 0, 2)
				accentBar.BackgroundColor3 = Theme.Accent
				accentBar.BorderSizePixel = 0
				accentBar.ZIndex = 7
				accentBar.Parent = frame

				local resolvedImage = ResolveIcon(image)
				local hasImage = resolvedImage ~= ""

				local textHolder = Instance.new("Frame")
				textHolder.Size = hasImage and UDim2.new(1, -(imageWidth + 34), 1, -32) or UDim2.new(1, -32, 1, -32)
				textHolder.Position = UDim2.new(0, 16, 0, 20)
				textHolder.BackgroundTransparency = 1
				textHolder.ZIndex = 7
				textHolder.Parent = frame

				local titleIcon
				local resolvedTitleIcon, titleIconIsCustom = ResolveIcon(c.Icon)
				local hasTitleIcon = resolvedTitleIcon ~= ""

				local titleLbl = Instance.new("TextLabel")
				titleLbl.Size = UDim2.new(1, hasTitleIcon and -22 or 0, 0, 22)
				titleLbl.Position = UDim2.new(0, hasTitleIcon and 22 or 0, 0, 0)
				titleLbl.BackgroundTransparency = 1
				titleLbl.Text = hTitle
				titleLbl.Font = Enum.Font.GothamBold
				titleLbl.TextSize = 17
				titleLbl.TextColor3 = Theme.Text
				titleLbl.TextXAlignment = Enum.TextXAlignment.Left
				titleLbl.ZIndex = 8
				titleLbl.Parent = textHolder

				if hasTitleIcon then
					titleIcon = Instance.new("ImageLabel")
					titleIcon.Size = UDim2.fromOffset(17, 17)
					titleIcon.Position = UDim2.new(0, 0, 0, 2)
					titleIcon.BackgroundTransparency = 1
					titleIcon.Image = resolvedTitleIcon
					titleIcon.ScaleType = titleIconIsCustom and Enum.ScaleType.Crop or Enum.ScaleType.Stretch
					titleIcon.ImageColor3 = titleIconIsCustom and Color3.new(1, 1, 1) or Theme.Accent
					titleIcon.ZIndex = 8
					titleIcon.Parent = textHolder
					if titleIconIsCustom then titleIcon:SetAttribute("WolfCustomIcon", true) end
				end

				local contentLbl = Instance.new("TextLabel")
				contentLbl.Size = UDim2.new(1, 0, 1, -32)
				contentLbl.Position = UDim2.new(0, 0, 0, 30)
				contentLbl.BackgroundTransparency = 1
				contentLbl.Text = content
				contentLbl.Font = Enum.Font.Gotham
				contentLbl.TextSize = 12
				contentLbl.TextColor3 = Theme.Placeholder
				contentLbl.TextWrapped = true
				contentLbl.TextXAlignment = Enum.TextXAlignment.Left
				contentLbl.TextYAlignment = Enum.TextYAlignment.Top
				contentLbl.ZIndex = 8
				contentLbl.Parent = textHolder

				local heroImg
				if hasImage then
					heroImg = Instance.new("ImageLabel")
					heroImg.Size = UDim2.fromOffset(imageWidth, height - 24)
					heroImg.Position = UDim2.new(1, -imageWidth - 16, 0.5, -(height - 24) / 2)
					heroImg.BackgroundTransparency = 1
					heroImg.Image = resolvedImage
					heroImg.ScaleType = Enum.ScaleType.Fit
					heroImg.ZIndex = 7
					heroImg.Parent = frame
				end

				table.insert(Registered, { Type = "Element", Instance = frame, Stroke = stroke, AccentBar = accentBar, Label = titleLbl, Icon = titleIcon, Extras = {{Kind = "Text", Object = contentLbl}} })

				local obj = {}
				function obj:SetImage(src)
					if heroImg then heroImg.Image = ResolveIcon(src) end
				end
				function obj:SetText(newTitle, newContent)
					if newTitle then titleLbl.Text = newTitle end
					if newContent then contentLbl.Text = newContent end
				end
				return obj
			end

			function Section:CreateCardGrid(gConfig)
				local c = NormalizeArgs(gConfig) or {}
				local cards = c.Cards or {}
				local columns = c.Columns or 2
				local cardHeight = c.CardHeight or 110

				local grid = Instance.new("Frame")
				grid.Size = UDim2.new(1, 0, 0, 0)
				grid.AutomaticSize = Enum.AutomaticSize.Y
				grid.BackgroundTransparency = 1
				grid.ZIndex = 6
				grid.Parent = container
				ApplyDependsOn(grid, c)

				local gridLayout = Instance.new("UIGridLayout")
				gridLayout.CellPadding = UDim2.new(0, 10, 0, 10)
				gridLayout.CellSize = UDim2.new(1 / columns, -(10 * (columns - 1) / columns), 0, cardHeight)
				gridLayout.FillDirectionMaxCells = 0
				gridLayout.SortOrder = Enum.SortOrder.LayoutOrder
				gridLayout.Parent = grid

				local cardObjs = {}

				for idx, cardCfg in ipairs(cards) do
					local cIcon = cardCfg.Icon
					local cTitle = cardCfg.Title or cardCfg.Name or ""
					local cDesc = cardCfg.Description or cardCfg.Content or ""
					local cButton = cardCfg.Button

					local card = Instance.new("Frame")
					card.BackgroundColor3 = Theme.ElementBackground
					card.BackgroundTransparency = elementTrans
					card.ClipsDescendants = true
					card.ZIndex = 6
					card.LayoutOrder = idx
					card.Parent = grid
					Round(8, card)
					if hasBackground and resolvedBgImage ~= "" then
						local cardBg = Instance.new("ImageLabel")
						cardBg.Size = UDim2.fromScale(1, 1)
						cardBg.BackgroundTransparency = 1
						cardBg.Image = resolvedBgImage
						cardBg.ImageTransparency = 0.55
						cardBg.ScaleType = Enum.ScaleType.Crop
						cardBg.ZIndex = 6
						cardBg.Parent = card
					end
					local cardStroke = Outline(card, Theme.Accent, 1.2, 0.55)

					local cardScan = Instance.new("Frame")
					cardScan.Size = UDim2.new(0, 50, 0, 2)
					cardScan.Position = UDim2.new(0, 0, 1, -1)
					cardScan.BorderSizePixel = 0
					cardScan.BackgroundColor3 = Theme.Accent
					cardScan.ZIndex = 9
					cardScan.Parent = card
					local cardScanGrad = Instance.new("UIGradient")
					cardScanGrad.Transparency = NumberSequence.new({
						NumberSequenceKeypoint.new(0, 1),
						NumberSequenceKeypoint.new(0.4, 0),
						NumberSequenceKeypoint.new(0.6, 0),
						NumberSequenceKeypoint.new(1, 1),
					})
					cardScanGrad.Parent = cardScan
					task.spawn(function()
						while cardScan and cardScan.Parent do
							local tw1 = TweenService:Create(cardScan, TweenInfo.new(2.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), { Position = UDim2.new(1, -50, 1, -1) })
							tw1:Play()
							tw1.Completed:Wait()
							if not cardScan or not cardScan.Parent then break end
							local tw2 = TweenService:Create(cardScan, TweenInfo.new(2.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), { Position = UDim2.new(0, 0, 1, -1) })
							tw2:Play()
							tw2.Completed:Wait()
						end
					end)

					local headRow = Instance.new("Frame")
					headRow.Size = UDim2.new(1, -28, 0, 34)
					headRow.Position = UDim2.new(0, 14, 0, 14)
					headRow.BackgroundTransparency = 1
					headRow.ZIndex = 7
					headRow.Parent = card

					local iconHolder
					if cIcon then
						iconHolder = Instance.new("Frame")
						iconHolder.Size = UDim2.fromOffset(34, 34)
						iconHolder.BackgroundColor3 = Shade(Theme.ElementBackground, 0.08)
						iconHolder.ZIndex = 7
						iconHolder.Parent = headRow
						Round(6, iconHolder)
						Outline(iconHolder, Theme.Outline, 1, 0.35)
						local iconImg = Img(iconHolder, cIcon, UDim2.fromOffset(17, 17), Theme.Accent, 0, 8)
						if iconImg then
							iconImg.AnchorPoint = Vector2.new(0.5, 0.5)
							iconImg.Position = UDim2.fromScale(0.5, 0.5)
						end
					end

					local cTitleLbl = Instance.new("TextLabel")
					cTitleLbl.Size = UDim2.new(1, cIcon and -44 or 0, 1, 0)
					cTitleLbl.Position = UDim2.new(0, cIcon and 44 or 0, 0, 0)
					cTitleLbl.BackgroundTransparency = 1
					cTitleLbl.Text = cTitle
					cTitleLbl.Font = Enum.Font.GothamBold
					cTitleLbl.TextSize = 13
					cTitleLbl.TextColor3 = Theme.Text
					cTitleLbl.TextXAlignment = Enum.TextXAlignment.Left
					cTitleLbl.TextYAlignment = Enum.TextYAlignment.Center
					cTitleLbl.ZIndex = 8
					cTitleLbl.Parent = headRow

					local cDescLbl = Instance.new("TextLabel")
					cDescLbl.Size = UDim2.new(1, -28, 0, cButton and (cardHeight - 108) or (cardHeight - 62))
					cDescLbl.Position = UDim2.new(0, 14, 0, 54)
					cDescLbl.BackgroundTransparency = 1
					cDescLbl.Text = cDesc
					cDescLbl.Font = Enum.Font.Gotham
					cDescLbl.TextSize = 11
					cDescLbl.TextColor3 = Theme.Placeholder
					cDescLbl.TextWrapped = true
					cDescLbl.TextXAlignment = Enum.TextXAlignment.Left
					cDescLbl.TextYAlignment = Enum.TextYAlignment.Top
					cDescLbl.ZIndex = 8
					cDescLbl.Parent = card

					local cardExtras = { { Kind = "Text", Object = cTitleLbl }, { Kind = "Text", Object = cDescLbl } }

					if cButton then
						local btnRow = Instance.new("TextButton")
						btnRow.Size = UDim2.new(1, -28, 0, 44)
						btnRow.Position = UDim2.new(0, 14, 1, -58)
						btnRow.BackgroundColor3 = Shade(Theme.ElementBackground, 0.08)
						btnRow.AutoButtonColor = false
						btnRow.Text = ""
						btnRow.ZIndex = 7
						btnRow.Parent = card
						Round(5, btnRow)
						local btnStroke = Outline(btnRow, Theme.Outline, 1, 0.3)

						local bIconImg
						if cButton.Icon then
							bIconImg = Img(btnRow, cButton.Icon, UDim2.fromOffset(16, 16), Theme.Accent, 0, 8)
							if bIconImg then bIconImg.Position = UDim2.new(0, 12, 0.5, -8) end
						end

						local bTextLbl = Instance.new("TextLabel")
						bTextLbl.Size = UDim2.new(1, -60, 1, 0)
						bTextLbl.Position = UDim2.new(0, cButton.Icon and 36 or 12, 0, 0)
						bTextLbl.BackgroundTransparency = 1
						bTextLbl.Text = cButton.Text or "Abrir"
						bTextLbl.Font = Enum.Font.GothamBold
						bTextLbl.TextSize = 12
						bTextLbl.TextColor3 = Theme.Text
						bTextLbl.TextXAlignment = Enum.TextXAlignment.Left
						bTextLbl.ZIndex = 8
						bTextLbl.Parent = btnRow

						local arrowLbl = Instance.new("TextLabel")
						arrowLbl.Size = UDim2.fromOffset(20, 20)
						arrowLbl.Position = UDim2.new(1, -28, 0.5, -10)
						arrowLbl.BackgroundTransparency = 1
						arrowLbl.Text = "->"
						arrowLbl.Font = Enum.Font.GothamBold
						arrowLbl.TextSize = 13
						arrowLbl.TextColor3 = Theme.Accent
						arrowLbl.ZIndex = 8
						arrowLbl.Parent = btnRow

						btnRow.MouseEnter:Connect(function() Tween(btnRow, 0.12, { BackgroundColor3 = Shade(Theme.ElementBackground, 0.14) }) end)
						btnRow.MouseLeave:Connect(function() Tween(btnRow, 0.12, { BackgroundColor3 = Shade(Theme.ElementBackground, 0.08) }) end)
						btnRow.MouseButton1Click:Connect(function()
							if cButton.Callback then cButton.Callback() end
						end)

						table.insert(cardExtras, { Kind = "Elevated", Object = btnRow })
						table.insert(cardExtras, { Kind = "Outline", Object = btnStroke })
						table.insert(cardExtras, { Kind = "Text", Object = bTextLbl })
						if bIconImg then table.insert(cardExtras, { Kind = "Icon", Object = bIconImg }) end
					end

					table.insert(Registered, { Type = "Element", Instance = card, Stroke = cardStroke, Extras = cardExtras })
					table.insert(cardObjs, card)
				end

				return { Cards = cardObjs }
			end

			function Section:CreateDropdown(dConfig)
				local c = NormalizeArgs(dConfig) or {}
				local name = c.Name or c.Title or "Dropdown"
				local options = c.Options or {}
				local multi = c.Multi == true
				local default = c.Default or c.Value
				local callback = c.Callback or function() end
				local flag = c.Flag

				local selected
				if multi then
					selected = {}
					if type(default) == "table" then
						for _, v in ipairs(default) do selected[v] = true end
					elseif default ~= nil then
						selected[default] = true
					end
				else
					selected = default
				end

				local row, stroke, accentBar = RegisterRow(40)
				row.Parent = container
				ApplyDependsOn(row, c)

				local lbl = Instance.new("TextLabel")
				lbl.Size = UDim2.new(0.4, 0, 1, 0)
				lbl.Position = UDim2.new(0, 14, 0, 0)
				lbl.BackgroundTransparency = 1
				lbl.Text = name
				lbl.Font = Enum.Font.GothamMedium
				lbl.TextSize = 13
				lbl.TextColor3 = Theme.Text
				lbl.TextXAlignment = Enum.TextXAlignment.Left
				lbl.ZIndex = 7
				lbl.Parent = row
				local elementIcon = AttachIcon(row, c, lbl)

				local sel = Instance.new("TextButton")
				sel.Size = UDim2.new(0.55, -12, 0, 26)
				sel.Position = UDim2.new(0.42, 0, 0.5, -13)
				sel.BackgroundColor3 = Shade(Theme.ElementBackground)
				sel.Text = ""
				sel.ZIndex = 7
				sel.Parent = row
				Round(4, sel)

				local function formatSelected()
					if multi then
						local parts = {}
						for _, opt in ipairs(options) do
							local val = type(opt) == "table" and (opt.Value or opt.Text) or opt
							local txt = type(opt) == "table" and (opt.Text or opt.Value) or tostring(opt)
							if selected[val] then table.insert(parts, tostring(txt)) end
						end
						if #parts == 0 then return "Seleccionar..." end
						if #parts <= 2 then return table.concat(parts, ", ") end
						return string.format("%d seleccionados", #parts)
					end
					return selected ~= nil and tostring(selected) or "Seleccionar..."
				end

				local selLbl = Instance.new("TextLabel")
				selLbl.Size = UDim2.new(1, -20, 1, 0)
				selLbl.Position = UDim2.new(0, 10, 0, 0)
				selLbl.BackgroundTransparency = 1
				selLbl.Text = formatSelected()
				selLbl.Font = Enum.Font.Gotham
				selLbl.TextSize = 12
				selLbl.TextColor3 = Theme.Text
				selLbl.TextXAlignment = Enum.TextXAlignment.Left
				selLbl.TextTruncate = Enum.TextTruncate.AtEnd
				selLbl.ZIndex = 8
				selLbl.Parent = sel

				local list = Instance.new("ScrollingFrame")
				list.BackgroundColor3 = Theme.ElementBackground
				list.BackgroundTransparency = 0.05
				list.Visible = false
				list.ZIndex = 100
				list.ClipsDescendants = true
				list.BorderSizePixel = 0
				list.ScrollBarThickness = 3
				list.ScrollBarImageColor3 = Theme.Outline
				list.CanvasSize = UDim2.new(0, 0, 0, 0)
				list.AutomaticCanvasSize = Enum.AutomaticSize.None
				list.Parent = WindowGui
				Round(4, list)
				Outline(list, Theme.Outline, 1, 0.15)

				local listPad = Instance.new("UIPadding")
				listPad.PaddingTop = UDim.new(0, 2)
				listPad.PaddingBottom = UDim.new(0, 2)
				listPad.Parent = list

				local listLayout = Instance.new("UIListLayout")
				listLayout.SortOrder = Enum.SortOrder.LayoutOrder
				listLayout.Parent = list

				local function getMultiArray()
					local arr = {}
					for _, opt in ipairs(options) do
						local val = type(opt) == "table" and (opt.Value or opt.Text) or opt
						if selected[val] then table.insert(arr, val) end
					end
					return arr
				end

				local function setFlag()
					if flag then Wolf.Flags[flag] = multi and getMultiArray() or selected end
				end

				local function build()
					for _, ch in ipairs(list:GetChildren()) do
						if ch:IsA("TextButton") then ch:Destroy() end
					end
					for i, opt in ipairs(options) do
						local txt = type(opt) == "table" and (opt.Text or opt.Value) or tostring(opt)
						local val = type(opt) == "table" and (opt.Value or opt.Text) or opt
						local isOn = multi and selected[val] or (selected == val)
						local ob = Instance.new("TextButton")
						ob.Size = UDim2.new(1, 0, 0, 26)
						ob.BackgroundColor3 = Shade(Theme.ElementBackground)
						ob.BackgroundTransparency = isOn and 0.7 or 1
						ob.Text = "  " .. txt
						ob.Font = Enum.Font.Gotham
						ob.TextSize = 12
						ob.TextColor3 = isOn and Theme.Accent or Theme.Text
						ob.TextXAlignment = Enum.TextXAlignment.Left
						ob.ZIndex = 101
						ob.LayoutOrder = i
						ob.Parent = list

						local tick = Instance.new("Frame")
						tick.Size = UDim2.new(0, 2, 1, 0)
						tick.BackgroundColor3 = Theme.Accent
						tick.BackgroundTransparency = isOn and 0 or 1
						tick.BorderSizePixel = 0
						tick.ZIndex = 102
						tick.Parent = ob

						ob.MouseButton1Click:Connect(function()
							if multi then
								selected[val] = not selected[val]
								selLbl.Text = formatSelected()
								build()
								setFlag()
								callback(getMultiArray())
							else
								selected = val
								selLbl.Text = txt
								list.Visible = false
								setFlag()
								callback(val)
							end
							CheckDependents()
						end)
					end
					list.CanvasSize = UDim2.new(0, 0, 0, (#options * 26) + 4)
				end
				build()
				setFlag()

				RegisterPopup(list, sel)
				sel.MouseButton1Click:Connect(function()
					if list.Visible then
						list.Visible = false
						return
					end
					CloseAllPopups(sel)
					task.wait()
					local abs = sel.AbsolutePosition
					local asz = sel.AbsoluteSize
					local viewport = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1920, 1080)
					local listHeight = math.clamp((#options * 26) + 4, 30, 200)
					local listW = math.max(asz.X, 130)
					local x = math.clamp(abs.X, 8, math.max(8, viewport.X - listW - 8))
					local belowY = abs.Y + asz.Y + 4
					local y = belowY
					if belowY + listHeight > viewport.Y - 10 then
						y = math.max(10, abs.Y - listHeight - 4)
					end
					list.Size = UDim2.fromOffset(listW, listHeight)
					list.Position = UDim2.fromOffset(x, y)
					list.Visible = true
				end)

				table.insert(Registered, { Type = "Element", Instance = row, Stroke = stroke, AccentBar = accentBar, Label = lbl, Icon = elementIcon, SubBg = sel, SubText = selLbl })

				local obj = {}
				function obj:Set(v)
					if multi then
						selected = {}
						if type(v) == "table" then
							for _, x in ipairs(v) do selected[x] = true end
						end
						selLbl.Text = formatSelected()
						build()
					else
						selected = v
						selLbl.Text = tostring(v)
					end
					setFlag()
					CheckDependents()
				end
				function obj:Get() return multi and getMultiArray() or selected end
				function obj:Refresh(opts)
					options = opts or {}
					build()
				end
				return obj
			end

			function Section:CreateColorPicker(cpConfig)
				local c = NormalizeArgs(cpConfig) or {}
				local name = c.Name or c.Title or "Color"
				local default = c.Default or c.Value or Color3.fromRGB(220, 40, 40)
				local callback = c.Callback or function() end

				local row, stroke, accentBar = RegisterRow(40)
				row.Parent = container
				ApplyDependsOn(row, c)

				local lbl = Instance.new("TextLabel")
				lbl.Size = UDim2.new(1, -50, 1, 0)
				lbl.Position = UDim2.new(0, 14, 0, 0)
				lbl.BackgroundTransparency = 1
				lbl.Text = name
				lbl.Font = Enum.Font.GothamMedium
				lbl.TextSize = 13
				lbl.TextColor3 = Theme.Text
				lbl.TextXAlignment = Enum.TextXAlignment.Left
				lbl.ZIndex = 7
				lbl.Parent = row
				local elementIcon = AttachIcon(row, c, lbl)

				local swatch = Instance.new("Frame")
				swatch.Size = UDim2.fromOffset(26, 18)
				swatch.Position = UDim2.new(1, -40, 0.5, -9)
				swatch.BackgroundColor3 = default
				swatch.ZIndex = 7
				swatch.Parent = row
				Round(3, swatch)
				Outline(swatch, Color3.fromRGB(0, 0, 0), 1, 0.3)

				local click = Instance.new("TextButton")
				click.Size = UDim2.fromScale(1, 1)
				click.BackgroundTransparency = 1
				click.Text = ""
				click.ZIndex = 8
				click.Parent = row

				local overlay = Instance.new("Frame")
				overlay.Size = UDim2.fromScale(1, 1)
				overlay.BackgroundColor3 = Color3.new(0, 0, 0)
				overlay.BackgroundTransparency = 0.45
				overlay.Visible = false
				overlay.ZIndex = 60
				overlay.Parent = MainFrame

				local overlayClose = Instance.new("TextButton")
				overlayClose.Size = UDim2.fromScale(1, 1)
				overlayClose.BackgroundTransparency = 1
				overlayClose.Text = ""
				overlayClose.ZIndex = 60
				overlayClose.Parent = overlay
				overlayClose.MouseButton1Click:Connect(function() overlay.Visible = false end)

				local popup = Instance.new("Frame")
				popup.Size = UDim2.fromOffset(240, 200)
				popup.Position = UDim2.fromScale(0.5, 0.5)
				popup.AnchorPoint = Vector2.new(0.5, 0.5)
				popup.BackgroundColor3 = Theme.ElementBackground
				popup.BackgroundTransparency = 0.05
				popup.ZIndex = 61
				popup.Parent = overlay
				Round(5, popup)
				Outline(popup, Theme.Outline, 1, 0.15)

				local hue, sat, val = default:ToHSV()
				local selected = default

				local svBox = Instance.new("Frame")
				svBox.Size = UDim2.new(1, -24, 0, 110)
				svBox.Position = UDim2.new(0, 12, 0, 12)
				svBox.BackgroundColor3 = Color3.fromHSV(hue, 1, 1)
				svBox.ZIndex = 62
				svBox.Parent = popup
				Round(4, svBox)

				local white = Instance.new("Frame")
				white.Size = UDim2.fromScale(1, 1)
				white.BackgroundColor3 = Color3.new(1, 1, 1)
				white.ZIndex = 62
				white.Parent = svBox
				local wg = Instance.new("UIGradient")
				wg.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1)})
				wg.Parent = white

				local black = Instance.new("Frame")
				black.Size = UDim2.fromScale(1, 1)
				black.BackgroundColor3 = Color3.new(0, 0, 0)
				black.ZIndex = 63
				black.Parent = svBox
				local bgrad = Instance.new("UIGradient")
				bgrad.Rotation = 90
				bgrad.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0)})
				bgrad.Parent = black

				local cursor = Instance.new("Frame")
				cursor.Size = UDim2.fromOffset(10, 10)
				cursor.AnchorPoint = Vector2.new(0.5, 0.5)
				cursor.Position = UDim2.new(sat, 0, 1 - val, 0)
				cursor.Rotation = 45
				cursor.BackgroundColor3 = Color3.new(1, 1, 1)
				cursor.ZIndex = 64
				cursor.Parent = svBox
				Outline(cursor, Color3.new(0, 0, 0), 1, 0.2)

				local hueTrack = Instance.new("Frame")
				hueTrack.Size = UDim2.new(1, -24, 0, 12)
				hueTrack.Position = UDim2.new(0, 12, 0, 130)
				hueTrack.ZIndex = 62
				hueTrack.Parent = popup
				local hg = Instance.new("UIGradient")
				hg.Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, Color3.fromHSV(0, 1, 1)),
					ColorSequenceKeypoint.new(0.166, Color3.fromHSV(0.166, 1, 1)),
					ColorSequenceKeypoint.new(0.333, Color3.fromHSV(0.333, 1, 1)),
					ColorSequenceKeypoint.new(0.5, Color3.fromHSV(0.5, 1, 1)),
					ColorSequenceKeypoint.new(0.666, Color3.fromHSV(0.666, 1, 1)),
					ColorSequenceKeypoint.new(0.833, Color3.fromHSV(0.833, 1, 1)),
					ColorSequenceKeypoint.new(1, Color3.fromHSV(1, 1, 1)),
				})
				hg.Parent = hueTrack

				local hueKnob = Instance.new("Frame")
				hueKnob.Size = UDim2.fromOffset(4, 16)
				hueKnob.AnchorPoint = Vector2.new(0.5, 0.5)
				hueKnob.Position = UDim2.new(hue, 0, 0.5, 0)
				hueKnob.BackgroundColor3 = Color3.new(1, 1, 1)
				hueKnob.ZIndex = 63
				hueKnob.Parent = hueTrack

				local prev = Instance.new("Frame")
				prev.Size = UDim2.fromOffset(28, 22)
				prev.Position = UDim2.new(0, 12, 0, 154)
				prev.BackgroundColor3 = selected
				prev.ZIndex = 62
				prev.Parent = popup
				Round(3, prev)
				Outline(prev, Theme.Outline, 1, 0.2)

				local closeCp = Instance.new("TextButton")
				closeCp.Size = UDim2.fromOffset(60, 22)
				closeCp.Position = UDim2.new(1, -72, 0, 154)
				closeCp.BackgroundColor3 = Shade(Theme.ElementBackground)
				closeCp.Text = "Listo"
				closeCp.Font = Enum.Font.GothamBold
				closeCp.TextSize = 12
				closeCp.TextColor3 = Theme.Text
				closeCp.ZIndex = 62
				closeCp.Parent = popup
				Round(4, closeCp)
				Outline(closeCp, Theme.Outline, 1, 0.2)

				local function recompute(fire)
					selected = Color3.fromHSV(hue, sat, val)
					svBox.BackgroundColor3 = Color3.fromHSV(hue, 1, 1)
					cursor.Position = UDim2.new(sat, 0, 1 - val, 0)
					hueKnob.Position = UDim2.new(hue, 0, 0.5, 0)
					swatch.BackgroundColor3 = selected
					prev.BackgroundColor3 = selected
					if fire then callback(selected) end
				end

				local dragSV, dragHue = false, false
				svBox.InputBegan:Connect(function(i)
					if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
						dragSV = true
						local abs = svBox.AbsolutePosition
						local asz = svBox.AbsoluteSize
						sat = math.clamp((i.Position.X - abs.X) / asz.X, 0, 1)
						val = 1 - math.clamp((i.Position.Y - abs.Y) / asz.Y, 0, 1)
						recompute(true)
					end
				end)
				hueTrack.InputBegan:Connect(function(i)
					if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
						dragHue = true
						local abs = hueTrack.AbsolutePosition
						local asz = hueTrack.AbsoluteSize
						hue = math.clamp((i.Position.X - abs.X) / asz.X, 0, 1)
						recompute(true)
					end
				end)
				Track(UserInputService.InputChanged:Connect(function(i)
					if i.UserInputType ~= Enum.UserInputType.MouseMovement and i.UserInputType ~= Enum.UserInputType.Touch then return end
					if dragSV then
						local abs = svBox.AbsolutePosition
						local asz = svBox.AbsoluteSize
						sat = math.clamp((i.Position.X - abs.X) / asz.X, 0, 1)
						val = 1 - math.clamp((i.Position.Y - abs.Y) / asz.Y, 0, 1)
						recompute(true)
					elseif dragHue then
						local abs = hueTrack.AbsolutePosition
						local asz = hueTrack.AbsoluteSize
						hue = math.clamp((i.Position.X - abs.X) / asz.X, 0, 1)
						recompute(true)
					end
				end))
				Track(UserInputService.InputEnded:Connect(function()
					dragSV = false
					dragHue = false
				end))

				click.MouseButton1Click:Connect(function() overlay.Visible = true end)
				closeCp.MouseButton1Click:Connect(function() overlay.Visible = false end)

				table.insert(Registered, { Type = "Element", Instance = row, Stroke = stroke, AccentBar = accentBar, Label = lbl, Icon = elementIcon })

				local obj = {}
				function obj:Set(col)
					hue, sat, val = col:ToHSV()
					recompute(true)
				end
				function obj:Get() return selected end
				return obj
			end

			function Section:CreateInput(iConfig)
				local c = NormalizeArgs(iConfig) or {}
				local name = c.Name or c.Title or "Input"
				local placeholder = c.Placeholder or "Escribir..."
				local default = c.Default or c.Value or ""
				local callback = c.Callback or function() end

				local row, stroke, accentBar = RegisterRow(40)
				row.Parent = container
				ApplyDependsOn(row, c)

				local lbl = Instance.new("TextLabel")
				lbl.Size = UDim2.new(0.4, 0, 1, 0)
				lbl.Position = UDim2.new(0, 14, 0, 0)
				lbl.BackgroundTransparency = 1
				lbl.Text = name
				lbl.Font = Enum.Font.GothamMedium
				lbl.TextSize = 13
				lbl.TextColor3 = Theme.Text
				lbl.TextXAlignment = Enum.TextXAlignment.Left
				lbl.ZIndex = 7
				lbl.Parent = row
				local elementIcon = AttachIcon(row, c, lbl)

				local boxFrame = Instance.new("Frame")
				boxFrame.Size = UDim2.new(0.55, -12, 0, 26)
				boxFrame.Position = UDim2.new(0.42, 0, 0.5, -13)
				boxFrame.BackgroundColor3 = Shade(Theme.ElementBackground)
				boxFrame.ZIndex = 7
				boxFrame.Parent = row
				Round(4, boxFrame)

				local box = Instance.new("TextBox")
				box.Size = UDim2.new(1, -12, 1, 0)
				box.Position = UDim2.new(0, 6, 0, 0)
				box.BackgroundTransparency = 1
				box.Text = default
				box.PlaceholderText = placeholder
				box.PlaceholderColor3 = Theme.Placeholder
				box.TextColor3 = Theme.Text
				box.Font = Enum.Font.Gotham
				box.TextSize = 12
				box.ClearTextOnFocus = false
				box.ZIndex = 8
				box.Parent = boxFrame

				box.FocusLost:Connect(function(enter)
					callback(box.Text, enter)
					CheckDependents()
				end)

				table.insert(Registered, { Type = "Element", Instance = row, Stroke = stroke, AccentBar = accentBar, Label = lbl, Icon = elementIcon, SubBg = boxFrame, SubText = box })

				local obj = {}
				function obj:Set(t) box.Text = t end
				function obj:Get() return box.Text end
				return obj
			end

			function Section:CreateKeybind(kConfig)
				local c = NormalizeArgs(kConfig) or {}
				local name = c.Name or c.Title or "Keybind"
				local default = c.Default or c.Value
				local callback = c.Callback or function() end

				local row, stroke, accentBar = RegisterRow(40)
				row.Parent = container
				ApplyDependsOn(row, c)

				local lbl = Instance.new("TextLabel")
				lbl.Size = UDim2.new(1, -90, 1, 0)
				lbl.Position = UDim2.new(0, 14, 0, 0)
				lbl.BackgroundTransparency = 1
				lbl.Text = name
				lbl.Font = Enum.Font.GothamMedium
				lbl.TextSize = 13
				lbl.TextColor3 = Theme.Text
				lbl.TextXAlignment = Enum.TextXAlignment.Left
				lbl.ZIndex = 7
				lbl.Parent = row
				local elementIcon = AttachIcon(row, c, lbl)

				local keyBtn = Instance.new("TextButton")
				keyBtn.Size = UDim2.fromOffset(70, 24)
				keyBtn.Position = UDim2.new(1, -82, 0.5, -12)
				keyBtn.BackgroundColor3 = Shade(Theme.ElementBackground)
				keyBtn.Text = default and default.Name or "Ninguno"
				keyBtn.Font = Enum.Font.GothamBold
				keyBtn.TextSize = 11
				keyBtn.TextColor3 = Theme.Text
				keyBtn.ZIndex = 7
				keyBtn.Parent = row
				Round(4, keyBtn)

				local current = default
				local listening = false
				local conn

				keyBtn.MouseButton1Click:Connect(function()
					if listening then return end
					listening = true
					keyBtn.Text = "..."
					if conn then conn:Disconnect() end
					conn = Track(UserInputService.InputBegan:Connect(function(input)
						if input.UserInputType == Enum.UserInputType.Keyboard then
							current = input.KeyCode
							keyBtn.Text = current.Name
							listening = false
							if conn then conn:Disconnect() end
							callback(current)
							CheckDependents()
						end
					end))
				end)

				table.insert(Registered, { Type = "Element", Instance = row, Stroke = stroke, AccentBar = accentBar, Label = lbl, Icon = elementIcon, SubBg = keyBtn, SubText = keyBtn })

				local obj = {}
				function obj:Set(k)
					current = k
					keyBtn.Text = k and k.Name or "Ninguno"
				end
				function obj:Get() return current end
				return obj
			end

			function Section:CreateProgressBar(pConfig)
				local c = NormalizeArgs(pConfig) or {}
				local name = c.Name or c.Title or "Progreso"
				local min = c.Min or 0
				local max = c.Max or 100
				local default = c.Default or c.Value or min
				local showPercent = c.ShowPercent
				if showPercent == nil then showPercent = true end

				local row, stroke, accentBar = RegisterRow(48)
				row.Parent = container
				ApplyDependsOn(row, c)

				local lbl = Instance.new("TextLabel")
				lbl.Size = UDim2.new(1, -70, 0, 18)
				lbl.Position = UDim2.new(0, 14, 0, 4)
				lbl.BackgroundTransparency = 1
				lbl.Text = name
				lbl.Font = Enum.Font.GothamMedium
				lbl.TextSize = 12
				lbl.TextColor3 = Theme.Text
				lbl.TextXAlignment = Enum.TextXAlignment.Left
				lbl.ZIndex = 7
				lbl.Parent = row
				local elementIcon = AttachIcon(row, c, lbl)

				local pctLbl = Instance.new("TextLabel")
				pctLbl.Size = UDim2.fromOffset(50, 18)
				pctLbl.Position = UDim2.new(1, -60, 0, 4)
				pctLbl.BackgroundTransparency = 1
				pctLbl.Font = Enum.Font.GothamBold
				pctLbl.TextSize = 12
				pctLbl.TextColor3 = Theme.Accent
				pctLbl.TextXAlignment = Enum.TextXAlignment.Right
				pctLbl.Visible = showPercent
				pctLbl.ZIndex = 7
				pctLbl.Parent = row

				local track = Instance.new("Frame")
				track.Size = UDim2.new(1, -28, 0, 4)
				track.Position = UDim2.new(0, 14, 0, 28)
				track.BackgroundColor3 = Shade(Theme.ElementBackground)
				track.ZIndex = 7
				track.Parent = row

				local fill = Instance.new("Frame")
				fill.Size = UDim2.fromScale(0, 1)
				fill.BackgroundColor3 = Theme.Accent
				fill.ZIndex = 8
				fill.Parent = track

				local value = default
				local function redraw(animate)
					local t = math.clamp((value - min) / math.max(max - min, 1), 0, 1)
					if animate then
						Tween(fill, 0.25, { Size = UDim2.fromScale(t, 1) })
					else
						fill.Size = UDim2.fromScale(t, 1)
					end
					pctLbl.Text = math.floor(t * 100) .. "%"
				end
				redraw(false)

				table.insert(Registered, { Type = "Element", Instance = row, Stroke = stroke, AccentBar = accentBar, Label = lbl, Icon = elementIcon })

				local obj = {}
				function obj:Set(v, animate)
					value = math.clamp(v, min, max)
					redraw(animate ~= false)
				end
				function obj:Get() return value end
				return obj
			end

			function Section:CreateLabel(text, iconConfig)
				if type(text) == "table" then
					iconConfig = text
					text = text.Text or text.Title or text.Desc or ""
				end
				local iconCfg = type(iconConfig) == "table" and iconConfig or {}
				local row = Instance.new("Frame")
				row.Size = UDim2.new(1, 0, 0, 26)
				row.BackgroundTransparency = 1
				row.ZIndex = 6
				row.Parent = container

				local lbl = Instance.new("TextLabel")
				lbl.Size = UDim2.new(1, -12, 1, 0)
				lbl.Position = UDim2.new(0, 2, 0, 0)
				lbl.BackgroundTransparency = 1
				lbl.Text = tostring(text)
				lbl.Font = Enum.Font.GothamMedium
				lbl.TextSize = 12
				lbl.TextColor3 = Theme.Placeholder
				lbl.TextXAlignment = Enum.TextXAlignment.Left
				lbl.ZIndex = 7
				lbl.Parent = row
				local labelIcon = AttachIcon(row, iconCfg, lbl)

				table.insert(Registered, { Type = "Section", Label = lbl, Icon = labelIcon })
			end

			function Section:CreateParagraph(text, iconConfig)
				if type(text) == "table" then
					iconConfig = text
					text = text.Text or text.Title or text.Desc or ""
				end
				local iconCfg = type(iconConfig) == "table" and iconConfig or {}
				local row = Instance.new("Frame")
				row.Size = UDim2.new(1, 0, 0, 0)
				row.AutomaticSize = Enum.AutomaticSize.Y
				row.BackgroundColor3 = Theme.ElementBackground
				row.BackgroundTransparency = hasBackground and 0.65 or 0.35
				row.ZIndex = 6
				row.Parent = container
				Round(4, row)

				local pad = Instance.new("UIPadding")
				pad.PaddingTop = UDim.new(0, 8)
				pad.PaddingBottom = UDim.new(0, 8)
				pad.PaddingLeft = UDim.new(0, 12)
				pad.PaddingRight = UDim.new(0, 10)
				pad.Parent = row

				local lbl = Instance.new("TextLabel")
				lbl.Size = UDim2.new(1, 0, 0, 0)
				lbl.AutomaticSize = Enum.AutomaticSize.Y
				lbl.BackgroundTransparency = 1
				lbl.Text = tostring(text)
				lbl.Font = Enum.Font.Gotham
				lbl.TextSize = 12
				lbl.TextColor3 = Theme.Text
				lbl.TextWrapped = true
				lbl.TextXAlignment = Enum.TextXAlignment.Left
				lbl.ZIndex = 7
				lbl.Parent = row
				local labelIcon = AttachIcon(row, iconCfg, lbl)

				table.insert(Registered, { Type = "Section", Label = lbl, Icon = labelIcon })
			end

			function Section:CreateDivider()
				local row = Instance.new("Frame")
				row.Size = UDim2.new(1, 0, 0, 10)
				row.BackgroundTransparency = 1
				row.ZIndex = 6
				row.Parent = container
				local line = Instance.new("Frame")
				line.Size = UDim2.new(1, 0, 0, 1)
				line.Position = UDim2.new(0, 0, 0.5, 0)
				line.BackgroundColor3 = Theme.Outline
				line.BackgroundTransparency = 0.5
				line.BorderSizePixel = 0
				line.ZIndex = 7
				line.Parent = row
				table.insert(Registered, { Type = "Element", Instance = row, Extras = {{Kind = "Outline", Object = line}} })
				return row
			end

			return Section
		end

		function Tab:CreateDivider()
			return Tab:CreateSection(""):CreateDivider()
		end

		function Tab:CreateToggle(...) return Tab:CreateSection(""):CreateToggle(...) end
		function Tab:CreateSlider(...) return Tab:CreateSection(""):CreateSlider(...) end
		function Tab:CreateButton(...) return Tab:CreateSection(""):CreateButton(...) end
		function Tab:CreateBanner(...) return Tab:CreateSection(""):CreateBanner(...) end
		function Tab:CreateHero(...) return Tab:CreateSection(""):CreateHero(...) end
		function Tab:CreateCardGrid(...) return Tab:CreateSection(""):CreateCardGrid(...) end
		function Tab:CreateDropdown(...) return Tab:CreateSection(""):CreateDropdown(...) end
		function Tab:CreateColorPicker(...) return Tab:CreateSection(""):CreateColorPicker(...) end
		function Tab:CreateInput(...) return Tab:CreateSection(""):CreateInput(...) end
		function Tab:CreateKeybind(...) return Tab:CreateSection(""):CreateKeybind(...) end
		function Tab:CreateProgressBar(...) return Tab:CreateSection(""):CreateProgressBar(...) end
		function Tab:CreateLabel(...) return Tab:CreateSection(""):CreateLabel(...) end
		function Tab:CreateParagraph(...) return Tab:CreateSection(""):CreateParagraph(...) end

		return Tab
	end

	UpdateTheme(themeName, false)
	OpenWindow()

	table.insert(Wolf.Windows, Window)
	return Window
end

Wolf.New = Wolf.CreateWindow
Wolf.Window = Wolf.CreateWindow

function Wolf:Toggle(name) 
	local f = Wolf.Flags[name]
	if f ~= nil then Wolf.Flags[name] = not f end
	return Wolf.Flags[name]
end

function Wolf:Get(name) return Wolf.Flags[name] end
function Wolf:Set(name, val) Wolf.Flags[name] = val end

function Wolf:Success(title, content, dur) return Wolf:Notify({Title = title or "Success", Content = content or "", Type = "Success", Duration = dur or 3}) end
function Wolf:Error(title, content, dur) return Wolf:Notify({Title = title or "Error", Content = content or "", Type = "Error", Duration = dur or 3.5}) end
function Wolf:Warn(title, content, dur) return Wolf:Notify({Title = title or "Warning", Content = content or "", Type = "Warning", Duration = dur or 3}) end
function Wolf:Info(title, content, dur) return Wolf:Notify({Title = title or "Info", Content = content or "", Type = "Info", Duration = dur or 3}) end

return Wolf
