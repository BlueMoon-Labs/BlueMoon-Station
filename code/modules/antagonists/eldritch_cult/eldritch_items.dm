/obj/item/living_heart
	name = "живое сердце"
	desc = "Сердце, которое бьётся в такт чужой душе. Еретик может сжать его для поиска цели; Alt-ЛКМ позволяет выбрать другую цель."
	icon = 'icons/obj/eldritch.dmi'
	icon_state = "living_heart"
	w_class = WEIGHT_CLASS_SMALL
	var/datum/mind/owner_mind
	COOLDOWN_DECLARE(track_cooldown)

/obj/item/living_heart/Initialize(mapload)
	. = ..()
	GLOB.living_heart_cache |= src

/obj/item/living_heart/Destroy()
	GLOB.living_heart_cache -= src
	owner_mind = null
	return ..()

/obj/item/living_heart/proc/bind(datum/mind/new_owner)
	if(!new_owner?.has_antag_datum(/datum/antagonist/heretic))
		return FALSE
	if(owner_mind && owner_mind != new_owner)
		return FALSE
	owner_mind = new_owner
	return TRUE

/obj/item/living_heart/add_context(atom/source, list/context, obj/item/held_item, mob/living/user)
	. = ..()
	if(IS_HERETIC(user) && (!owner_mind || user.mind == owner_mind))
		LAZYSET(context[SCREENTIP_CONTEXT_ALT_LMB], INTENT_ANY, "Сменить цель")
	return CONTEXTUAL_SCREENTIP_SET

/obj/item/living_heart/examine(mob/user)
	. = ..()
	if(!IS_HERETIC(user))
		return
	if(owner_mind && owner_mind != user.mind)
		. += span_warning("Это сердце связано с другим еретиком.")
		return
	var/datum/antagonist/heretic/heretic = user.mind.has_antag_datum(/datum/antagonist/heretic)
	if(heretic.hunt_target?.current)
		. += span_notice("Цель: [heretic.hunt_target.current.real_name]. Подношение принимается без сознания; убивать цель не требуется.")
	else
		. += span_notice("Сожмите сердце, чтобы выбрать цель. Для жертвоприношения положите сердце рядом с целью на руну трансмутации.")

/obj/item/living_heart/AltClick(mob/user)
	. = ..()
	if(!user.canUseTopic(src, BE_CLOSE, FALSE, NO_TK) || !bind(user.mind))
		return
	var/datum/antagonist/heretic/heretic = user.mind.has_antag_datum(/datum/antagonist/heretic)
	heretic.ensure_hunt_target(user, force_replace = TRUE)

/obj/item/living_heart/attack_self(mob/living/user)
	. = ..()
	if(!bind(user.mind))
		balloon_alert(user, "сердце молчит")
		to_chat(user, span_warning("Сердце не отзывается на ваш зов."))
		return
	var/datum/antagonist/heretic/heretic = user.mind.has_antag_datum(/datum/antagonist/heretic)
	if(!heretic.hunt_target_available(heretic.hunt_target))
		heretic.ensure_hunt_target(user)
		return
	if(!COOLDOWN_FINISHED(src, track_cooldown))
		return
	COOLDOWN_START(src, track_cooldown, 4 SECONDS)
	var/mob/living/carbon/human/target = heretic.hunt_target.current
	var/turf/target_turf = get_turf(target)
	var/turf/user_turf = get_turf(user)
	playsound(src, 'modular_bluemoon/sound/heretic/heart_track.ogg', 25, FALSE, extrarange = SILENCED_SOUND_EXTRARANGE)
	if(!target_turf || !user_turf || target_turf.z != user_turf.z)
		balloon_alert(user, "на другом уровне")
		to_chat(user, span_notice("[target.real_name] находится на другом уровне станции."))
		return
	var/distance = get_dist(user_turf, target_turf)
	var/direction = get_dir(user_turf, target_turf)
	balloon_alert(user, distance ? "[distance] кл., [dir2text_ru(direction)]" : "прямо здесь")
	to_chat(user, span_notice("[target.real_name]: [distance <= 15 ? "совсем рядом" : distance <= 31 ? "поблизости" : "далеко"], [dir2text_ru(direction)]."))
	if(target.stat >= UNCONSCIOUS)
		to_chat(user, span_notice("Цель без сознания. Перенесите её и живое сердце к руне трансмутации."))
	var/datum/hud/user_hud = user.hud_used
	if(!user_hud || !islist(user_hud.infodisplay))
		return
	var/atom/movable/screen/navigate_arrow/arrow = new(null, user_hud)
	arrow.color = distance <= 15 ? COLOR_GREEN : distance <= 31 ? COLOR_YELLOW : COLOR_ORANGE
	arrow.screen_loc = around_player
	arrow.transform = matrix(dir2angle(direction), MATRIX_ROTATE)
	user_hud.infodisplay += arrow
	user_hud.show_hud(user_hud.hud_version)
	QDEL_IN(arrow, 1.6 SECONDS)

