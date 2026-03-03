@icon("uid://c8m84g2pnkmb4")
@abstract
extends Resource
class_name Action
## Base class for all actions, which can be used inside of both [Ability] and [StatusEffect]

## Emits this signal once the action is completely done running, including any animations.
signal finished();

## Runs the action. Each type contains its own logic.
@abstract func run(source: Character, target: Character);
