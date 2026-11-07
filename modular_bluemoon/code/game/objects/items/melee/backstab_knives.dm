/**
 * (МГЕ, МУЖИКИ!)
 * Несколько ножей, мгновенно убивающих жертв в спину.
 */

/obj/item/kitchen/knife/backstabber
	name = "Strange Butterfly Knife"
	icon = 'modular_splurt/icons/obj/items_and_weapons.dmi'
	icon_state = "butterflyknife_open"
	item_state = "knife"
	desc = "A strange butterfly knife, impeccably sharpened and quite well-maintained. For some reason, you have an irresistible desire to strike someone in the back with it..."
	embedding = list("pain_mult" = 6, "embed_chance" = 50, "fall_chance" = 10, "ignore_throwspeed_threshold" = TRUE)
	resistance_flags = FIRE_PROOF
	custom_materials = list(/datum/material/iron=12000, /datum/material/bluespace=4000, /datum/material/titanium=2000)
	slot_flags = ITEM_SLOT_POCKETS | ITEM_SLOT_BELT | ITEM_SLOT_BACK
	force = 5 // Не поощряем удары в лицо
	throwforce = 5
	wound_bonus = 4
	bare_wound_bonus = 3
	attack_verb = list("facestabbed")
	bayonet = FALSE
	var/can_transform = TRUE // Может ли быть превращён в другой нож. Изменяется на FALSE после превращения.
	var/unique = FALSE // Уникальная вариация. В неё нельзя превратить другой нож.
	var/cooldown_icon_state = "butterflyknife" // Иконка ножа, пока он находится на кулдауне.
	var/start_cooldown_message = "складывается с тихим щелчком" // Сообщение при начале кулдауна, воспроизводится носителю
	var/end_cooldown_message = "внезапно сам собой раскладывается, готовый к новым убийствам" // при окончании кулдауна
	var/cooldown_time = 30 SECONDS // Время кулдауна
	var/is_on_cooldown = FALSE // Находится ли нож сейчас на кулдауне
	var/silent_backstab = FALSE // Убивает ли полностью бесшумно
	var/peaceful = FALSE // Не является мирной вариацией, которая не может навредить
	var/speech_after_backstab = TRUE // Воспроизводятся ли фразы шпиона™ после убийства. Если активен silent_backstab, то они в любом случае воспроизводиться не будут. Может переключаться игроком.
	var/custom_backstab_sound = "" // Кастомный звук удара в спину (без него будет воспроизводиться звук крита из TF2)

/obj/item/kitchen/knife/backstabber/examine(mob/user)
	. = ..()
	if(can_transform)
		. += "\n\n<span class='notice'>It seems that the quick replacement system of this knife works, and you can choose a new murder weapon <span class='boldnotice'>by using it in your hand!</span></span>"
	if(is_on_cooldown)
		. += "\n\n<span class='warning'>It's unlikely that this knife can stab anyone right now... give it some time</span>"
	if(silent_backstab)
		. += "\n\n<span class='notice'>Apparently, this knife is VERY good for covert killings</span>"
	else // Если он убивает тихо, то не важно, включен ли спикер
		. += "\n\n<span class='notice'>It seems, that after-backstab-speech subsystem is currently <span class='boldnotice'>[speech_after_backstab ? "ON" : "OFF"]</span> and can be toggled with <span class='boldnotice'>Alt+Click!</span></span>"
	if(peaceful)
		. += "\n\n<span class='notice'>Don't you think this knife is uncapable of killing someone at all?</span>"