/obj/item/melee/sickly_blade
	name = "зловещий клинок"
	desc = "Серповидный клинок болезненно-зелёного цвета с узором в виде глаза. Кажется, из него за вами наблюдают."
	icon = 'icons/obj/eldritch.dmi'
	icon_state = "eldritch_blade"
	item_state = "eldritch_blade"
	lefthand_file = 'modular_bluemoon/icons/obj/heretic_blades_lefthand.dmi'
	righthand_file = 'modular_bluemoon/icons/obj/heretic_blades_righthand.dmi'
	inhand_x_dimension = 48
	inhand_y_dimension = 36
	flags_1 = CONDUCT_1
	sharpness = SHARP_EDGED
	w_class = WEIGHT_CLASS_NORMAL
	force = 22
	throwforce = 15
	hitsound = 'sound/weapons/bladeslice.ogg'
	attack_verb = list("атаковал", "рубанул", "уколол", "порезал", "терзал")
	wound_bonus = 5
	bare_wound_bonus = 10
	/// Только соответствующий клинок активирует метку своего пути.
	var/mark_type = /datum/status_effect/eldritch
	var/route = PATH_SIDE

/obj/item/melee/sickly_blade/attack(mob/living/target, mob/living/user, attackchain_flags = NONE, damage_multiplier = 1)
	if(!(IS_HERETIC(user) || IS_HERETIC_MONSTER(user)))
		to_chat(user,"<span class='danger'>Чужая воля пронзает ваш разум!</span>")
		user.DefaultCombatKnockdown(100)
		user.dropItemToGround(src, TRUE)
		if(ishuman(user))
			var/mob/living/carbon/human/H = user
			H.apply_damage(rand(force/2, force), BRUTE, pick(BODY_ZONE_L_ARM, BODY_ZONE_R_ARM))
		else
			user.adjustBruteLoss(rand(force/2,force))
		return
	var/damage_before = target.getBruteLoss() + target.getFireLoss()
	. = ..()
	if(QDELETED(target) || QDELETED(src) || target.getBruteLoss() + target.getFireLoss() <= damage_before || !heretic_can_affect(user, target))
		return
	var/datum/antagonist/heretic/heretic = user.mind?.has_antag_datum(/datum/antagonist/heretic)
	if(!heretic)
		return
	var/list/knowledge = heretic.get_all_knowledge()
	var/datum/status_effect/eldritch/mark = target.has_status_effect(mark_type)
	if(mark)
		mark.on_effect()
		for(var/knowledge_type in knowledge)
			var/datum/eldritch_knowledge/entry = knowledge[knowledge_type]
			if(entry.route == route)
				entry.on_mark_detonated(user, target)
	for(var/knowledge_type in knowledge)
		var/datum/eldritch_knowledge/entry = knowledge[knowledge_type]
		if(entry.route == route || entry.route == PATH_SIDE)
			entry.on_eldritch_blade(target, user, TRUE, null)

