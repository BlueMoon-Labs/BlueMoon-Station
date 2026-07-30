// Путь был /datum/species/golems - такого вида в кодовой базе нет (реальный - /datum/species/golem).
// DM молча создавал тип из определения прока, поэтому патч не применялся ни к одному голему,
// а в GLOB.species_list появлялся фантом с id = null: именно он ронял админский пикер видов
// рантаймом "Null in a tgui_input_list() items" (прод-раунд 9832).
/datum/species/golem/New()
	. = ..()
	// Идемпотентное добавление, а не LAZYADD: повторный проход по тому же списку (наследование
	// New() подтипами, ручное досоздание вида) дописывал бы вторую копию трейта.
	LAZYINITLIST(inherent_traits)
	inherent_traits |= CAN_BE_OPERATED_WITHOUT_PAIN