/obj/item/kitchen/knife/backstabber/attack_self(mob/user)
	if(istype(user, /mob/living/carbon) && can_transform)
		// Жёстко накопипастил с нуллродов, целый прок говнокода
		var/obj/item/kitchen/knife/backstabber/new_knife
		var/list/possible_knives = subtypesof(/obj/item/kitchen/knife/backstabber)
		var/list/display_names = list()
		var/list/knife_icons = list()
		for(var/k in possible_knives)
			var/obj/item/kitchen/knife/backstabber/knife_type = k
			if(!initial(knife_type.unique))
				display_names[initial(knife_type.name)] = knife_type
				knife_icons += list(initial(knife_type.name) = image(icon = initial(knife_type.icon), icon_state = initial(knife_type.icon_state)))

		knife_icons = sort_list(knife_icons)

		var/choice = show_radial_menu(user, src , knife_icons, radius = 42, require_near = TRUE)
		if(!choice || !istype(user) || QDELETED(src) || !can_transform || user.incapacitated() || !user.is_holding(src))
			return

		var/A = display_names[choice]
		new_knife = new A

		if(new_knife)
			new_knife.can_transform = FALSE
			if(is_on_cooldown)
				new_knife.go_on_cooldown()
			new_knife.speech_after_backstab = speech_after_backstab
			to_chat(user, "<span class='warning'>[src] загорается ярким светом и исчезает, а в руках у вас появляется новенький [new_knife]!</span>")
			qdel(src)
			user.put_in_active_hand(new_knife)
	else
		return ..()

/obj/item/kitchen/knife/backstabber/AltClick(mob/living/carbon/user)
	. = ..()
	if(!istype(user) || !user.canUseTopic(src, BE_CLOSE) || silent_backstab)
		return
	toggle_speaker()
	return TRUE

/obj/item/kitchen/knife/backstabber/proc/toggle_speaker()
	if(speech_after_backstab)
		if(item_flags & IN_INVENTORY && istype(loc, /mob/living/carbon)) // Воспроизводится только тому, у кого он в инвентаре
			var/mob/living/carbon/user = loc
			to_chat(user, "<span class='boldnotice'>Вы отключаете воспроизведение фраз после убийства у [src]. Ассоциация разочарована в вас.</span>")
		speech_after_backstab = FALSE
	else
		if(item_flags & IN_INVENTORY && istype(loc, /mob/living/carbon))
			var/mob/living/carbon/user = loc
			to_chat(user, "<span class='boldnotice'>Вы вновь включаете воспроизведение фраз после убийства у [src]. Так держать!</span>")
		speech_after_backstab = TRUE

// Запуск кулдауна. Время может быть умножено на соответствующий мультипликатор
/obj/item/kitchen/knife/backstabber/proc/go_on_cooldown(cooldown_multiplier = 1)
	if(item_flags & IN_INVENTORY && istype(loc, /mob/living/carbon))
		var/mob/living/carbon/user = loc
		to_chat(user, "<span class='boldnotice'>[src] [start_cooldown_message].</span>")
	if(cooldown_icon_state) // Меняем иконку на кулдауновую, если таковая имеется
		icon_state = cooldown_icon_state
	is_on_cooldown = TRUE
	// Возвращаем в исходное положение по окончанию кулдауна с учётом мультипликатора
	addtimer(CALLBACK(src, PROC_REF(end_stab_cooldown)), cooldown_time * cooldown_multiplier)

// Окончание кулдауна
/obj/item/kitchen/knife/backstabber/proc/end_stab_cooldown()
	if(item_flags & IN_INVENTORY && istype(loc, /mob/living/carbon))
		var/mob/living/carbon/user = loc
		to_chat(user, "<span class='boldnotice'>[src] [end_cooldown_message].</span>")
	if(cooldown_icon_state)
		icon_state = initial(icon_state)
	is_on_cooldown = FALSE

// Проверка одежды носителя. Возвращает множитель стиля, на который после будет умножено время кулдауна
/obj/item/kitchen/knife/backstabber/proc/check_style(mob/living/carbon/murderer)
	var/style_rate = 1
	var/list/stylish_clothes = list(
		/obj/item/clothing/accessory/waistcoat,
		/obj/item/clothing/accessory/suitjacket,
		/obj/item/clothing/under/suit,
		/obj/item/clothing/gloves/color/white,
		/obj/item/clothing/gloves/color/black,
		/obj/item/clothing/gloves/color/latex,
		/obj/item/clothing/gloves/evening,
		/obj/item/clothing/under/misc/assistantformal,
		/obj/item/clothing/under/rank/security/officer/formal/sol/armorless,
		/obj/item/clothing/under/rank/security/head_of_security/formal,
		/obj/item/clothing/under/rank/security/officer/formal,
		/obj/item/clothing/under/rank/security/warden/formal,
		/obj/item/clothing/head/fedora,
		/obj/item/clothing/head/that,
		/obj/item/clothing/shoes/laceup
		)
	var/list/items = murderer.get_contents()
	for(var/gear in items)
		var/obj/item/gearitem = gear
		if(gearitem.blood_DNA)
			style_rate *= 1.1
		else
			for(var/stylish_gear in stylish_clothes)
				if(istype(gear, stylish_gear))
					style_rate *= 0.9
	style_rate = clamp(style_rate, 0.5, 2)
	return style_rate

