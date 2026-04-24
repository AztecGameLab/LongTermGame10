extends BattleCharacter
class_name BattleFortune

# --- Instantiation ---
## Instantiates a new character with the specified abilities
static func create(p_abilities: Array[BaseAbility]) -> BattleFortune:
	var character := BattleFortune.new()
	character.abilities = p_abilities
	return character
