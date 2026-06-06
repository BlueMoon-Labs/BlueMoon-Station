/obj/item/living_heart
	name = "Живое сердце"
	desc = "Связь с другим миром... смажь меня кровью, если хочешь возобновить биение сердца. Нажмите АЛЬТ-ЛКМ, чтобы сбросить жертву."
	icon = 'icons/obj/eldritch.dmi'
	icon_state = "living_heart"
	w_class = WEIGHT_CLASS_SMALL
	///Target
	var/mob/living/carbon/human/target
	var/datum/antagonist/heretic/sac_targetter	//The heretic who used this to acquire the current target - gets cleared when target gets sacrificed.
	COOLDOWN_DECLARE(cooldown)

/obj/item/living_heart/Initialize(mapload)
	. = ..()
	GLOB.living_heart_cache.Add(src)	//Add is better than +=.

/obj/item/living_heart/Destroy()
	GLOB.living_heart_cache.Remove(src)
	if(sac_targetter && target)
		sac_targetter.sac_targetted.Remove(target.real_name)
	return ..()

/obj/item/living_heart/add_context(atom/source, list/context, obj/item/held_item, mob/living/user)
	. = ..()
	if(COOLDOWN_FINISHED(src, cooldown))
		LAZYSET(context[SCREENTIP_CONTEXT_ALT_LMB], INTENT_ANY, "Restart")
	return CONTEXTUAL_SCREENTIP_SET

/obj/item/living_heart/AltClick(mob/user)
	. = ..()
	if(COOLDOWN_FINISHED(src, cooldown))
		COOLDOWN_START(src, cooldown, 180 SECONDS)
		playsound(src, 'sound/misc/bloop.ogg', 50, FALSE)
		GLOB.living_heart_cache.Remove(src)
		if(sac_targetter)
			sac_targetter.sac_targetted.Remove(target.real_name)
		target = null
		user.balloon_alert(user,"<span class='warning'>Состояние Живого Сердца сброшено.</span>")
		to_chat(user,"<span class='warning'>Состояние Живого Сердца сброшено!</span>")
	else
		to_chat(user, "<span class='warning'>Состояние Живого Сердца пока что не может быть сброшено.</span>")

/obj/item/living_heart/attack_self(mob/user)
	. = ..()
	if(!IS_HERETIC(user))
		return
	if(!target)
		to_chat(user,"<span class='warning'>Не найдено ни одной цели. Нужно поместить живое сердце на руну чтобы найти новую цель.</span>")
		return
	var/dist = get_dist(user.loc,target.loc)
	var/dir = get_dir(user.loc,target.loc)

	if(user.z != target.z)
		user.balloon_alert(user,"<span class='warning'>[target.real_name] находится на другом плане существования!</span>")
		to_chat(user,"<span class='warning'>[target.real_name] находится на другом плане существования!</span>")
	else
		switch(dist)
			if(0 to 15)
				user.balloon_alert(user,"<span class='warning'>[target.real_name] рядом со мной. Он находится на [dir2text_ru(dir)] от меня!</span>")

				to_chat(user,"<span class='warning'>[target.real_name] облизко ко мне. Он находится на [dir2text_ru(dir)] от меня!</span>")
			if(16 to 31)
				user.balloon_alert(user,"<span class='warning'>[target.real_name] поблизости со мной. Он находится на [dir2text_ru(dir)] от меня!</span>")

				to_chat(user,"<span class='warning'>[target.real_name] поблизости со мной. Он находится на [dir2text_ru(dir)] от меня!</span>")
			if(32 to 222)
				user.balloon_alert(user,"<span class='warning'>[target.real_name] далеко от меня. Он находится на [dir2text_ru(dir)] от меня!</span>")

				to_chat(user,"<span class='warning'>[target.real_name] далеко от меня. Он находится на [dir2text_ru(dir)] от меня!</span>")
			else
				user.balloon_alert(user,"<span class='warning'>[target.real_name] находится за пределами моих возможностей.</span>")

				to_chat(user,"<span class='warning'>[target.real_name] находится за пределами моих возможностей.</span>")

	if(target.stat == DEAD)
		user.balloon_alert(user,"<span class='warning'>[target.real_name] мертва. Нужно перенести её на руну трансмутации!</span>")

		to_chat(user,"<span class='warning'>[target.real_name] мертва. Нужно перенести её на руну трансмутации!</span>")

