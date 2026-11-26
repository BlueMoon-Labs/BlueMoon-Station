/// Синтетическая «болезнь» для отображения на мед. ХУДах и анализаторах (реальная механика — /datum/component/changeling_zombie_infection).
/datum/disease/changeling_virus
	form = "Virus"
	name = "Cryptogenic polymorph strain"
	desc = "Аберрантные тканевые маркеры, согласующиеся с воздействием ксеноморфных ферментов — возможно, связано с генокрадами."
	agent = "Криптогенные прионы, связанные с ксеноморфами"
	spread_text = "Не заразно; связано с контактом тканей полиморфного класса"
	cure_text = "Высокая доза спейсациллина при достаточной токсической нагрузке крови или агрессивная очистка токсинов после открытия окна инфекции (медицинский протокол)."
	max_stages = 1
	stage = 1
	stage_prob = 0
	severity = DISEASE_SEVERITY_DANGEROUS
	disease_flags = CAN_CARRY | CAN_RESIST
	spread_flags = DISEASE_SPREAD_NON_CONTAGIOUS
	infectivity = 0
	viable_mobtypes = list(/mob/living/carbon/human)
	bypasses_immunity = TRUE
	infectable_biotypes = MOB_ORGANIC

/datum/disease/changeling_virus/stage_act()
	// Симптомы и прогресс инфекции обрабатываются компонентом changeling_zombie_infection.
	return
