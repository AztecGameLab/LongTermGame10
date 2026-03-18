class_name BattleContext

var player_team: Array[BattleCharacter]
var boss_team: Array[BattleCharacter]

func _init(p_player_team: Array[BattleCharacter], p_boss_team: Array[BattleCharacter]) -> void:
	self.player_team = p_player_team
	self.boss_team = p_boss_team

func get_allies(character: BattleCharacter) -> Array[BattleCharacter]:
	if player_team.has(character):
		return player_team
	return boss_team
	
func get_enemies(character: BattleCharacter) -> Array[BattleCharacter]:
	if player_team.has(character):
		return boss_team
	return player_team
