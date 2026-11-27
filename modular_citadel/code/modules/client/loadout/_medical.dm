/datum/gear/hands/medicbriefcase
	name = "Medical Briefcase"
	description = "Белый медицинский портфель с синим крестом — для медицинского снаряжения, которое обычно не помещается в сумке."
	path = /obj/item/storage/briefcase/medical
	restricted_roles = list("Medical Doctor", "Chief Medical Officer")
	restricted_desc = "MD, CMO"

/datum/gear/neck/stethoscope
	name = "Stethoscope"
	description = "Устаревший медицинский прибор для прослушивания звуков человеческого тела. Ещё и заставляет выглядеть так, будто ты знаешь, что делаешь."
	path = /obj/item/clothing/neck/stethoscope
	restricted_roles = list("Medical Doctor", "Chief Medical Officer")

/datum/gear/uniform/bluescrubs
	name = "Blue Scrubs"
	description = "Сделано из специального волокна, дающего небольшую защиту от биологических угроз. Это — нежно-голубого цвета."
	subcategory = LOADOUT_SUBCATEGORY_UNIFORM_JOBS
	path = /obj/item/clothing/under/rank/medical/doctor/blue
	restricted_roles = list("Medical Doctor", "Chief Medical Officer", "Geneticist", "Chemist", "Virologist", "Brig Physician")
	restricted_desc = "Medical, Brig Physician"

/datum/gear/uniform/greenscrubs
	name = "Green Scrubs"
	description = "Сделано из специального волокна, дающего небольшую защиту от биологических угроз. Это — тёмно-зелёного цвета."
	subcategory = LOADOUT_SUBCATEGORY_UNIFORM_JOBS
	path = /obj/item/clothing/under/rank/medical/doctor/green
	restricted_roles = list("Medical Doctor", "Chief Medical Officer", "Geneticist", "Chemist", "Virologist", "Brig Physician")
	restricted_desc = "Medical, Brig Physician"

/datum/gear/uniform/purplescrubs
	name = "Purple Scrubs"
	description = "Сделано из специального волокна, дающего небольшую защиту от биологических угроз. Это — глубокого фиолетового цвета."
	subcategory = LOADOUT_SUBCATEGORY_UNIFORM_JOBS
	path = /obj/item/clothing/under/rank/medical/doctor/purple
	restricted_roles = list("Medical Doctor", "Chief Medical Officer", "Geneticist", "Chemist", "Virologist", "Brig Physician")
	restricted_desc = "Medical, Brig Physician"

/datum/gear/head/nursehat
	name = "Nurse Hat"
	description = "Позволяет быстро опознать обученный медицинский персонал."
	path = /obj/item/clothing/head/nursehat
	subcategory = LOADOUT_SUBCATEGORY_HEAD_JOBS
	restricted_roles = list("Medical Doctor", "Chief Medical Officer", "Geneticist", "Chemist", "Virologist", "Brig Physician")
	restricted_desc = "Medical, Brig Physician"

/datum/gear/uniform/nursesuit
	name = "Nurse Suit"
	description = "Комбинезон, который обычно носят младшие сотрудники мебея."
	path = /obj/item/clothing/under/rank/medical/doctor/nurse
	subcategory = LOADOUT_SUBCATEGORY_UNIFORM_JOBS
	restricted_roles = list("Medical Doctor", "Chief Medical Officer", "Geneticist", "Chemist", "Virologist", "Brig Physician")
	restricted_desc = "Medical, Brig Physician"
