-- UIKit: пиксельные панели и кнопки поверх обычных Frame / TextButton.
-- Картинки (art/src/ui_kit.py -> SpriteData) растягиваются как 9-slice: углы остаются целыми пикселями, середина тянется.
-- Если картинок нет (Sprites.apply вернул false), элемент остаётся прежним плоским — интерфейс не ломается.
-- Кнопка продолжает работать как раньше: Text, TextColor3, BackgroundColor3 и Activated читаются и меняются тем же кодом.
-- Вид кнопки выбирается по её BackgroundColor3 (бирюзовый, золотой, тёмный, серый) и меняется вместе с ним.

local Sprites = require(script.Parent:WaitForChild("Sprites"))

local UIKit = {}

-- размер картинки и ширина угла (SliceCenter), в пикселях исходника
local SLICE = {
	ui_panel = { size = 24, corner = 6 },
	ui_row = { size = 12, corner = 4 },
}
for _, name in ipairs({ "ui_btn", "ui_btn_down", "ui_btn_gold", "ui_btn_gold_down", "ui_btn_dark", "ui_btn_dark_down", "ui_btn_off" }) do
	SLICE[name] = { size = 16, corner = 5 }
end

-- По цвету фона кнопки: какая картинка (обычная, нажатая)
local LOOKS = {
	{ color = Color3.fromRGB(38, 166, 154), up = "ui_btn", down = "ui_btn_down" }, -- бирюзовая
	{ color = Color3.fromRGB(255, 202, 40), up = "ui_btn_gold", down = "ui_btn_gold_down" }, -- золотая
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
	label.SliceCenter = Rect.new(slice.corner, slice.corner, slice.size - slice.corner, slice.size - slice.corner)
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
	label.ZIndex = zIndex
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
		local label = makeImage(frame, id or "ui_panel", 1)
		if label == nil then
			return false
		end
		frame.BackgroundTransparency = 1
		return true
	end)
	return ok and result == true
end

-- Кнопка или подпись: картинка-фон + копия текста поверх (дети всегда рисуются над текстом самого элемента).
-- fixedLook — не выбирать вид по цвету фона (для подписей).
local function skinText(button, fixedLook)
	if button:FindFirstChild("Skin") then
		return true
	end
	local ok, result = pcall(function()
		local look = fixedLook or lookFor(button.BackgroundColor3)
		local image = makeImage(button, look.up, 1)
		if image == nil then
			return false
		end
		-- копия текста
		local text = Instance.new("TextLabel")
		text.Name = "SkinText"
		text.BackgroundTransparency = 1
		text.Size = UDim2.fromScale(1, 1)
		text.ZIndex = 2
		text.Active = false
		text.Font = button.Font
		text.TextScaled = button.TextScaled
		text.TextSize = button.TextSize
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
			look = lookFor(button.BackgroundColor3)
			local id = if pressed then look.down else look.up
			if Sprites.apply(image, id, false) then
				applySlice(image, id)
			end
			text.Position = if pressed and look.down ~= look.up then UDim2.fromOffset(0, pixelScale()) else UDim2.new()
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

-- Подпись (монеты, число рыб): тёмная плитка без нажатия
function UIKit.label(label)
	local look = { up = "ui_btn_dark", down = "ui_btn_dark" }
	return skinText(label, look)
end

return UIKit