/obj/item/kitchen/knife/backstabber/attack(mob/living/carbon/M, mob/living/carbon/user)
	if(is_on_cooldown)
		to_chat(user, "<span class='warning'>Твоему [src] нужно немного времени...</span>")
		return
	if(!istype(user, /mob/living/carbon))
		. = ..()
		return
	if(!istype(M, /mob/living/carbon))
		. = ..()
		return
	if(user == M)
		to_chat(user, "<span class='warning'>Я слишком ПРОФЕССИОНАЛЕН, чтобы порезаться собственным кинжалом!</span>")
		return
	user.DelayNextAction(CLICK_CD_MELEE) // На всякий
	if(M.stat == DEAD)
		to_chat(user, "<span class='warning'>В издевательствах над трупами нет шарма!</span>")
		return
	if(user.lying || (M.dir != user.dir && !M.lying)) // Чтобы мамины робустеры не абузили ползки
		to_chat(user, "<span class='warning'>Какой позорный удар! Настоящие профессионалы бьют В СПИНУ!</span>")
		. = ..()
		return
	// Летальные ножи нельзя использовать, будучи пацифистом
	if(HAS_TRAIT(user, TRAIT_PACIFISM) && !peaceful)
		to_chat(user, "<span class='warning'>Ты не можешь заставить себя сделать это!</span>")
		if(!silent_backstab)
			user.visible_message("<span class='boldwarning'>[user] заносит [src] над спиной [M], но вовремя останавливается! </span>")
		return
	if(!silent_backstab) // Воспроизводим сообщение об ударе в спину, если нож не тихий
		user.visible_message("<span class='boldwarning'>[M] не успевает и обернуться, как [user] с невероятной точностью вонзает [src] [M.ru_emu()] в спину! </span>")
	// Щит на спине блокирует удар
	var/obj/item/backpack = M.get_item_by_slot(ITEM_SLOT_BACK)
	if(backpack && istype(backpack, /obj/item/shield))
		user.visible_message("<span class='warning'>[src] рикошетит от [backpack] на [M.ru_emu()] спине, сбивая щит на пол!</span>")
		playsound(user, 'sound/weapons/parry.ogg', 90, TRUE)
		user.do_attack_animation(M)
		M.dropItemToGround(backpack)
		go_on_cooldown()
		return
	// Жертва бессмертна
	if((M.status_flags & GODMODE || HAS_TRAIT(M, TRAIT_NODEATH)) && !peaceful)
		if(!silent_backstab)
			M.visible_message("<span class='warning'>[src] необъяснимым образом рикошетит от спины жертвы...</span>")
			playsound(user, 'sound/weapons/parry.ogg', 90, TRUE)
			user.do_attack_animation(M)
		go_on_cooldown()
		return
	// Какие-то имбовые мобы
	if(M.health > 300 && !peaceful)
		if(!silent_backstab)
			M.visible_message("<span class='warning'>[src] наносит страшный удар, который, однако, не может убить [M]!</span>")
			user.do_attack_animation(M)
			playsound(M, 'sound/weapons/slash.ogg', 100, 1)
			if(user != M)
				user.do_attack_animation(M)
		M.apply_damage(250, BRUTE, BODY_ZONE_CHEST, wound_bonus=CANT_WOUND)
		go_on_cooldown()
		return
	backstab(M, user) // Собственно, наносим удар в спину