/obj/item/melee/sickly_blade
	name = "Болезненный клинок"
	desc = "Клинок похожий на серп болезненно зелёного цвета, украшенный арнаментом из глаза. Вам кажется что из него за вами кто-то наблюдает..."
	icon = 'icons/obj/eldritch.dmi'
	icon_state = "eldritch_blade"
	item_state = "eldritch_blade"
	lefthand_file = 'icons/mob/inhands/64x64_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/64x64_righthand.dmi'
	inhand_x_dimension = 64
	inhand_y_dimension = 64
	flags_1 = CONDUCT_1
	sharpness = SHARP_EDGED
	w_class = WEIGHT_CLASS_NORMAL
	force = 28
	throwforce = 15
	hitsound = 'sound/weapons/bladeslice.ogg'
	attack_verb = list("attacked", "slashed", "stabbed", "sliced", "tore", "lacerated", "ripped", "diced", "rended")
	wound_bonus = 30
	bare_wound_bonus = 35

/obj/item/melee/sickly_blade/attack(mob/living/target, mob/living/user)
	if(!(IS_HERETIC(user) || IS_HERETIC_MONSTER(user)))
		to_chat(user,"<span class='danger'>Чувствую как импульс чужеродного интеллекта пронзает мой разум!</span>")
		user.DefaultCombatKnockdown(100)
		user.dropItemToGround(src, TRUE)
		if(ishuman(user))
			var/mob/living/carbon/human/H = user
			H.apply_damage(rand(force/2, force), BRUTE, pick(BODY_ZONE_L_ARM, BODY_ZONE_R_ARM))
		else
			user.adjustBruteLoss(rand(force/2,force))
		return
	return ..()

/obj/item/melee/sickly_blade/attack_self(mob/user)
	var/turf/safe_turf = find_safe_turf(zlevels = z, extended_safety_checks = TRUE)
	if(IS_HERETIC(user) || IS_HERETIC_MONSTER(user))
		if(do_teleport(user, safe_turf, forceMove = TRUE, channel = TELEPORT_CHANNEL_MAGIC))
			to_chat(user,"<span class='warning'>Когда я разбиваю [src], начинаю чувствовать присутствие неведомой энергии пронзающей моё тело. Ржавые холмы услышали мой зов...</span>")
		else
			to_chat(user,"<span class='warning'>Я разбиваю [src], но моя мольба остаётся не услышанной.</span>")
	else
		to_chat(user,"<span class='warning'>Я разбиваю [src].</span>")
	playsound(src, "shatter", 70, TRUE) //copied from the code for smashing a glass sheet onto the ground to turn it into a shard
	qdel(src)

/obj/item/melee/sickly_blade/afterattack(atom/target, mob/user, proximity_flag, click_parameters)
	. = ..()
	var/datum/antagonist/heretic/cultie = user.mind.has_antag_datum(/datum/antagonist/heretic)
	if(!cultie)
		return
	var/list/knowledge = cultie.get_all_knowledge()
	for(var/X in knowledge)
		var/datum/eldritch_knowledge/eldritch_knowledge_datum = knowledge[X]
		if(proximity_flag)
			eldritch_knowledge_datum.on_eldritch_blade(target,user,proximity_flag,click_parameters)
		else
			eldritch_knowledge_datum.on_ranged_attack_eldritch_blade(target,user,click_parameters)

/obj/item/melee/sickly_blade/examine(mob/user)
	. = ..()
	if(IS_HERETIC(user) || IS_HERETIC_MONSTER(user))
		. += "<span class='notice'><B>Еретик (или его слуга) может разбить клинок чтобы телепортироваться в случайное место, чаще всего безопасное, после активации его в руке.</B></span>"

/obj/item/melee/sickly_blade/rust
	name = "Ржавый клинок"
	desc = "Этот серповидный клинок довольно ветх и ржавеет. Но он продолжается кусаться и разрывать плоть и кости своими ржавыми зубцами."
	icon_state = "rust_blade"
	item_state = "rust_blade"
	embedding = list("pain_mult" = 4, "embed_chance" = 75, "fall_chance" = 10, "ignore_throwspeed_threshold" = TRUE)

