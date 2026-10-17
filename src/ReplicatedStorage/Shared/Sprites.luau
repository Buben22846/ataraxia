-- Sprites: превращает пиксель-арт из SpriteData в картинки для интерфейса.
-- Картинки создаются на лету (EditableImage), поэтому их не нужно загружать в Roblox и ждать модерацию.
-- Если что-то пошло не так (нет данных, EditableImage недоступен) — функции возвращают nil/false,
-- и интерфейс показывает запасной вариант (эмодзи, цвет воды).

local AssetService = game:GetService("AssetService")

local SpriteData = require(script.Parent:WaitForChild("SpriteData"))

local SYMBOLS = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"

local Sprites = {}

local cache = {} -- "id" или "id:flip" -> Content или false (не получилось)

local function hexToRgb(hex)
	return tonumber(hex:sub(2, 3), 16), tonumber(hex:sub(4, 5), 16), tonumber(hex:sub(6, 7), 16)
end

local function build(id, flip)
	local data = SpriteData[id]
	if data == nil then
		return nil
	end

	local palette = {}
	for index, hex in ipairs(data.pal) do
		local r, g, b = hexToRgb(hex)
		palette[SYMBOLS:sub(index, index)] = { r, g, b }
	end

	local w, h = data.w, data.h
	local buf = buffer.create(w * h * 4) -- RGBA, по 4 байта на пиксель; по умолчанию всё прозрачное
	for y, row in ipairs(data.rows) do
		local x = 0
		for symbol, digits in row:gmatch("(%D)(%d*)") do
			local count = if digits == "" then 1 else tonumber(digits)
			local color = palette[symbol] -- для '.' нет цвета: пиксель остаётся прозрачным
			for _ = 1, count do
				if color then
					local px = if flip then w - 1 - x else x
					local offset = ((y - 1) * w + px) * 4
					buffer.writeu8(buf, offset, color[1])
					buffer.writeu8(buf, offset + 1, color[2])
					buffer.writeu8(buf, offset + 2, color[3])
					buffer.writeu8(buf, offset + 3, 255)
				end
				x += 1
			end
		end
	end

	local image = AssetService:CreateEditableImage({ Size = Vector2.new(w, h) })
	image:WritePixelsBuffer(Vector2.zero, Vector2.new(w, h), buf)
	return Content.fromObject(image)
end

-- Content картинки (flip = true — зеркально, для рыбы, плывущей влево). nil, если не получилось.
function Sprites.content(id, flip)
	local key = if flip then id .. ":flip" else id
	local cached = cache[key]
	if cached ~= nil then
		return cached or nil
	end
	local ok, result = pcall(build, id, flip)
	if not ok then
		warn("[Sprites] не удалось создать " .. key .. ": " .. tostring(result))
		result = nil
	end
	cache[key] = result or false
	return result
end

-- Ставит картинку в ImageLabel. Возвращает true, если получилось.
function Sprites.apply(imageLabel, id, flip)
	local content = Sprites.content(id, flip)
	if content == nil then
		return false
	end
	imageLabel.ImageContent = content
	imageLabel.ResampleMode = Enum.ResamplerMode.Pixelated -- чёткие пиксели при увеличении
	return true
end

return Sprites
