/datum/action/cooldown/blood_bond/brother_sign
	name = "Знак братства"
	desc = "Нарисовать своей кровью на полу знак братства: две ладони, прижатые друг к другу. Знаки нужны клятве. Уборщик может их смыть, но уже скреплённый шаг останется."
	bond_how = "Встать на нужную клетку, нажать кнопку и не двигаться, пока рисуете. Крови уходит немного, но при сильной кровопотере и в наручниках рисовать нельзя."
	button_icon_state = "brother_sign"
	check_flags = AB_CHECK_CONSCIOUS | AB_CHECK_RESTRAINED
	cooldown_time = 10 SECONDS

/datum/action/cooldown/blood_bond/brother_sign/Activate(atom/target)
	var/mob/living/carbon/drawer = owner
	var/turf/spot = get_turf(drawer)
	var/refusal = sign_refusal(drawer, spot)
	if(refusal)
		drawer.balloon_alert(drawer, refusal)
		return FALSE
	var/angle = pick(0, 90, 180, 270)
	var/obj/effect/temp_visual/brother_sign_draw/sketch = new(spot, drawer, angle)
	drawer.visible_message(span_warning("[drawer] опускается на колено и выводит что-то на полу кровью из ладони."), span_notice("Вы надрезаете ладонь и рисуете знак братства."))
	var/drawn = do_after(drawer, BROTHER_SIGN_DRAW_TIME, spot)
	qdel(sketch)
	if(!drawn || QDELETED(src) || owner != drawer || !IsAvailable())
		return FALSE
	refusal = sign_refusal(drawer, spot)
	if(refusal)
		drawer.balloon_alert(drawer, refusal)
		return FALSE
	var/obj/effect/decal/cleanable/blood/brother_sign/sign = draw_sign(drawer, spot, angle)
	var/datum/blood_oath/brother_sign/sign_oath = brother.team.oath
	if(sign)
		to_chat(drawer, span_notice(sign_oath.sign_note(sign)))
	StartCooldown(bond_cooldown())
	return TRUE

/// Причина, по которой здесь не нарисовать знак, или null
/datum/action/cooldown/blood_bond/brother_sign/proc/sign_refusal(mob/living/carbon/drawer, turf/spot)
	if(!istype(brother?.team?.oath, /datum/blood_oath/brother_sign))
		return "клятва не о знаках"
	if(!iscarbon(drawer) || !drawer.get_blood_dna_list())
		return "нет крови"
	if(!isfloorturf(spot))
		return "здесь не нарисовать"
	if(locate(/obj/effect/decal/cleanable/blood/brother_sign) in spot)
		return "здесь уже есть знак"
	if(drawer.blood_volume - BROTHER_SIGN_BLOOD_COST < BLOOD_VOLUME_SAFE)
		return "слишком мало крови"
	return null

/datum/action/cooldown/blood_bond/brother_sign/proc/draw_sign(mob/living/carbon/drawer, turf/spot, angle)
	drawer.blood_volume -= BROTHER_SIGN_BLOOD_COST
	var/obj/effect/decal/cleanable/blood/brother_sign/sign = new(spot)
	if(QDELETED(sign))
		return null
	sign.transform = brother_sign_rotation(angle)
	sign.add_mob_blood(drawer)
	sign.bind_team(brother.team)
	log_game("Blood brother [key_name(drawer)] of [brother.team.name] drew a blood sign at [AREACOORD(spot)].")
	return sign
