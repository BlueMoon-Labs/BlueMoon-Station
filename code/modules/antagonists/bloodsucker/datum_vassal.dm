#define VASSAL_SCAN_MIN_DISTANCE 5
#define VASSAL_SCAN_MAX_DISTANCE 500
#define VASSAL_SCAN_PING_TIME 20 //2s update time.


/datum/antagonist/bloodsucker/proc/attempt_turn_vassal(mob/living/carbon/C)
	C.silent = 0
	return SSticker.mode.make_vassal(C,owner)

/datum/antagonist/bloodsucker/proc/FreeAllVassals()
	for(var/datum/antagonist/vassal/V in vassals)
		SSticker.mode.remove_vassal(V.owner)

/datum/antagonist/vassal
	name = "Vassal"//WARNING: DO NOT SELECT" // "Vassal"
	roundend_category = "vassals"
	antagpanel_category = "Bloodsucker"
	job_rank = ROLE_BLOODSUCKER
	var/datum/antagonist/bloodsucker/master		// Who made me?
	var/list/datum/action/powers = list()// Purchased powers
	var/list/datum/objective/objectives_given = list()	// For removal if needed.
	threat = 1

/datum/antagonist/vassal/can_be_owned(datum/mind/new_owner)
	// If we weren't created by a bloodsucker, then we cannot be a vassal (assigned from antag panel)
	if(!master)
		return FALSE
	return ..()

/datum/antagonist/vassal/on_gain()
	SSticker.mode.vassals |= owner // Add if not already in here (and you might be, if you were picked at round start)
	// Mindslave Add
	if(master)
		var/datum/antagonist/bloodsucker/B = master.owner.has_antag_datum(ANTAG_DATUM_BLOODSUCKER)
		if(B)
			B.vassals |= src
		owner.enslave_mind_to_creator(master.owner.current)
	// Master Pinpointer
	owner.current.apply_status_effect(/datum/status_effect/agent_pinpointer/vassal_edition)
	// Powers
	var/datum/action/cooldown/bloodsucker/vassal/recuperate/new_Recuperate = new ()
	// BLUEMOON ADD START
	var/datum/action/cooldown/bloodsucker/tutorial/vassal/new_Tutorial = new()
	new_Tutorial.Grant(owner.current)
	powers += new_Tutorial
	// BLUEMOON ADD END
	new_Recuperate.Grant(owner.current)
	powers += new_Recuperate
	// Give Vassal Objective
	var/datum/objective/bloodsucker/vassal/vassal_objective = new
	vassal_objective.owner = owner
	vassal_objective.generate_objective()
	objectives += vassal_objective
	objectives_given += vassal_objective
	give_thrall_eyes()
	owner.current.grant_language(/datum/language/vampiric, source = LANGUAGE_VASSAL)
	// Add Antag HUD
	update_vassal_icons_added(owner.current, "vassal")
	. = ..()

/datum/antagonist/vassal/proc/give_thrall_eyes()
	var/obj/item/organ/eyes/vassal/E = new
	E.Insert(owner.current)

/datum/antagonist/vassal/proc/remove_thrall_eyes()
	var/obj/item/organ/eyes/E = new
	E.Insert(owner.current)

/datum/antagonist/vassal/on_removal()
	SSticker.mode.vassals -= owner // Add if not already in here (and you might be, if you were picked at round start)
	// Mindslave Remove
	if(master && master.owner)
		master.vassals -= src
		if(owner.enslaved_to == master.owner.current)
			owner.enslaved_to = null
	// Master Pinpointer
	owner.current.remove_status_effect(/datum/status_effect/agent_pinpointer/vassal_edition)
	// Powers
	while(powers.len)
		var/datum/action/power = pick(powers)
		powers -= power
		power.Remove(owner.current)
	// Remove Hunter Objectives
	for(var/O in objectives_given)
		objectives -= O
		qdel(O)
	objectives_given = list()
	remove_thrall_eyes()
	owner.current.remove_language(/datum/language/vampiric, TRUE, TRUE, LANGUAGE_VASSAL)
	// Clear Antag HUD
	update_vassal_icons_removed(owner.current)
	owner.special_role = null // BLUEMOON ADD
	. = ..()