/obj/item/melee/sickly_blade/attack_self(mob/user)
	var/turf/safe_turf = find_safe_turf(zlevels = z, extended_safety_checks = TRUE)
	if(IS_HERETIC(user) || IS_HERETIC_MONSTER(user))
		if(do_teleport(user, safe_turf, forceMove = TRUE, channel = TELEPORT_CHANNEL_MAGIC))
			to_chat(user,"<span class='warning'>Вы разбиваете [src], и чужая сила подхватывает ваше тело. Ржавые холмы услышали зов.</span>")
		else
			to_chat(user,"<span class='warning'>Вы разбиваете [src], но на зов никто не отвечает.</span>")
	else
		to_chat(user,"<span class='warning'>Вы разбиваете [src].</span>")
	playsound(src, "shatter", 70, TRUE) //copied from the code for smashing a glass sheet onto the ground to turn it into a shard
	qdel(src)

/obj/item/melee/sickly_blade/afterattack(atom/target, mob/user, proximity_flag, click_parameters)
	. = ..()
	if(proximity_flag)
		return
	var/datum/antagonist/heretic/cultie = user.mind?.has_antag_datum(/datum/antagonist/heretic)
	if(!cultie)
		return
	var/list/knowledge = cultie.get_all_knowledge()
	for(var/X in knowledge)
		var/datum/eldritch_knowledge/eldritch_knowledge_datum = knowledge[X]
		if(eldritch_knowledge_datum.route == route || eldritch_knowledge_datum.route == PATH_SIDE)
			eldritch_knowledge_datum.on_ranged_attack_eldritch_blade(target,user,click_parameters)

/obj/item/melee/sickly_blade/examine(mob/user)
	. = ..()
	if(IS_HERETIC(user) || IS_HERETIC_MONSTER(user))
		. += span_notice("Еретик или его слуга может активировать клинок в руке и разбить его, чтобы переместиться в случайное место, обычно безопасное.")

/obj/item/melee/sickly_blade/rust
	name = "ржавый клинок"
	icon = 'modular_bluemoon/icons/obj/heretic.dmi'
	mark_type = /datum/status_effect/eldritch/rust
	route = PATH_RUST
	desc = "Ветхий серповидный клинок с ржавыми зубцами, которые всё ещё легко рвут плоть."
	icon_state = "rust_blade"
	item_state = "rust_blade"
	embedding = list("pain_mult" = 2, "embed_chance" = 25, "fall_chance" = 10, "ignore_throwspeed_threshold" = TRUE)

/obj/item/melee/sickly_blade/ash
	name = "пепельный клинок"
	icon = 'modular_bluemoon/icons/obj/heretic_ash.dmi'
	mark_type = /datum/status_effect/eldritch/ash
	route = PATH_ASH
	desc = "Оплавленный кусок металла, с которого сыплются пепел и шлак. Жар проникает в каждую оставленную им рану."
	icon_state = "ash_blade"
	item_state = "ash_blade"
	force = 25

/obj/item/melee/sickly_blade/flesh
	name = "клинок плоти"
	icon = 'modular_bluemoon/icons/obj/heretic.dmi'
	mark_type = /datum/status_effect/eldritch/flesh
	route = PATH_FLESH
	desc = "Серповидный клинок из искривлённой живой плоти. Под кожей лезвия что-то судорожно сокращается."
	icon_state = "flesh_blade"
	item_state = "flesh_blade"

/obj/item/melee/sickly_blade/void
	name = "клинок Пустоты"
	icon = 'modular_bluemoon/icons/obj/heretic.dmi'
	mark_type = /datum/status_effect/eldritch/void
	route = PATH_VOID
	desc = "Гладкий клинок без украшений. В его поверхности не отражается ничего, даже свет."
	icon_state = "void_blade"
	item_state = "void_blade"
	throwforce = 20