/obj/item/kitchen/knife/backstabber/proc/backstab(mob/living/carbon/victim, mob/living/carbon/user)
	// Бессмертный моб. При суициде он всё ещё может пройти проверки выше
	if((victim.status_flags & GODMODE || HAS_TRAIT(victim, TRAIT_NODEATH)) && !peaceful)
		return
	// Логи
	if(victim == user)
		log_admin("[user] ([key_name(user)]) suicided, backstabbing himself with [src]")
	else
		log_admin("[user] ([key_name(user)]) backstabbed [victim] ([key_name(victim)]) with [src]")
	// Звук и анимация убийства, а также крик жертвы с определённым шансом
	if(!silent_backstab)
		if(user != victim)
			user.do_attack_animation(victim)
		var/bs_sound = "modular_bluemoon/sound/effects/critical_hit.ogg"
		if(custom_backstab_sound)
			bs_sound = custom_backstab_sound
		playsound(victim, bs_sound, 100, 1)
		if(!victim.mind?.miming && !HAS_TRAIT(victim, TRAIT_MUTE) && victim.IsVocal() && prob(30))
			if(isrobotic(victim))
				victim.emote("buzz2")
			else
				if(victim.is_muzzled())
					victim.emote("moan")
				else
					victim.emote(pick("scream", "realagony"))
	// deathgasp тут немного мешался, так что я решил его убрать с помощью комы. Не самое лучшее решение, даа
	var/enforced_deathcoma = FALSE
	if(!peaceful && !HAS_TRAIT(victim, TRAIT_DEATHCOMA))
		ADD_TRAIT(victim, TRAIT_DEATHCOMA, "backstab")
		enforced_deathcoma = TRUE
	// Сам эффект ножа, убивающий жертву
	apply_backstab_effect(victim, user)
	// Жертва не помнит смерть от мгновенного удара в спину
	if(victim.stat == DEAD)
		victim.mind?.forget_death(DEATH_FORGETFULNESS_REASON_IMMEDIATE)
	if(enforced_deathcoma)
		REMOVE_TRAIT(victim, TRAIT_DEATHCOMA, "backstab")
	// Произносим фразу, если спикер включён
	if(!silent_backstab && speech_after_backstab && !user.mind?.miming)
		// Общие фразы
		var/list/spy_phrases = list(
			"Вы испачкали мне костюм!",
			"О, извините!",
			"О Боже, что я тут устроил[user.ru_a()]!",
			"Спасибо, что были так любезны...",
			"Простите, что без приглашения!",
			"Обычный рабочий день...")
		// Узнаём работу по карточке жертвы
		var/job_on_the_card = ""
		if(victim.get_idcard())
			var/obj/item/card/id/card = victim.get_idcard()
			job_on_the_card = card.assignment ? ckey(card.get_job_name()) : ""
			job_on_the_card = lowertext(job_on_the_card)
		// Рофлы над сверхтяжёлыми
		if(victim.mob_weight > MOB_WEIGHT_NORMAL)
			spy_phrases = list(
				"Это ЖИРНАЯ точка в твоей жизни!",
				"Ну, толстяк, даже не ловко как-то!")
		// Рофлы над офицерами
		if(findtext(job_on_the_card, "security") || findtext(job_on_the_card, "detective") || findtext(job_on_the_card, "warden"))
			spy_phrases = list(
				"Может быть, в следующий раз пришлют настоящего бойца!",
				"Тебе поставят памятник \"Зелёный Салага\"!")
		// Рофлы над медиками
		if(findtext(job_on_the_card, "medic") || findtext(job_on_the_card, "doctor") || findtext(job_on_the_card, "virolog") || findtext(job_on_the_card, "geneti"))
			spy_phrases = list(
				"Всё-таки смех - лучшее лекарство!",
				"Судя по вашей кардиограмме... вы мертвы!")
		user.say(pick(spy_phrases), forced = "backstab")
	// Проверка то, насколько стильным было убийство, чтобы изменить итоговый кулдаун
	var/style = check_style(user)
	if(!silent_backstab && !speech_after_backstab)
		style *= 1.1 // Без фразы не так стильно!
	if(style < 1)
		to_chat(user, "<span class='notice'>\"Это было стильно! Даю этому убийству [round((1 - style) * 100)] очков!\"</span>")
	if(style > 1)
		to_chat(user, "<span class='notice'>\"Фу! Настоящие профессионалы не делают это в простой грязной одежде! Минус [round((style - 1) * 100)] очков!\"</span>")
	// Уходим на кулдаун
	go_on_cooldown(style)

