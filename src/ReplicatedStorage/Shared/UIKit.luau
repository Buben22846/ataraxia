-- UIKit: пиксельные панели и кнопки поверх обычных Frame / TextButton.
-- Картинки (art/src/ui_kit.py -> SpriteData) растягиваются как 9-slice: углы остаются целыми пикселями, середина тянется.
-- Если картинок нет (Sprites.apply вернул false), элемент остаётся прежним плоским — интерфейс не ломается.
-- Кнопка продолжает работать как раньше: Text, TextColor3, BackgroundColor3 и Activated читаются и меняются тем же кодом.
-- Вид кнопки выбирается по её BackgroundColor3 (бирюзовый, золотой, тёмный, серый) и меняется вместе с ним.

local Sprites = require(script.Parent:WaitForChild("Sprites"))
local SpriteData = require(script.Parent:WaitForChild("SpriteData"))

local UIKit = {}

-- Единый шрифт интерфейса: Ubuntu Bold (есть в Roblox, поддерживает кириллицу, круглые «дружелюбные» буквы). Если шрифт не загрузится, остаётся прежний.
UIKit.PIXEL_FONT = Font.new("rbxasset://fonts/families/Ubuntu.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal)

function UIKit.font(inst)
	if inst:IsA("TextLabel") or inst:IsA("TextButton") or inst:IsA("TextBox") then
		pcall(function()
			inst.FontFace = UIKit.PIXEL_FONT
		end)
	end
end

-- размер картинки и ширина угла (SliceCenter), в пикселях исходника
local SLICE = {
	ui_panel = { size = 24, corner = 6 },
	ui_row = { size = 12, corner = 4 },
	-- билет не квадратный: ширина w, высота h, угол по горизонтали cx и по вертикали cy
	ui_banner = { size = 24, corner = 8 },
	ui_banner_night = { size = 24, corner = 8 },
	ui_banner_hall = { size = 24, corner = 8 },
	ui_banner_quick = { size = 24, corner = 8 },
	ui_ticket = { w = 32, h = 16, cx = 10, cy = 5 },
	ui_ticket_down = { w = 32, h = 16, cx = 10, cy = 5 },
}
SLICE.ui_btn_gold_big = { size = 24, corner = 8 }
SLICE.ui_btn_gold_big_down = { size = 24, corner = 8 }
for _, name in ipairs({ "ui_btn_coral", "ui_btn_coral_down", "ui_btn_blue", "ui_btn_blue_down", "ui_btn_pink", "ui_btn_pink_down" }) do
	SLICE[name] = { size = 16, corner = 5 }
end
for _, name in ipairs({ "ui_btn", "ui_btn_down", "ui_btn_gold", "ui_btn_gold_down", "ui_btn_dark", "ui_btn_dark_down", "ui_btn_off" }) do
	SLICE[name] = { size = 16, corner = 5 }
end

-- По цвету фона кнопки: какая картинка (обычная, нажатая)
local LOOKS = {
	{ color = Color3.fromRGB(38, 166, 154), up = "ui_btn", down = "ui_btn_down", pattern = "pat_bubbles" }, -- бирюзовая: пузырьки
	{ color = Color3.fromRGB(255, 202, 40), up = "ui_btn_gold", down = "ui_btn_gold_down", pattern = "pat_sparkle" }, -- золотая: искры
	{ color = Color3.fromRGB(198, 63, 38), up = "ui_btn_coral", down = "ui_btn_coral_down", pattern = "pat_stripes" }, -- коралловая: полоски
	{ color = Color3.fromRGB(31, 100, 189), up = "ui_btn_blue", down = "ui_btn_blue_down", pattern = "pat_lines" }, -- синяя: линейка
	{ color = Color3.fromRGB(184, 50, 107), up = "ui_btn_pink", down = "ui_btn_pink_down", pattern = "pat_dots" }, -- розовая: «чешуя»
	{ color = Color3.fromRGB(10, 70, 95), up = "ui_btn_dark", down = "ui_btn_dark_down" }, -- тёмная (панели, значки)
	{ color = Color3.fromRGB(120, 144, 156), up = "ui_btn_off", down = "ui_btn_off" }, -- серая (недоступно)
	{ color = Color3.fromRGB(8, 52, 72), up = "ui_row", down = "ui_row" }, -- строка списка
	{ color = Color3.fromRGB(231, 111, 81), up = "ui_btn_gold", down = "ui_btn_gold_down" }, -- предупреждение
}

local function lookFor(color)
	local best, bestDistance = LOOKS[1], math.huge
	for _, look in ipairs(LOOKS) do
		local dr, dg, db = color.R - look.color.R, color.G - look.color.G, color.B - look.color.B
		local distance = dr * dr + dg * dg + db * db
		if distance < bestDistance then
			best, bestDistance = look, distance
		end
	end
	return best
end

-- Целый масштаб пикселя: короткая сторона экрана / 180, от 1 до 4
local function pixelScale()
	local camera = workspace.CurrentCamera
	if camera == nil then
		return 2
	end
	local size = camera.ViewportSize
	return math.clamp(math.floor(math.min(size.X, size.Y) / 180), 1, 4)
end
UIKit.pixelScale = pixelScale

local sliced = setmetatable({}, { __mode = "k" }) -- ImageLabel -> true (для пересчёта при смене размера экрана)

local function applySlice(label, id)
	local slice = SLICE[id]
	label.ScaleType = Enum.ScaleType.Slice
	local w, h = slice.w or slice.size, slice.h or slice.size
	local cx, cy = slice.cx or slice.corner, slice.cy or slice.corner
	label.SliceCenter = Rect.new(cx, cy, w - cx, h - cy)
	label.SliceScale = pixelScale()
	sliced[label] = true
end

pcall(function()
	local camera = workspace.CurrentCamera
	if camera then
		camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
			local scale = pixelScale()
			for label in pairs(sliced) do
				label.SliceScale = scale
			end
		end)
	end
end)