/obj/item/clothing/neck/eldritch_amulet
	name = "зловещий медальон"
	desc = "Медальон с живым глазом в оправе. На шее еретика или его слуги глаз приоткрывается и различает тепло живых тел. В чужих руках он спит."
	icon = 'modular_bluemoon/icons/obj/heretic_medallion.dmi'
	icon_state = "watching_eye_closed"
	w_class = WEIGHT_CLASS_SMALL
	///What trait do we want to add upon equipiing
	var/trait = TRAIT_THERMAL_VISION

/obj/item/clothing/neck/eldritch_amulet/equipped(mob/user, slot)
	. = ..()
	if(ishuman(user) && user.mind && slot == ITEM_SLOT_NECK && (IS_HERETIC(user) || IS_HERETIC_MONSTER(user)))
		ADD_TRAIT(user, trait, REF(src))
		user.update_sight()
	update_icon()

/obj/item/clothing/neck/eldritch_amulet/dropped(mob/user)
	. = ..()
	REMOVE_TRAIT(user, trait, REF(src))
	user.update_sight()
	update_icon()

/obj/item/clothing/neck/eldritch_amulet/piercing
	name = "всевидящий медальон"
	desc = "Медальон с широко раскрывающимся глазом. На шее еретика или его слуги он видит сквозь стены; снятый медальон закрывает веко."
	trait = TRAIT_XRAY_VISION

/obj/item/clothing/head/hooded/cult_hoodie/eldritch
	name = "капюшон еретика"
	icon_state = "eldritch"
	desc = "Пыльный рваный капюшон. Из складок на вас смотрят чужие глаза."
	flags_inv = HIDEMASK|HIDEEARS|HIDEEYES|HIDEFACE|HIDEHAIR|HIDEFACIALHAIR
	flags_cover = HEADCOVERSEYES | HEADCOVERSMOUTH
	flash_protect = 2
	alternate_screams = BLOOD_SCREAMS

/obj/item/clothing/suit/hooded/cultrobes/eldritch
	name = "мантия еретика"
	desc = "Рваное пыльное облачение. В складках ткани шевелятся чужие глаза."
	icon_state = "eldritch_armor"
	item_state = "eldritch_armor"
	flags_inv = HIDESHOES|HIDEJUMPSUIT
	body_parts_covered = CHEST|GROIN|LEGS|FEET|ARMS
	allowed = list(/obj/item/melee/sickly_blade, /obj/item/forbidden_book, /obj/item/living_heart)
	hoodtype = /obj/item/clothing/head/hooded/cult_hoodie/eldritch
	// slightly better than normal cult robes
	armor = list(MELEE = 50, BULLET = 50, LASER = 50,ENERGY = 50, BOMB = 35, BIO = 20, RAD = 0, FIRE = 20, ACID = 20)
	mutantrace_variation = STYLE_DIGITIGRADE|STYLE_NO_ANTHRO_ICON
	alternate_screams = BLOOD_SCREAMS

/obj/item/reagent_containers/glass/beaker/eldritch
	name = "потусторонняя эссенция"
	desc = "Яд для непосвящённых и целительный напиток для тех, кто знает тайны завесы."
	icon = 'icons/obj/eldritch.dmi'
	icon_state = "eldrich_flask"
	list_reagents = list(/datum/reagent/eldritch = 50)

/obj/item/clothing/head/hooded/cult_hoodie/void
	name = "капюшон Пустоты"
	icon_state = "void_cloak"
	flags_inv = NONE
	flags_cover = NONE
	desc = "Чёрный капюшон, который словно поглощает свет. Руны на ткани вспыхивают и ускользают из памяти."
	armor = list(MELEE = 30, BULLET = 30, LASER = 30,ENERGY = 30, BOMB = 15, BIO = 0, RAD = 0, FIRE = 0, ACID = 0)
	obj_flags = NONE | EXAMINE_SKIP