/obj/item/kitchen/knife/backstabber/proc/apply_backstab_effect(mob/living/carbon/victim, mob/living/carbon/user)
	if(!silent_backstab)
		victim.visible_message("<span class='warning'>[victim] падает на землю и перестаёт подавать признаки жизни...</span>")
	victim.apply_damage(200, BRUTE, BODY_ZONE_CHEST, wound_bonus=CANT_WOUND)
	victim.death(FALSE)

/obj/item/kitchen/knife/backstabber/suicide_act(mob/user)
	if(HAS_TRAIT(user, TRAIT_PACIFISM))
		user.visible_message("<span class='suicide'>[user] заносит над собой [src], но не решается нанести удар, падая на землю и начиная плакать от беспомощности!</span>")
		user.emote("cry") // gonna cry?
		return (SHAME)
	if(peaceful || is_on_cooldown)
		if(!silent_backstab)
			user.visible_message("<span class='suicide'>[user] безнадёжно пытается ударить себя своим [src], но это оружие оказывается неспособно [user.ru_ego()] убить!</span>")
		return (SHAME)
	if(!silent_backstab)
		user.visible_message("<span class='suicide'>[user] заворачивает руку под, казалось бы, невозможным углом, и ударяет себя в спину своим [src]!</span>")
	backstab(user, user)
	return (BRUTELOSS)

// Супер-стелсовый нож
/obj/item/kitchen/knife/backstabber/silent
	name = "Your Eternal Reward"
	desc  = "It seems to be a REALLY stealthy knife"
	icon = 'icons/obj/kitchen.dmi'
	icon_state = "buckknife"
	silent_backstab = TRUE
	cooldown_icon_state = null
	cooldown_time = 1.5 MINUTES
	start_cooldown_message = "потухает и становится холоднее на ощупь"
	end_cooldown_message = "вновь загорается странным светом"

/obj/item/kitchen/knife/backstabber/silent/apply_backstab_effect(mob/living/carbon/victim, mob/living/carbon/user)
	to_chat(victim, "<span class='userdanger'>Стоп, что это б...</span>")
	if(victim != user)
		to_chat(user, "<span class='boldwarning'>Ты с невероятной точностью вонзаешь [src] в спину [victim], после чего [victim.ru_ego()] тело оседает на землю в беззвучном крике и становится невидимым!</span>")
	var/initial_alpha = victim.alpha
	animate(victim, alpha = 0, time = 1 SECONDS) // жертва исчезает
	victim.apply_damage(75, BRUTE, BODY_ZONE_CHEST, wound_bonus=CANT_WOUND)
	victim.death(FALSE)
	addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(victim_fade_in), victim, initial_alpha, 0.3 SECONDS), 10 SECONDS) // появляется через 10 секунд

// Такая себе реализация через глобальный прок, но мне было лень придумывать более адекватное решение, не привязанное к ножу
/proc/victim_fade_in(mob/target, required_alpha, fade_time)
	animate(target, alpha = required_alpha, time = fade_time)
	target.visible_message("<span class='warning'>Тело [target] внезапно появляется...</span>")

// Сосулька (фановое)
/obj/item/kitchen/knife/backstabber/icicle
	name = "Strange Icicle"
	desc = "A very sharp piece of ice. Why this thing looks like you can stab someone in back with it?"
	cooldown_icon_state = null
	cooldown_time = 35 SECONDS
	icon = 'icons/obj/lollipop.dmi'
	icon_state = "lollipop_stick"
	item_state = "lollipop_stick"
	start_cooldown_message = "будто бы слегка плавится, становясь менее острой"
	end_cooldown_message = "вновь начинает казаться самым острым куском льда из тех, которые вы видели"

