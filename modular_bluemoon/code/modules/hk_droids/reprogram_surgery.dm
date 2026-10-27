/// Дроид не может помешать перепрошивке: без сознания, в крите, мёртв, сбит с ног, скован или в стазисе.
/proc/is_hk_droid_disabled(mob/living/droid)
	return droid.incapacitated(ignore_grab = TRUE) || droid.IsKnockdown()

/datum/surgery/hk_reprogram
	name = "HK Loyalty Reprogramming"
	desc = "Вскрыть панель на голове дроида серии HK и перезаписать блок лояльности мультитулом. Хозяином станет хирург: хирурга-антагониста дроид примет в его команду, иначе выйдет из команды прежнего хозяина и встанет на сторону станции. Дроид должен быть обездвижен - без сознания, в крите, мёртв, отключён ЭМИ, сбит с ног или в наручниках. Чип лояльности с фабрики HK делает то же без операции."
	possible_locs = list(BODY_ZONE_HEAD)
	requires_bodypart_type = BODYPART_ROBOTIC
	steps = list(
		/datum/surgery_step/mechanic_open,
		/datum/surgery_step/open_hatch,
		/datum/surgery_step/hk_reprogram,
		/datum/surgery_step/mechanic_close)
	is_healing = FALSE
	icon = 'icons/obj/device.dmi'
	icon_state = "multitool"
	radial_priority = SURGERY_RADIAL_PRIORITY_OTHER_FIRST

/datum/surgery/hk_reprogram/can_start(mob/user, mob/living/carbon/target, obj/item/tool)
	if(user == target || !is_species(target, /datum/species/ipc/hk) || !is_hk_droid_disabled(target))
		return FALSE
	return ..()

/datum/surgery_step/hk_reprogram
	name = "Перезаписать блок лояльности"
	implements = list(TOOL_MULTITOOL = 100, /obj/item/card/emag = 100, TOOL_WIRECUTTER = 40)
	time = 8 SECONDS
	preop_sound = 'sound/machines/terminal_processing.ogg'
	success_sound = 'sound/machines/terminal_success.ogg'

/datum/surgery_step/hk_reprogram/preop(mob/user, mob/living/carbon/target, target_zone, obj/item/tool, datum/surgery/surgery)
	if(!is_hk_droid_disabled(target))
		to_chat(user, span_warning("Дроид не обездвижен: блок лояльности перезаписывают только у отключённого, сбитого с ног или скованного HK."))
		return -1
	display_results(user, target, span_notice("Вы подключаетесь к блоку лояльности [target] и начинаете перезапись..."),
		span_notice("[user] подключается к блоку лояльности в голове [target]."),
		span_notice("[user] копается в голове [target]."))

/datum/surgery_step/hk_reprogram/success(mob/user, mob/living/carbon/target, target_zone, obj/item/tool, datum/surgery/surgery)
	var/datum/component/hk_loyalty/loyalty = target.LoadComponent(/datum/component/hk_loyalty)
	var/datum/mind/old_master = loyalty.get_master()
	loyalty.set_master(user.mind)
	var/enslaved = target.mind?.enslaved_to == user
	display_results(user, target, span_notice("Блок лояльности [target] перезаписан. Теперь вы - хозяин дроида[enslaved ? ", и он служит вашей команде" : ""]."),
		span_notice("[user] перезаписывает блок лояльности [target]."),
		span_notice("[user] заканчивает копаться в голове [target]."))
	log_combat(user, target, "reprogrammed the HK loyalty block of")
	var/old_master_admin = old_master ? (old_master.current ? ADMIN_LOOKUPFLW(old_master.current) : key_name_admin(old_master)) : "нет"
	message_admins("[ADMIN_LOOKUPFLW(user)] перепрошил [ADMIN_LOOKUPFLW(target)], прежний хозяин - [old_master_admin][enslaved ? "; хирург антагонист, дроид порабощён" : ""].")
	log_game("[key_name(user)] перепрошил [key_name(target)] в [AREACOORD(target)], прежний хозяин [old_master ? key_name(old_master) : "нет"][enslaved ? ", дроид порабощён хирургом-антагонистом" : ""].")
	return TRUE
