extends BattleCharacter
class_name BattleCorraleine

# --- Instantiation ---
## Instantiates a new character with the specified abilities
static func create(p_abilities: Array[BaseAbility]) -> BattleCorraleine:
	var character := BattleCorraleine.new()
	character.abilities = p_abilities
	return character
