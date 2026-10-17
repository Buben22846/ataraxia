# Загрузка картинок в Roblox (необязательно, но надёжнее)

Сейчас игра рисует спрайты сама (EditableImage). Если у игроков в опубликованной игре картинок нет (видны эмодзи) — загрузите эти файлы:

1. Creator Hub -> Creations -> Assets (или Studio: View -> Asset Manager -> Bulk Import) -> загрузить как **Image**.
2. Файлы: `<вид>.png` (рыба смотрит вправо), `<вид>_flip.png` (смотрит влево), `bg_<аквариум>.png` (фоны). 44 файла.
3. Дождитесь модерации, скопируйте id каждой картинки и впишите в `src/ReplicatedStorage/Shared/SpriteAssets.luau`:
   `guppy = "rbxassetid://123"`, `["guppy:flip"] = "rbxassetid://124"`, `bg_lagoon = "rbxassetid://125"`.
