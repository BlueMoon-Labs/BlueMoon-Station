/datum/antagonist/ert/lfwb_ordinator/leader
	name = "Officer Tribunal Ordinator"
	outfit = /datum/outfit/lfwb_ordinator/officer
	role = "Офицер"
	leader = TRUE

/datum/antagonist/ert/lfwb_ordinator
	name = "Tribunal Ordinator"
	outfit = /datum/outfit/lfwb_ordinator
	role = "Солдат"

//////////////////////////////
/datum/antagonist/ert/security/rabbit
	role = "Specialist"
	outfit = /datum/outfit/ert/security/rabbit

/datum/antagonist/ert/commander/rabbit
	role = "Lieutenant"
	outfit = /datum/outfit/ert/commander/rabbit
	leader = TRUE

//////////////////////////////
/datum/antagonist/ert/firesquad
	name = "Firesquad Trooper"
	outfit = /datum/outfit/ert/firesquad_trooper
	role = "Огнеметчик"

/datum/antagonist/ert/firesquad/leader
	name = "Firesquad Commander"
	outfit = /datum/outfit/ert/firesquad_commander
	role = "Командир"
	leader = TRUE

//////////////////////////////
/datum/antagonist/ert/heavysquad
	name = "Emergency Heavy Squad"
	outfit = /datum/outfit/ert/heavysquad_trooper
	role = "Пехотинец"

/datum/antagonist/ert/heavysquad/machinegun
	name = "Emergency Heavy Squad"
	outfit = /datum/outfit/ert/heavysquad_machinegun
	role = "Пулеметчик"

/datum/antagonist/ert/heavysquad/leader
	name = "Emergency Heavy Squad"
	outfit = /datum/outfit/ert/heavysquad_commander
	role = "Командир"
	leader = TRUE

///////////////////////////
/datum/antagonist/ert/zeal_team
	name = "Zeal Team Squad"
	outfit = /datum/outfit/zeal_team
	role = "Коммандос"

/datum/antagonist/ert/zeal_team/leader
	name = "Zeal Team Squad"
	outfit = /datum/outfit/zeal_team/officer
	role = "Командир"
	leader = TRUE

///////////////////////////
/datum/antagonist/ert/russian_ert
	name = "NRI Spetsnaz Squad"
	outfit = /datum/outfit/ert/ert_russian_soldier
	role = "Ефрейтор"

/datum/antagonist/ert/russian_ert/support
	name = "NRI Spetsnaz Squad"
	outfit = /datum/outfit/ert/ert_russian_support
	role = "Лейтенант"

/datum/antagonist/ert/russian_ert/leader
	name = "NRI Spetsnaz Squad"
	outfit = /datum/outfit/ert/ert_russian_leader
	role = "Полковник"
	leader = TRUE

/////////////////////////
/datum/antagonist/ert/sol_ert
	name = "SolFed Squad"
	outfit = /datum/outfit/ert/sol_soldier
	role = "Космопехотинец"

/datum/antagonist/ert/sol_ert/support
	name = "SolFed Squad"
	outfit = /datum/outfit/ert/sol_soldier_support
	role = "Космопехотинец"

/datum/antagonist/ert/sol_ert/demo // Не задействуется
	name = "SolFed Squad"
	outfit = /datum/outfit/ert/sol_soldier_demo
	role = "Подрывник"

/datum/antagonist/ert/sol_ert/leader
	name = "SolFed Squad"
	outfit = /datum/outfit/ert/sol_soldier_leader
	role = "Капитан"
	leader = TRUE

/////////////////////////////////////////
/datum/antagonist/ert/engineer_squadleader
	role = "Бригадир"
	outfit = /datum/outfit/ert/engineer
	skill_modifiers = list(/datum/skill_modifier/job/level/wiring)
	leader = TRUE

/////////////////////////////////////////
/datum/antagonist/ert/ntr_ert_agent
	name = "Internal Affairs Squad"
	outfit = /datum/outfit/ert/ntr_ert_agent
	role = "Агент"

/datum/antagonist/ert/ntr_ert_leader
	name = "Internal Affairs Squad"
	outfit = /datum/outfit/ert/ntr_ert_leader
	role = "Следователь"
	leader = TRUE

//////////////////////////////////////////
/datum/antagonist/ert/maid_leader
	name = "Maid Squad"
	outfit = /datum/outfit/ert/maid_leader
	role = "Старшая горничная"
	leader = TRUE

/datum/antagonist/ert/maid
	name = "Maid Squad"
	outfit = /datum/outfit/ert/maid
	role = "Горничная"

/////////////////////////////////////////
// Добавление трейтов ОБР ролям в их mind
/datum/antagonist/ert/engineer_squadleader/on_gain()
	. = ..()
	ADD_TRAIT(owner, TRAIT_KNOW_ENGI_WIRES, JOB_TRAIT)
	ADD_TRAIT(owner, TRAIT_KNOW_CYBORG_WIRES, JOB_TRAIT)
	ADD_TRAIT(owner, TRAIT_MECHA_EXPERT, TRAIT_GENERIC)

/datum/antagonist/ert/engineer/on_gain()
	. = ..()
	ADD_TRAIT(owner, TRAIT_KNOW_ENGI_WIRES, TRAIT_GENERIC)
	ADD_TRAIT(owner, TRAIT_KNOW_CYBORG_WIRES, TRAIT_GENERIC)
	ADD_TRAIT(owner, TRAIT_MECHA_EXPERT, TRAIT_GENERIC)

/datum/antagonist/ert/medic/on_gain()
	. = ..()
	ADD_TRAIT(owner, TRAIT_QUICK_CARRY, TRAIT_GENERIC)
	ADD_TRAIT(owner, TRAIT_REAGENT_EXPERT, TRAIT_GENERIC)

/datum/antagonist/ert/hsc/on_gain()
	. = ..()
	ADD_TRAIT(owner, TRAIT_QUICK_CARRY, TRAIT_GENERIC)
	ADD_TRAIT(owner, TRAIT_REAGENT_EXPERT, TRAIT_GENERIC)

/////////////////////////////////////////