/obj/item/clothing/suit/hooded/cultrobes/void
	name = "плащ Пустоты"
	desc = "Чёрный плащ, который словно поглощает свет. Руны на ткани вспыхивают и ускользают из памяти."
	icon_state = "void_cloak"
	item_state = "void_cloak"
	allowed = list(/obj/item/melee/sickly_blade, /obj/item/forbidden_book, /obj/item/living_heart)
	hoodtype = /obj/item/clothing/head/hooded/cult_hoodie/void
	flags_inv = NONE
	// slightly worse than normal cult robes
	armor = list(MELEE = 30, BULLET = 30, LASER = 30,ENERGY = 30, BOMB = 15, BIO = 0, RAD = 0, FIRE = 0, ACID = 0)
	pocket_storage_component_path = /datum/component/storage/concrete/pockets/void_cloak
	mutantrace_variation = STYLE_DIGITIGRADE|STYLE_NO_ANTHRO_ICON

/obj/item/clothing/suit/hooded/cultrobes/void/ToggleHood()
	if(!iscarbon(loc))
		return
	var/mob/living/carbon/carbon_user = loc
	if(IS_HERETIC(carbon_user) || IS_HERETIC_MONSTER(carbon_user))
		. = ..()
		//We need to account for the hood shenanigans, and that way we can make sure items always fit, even if one of the slots is used by the fucking hood.
		if(suittoggled)
			to_chat(carbon_user,"<span class='notice'>Пустота обволакивает вас, скрывая плащ!</span>")
			obj_flags |= EXAMINE_SKIP
		else if(obj_flags & EXAMINE_SKIP) // ensures that it won't toggle visibility if raising the hood failed
			to_chat(carbon_user,"<span class='notice'>Калейдоскоп цветов рушится вокруг вас, когда плащ становится вновь видимым!</span>")
			obj_flags ^= EXAMINE_SKIP
	else
		to_chat(carbon_user,"<span class='danger'>Не удаётся надеть капюшон!</span>")

/obj/item/clothing/mask/void_mask
	name = "маска безумия"
	desc = "Лицо, застывшее в мучительной гримасе. Если заглянуть в его глаза, что-то посмотрит в ответ."
	icon_state = "mad_mask"
	item_state = "mad_mask"
	w_class = WEIGHT_CLASS_SMALL
	flags_cover = MASKCOVERSEYES
	resistance_flags = FLAMMABLE
	flags_inv = HIDEFACE|HIDEFACIALHAIR
	///Who is wearing this
	var/mob/living/carbon/human/local_user

/obj/item/clothing/mask/void_mask/equipped(mob/user, slot)
	. = ..()
	if(ishuman(user) && user.mind && slot == ITEM_SLOT_MASK)
		local_user = user
		START_PROCESSING(SSobj, src)

		if(IS_HERETIC(user) || IS_HERETIC_MONSTER(user))
			return
		ADD_TRAIT(src, TRAIT_NODROP, CLOTHING_TRAIT)

/obj/item/clothing/mask/void_mask/dropped(mob/M)
	local_user = null
	STOP_PROCESSING(SSobj, src)
	REMOVE_TRAIT(src, TRAIT_NODROP, CLOTHING_TRAIT)
	return ..()

/obj/item/clothing/mask/void_mask/Destroy()
	STOP_PROCESSING(SSobj, src)
	local_user = null
	return ..()

