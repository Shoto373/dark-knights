class_name VictoryScreen
extends CanvasLayer

## Финальный победный экран: завершение забега, триумф, статистика и мета-прогресс

@onready var background: ColorRect = $Background
@onready var center_container: CenterContainer = $CenterContainer
@onready var title_label: Label = %TitleLabel
@onready var hero_label: Label = %HeroLabel
@onready var seed_label: Label = %SeedLabel
@onready var time_label: Label = %TimeLabel
@onready var kills_label: Label = %KillsLabel
@onready var dmg_dealt_label: Label = %DmgDealtLabel
@onready var dmg_taken_label: Label = %DmgTakenLabel
@onready var souls_earned_label: Label = %SoulsEarnedLabel
@onready var return_button: Button = %ReturnButton

var run_souls_awarded: int = 0

func _ready() -> void:
	layer = 20
	if return_button:
		return_button.pressed.connect(_on_return_pressed)
	
	_calculate_and_apply_victory()
	_update_display()
	
	# Анимация появления экрана
	if background:
		background.modulate.a = 0.0
	if center_container:
		center_container.modulate.a = 0.0
	var tween: Tween = create_tween().set_parallel(true)
	if background:
		tween.tween_property(background, "modulate:a", 1.0, 0.6)
	if center_container:
		tween.tween_property(center_container, "modulate:a", 1.0, 0.6)

func _calculate_and_apply_victory() -> void:
	# Бонус за победу: 50 душ + конвертация собранного золота (1 душа за каждые 5 золота)
	run_souls_awarded = 50 + int(GameState.gold / 5)
	
	# Начисление в мета-прогресс
	MetaProgress.add_souls(run_souls_awarded)
	MetaProgress.lifetime_stats["victories"] = MetaProgress.lifetime_stats.get("victories", 0) + 1
	MetaProgress.lifetime_stats["total_runs"] = MetaProgress.lifetime_stats.get("total_runs", 0) + 1
	
	# Сохраняем постоянный прогресс и удаляем промежуточный забег
	SaveManager.save_meta()
	SaveManager.delete_run_save()
	
	# Фиксируем победу в состоянии забега
	GameState.end_run(true)

func _update_display() -> void:
	if not hero_label:
		return
	var hero_names: Dictionary = {
		"warrior": "Воин",
		"mage": "Маг",
		"ranger": "Следопыт"
	}
	hero_label.text = "Герой: %s" % hero_names.get(GameState.selected_hero_id, GameState.selected_hero_id)
	if seed_label:
		seed_label.text = "Seed: %d" % GameState.current_seed
	
	var elapsed_secs: int = int(GameState.run_stats.get("time_elapsed", 0.0))
	var minutes: int = elapsed_secs / 60
	var seconds: int = elapsed_secs % 60
	if time_label:
		time_label.text = "Время забега: %02d:%02d" % [minutes, seconds]
	
	if kills_label:
		kills_label.text = "Сражено врагов: %d" % GameState.run_stats.get("kills", 0)
	if dmg_dealt_label:
		dmg_dealt_label.text = "Нанесено урона: %d" % GameState.run_stats.get("damage_dealt", 0)
	if dmg_taken_label:
		dmg_taken_label.text = "Получено урона: %d" % GameState.run_stats.get("damage_taken", 0)
	if souls_earned_label:
		souls_earned_label.text = "+%d Душ передано в Хаб" % run_souls_awarded

func _on_return_pressed() -> void:
	SceneRouter.change_scene("res://levels/Hub.tscn", 0.5)