/datum/antagonist/vassal/greet()
	to_chat(owner, "<span class='cult'>Вы теперь смертный слуга [master.owner.current], кровососущего вампира!</span>")
	to_chat(owner, "<span class='boldannounce'>Сила бессмертной крови обязывает вас слушаться [master.owner.current.ru_ego()] во всём, даже жертвовать собой ради жизни вампира.<br>\
			Вы не обязаны слушаться какого-либо другого кровососа, ведь только [master.owner.current] владеет вами. Законы ПАКТа теперь для вас ничто; только воля вашего хозяина или хозяйки превыше всего.<span>")
	to_chat(owner, "<span class='userdanger'>Вы - антагонист! Не игнорируйте своего хоязина и тем более не действуйте против него!<span>") // BLUEMOON ADD

	// Effects...
	owner.current.playsound_local(null, 'sound/magic/mutate.ogg', 100, FALSE, pressure_affected = FALSE)
	//owner.store_memory("You became the mortal servant of [master.owner.current], a bloodsucking vampire!")
	antag_memory += "Вы стали смертным слугой <b>[master.owner.current]</b>, кровососущего вампира!<br>"
	// And to your new Master...
	to_chat(master.owner, "<span class='cult'>[owner.current] падает в пристрастие к вашей бессмертной крови. [owner.current.ru_who(TRUE)] теперь ваш неумирающий слуга!</span>")
	master.owner.current.playsound_local(null, 'sound/magic/mutate.ogg', 100, FALSE, pressure_affected = FALSE)

/datum/antagonist/vassal/farewell()
	owner.current.visible_message("Глаза [owner.current] лихорадочно мечутся из стороны в сторону, затем останавливаются. [owner.current.ru_who(TRUE)] выглядит спокойно, \
			словно [owner.current.ru_who()] восстанавливает какую-то часть себя.",\
			"<span class='warning'><FONT size = 3>Внезапно, вы больше не принадлежите [master.owner]! Вы тяжело вздыхаете, теперь вернув свою свободную волю.</FONT></span>")
	owner.current.playsound_local(null, 'sound/magic/mutate.ogg', 100, FALSE, pressure_affected = FALSE)
	// And to your former Master...
	//if (master && master.owner)
	//	to_chat(master.owner, "<span class='cult'>Вы ощущаете, что связь с вашим вассалом [owner.current] была каким то образом разрушена!</span>")

/datum/status_effect/agent_pinpointer/vassal_edition
	id = "agent_pinpointer"
	alert_type = /atom/movable/screen/alert/status_effect/agent_pinpointer/vassal_edition
	minimum_range = VASSAL_SCAN_MIN_DISTANCE
	tick_interval = VASSAL_SCAN_PING_TIME
	duration = -1 // runs out fast
	range_fuzz_factor = 0

/atom/movable/screen/alert/status_effect/agent_pinpointer/vassal_edition
	name = "Кровавые Узы"
	desc = "Вы всегда знаете где ваш хозяин."
	//icon = 'icons/obj/device.dmi'
	//icon_state = "pinon"

/datum/status_effect/agent_pinpointer/vassal_edition/on_creation(mob/living/new_owner, ...)
	..()

	var/datum/antagonist/vassal/antag_datum = new_owner.mind.has_antag_datum(ANTAG_DATUM_VASSAL)
	scan_target = antag_datum?.master?.owner?.current

/datum/status_effect/agent_pinpointer/vassal_edition/scan_for_target()
	// DO NOTHING. We already have our target, and don't wanna do anything from agent_pinpointer

/datum/antagonist/vassal/proc/update_vassal_icons_added(mob/living/vassal, icontype="vassal")
	var/datum/atom_hud/antag/bloodsucker/hud = GLOB.huds[ANTAG_HUD_BLOODSUCKER]
	hud.join_hud(vassal)
	set_antag_hud(vassal, icontype) // Located in icons/mob/hud.dmi
	owner.current.hud_list[ANTAG_HUD].icon = image('icons/mob/hud.dmi', owner.current, "bloodsucker")

/datum/antagonist/vassal/proc/update_vassal_icons_removed(mob/living/vassal)
	var/datum/atom_hud/antag/hud = GLOB.huds[ANTAG_HUD_BLOODSUCKER]
	hud.leave_hud(vassal)
	set_antag_hud(vassal, null)

//Displayed at the start of roundend_category section, default to roundend_category header
/*/datum/antagonist/vassal/roundend_report_header()
	return 	"<span class='header'>Лояльные своим кровососущим хозяевам, Вассалами были:</span><br><br>"*/
