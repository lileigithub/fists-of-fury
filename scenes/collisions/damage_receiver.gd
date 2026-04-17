class_name DamageReceiver extends Area2D

enum HitType {NORMAL, KICKDOWN, POWER}

signal damage_received(damage:int, hit_type:HitType)
	
