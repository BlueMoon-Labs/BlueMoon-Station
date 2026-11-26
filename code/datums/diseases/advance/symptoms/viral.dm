/*
//////////////////////////////////////
Viral adaptation

	Moderate stealth boost.
	Major Increases to resistance.
	Reduces stage speed.
	No change to transmission
	Critical Level.

BONUS
	Extremely useful for buffing viruses

//////////////////////////////////////
*/
/datum/symptom/viraladaptation
	name = "Viral self-adaptation"
	desc = "Вирус имитирует функцию обычных клеток организма, становясь труднее обнаруживаемым и уничтожаемым, но замедляясь."
	stealth = 3
	resistance = 5
	stage_speed = -3
	transmittable = 0
	level = 3

/*
//////////////////////////////////////
Viral evolution

	Moderate stealth reduction.
	Major decreases to resistance.
	increases stage speed.
	increase to transmission
	Critical Level.

BONUS
	Extremely useful for buffing viruses

//////////////////////////////////////
*/
/datum/symptom/viralevolution
	name = "Viral evolutionary acceleration"
	desc = "Вирус быстро адаптируется, чтобы распространяться как можно быстрее как вне, так и внутри хозяина. \
	Однако это делает вирус легче обнаруживаемым и менее способным противостоять лекарству."
	stealth = -2
	resistance = -3
	stage_speed = 5
	transmittable = 3
	level = 3