/obj/item/kitchen/knife/backstabber/icicle/apply_backstab_effect(mob/living/carbon/victim, mob/living/carbon/user)
	victim.visible_message("<span class='warning'>[victim] внезапно застывает и превращается в ледяную статую!</span>")
	// Создаём статую в виде жертвы
	var/obj/structure/statue/custom/icicle_knife_statue/new_statue = new(get_turf(victim))
	new_statue.alpha = 40 // Она сначала еле видима, потом становится почти полупрозрачной
	new_statue.set_visuals(victim)
	new_statue.set_custom_materials(list(/datum/material/snow=MINERAL_MATERIAL_AMOUNT*5))
	var/mutable_appearance/ma = victim
	new_statue.dir = ma.dir
	new_statue.name = "ice statue of [ma.name]"
	new_statue.desc = "A statue depicting [ma.name], made from ice... This thing feels strange..."
	new_statue.victim = victim
	victim.forceMove(new_statue) // Прячем в статую жертву
	victim.death(FALSE)
	animate(new_statue, alpha = 160, time = 1 SECONDS) // Статуя появляется

/obj/structure/statue/custom/icicle_knife_statue
	name = "ice statue"
	var/mob/living/carbon/victim = null // Жертва внутри статуи

/obj/structure/statue/custom/icicle_knife_statue/Initialize(mapload)
	. = ..()
	addtimer(CALLBACK(src, PROC_REF(eject_victim)), 1 MINUTES) // Плавится через одну минуту

/obj/structure/statue/custom/icicle_knife_statue/proc/eject_victim(delete_statue = TRUE)
	if(victim && !QDELETED(victim))
		victim.forceMove(get_turf(src))
		victim.visible_message("<span class='boldwarning'>[victim.name] выпадает из [name]!</span>")
		playsound(src, "bodyfall", 30, 1)
		victim = null
	if(delete_statue)
		qdel(src)

/obj/structure/statue/custom/icicle_knife_statue/Destroy()
	eject_victim(FALSE)
	victim = null
	return ..()

/obj/structure/statue/custom/icicle_knife_statue/attackby(obj/item/W, mob/living/user, params)
	add_fingerprint(user)
	if(!(flags_1 & NODECONSTRUCT_1))
		if(default_unfasten_wrench(user, W))
			return
		// Плавим горелкой
		if(W.tool_behaviour == TOOL_WELDER)
			if(!W.tool_start_check(user, amount=0))
				return FALSE
			user.visible_message("<span class='notice'>[user] начинает плавить [src].</span>", "<span class='notice'>Вы плавите [src]...</span>")
			if(W.use_tool(src, user, 70, volume=50))
				user.visible_message("<span class='notice'>[user] расплавляет [src].</span>", "<span class='notice'>Вы успешно расплавили [src]...</span>")
				eject_victim(TRUE)
			return
	return ..()

// Вампирический ножик
/obj/item/kitchen/knife/backstabber/kunai
	name = "Kunai"
	desc = "A very sharp kunai, suitable for the finest of ninjas"
	cooldown_icon_state = null
	cooldown_time = 1 MINUTES
	icon = 'icons/obj/kitchen.dmi'
	icon_state = "survivalknife"
	start_cooldown_message = "похоже, пока что может быть использован лишь как садовый инструмент"
	end_cooldown_message = "снова удобно сидит в руке предприимчивого ниндзя"

/obj/item/kitchen/knife/backstabber/kunai/apply_backstab_effect(mob/living/carbon/victim, mob/living/carbon/user)
	// Лечим ввсе типы урона на 1/3 от здоровья жертвы
	if(victim != user && victim.health > 0)
		var/healing_amount = victim.health / 3
		healing_amount = clamp(healing_amount, 0, 70)
		user.heal_overall_damage(healing_amount, healing_amount, healing_amount, FALSE, FALSE, TRUE)
		to_chat(user, "<span class='nicegreen'>Кажется, [src] направляет в ваше тело часть жизненной энергии жертвы!</span>")
	victim.apply_damage(100, BRUTE, BODY_ZONE_CHEST, wound_bonus=CANT_WOUND)
	victim.death(FALSE)

// Коробка с ножом, мануалом к ножу и всякими безделушками
/obj/item/storage/box/backstabber_kit
	name = "assasination kit"
	desc = "Suspicious as fuck..."
	icon_state = "syndiebox"
	illustration = null