-- Создаёт ImageLabel-фон внутри parent. Возвращает nil, если картинки нет.
local function makeImage(parent, id, zIndex)
	if SLICE[id] == nil then
		return nil
	end
	local label = Instance.new("ImageLabel")
	label.Name = "Skin"
	label.BackgroundTransparency = 1
	label.BorderSizePixel = 0
	label.Size = UDim2.fromScale(1, 1)
	-- zIndex здесь — сдвиг относительно слоя самого элемента: скин рисуется ровно на его уровне
	-- (иначе рамка окажется под затемнением и другими окнами) и следует за ним, если слой изменят
	label.ZIndex = parent.ZIndex + zIndex
	parent:GetPropertyChangedSignal("ZIndex"):Connect(function()
		label.ZIndex = parent.ZIndex + zIndex
	end)
	label.Active = false
	if not Sprites.apply(label, id, false) then
		label:Destroy()
		return nil
	end
	applySlice(label, id)
	label.Parent = parent
	return label
end

-- Панель или строка: Frame с пиксельной рамкой. Дети с ZIndex выше 1 рисуются поверх картинки.
function UIKit.frame(frame, id)
	local ok, result = pcall(function()
		local label = makeImage(frame, id or "ui_panel", 0)
		if label == nil then
			return false
		end
		frame.BackgroundTransparency = 1
		return true
	end)
	return ok and result == true
end

-- Узор поверх кнопки: маленькая плитка, которую повторяют по всей кнопке (внутри рамки)
local patterned = setmetatable({}, { __mode = "k" }) -- ImageLabel -> { w, h }

local function placePattern(label, w, h)
	local scale = pixelScale()
	local inset = 3 * scale
	label.Position = UDim2.fromOffset(inset, inset)
	label.Size = UDim2.new(1, -2 * inset, 1, -2 * inset)
	label.TileSize = UDim2.fromOffset(w * scale, h * scale)
end

local function setPattern(button, id, current)
	local data = SpriteData[id]
	if data == nil then
		if current then
			current.Visible = false
		end
		return current
	end
	local label = current
	if label == nil then
		label = Instance.new("ImageLabel")
		label.Name = "Pattern"
		label.BackgroundTransparency = 1
		label.BorderSizePixel = 0
		label.Active = false
		label.ScaleType = Enum.ScaleType.Tile
		label.ZIndex = button.ZIndex
		button:GetPropertyChangedSignal("ZIndex"):Connect(function()
			label.ZIndex = button.ZIndex
		end)
		label.Parent = button
	end
	if Sprites.apply(label, id, false) then
		label.ScaleType = Enum.ScaleType.Tile
		placePattern(label, data.w, data.h)
		patterned[label] = { data.w, data.h }
		label.Visible = true
	else
		label.Visible = false
	end
	return label
end

pcall(function()
	local camera = workspace.CurrentCamera
	if camera then
		camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
			for label, size in pairs(patterned) do
				placePattern(label, size[1], size[2])
			end
		end)
	end
end)

-- Кнопка или подпись: картинка-фон + копия текста поверх (дети всегда рисуются над текстом самого элемента).
-- fixedLook — не выбирать вид по цвету фона (для подписей).
local layouts = setmetatable({}, { __mode = "k" }) -- button -> { position } (где стоит копия текста; меняется иконкой)

