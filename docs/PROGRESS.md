# Прогресс разработки: «Путь в Чистилище»

## Спринт 0: Каркас проекта [ВЫПОЛНЕН]
- [x] Установка и проверка Godot 4 (версия 4.7.2 stable)
- [x] Создание структуры папок согласно архитектуре
- [x] Базовая документация: AGENTS.md, README.md, docs/GDD.md, docs/PROGRESS.md, docs/BACKLOG.md
- [x] Конфигурация project.godot (разрешение 1280x720, nearest filter, слои коллизий, input map, autoload)
- [x] Autoload-синглтоны: EventBus, GameState, MetaProgress, SaveManager, AudioManager, SceneRouter
- [x] Базовые сцены: Main.tscn, MainMenu.tscn, Hub.tscn с плавным fade-переходом
- [x] Подключение GUT и первый smoke-тест (6 тестов, 17 проверок — все пройдены успешно)
- [x] Пресеты экспорта Windows и Linux (export_presets.cfg)

## Спринт 1: Игрок и базовый бой [СЛЕДУЮЩИЙ]
- [ ] Компоненты: HealthComponent, HurtboxComponent, HitboxComponent, MovementComponent
- [ ] Сцена Player (CharacterBody2D, dash, i-frames, ближняя атака дугой, knockback)
- [ ] systems/combat/DamageCalculator.gd: damage = max(1, round(B * (1 + M) * C - A))
- [ ] Камера с плавным следованием и screen shake
- [ ] Тестовый манекен с HP и полоской здоровья
- [ ] HUD (HP, перезарядка dash)
- [ ] Hit-stop (~50 мс)
- [ ] GUT-тесты на урон и компоненты