/obj/item/melee/sickly_blade/ash
	name = "Пепельный клинок"
	desc = "Расплавленный и необработанный кусок металла осыпающийся пеплом и шлаком. Он стремиться быть чем-то большим разрезая наполенные пеплом раны."
	icon_state = "ash_blade"
	item_state = "ash_blade"
	force = 35

/obj/item/melee/sickly_blade/flesh
	name = "Мясной клинок"
	desc = "Серповидный клинок, созданный из искажённой плоти существа. Понимая это, он стремится распространить на других страдания, которые он перенес в ходе этого превращения."
	icon_state = "flesh_blade"
	item_state = "flesh_blade"

/obj/item/melee/sickly_blade/void
	name = "Пустотный клинок"
	desc = "Лишенный каких-либо излишеств, этот клинок отражает ничто. Он представляет собой настоящее изображение чистоты и хаоса, который наступаю после конца всего."
	icon_state = "void_blade"
	item_state = "void_blade"
	throwforce = 35

/obj/item/clothing/neck/eldritch_amulet
	name = "Тёплый древний медальен"
	desc = "Странный медальен. Глядя сквозь кристаллическую линзу, мир вокруг тает. Вы видите свое биение сердца и пульс тысячи других."
	icon = 'icons/obj/eldritch.dmi'
	icon_state = "eye_medalion"
	w_class = WEIGHT_CLASS_SMALL
	///What trait do we want to add upon equipiing
	var/trait = TRAIT_THERMAL_VISION

/obj/item/clothing/neck/eldritch_amulet/equipped(mob/user, slot)
	. = ..()
	if(ishuman(user) && user.mind && slot == ITEM_SLOT_NECK && (IS_HERETIC(user) || IS_HERETIC_MONSTER(user)))
		ADD_TRAIT(user, trait, CLOTHING_TRAIT)
		user.update_sight()

/obj/item/clothing/neck/eldritch_amulet/dropped(mob/user)
	. = ..()
	REMOVE_TRAIT(user, trait, CLOTHING_TRAIT)
	user.update_sight()

/obj/item/clothing/neck/eldritch_amulet/piercing
	name = "Пронзённый древний медальон"
	desc = "Странный медальон. Если заглянуть сквозь кристаллическую линзу, свет преломится и искажается открывая новые оттенки цветов. Вы видите себя, отраженного в каскаде зеркал, принявшего невероятную форму."
	trait = TRAIT_XRAY_VISION

/obj/item/clothing/head/hooded/cult_hoodie/eldritch
	name = "Зловещий капюшон"
	icon_state = "eldritch"
	desc = "Порванный, запыленный капюшон. Странные глаза смотрят на вас изнутри."
	flags_inv = HIDEMASK|HIDEEARS|HIDEEYES|HIDEFACE|HIDEHAIR|HIDEFACIALHAIR
	flags_cover = HEADCOVERSEYES | HEADCOVERSMOUTH
	flash_protect = 2
	alternate_screams = BLOOD_SCREAMS

/obj/item/clothing/suit/hooded/cultrobes/eldritch
	name = "Зловещий балахон"
	desc = "Рваная, пыльная роба. Странные глаза смотрят на вас изнутри.."
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
	name = "Фляжка с древней эссенцией"
	desc = "Токсично для неведующих умов, но освежает тех, кто знает секреты завесы."
	icon = 'icons/obj/eldritch.dmi'
	icon_state = "eldrich_flask"
	list_reagents = list(/datum/reagent/eldritch = 50)

/obj/item/clothing/head/hooded/cult_hoodie/void
	name = "Пустотный капюшон"
	icon_state = "void_cloak"
	flags_inv = NONE
	flags_cover = NONE
	desc = "Черный, как смола и не отражающий свет капюшон. Рунические символы украшают его внешнюю поверхность, с каждой их вспышкой вы теряете понимание того, что видите."
	armor = list(MELEE = 30, BULLET = 30, LASER = 30,ENERGY = 30, BOMB = 15, BIO = 0, RAD = 0, FIRE = 0, ACID = 0)
	obj_flags = NONE | EXAMINE_SKIP

