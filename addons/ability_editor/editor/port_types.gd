@tool
class_name AbilityGraphPortTypes
extends RefCounted

enum PortType {
	ACTION = 0,
	STATUS_EFFECT = 1,
	STACK = 2,
	MODIFIER = 3,
	TRIGGER = 4,
	TEXTURE = 5,
	CONCENTRATION_STATUS_EFFECT = 6,
}

const PORT_COLORS := {
	PortType.ACTION: Color(0.4, 0.6, 1.0),
	PortType.STATUS_EFFECT: Color(1.0, 0.6, 0.2),
	PortType.STACK: Color(0.3, 0.85, 0.4),
	PortType.MODIFIER: Color(1.0, 0.9, 0.3),
	PortType.TRIGGER: Color(0.7, 0.4, 1.0),
	PortType.TEXTURE: Color(0.8, 0.5, 0.5),
	PortType.CONCENTRATION_STATUS_EFFECT: Color(1.0, 0.6, 0.2)
}


static func get_color(port_type: PortType) -> Color:
	return PORT_COLORS.get(port_type, Color.WHITE)