/obj/item/clothing/mask/void_mask/process(delta_time)
	if(QDELETED(local_user) || loc != local_user || local_user.wear_mask != src)
		local_user = null
		return PROCESS_KILL

	if((IS_HERETIC(local_user) || IS_HERETIC_MONSTER(local_user)) && HAS_TRAIT(src,TRAIT_NODROP))
		REMOVE_TRAIT(src, TRAIT_NODROP, CLOTHING_TRAIT)

	for(var/mob/living/carbon/human/human_in_range in viewers(9,local_user))
		if(IS_HERETIC(human_in_range) || IS_HERETIC_MONSTER(human_in_range))
			continue

		SEND_SIGNAL(human_in_range,COMSIG_VOID_MASK_ACT,rand(-2,-20)*delta_time)

		if(DT_PROB(60,delta_time))
			human_in_range.hallucination += 5

		if(DT_PROB(40,delta_time))
			human_in_range.Jitter(5)

		if(DT_PROB(30,delta_time))
			human_in_range.emote(pick("giggle","laugh"))
			human_in_range.adjustStaminaLoss(6)

		if(DT_PROB(25,delta_time))
			human_in_range.Dizzy(5)

/obj/item/melee/rune_knife
	name = "нож для вырезания рун"
	desc = "Холодное стальное лезвие для вырезания рун. Посвящённый может пробудить силу оставленных им знаков."
	icon = 'icons/obj/eldritch.dmi'
	icon_state = "rune_carver"
	flags_1 = CONDUCT_1
	sharpness = SHARP_EDGED
	w_class = WEIGHT_CLASS_SMALL
	wound_bonus = 30
	force = 35
	throwforce = 30
	embedding = list(embed_chance=75, jostle_chance=2, ignore_throwspeed_threshold=TRUE, pain_stam_pct=0.4, pain_mult=3, jostle_pain_mult=5, rip_time=15)
	hitsound = 'sound/weapons/bladeslice.ogg'
	attack_verb = list("атаковал", "рубанул", "уколол", "порезал", "терзал")
	///turfs that you cannot draw carvings on
	var/static/list/blacklisted_turfs = typecacheof(list(/turf/closed,/turf/open/space,/turf/open/lava))
	///A check to see if you are in process of drawing a rune
	var/drawing = FALSE
	///A list of current runes
	var/list/current_runes = list()
	///Max amount of runes
	var/max_rune_amt = 3
	///Linked action
	var/datum/action/innate/rune_shatter/linked_action

/obj/item/melee/rune_knife/examine(mob/user)
	. = ..()
	. += "Предупреждающая руна почти невидима. Она сообщает, кто и где на неё наступил, и сохраняется после срабатывания."
	. += "Хватающая руна ранит обе ноги, сбивает с ног на 5 секунд и заставляет выронить предметы из рук."
	. += "Руна безумия вызывает слабость, головокружение, дрожь, временную слепоту, спутанность сознания и потерю голоса."

/obj/item/melee/rune_knife/Initialize(mapload)
	. = ..()
	linked_action = new(src)

/obj/item/melee/rune_knife/Destroy()
	QDEL_NULL(linked_action)
	. = ..()

/obj/item/melee/rune_knife/pickup(mob/user)
	. = ..()
	linked_action.Grant(user, src)

/obj/item/melee/rune_knife/dropped(mob/user, silent)
	. = ..()
	linked_action.Remove(user, src)

/obj/item/melee/rune_knife/afterattack(atom/target, mob/user, proximity_flag, click_parameters)
	. = ..()
	if(!is_type_in_typecache(target,blacklisted_turfs) && !drawing && proximity_flag)
		carve_rune(target,user,proximity_flag,click_parameters)