/obj/item/clothing/suit/hooded/cultrobes/void
	name = "Пустотный плащ"
	desc = "Черный, как смола и не отражающий свет плащ. Рунические символы украшают его внешнюю поверхность, с каждой их вспышкой вы теряете понимание того, что видите."
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
			to_chat(carbon_user,"<span class='notice'>Пустота обволакивает меня, делая плащ невидимым!</span>")
			obj_flags |= EXAMINE_SKIP
		else if(obj_flags & EXAMINE_SKIP) // ensures that it won't toggle visibility if raising the hood failed
			to_chat(carbon_user,"<span class='notice'>Калейдоскоп цветов рушится вокруг вас, когда плащ становится вновь видимым!</span>")
			obj_flags ^= EXAMINE_SKIP
	else
		to_chat(carbon_user,"<span class='danger'>Не могу натянуть капюшон на голову!</span>")

/obj/item/clothing/mask/void_mask
	name = "Маска бездны"
	desc = "Маска, созданная из всевозможных страданий живых существ, вы можете посмотреть в ее глаза и заметить, что что-то смотрит в ответ."
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

/obj/item/clothing/mask/void_mask/process(delta_time)
	if(!local_user)
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
	name = "Нож для резьбы"
	desc = "Холодная сталь, чистая, совершенная, этот нож может резать пол разными способами, но лишь немногие смогут пробудить опасности что представляет реальность скрывающаяся в этих рисунках."
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
	attack_verb = list("attacked", "slashed", "stabbed", "sliced", "tore", "lacerated", "ripped", "diced", "rended")
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
	. += "Им можно вырезать 'Резьбу предосторожности' - почти невидимую руну, которая, если на нее наступить, дает вам подсказку о том, где кто-то стоял на ней и кто это был, и не разрушается, если на нее наступить."
	. += "Им можно вырезать 'Резьбу захвата' - если наступить на ее, она нанесет тяжелый урон ногам и оглушит на 5 секунд."
	. += "Им можно вырезать 'Резьбу безумия' - если на её наступить, это вызовет головокружение, головную боль, временную слепоту, спутанность сознания, заикание и невнятность."

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
		to_chat(user,"<span class='notice'>Не могу рисовать руны так близко друг к другу!</span>")
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

	var/type = pick_list[input(user,"Choose the rune","Rune") as null|anything in pick_list ]
	if(!type)
		drawing = FALSE
		return


	to_chat(user,"<span class='notice'>Начинаю чертить руну...</span>")
	if(!do_after(user,5 SECONDS,target = target))
		drawing = FALSE
		return

	drawing = FALSE
	var/obj/structure/trap/eldritch/eldritch = new type(target)
	eldritch.set_owner(user)
	current_runes += eldritch

/datum/action/innate/rune_shatter
	name = "Разрушение рун"
	desc = "Устраняет все руны привязанные к этому клинку."
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
	name = "Напиток Дня и Ночи"
	desc = "Я никогда не должен был видеть этого."
	icon = 'icons/obj/eldritch.dmi'
	///Typepath to the status effect this is supposed to hold
	var/status_effect

/obj/item/eldritch_potion/attack_self(mob/user)
	. = ..()
	to_chat(user,"<span class='notice'>Я выпиваю зелье, и вместе с вязкой жидкостью стакан дематериализуется.</span>")
	effect(user)
	qdel(src)

///The effect of the potion if it has any special one, in general try not to override this and utilize the status_effect var to make custom effects.
/obj/item/eldritch_potion/proc/effect(mob/user)
	if(!iscarbon(user))
		return
	var/mob/living/carbon/carbie = user
	carbie.apply_status_effect(status_effect)

/obj/item/eldritch_potion/crucible_soul
	name = "Напиток Крепкой Души"
	desc = "Позволяет проходить сквозь стены в течение 15 секунд, по истечении этого времени вы телепортируетесь в свое первоначальное местоположение."
	icon_state = "crucible_soul"
	status_effect = /datum/status_effect/crucible_soul

/obj/item/eldritch_potion/duskndawn
	name = "Напиток Заката и Рассвета"
	desc = "Позволяет вам четко видеть сквозь стены и предметы в течение 60 секунд."
	icon_state = "clarity"
	status_effect = /datum/status_effect/duskndawn

/obj/item/eldritch_potion/wounded
	name = "Напиток Раненного солдата"
	desc = "В течение следующих 60 секунд каждая рана будет заживать на вас, незначительные раны заживают на 1 единицу урона в секунду, средние - на 3, а критические - на 6. Вы также становитесь невосприимчивы к замедленнию от урона."
	icon_state = "marshal"
	status_effect = /datum/status_effect/marshal
