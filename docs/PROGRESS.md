# Прогресс разработки: «Путь в Чистилище»

## Спринт 0: Каркас проекта [ВЫПОЛНЕН]
- [x] Установка и проверка Godot 4 (версия 4.7.2 stable)
- [x] Создание структуры папок согласно архитектуре
- [x] Базовая документация: AGENTS.md, README.md, docs/GDD.md, docs/PROGRESS.md, docs/BACKLOG.md
- [x] Конфигурация project.godot (разрешение 1280x720, nearest filter, слои коллизий, input map, autoload)
- [x] Autoload-синглтоны: EventBus, GameState, MetaProgress, SaveManager, AudioManager, SceneRouter
- [x] Базовые сцены: Main.tscn, MainMenu.tscn, Hub.tscn с плавным fade-переходом
- [x] Подключение GUT и первый smoke-тест (6 тестов, 17 проверок)
- [x] Пресеты экспорта Windows и Linux (export_presets.cfg)

## Спринт 1: Игрок и базовый бой [ВЫПОЛНЕН]
- [x] Компоненты:
  - `HealthComponent` (урон, лечение, неуязвимость, смерть)
  - `HurtboxComponent` (приём урона, фильтрация слоев, связь с Health и Movement)
  - `HitboxComponent` (нанесение урона, отталкивание, учёт уже поражённых целей)
  - `MovementComponent` (ускорение, трение, knockback)
- [x] Сцена `Player` (`CharacterBody2D`, движение, прицеливание мышь/стик, атака ближнего боя с дугой, dash с i-frames и перезарядкой, мигание неуязвимости)
- [x] `systems/combat/DamageCalculator.gd` (формула `max(1, round(B * (1 + M) * C - A))`, проверка крита)
- [x] Камера `PlayerCamera` (плавное следование, screen shake по сигналу `EventBus.screen_shake_requested`)
- [x] Тестовый манекен `Dummy` (HP над головой, реакция на урон, вспышка, отталкивание, автореспавн)
- [x] Ловушка `TrapSpikes` (для проверки получения урона игроком и гибели)
- [x] `HUD` (полоска HP игрока, индикатор перезарядки рывка, всплывающие цифры урона, экран «ВЫ ПОГИБЛИ» с кнопкой возврата в Хаб)
- [x] Hit-stop эффект (~50 мс) при ударе через `EventBus.hit_stop_requested` в `SceneRouter`
- [x] GUT-тесты: 19 тестов, 50 проверок (DamageCalculator, HealthComponent, Player, Dummy, Scene Smoke)

## Спринт 2: Герои и хаб [СЛЕДУЮЩИЙ]
- [ ] Ресурсы `HeroData` и `AbilityData`
- [ ] 3 героя: Воин (щит, рывок-удар), Маг (огненный шар, телепорт), Следопыт (ловушка, залп)
- [ ] Хаб со статуями героев для выбора и порталом «Начать путь»
- [ ] Спавн игрока на основе выбранного `HeroData`
