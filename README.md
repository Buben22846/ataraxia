# Атараксия (Ataraxia)

Спокойная Roblox-игра про аквариум с гача-паками. Мобильный экранный интерфейс.
Place ID: 76014161027398.

## Что здесь хранится

Весь код игры и разметка интерфейса в формате [Rojo](https://rojo.space):

| Файл | Где в Studio | Что делает |
|---|---|---|
| `src/ReplicatedStorage/Shared/FishConfig.luau` | ReplicatedStorage.Shared | Каталог рыб, паки, цены мест — весь баланс |
| `src/ServerScriptService/GameServer.server.luau` | ServerScriptService | Правила игры на сервере, админ-команды |
| `src/ServerScriptService/PlayerData.luau` | ServerScriptService | Сохранение (DataStore, блокировка сессии, миграции) |
| `src/ServerScriptService/PackRoller.luau` | ServerScriptService | Выпадение рыбы из пака |
| `src/ServerStorage/Tests/RunAll.luau` | ServerStorage.Tests | Автотесты |
| `src/StarterGui/AquariumGui/AquariumClient.client.luau` | StarterGui.AquariumGui | Весь интерфейс игрока |
| `default.project.json` | — | Схема: какой файл куда кладётся, RemoteEvent'ы, базовая разметка GUI |

## Как сейчас идёт работа

Источник правды — Studio: правки делаются прямо в плейсе (Claude через MCP).
После каждого этапа код выгружается сюда отдельным коммитом. Полная копия плейса
(включая всё, что не в коде) — в истории версий Roblox: Creator Hub → игра → Places → Version History.

## Как восстановить

- Проще всего: попросить Claude вернуть скрипты из этого репозитория в Studio.
- Через Rojo: `rojo build -o Ataraxia.rbxl` соберёт плейс из этих файлов.

## Тесты

В Studio запустите Play, затем в командной строке сервера:

```lua
print(require(game.ServerStorage.Tests.RunAll)())
```

## Хранилища данных

- `PlayerData_v1` — живая игра.
- `PlayerData_Studio_v1` — только Studio, тесты не трогают сохранения игроков.