local function skinText(button, fixedLook)
	if button:FindFirstChild("Skin") then
		return true
	end
	local ok, result = pcall(function()
		local look = fixedLook or lookFor(button.BackgroundColor3)
		local image = makeImage(button, look.up, 0)
		if image == nil then
			return false
		end
		local patternLabel = if look.pattern then setPattern(button, look.pattern, nil) else nil
		-- копия текста; textScale — доля ширины под текст (у билета края заняты корешками)
		local textScale = look.textScale
		local basePosition = if textScale then UDim2.fromScale(0.5, 0.5) else UDim2.new()
		local layout = { position = basePosition }
		layouts[button] = layout
		local text = Instance.new("TextLabel")
		text.Name = "SkinText"
		text.BackgroundTransparency = 1
		text.Size = UDim2.fromScale(textScale or 1, 1)
		text.AnchorPoint = if textScale then Vector2.new(0.5, 0.5) else Vector2.zero
		text.Position = basePosition
		text.ZIndex = button.ZIndex + 1
		button:GetPropertyChangedSignal("ZIndex"):Connect(function()
			text.ZIndex = button.ZIndex + 1
		end)
		text.Active = false
		text.Font = button.Font
		pcall(function()
			text.FontFace = button.FontFace
		end)
		text.TextSize = button.TextSize
		text.TextScaled = button.TextScaled -- после TextSize: запись TextSize сбрасывает автомасштаб
		text.TextWrapped = button.TextWrapped
		text.TextXAlignment = button.TextXAlignment
		text.RichText = button.RichText
		text.Text = button.Text
		text.TextColor3 = button.TextColor3
		local constraint = button:FindFirstChildOfClass("UITextSizeConstraint")
		if constraint then
			constraint:Clone().Parent = text
		end
		text.Parent = button
		button.TextTransparency = 1
		button.BackgroundTransparency = 1

		local pressed = false
		local function refresh()
			look = fixedLook or lookFor(button.BackgroundColor3)
			local id = if pressed then look.down else look.up
			if Sprites.apply(image, id, false) then
				applySlice(image, id)
			end
			if look.pattern or patternLabel then
				patternLabel = setPattern(button, look.pattern, patternLabel)
			end
			local shift = if pressed and look.down ~= look.up then pixelScale() else 0
			text.Position = layout.position + UDim2.fromOffset(0, shift)
		end
		button:GetPropertyChangedSignal("Text"):Connect(function()
			text.Text = button.Text
		end)
		button:GetPropertyChangedSignal("TextColor3"):Connect(function()
			text.TextColor3 = button.TextColor3
		end)
		if fixedLook == nil then
			button:GetPropertyChangedSignal("BackgroundColor3"):Connect(function()
				refresh() -- вид выбираем по новому цвету; сам цветной фон остаётся прозрачным
			end)
		end
		if button:IsA("GuiButton") then
			button.MouseButton1Down:Connect(function()
				pressed = true
				refresh()
			end)
			local function release()
				if pressed then
					pressed = false
					refresh()
				end
			end
			button.MouseButton1Up:Connect(release)
			button.MouseLeave:Connect(release)
			button.InputEnded:Connect(release)
		end
		return true
	end)
	return ok and result == true
end

function UIKit.button(button)
	return skinText(button, nil)
end

-- Иконка в кнопке: сверху, подпись под ней (как нижняя панель) или слева от подписи.
local function addIcon(button, id, mode)
	local layout, text = layouts[button], button:FindFirstChild("SkinText")
	if layout == nil or text == nil then
		return false
	end
	local icon = Instance.new("ImageLabel")
	icon.Name = "Icon_" .. id
	icon.BackgroundTransparency = 1
	icon.Active = false
	icon.SizeConstraint = Enum.SizeConstraint.RelativeYY
	icon.ZIndex = button.ZIndex + 3
	if mode == "top" then
		icon.AnchorPoint = Vector2.new(0.5, 0)
		icon.Position = UDim2.fromScale(0.5, 0.06)
		icon.Size = UDim2.fromScale(0.52, 0.52)
		layout.position = UDim2.fromScale(0, 0.58)
		text.Size = UDim2.fromScale(1, 0.38)
	else
		icon.AnchorPoint = Vector2.new(0, 0.5)
		icon.Position = UDim2.fromScale(0.05, 0.5)
		icon.Size = UDim2.fromScale(0.62, 0.62)
		layout.position = UDim2.fromScale(0.3, 0)
		text.Size = UDim2.fromScale(0.66, 1)
	end
	text.Position = layout.position
	if not Sprites.apply(icon, id, false) then
		icon:Destroy()
		layout.position = UDim2.new()
		text.Position = UDim2.new()
		text.Size = UDim2.fromScale(1, 1)
		return false
	end
	icon.Parent = button
	button:GetPropertyChangedSignal("ZIndex"):Connect(function()
		icon.ZIndex = button.ZIndex + 3
	end)
	return true
end

function UIKit.iconTop(button, id)
	return addIcon(button, id, "top")
end

function UIKit.iconLeft(button, id)
	return addIcon(button, id, "left")
