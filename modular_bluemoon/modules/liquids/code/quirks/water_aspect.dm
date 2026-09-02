/datum/quirk/water_aspect
	name = "Водный аспект"
	desc = "(Родовая черта водных видов) Подводные города тебе родной дом. Ты дышишь под водой и увереннее двигаешься в глубокой воде."
	value = 1
	mob_trait = TRAIT_WATER_ASPECT
	gain_text = "<span class='notice'>Вы чувствуете родство с водной стихией.</span>"
	lose_text = "<span class='danger'>Связь с водой исчезла!</span>"
	medical_record_text = "Пациент адаптирован к жизни под водой."
	flavor_quirk = TRUE

/datum/quirk/water_aspect/add()
	ADD_TRAIT(quirk_holder, TRAIT_WATER_BREATHING, QUIRK_TRAIT)

/datum/quirk/water_aspect/remove()
	REMOVE_TRAIT(quirk_holder, TRAIT_WATER_BREATHING, QUIRK_TRAIT)
	return ..()
