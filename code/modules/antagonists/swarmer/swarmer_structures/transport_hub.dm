/obj/structure/swarmer/transport_hub
	name = "swarmer hub"
	desc = "Телепортер \"Свармеров\", позволяющий им телепортироваться к другим телепортерам."
	icon_state = "hub_enabled"
	swarmer_examine = "Можно использовать, нажав на телепортер в интенте \"Помощь\""
	max_integrity = 100
	var/listkey
	var/datum/effect_system/spark_spread/spark_system
	var/enabled = TRUE

/obj/structure/swarmer/transport_hub/Initialize(mapload, datum/team/swarmer_team/swarm_team)
	. = ..()
	var/area/A = get_area(src)
	var/locname = initial(A.name)
	listkey = "[locname]"
	spark_system = new
	spark_system.set_up(5, 0, src)
	spark_system.attach(src)

/obj/structure/swarmer/transport_hub/Destroy()
	QDEL_NULL(spark_system)
	return ..()

/obj/structure/swarmer/transport_hub/proc/toggle_enabled()
	enabled = !enabled
	update_icon(UPDATE_ICON_STATE)

/obj/structure/swarmer/transport_hub/emp_act(severity)
	. = ..()
	if(QDELETED(src) || (. & EMP_PROTECT_SELF) || !enabled)
		return
	toggle_enabled()
	addtimer(CALLBACK(src, PROC_REF(toggle_enabled)), SWARMER_STRUCTURE_EMP_DURATION * severity, TIMER_DELETE_ME)

/obj/structure/swarmer/transport_hub/update_icon_state()
	icon_state = (enabled && anchored) ? initial(icon_state) : "hub_disabled"

/obj/structure/swarmer/transport_hub/swarmer_help_act(mob/living/simple_animal/hostile/swarmer/swarmer)
	. = ..()
	if(!.)
		return
	if(!enabled)
		swarmer.balloon_alert(swarmer, "калибруется!")
		return

	if(!team)
		return

	var/list/potential_hubs = team.get_transport_hub_list(src)
	if(!length(potential_hubs))
		swarmer.balloon_alert(swarmer, "отсутствуют другие хабы!")
		return

	var/input_hub_key = tgui_input_list(swarmer, "Выберите хаб для телепорта.", "Выбор хаба", potential_hubs)
	var/obj/structure/swarmer/transport_hub/actual_selected_hub = potential_hubs[input_hub_key]
	if(QDELETED(src) || QDELETED(actual_selected_hub) || !Adjacent(swarmer) || !enabled || !actual_selected_hub.enabled || !actual_selected_hub.anchored || swarmer_actions_blocked(swarmer))
		return

	playsound(swarmer, 'sound/swarmer/swarmer_teleport.ogg', 100, TRUE)
	if(!do_after(swarmer, SWARMER_TELEPORT_DELAY(swarmer), src) || QDELETED(actual_selected_hub) || !enabled || !actual_selected_hub.enabled || !actual_selected_hub.anchored || swarmer_actions_blocked(swarmer))
		swarmer.balloon_alert(swarmer, "нельзя двигаться!")
		return
	var/turf/target_turf = get_turf(actual_selected_hub)
	if(!target_turf || !swarmer.training_move_allowed(target_turf))
		return
	swarmer.forceMove(target_turf)
	spark_system.start()
	actual_selected_hub.spark_system.start()