/obj/item/storage/box/backstabber_kit/PopulateContents()
	new /obj/item/kitchen/knife/backstabber(src)
	new /obj/item/paper/guides/backstabber(src)
	new /obj/item/lighter/black(src)
	new /obj/item/storage/fancy/cigarettes/cigpack_robustgold(src)
	new /obj/item/soap/inteq(src)
	new /obj/item/clothing/head/fedora(src)
	new /obj/item/clothing/under/suit/black_really(src)
	new /obj/item/clothing/accessory/waistcoat(src)
	new /obj/item/clothing/gloves/color/black(src)
	new /obj/item/clothing/shoes/laceup(src)

// Мануал к ножу
/obj/item/paper/guides/backstabber
	name = "Мануал искусства ударов в спину"
	desc = "Довольно подозрительно, не так ли?"
	default_raw_text = {"<h1>Пояснительная записка к устройству RSCW "Нож"</h1>© InteQ, все права защищены
	<p>Поздравляю с новой работой, агент! У тебя в руках оружие невероятной силы, однако любым оружием нужно уметь
	пользоваться! Нож, который ты можешь найти в этой коробке, не такой простой, каким кажется на первый взгляд. Один удар
	в спину или в лежачего противника - и обидчик, скорее всего отправится к праотцам (если, конечно, такие у него имеются). Удары же во все остальные
	места - довольно позорная для доблестного агента ошибка и особого успеха не принесут. Также у всех ножей есть время перезарядки,
	необходимое для восстановления блюспейс-механизмов, позволяющих ножу игнорировать любую броню и мгновенно убивать.
	Большинство ножей при ударе издают довольно громкий звук, благодаря которому все вокруг узнают, что произошло, так что стоит быть осторожным!</p>
	<br>
	<p>Помни, что у настоящего шпиона есть СТИЛЬ! В связи с многочисленными жалобами на наших агентов, устраивающих мерзкую
	резню в окровавленных скафандрах, Ассоциация Ассасинов InteQ ввела требования к дресскоду для своих скрытных сотрудников:
	отныне хождение в окровавленных обмотках будет повышать время перезарядки, а красивый костюм - понижать! В комплекте идёт
	несколько стильных вещей для максимально красивых убийств! Для того, чтобы его носитель и звучал как джентльмен, нож будет
	выдавать реплику от имени агента после каждого удара в спину... по крайней мере, большинство ножей. Ты всегда можешь
	выключить эту функцию, но это немного повысит время перезарядки!</p>
	<br>
	<h3>Разновидности</h3>
	<p>Использовав нож в руке, ты можешь выбрать желаемый его образ. У всех их есть свои особенности!</p><ol>
	<li><b>Классика</b> - обычный нож-бабочка, который у тебя в руках. Наносит 200 единиц физического урона и мгновенно убивает цель
	Перезарядка: <b>30 секунд</b></li>
	<li><b>Вечный покой</b> - орудия для поистине скрытных убийств. Работает беззвучно, окружающие лишь услышат стук
	трупа о плитку станции. Тело менее чем за секунду растворится в воздухе и станет невидимым, возвратив себе непрозрачность
	лишь через 10 секунд. Наносит 75 единиц физического урона и мгновенно убивает цель.
	Перезарядка: <b>1.5 минуты</b></li>
	<li><b>Сосулька</b> - грозное оружие, несмотря на своё название. Не наносит урона, но мгновенно убивает цель, тело которой
	превращается в ледяную статую. Статуя сама собой растает через минуту, но также может быть расплавлена сваркой или просто
	разбита, после чего тело жертвы выпадет из неё.
	Перезарядка: <b>35 секунд</b></li>
	<li><b>Кунай</b> - орудие настоящих ниндзя. При ударе наносит 100 единиц физического урона и мгновенно убивает жертву, а
	также крадёт часть её здоровья, которое у неё было до удара, излечивая носителя.
	Перезарядка: <b>1 минута</b></li></ol>
	<br>
	<p>Помимо своего замечательного ножа вы также можете найти в наборе комплект одежды, этот мануал, зажигалку для уничтожения
	документов, пачку сигарет и мыло™ для очистки следов и своей одежды от крови! Не забудь уничтожить коробку и эту бумагу!</p>
	<br>
	<b>Удачи, агент!</b>"}