///Action of carving runes, gives you the ability to click on floor and choose a rune of your need.
/obj/item/melee/rune_knife/proc/carve_rune(atom/target, mob/user, proximity_flag, click_parameters)
	var/obj/structure/trap/eldritch/elder = locate() in range(1,target)
	if(elder)
		to_chat(user,"<span class='notice'>Нельзя вырезать руны так близко друг к другу!</span>")
		return

	for(var/X in current_runes)
		var/obj/structure/trap/eldritch/eldritch = X
		if(QDELETED(eldritch) || !eldritch)
			current_runes -= eldritch

	if(current_runes.len >= max_rune_amt)
		to_chat(user,"<span class='notice'>Клинок не может поддерживать больше рун!</span>")
		return

	var/list/pick_list = list()
	for(var/E in subtypesof(/obj/structure/trap/eldritch))
		var/obj/structure/trap/eldritch/eldritch = E
		pick_list[initial(eldritch.name)] = eldritch

	drawing = TRUE

	var/type = pick_list[input(user, "Выберите руну", "Вырезание руны") as null|anything in pick_list]
	if(!type)
		drawing = FALSE
		return


	to_chat(user,"<span class='notice'>Вы начинаете вырезать руну...</span>")
	if(!do_after(user,5 SECONDS,target = target))
		drawing = FALSE
		return

	drawing = FALSE
	var/obj/structure/trap/eldritch/eldritch = new type(target)
	eldritch.set_owner(user)
	current_runes += eldritch

/datum/action/innate/rune_shatter
	name = "Разрушение рун"
	desc = "Уничтожает все руны, привязанные к этому клинку."
	background_icon_state = "bg_ecult"
	button_icon_state = "rune_break"
	icon_icon = 'icons/mob/actions/actions_ecult.dmi'
	check_flags = AB_CHECK_CONSCIOUS
	///Reference to the rune knife it is inside of
	var/obj/item/melee/rune_knife/sword

/datum/action/innate/rune_shatter/Grant(mob/user, obj/object)
	sword = object
	return ..()

/datum/action/innate/rune_shatter/Activate()
	for(var/X in sword.current_runes)
		var/obj/structure/trap/eldritch/eldritch = X
		if(!QDELETED(eldritch) && eldritch)
			qdel(eldritch)

/obj/item/eldritch_potion
	name = "напиток дня и ночи"
	desc = "Я никогда не должен был видеть этого."
	icon = 'icons/obj/eldritch.dmi'
	///Typepath to the status effect this is supposed to hold
	var/status_effect

/obj/item/eldritch_potion/attack_self(mob/user)
	. = ..()
	to_chat(user,"<span class='notice'>Вы выпиваете вязкое зелье. Пустой сосуд растворяется в воздухе.</span>")
	effect(user)
	qdel(src)

///The effect of the potion if it has any special one, in general try not to override this and utilize the status_effect var to make custom effects.
/obj/item/eldritch_potion/proc/effect(mob/user)
	if(!iscarbon(user))
		return
	var/mob/living/carbon/carbie = user
	carbie.apply_status_effect(status_effect)

/obj/item/eldritch_potion/crucible_soul
	name = "напиток крепкой души"
	desc = "Позволяет проходить сквозь стены в течение 15 секунд. Затем вы возвращаетесь туда, где выпили зелье."
	icon_state = "crucible_soul"
	status_effect = /datum/status_effect/crucible_soul

/obj/item/eldritch_potion/duskndawn
	name = "напиток заката и рассвета"
	desc = "Позволяет видеть сквозь стены и предметы в течение 60 секунд."
	icon_state = "clarity"
	status_effect = /datum/status_effect/duskndawn

/obj/item/eldritch_potion/wounded
	name = "напиток раненого солдата"
	desc = "В течение 60 секунд лечит каждую рану и защищает от замедления из-за урона. Незначительные раны восстанавливаются на 1 единицу урона в секунду, средние — на 3, критические — на 6."
	icon_state = "marshal"
	status_effect = /datum/status_effect/marshal

/atom/movable/screen/navigate_arrow
	icon = 'icons/effects/multitool_arrows.dmi'
	icon_state = "navigate_arrow_appear"
	name = "указатель направления"
	pixel_x = -32
	pixel_y = -32

/atom/movable/screen/navigate_arrow/Destroy()
	if(hud)
		hud.infodisplay -= src
		INVOKE_ASYNC(hud, TYPE_PROC_REF(/datum/hud, show_hud), hud.hud_version)
	return ..()
