extends BattleCharacter
class_name BattleCoralleine

# --- Instantiation ---
## Instantiates a new character with the specified abilities
static func create(p_abilities: Array[BaseAbility]) -> BattleCoralleine:
	var character := BattleCoralleine.new()
	character.abilities = p_abilities
	return character
