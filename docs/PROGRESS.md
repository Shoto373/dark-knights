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
- [x] Компоненты HealthComponent, HurtboxComponent, HitboxComponent, MovementComponent
- [x] Сцена Player (CharacterBody2D, движение, прицеливание мышь/стик, атака ближнего боя с дугой, dash с i-frames и перезарядкой, мигание неуязвимости)
- [x] systems/combat/DamageCalculator.gd (формула урона, криты)
- [x] Камера PlayerCamera (слежение, screen shake)
- [x] Dummy и TrapSpikes для проверки урона и гибели
- [x] HUD (HP игрока, индикатор рывка, экран «ВЫ ПОГИБЛИ»)
- [x] Hit-stop эффект (~50 мс)
- [x] GUT-тесты: 19 тестов, 50 проверок

## Спринт 2: Герои и хаб [ВЫПОЛНЕН]
- [x] Ресурсы `HeroData` и `AbilityData` (Data-driven архитектура)
- [x] 3 полноценных героя (.tres): Воин, Маг, Следопыт
- [x] Поддержка дальних атак снарядами (Projectile) и взрывов по площади (AreaOfEffect)
- [x] Хаб с пьедесталами выбора героев, порталом и разблокировкой за души
- [x] Player dynamic builder из `HeroData`
- [x] HUD со способностями и душами
- [x] GUT-тесты: 23 теста, 80 проверок

## Спринт 3: Процедурная генерация этажа [ВЫПОЛНЕН]
- [x] `FloorGenerator.gd` (детерминированная генерация связного графа от seed)
- [x] Сетка комнат 8–14 штук (START, COMBAT, TREASURE, SHOP, ELITE, BOSS)
- [x] Поиск комнаты Босса по максимальному расстоянию BFS от старта
- [x] Ресурс `BiomeData.gd` и `goblin_dungeon.tres`
- [x] Сцена комнаты `Room.tscn` и дверей `Door.tscn` (блокировка дверей в бою, открытие после зачистки)
- [x] Менеджер этажа `DungeonFloor.tscn` со связыванием комнат и переходом игрока между ними
- [x] Мини-карта `Minimap.tscn` (отображение открытых/посещённых комнат, текущей комнаты и типов)
- [x] Меню паузы `PauseMenu.tscn` с отображением seed забега
- [x] Портал перехода на следующий этаж в комнате босса
- [x] GUT-тесты: 27 тестов, 1622 проверки (включая 100 генераций подряд без недостижимых комнат и тест детерминизма по seed)

## Спринт 4: ИИ врагов и Темница гоблинов [СЛЕДУЮЩИЙ]
- [ ] StateMachine-компонент (idle, patrol, chase, attack, hurt, dead)
- [ ] Ресурс `EnemyData` (hp, speed, damage, armor, ai_profile, loot_table, xp/gold)
- [ ] Навигация через NavigationAgent2D
- [ ] Гоблины: рубака (ближний бой), лучник (дистанция), шаман (лечит), громила (элитный)
- [ ] Волны врагов и бюджет сложности комнат
- [ ] Босс «Вождь гоблинов» (2 фазы, паттерны атак, полоска HP босса, призыв подкрепления)
- [ ] GUT-тесты ИИ и фаз босса
