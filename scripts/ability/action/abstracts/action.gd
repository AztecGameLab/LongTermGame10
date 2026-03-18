@icon("uid://c8m84g2pnkmb4")
@abstract
extends Resource
class_name Action
## Base class for all actions, which can be used inside of both [Ability] and [StatusEffect]

## Runs the action. Each type contains its own logic. This is a coroutine, so it must be awaited.
## Being a coroutine allows us to have actions that take time, such as waiting for an animation to finish, or waiting for a timer.
@abstract func run(context: ActionContext) -> void;
