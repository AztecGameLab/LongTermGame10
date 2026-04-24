extends BattleCharacter
class_name BattleUmi

# --- Instantiation ---
## Instantiates a new character with the specified abilities
static func create(p_abilities: Array[BaseAbility]) -> BattleUmi:
	var character := BattleUmi.new()
	character.abilities = p_abilities
	return character