end

-- Главная кнопка: крупная золотая «жемчужина» с искрами
function UIKit.hero(button)
	return skinText(button, { up = "ui_btn_gold_big", down = "ui_btn_gold_big_down", pattern = "pat_sparkle" })
end

-- Блик, пробегающий по кнопке раз в несколько секунд. Возвращает функцию остановки.
function UIKit.shine(button, every)
	every = every or 3.2
	local TweenService = game:GetService("TweenService")
	local clip = Instance.new("Frame")
	clip.Name = "ShineClip"
	clip.BackgroundTransparency = 1
	clip.BorderSizePixel = 0
	clip.ClipsDescendants = true
	clip.Active = false
	clip.Size = UDim2.fromScale(1, 1)
	clip.ZIndex = button.ZIndex + 2
	button:GetPropertyChangedSignal("ZIndex"):Connect(function()
		clip.ZIndex = button.ZIndex + 2
	end)
	local band = Instance.new("ImageLabel")
	band.BackgroundTransparency = 1
	band.BorderSizePixel = 0
	band.Active = false
	band.ImageTransparency = 0.62
	band.ScaleType = Enum.ScaleType.Stretch
	band.AnchorPoint = Vector2.new(0, 0)
	band.Size = UDim2.fromScale(0.22, 1)
	band.Position = UDim2.fromScale(-0.3, 0)
	band.ZIndex = clip.ZIndex
	if not Sprites.apply(band, "fx_shine", false) then
		clip:Destroy()
		return function() end
	end
	band.Parent = clip
	clip.Parent = button
	local running = true
	task.spawn(function()
		while running and clip.Parent do
			band.Position = UDim2.fromScale(-0.3, 0)
			local tween = TweenService:Create(band, TweenInfo.new(0.9, Enum.EasingStyle.Sine), { Position = UDim2.fromScale(1.1, 0) })
			tween:Play()
			task.wait(every)
		end
	end)
	return function()
		running = false
		clip:Destroy()
	end
end

-- Подпись (монеты, число рыб): тёмная плитка без нажатия
-- textScale (необязательно) — доля ширины под текст, если слева или справа нужно место под иконку
function UIKit.label(label, textScale)
	local look = { up = "ui_btn_dark", down = "ui_btn_dark", textScale = textScale }
	return skinText(label, look)
end

-- Иконка внутри элемента слева (монета и т.п.). Рисуется поверх скина и текста. Возвращает ImageLabel или nil, если картинки нет.
function UIKit.icon(parent, id, offsetX)
	local icon = Instance.new("ImageLabel")
	icon.Name = "Icon_" .. id
	icon.BackgroundTransparency = 1
	icon.AnchorPoint = Vector2.new(0, 0.5)
	icon.Position = UDim2.fromScale(offsetX or 0.04, 0.5)
	icon.SizeConstraint = Enum.SizeConstraint.RelativeYY -- и ширина, и высота считаются от высоты: иконка квадратная
	icon.Size = UDim2.fromScale(0.62, 0.62)
	icon.ZIndex = parent.ZIndex + 3
	icon.Active = false
	if not Sprites.apply(icon, id, false) then
		icon:Destroy()
		return nil
	end
	icon.Parent = parent
	parent:GetPropertyChangedSignal("ZIndex"):Connect(function()
		icon.ZIndex = parent.ZIndex + 3
	end)
	return icon
end

-- Цирковой билет: красная кнопка-приманка. Нажимается как обычная кнопка (Activated), текст читается из button.Text.
function UIKit.ticket(button)
	return skinText(button, { up = "ui_ticket", down = "ui_ticket_down", textScale = 0.62 })
end

-- Пульсация: кнопка плавно «дышит» (размер ±4%) и мигает тёплым оттенком. Работает и без картинок (тогда только размер).
-- Возвращает функцию остановки.
function UIKit.pulse(button, period)
	period = period or 0.8
	local TweenService = game:GetService("TweenService")
	local base = button.Size
	local info = TweenInfo.new(period, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
	local grow = TweenService:Create(button, info, {
		Size = UDim2.new(base.X.Scale * 1.04, base.X.Offset, base.Y.Scale * 1.07, base.Y.Offset),
	})
	grow:Play()
	local tweens = { grow }
	local skin = button:FindFirstChild("Skin")
	if skin and skin:IsA("ImageLabel") then
		local blink = TweenService:Create(skin, info, { ImageColor3 = Color3.fromRGB(255, 196, 120) })
		blink:Play()
		table.insert(tweens, blink)
	end
	return function()
		for _, tween in ipairs(tweens) do
			tween:Cancel()
		end
		button.Size = base
		if skin then
			skin.ImageColor3 = Color3.new(1, 1, 1)
		end
	end
end

return UIKit
