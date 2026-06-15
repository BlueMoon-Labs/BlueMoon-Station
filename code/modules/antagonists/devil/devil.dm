#define BLOOD_THRESHOLD 3 //How many souls are needed per stage.
#define TRUE_THRESHOLD 7
#define ARCH_THRESHOLD 12

#define BASIC_DEVIL 0
#define BLOOD_LIZARD 1
#define TRUE_DEVIL 2
#define ARCH_DEVIL 3

#define LOSS_PER_DEATH 2

#define SOULVALUE soulsOwned.len-reviveNumber

#define DEVILRESURRECTTIME 600

GLOBAL_LIST_EMPTY(allDevils)
GLOBAL_LIST_INIT(lawlorify, alist(
		LORE = list(
			OBLIGATION_FOOD = "Этот дьявол, кажется, всегда предлагает жертвам еду перед тем, как зарезать их.",
			OBLIGATION_FIDDLE = "Этот дьявол никогда не откажется от музыкального состязания.",
			OBLIGATION_DANCEOFF = "Этот дьявол никогда не откажется от танцевального баттла.",
			OBLIGATION_GREET = "Этот дьявол, кажется, может общаться только с теми, чьи имена ему известны.",
			OBLIGATION_PRESENCEKNOWN = "Этот дьявол, кажется, не способен атаковать из засады.",
			OBLIGATION_SAYNAME = "Он всегда произносит своё имя после убийства.",
			OBLIGATION_ANNOUNCEKILL = "Этот дьявол всегда громко объявляет о своих убийствах на весь мир.",
			OBLIGATION_ANSWERTONAME = "Этот дьявол всегда откликается на своё истинное имя.",
			BANE_SILVER = "Серебро, по-видимому, тяжело ранит этого дьявола.",
			BANE_SALT = "Бросок соли временно мешает ему пользоваться инфернальными силами.",
			BANE_LIGHT = "Яркие вспышки дезориентируют дьявола и заставляют его бежать.",
			BANE_IRON = "Холодное железо медленно ранит его, пока он не избавится от него.",
			BANE_WHITECLOTHES = "Ношение чистой белой одежды помогает отгонять этого дьявола.",
			BANE_HARVEST = "Дары урожая нарушают работу сил дьявола.",
			BANE_TOOLBOX = "То, что хранит орудия творения, хранит и средство его гибели.",
			BAN_HURTWOMAN = "Этот дьявол, кажется, предпочитает охотиться на мужчин.",
			BAN_CHAPEL = "Этот дьявол избегает святой земли.",
			BAN_HURTPRIEST = "Рукоположенное духовенство, по-видимому, неуязвимо к его силам.",
			BAN_AVOIDWATER = "Дьявол, кажется, испытывает отвращение к воде, хотя она и не причиняет ему вреда.",
			BAN_STRIKEUNCONSCIOUS = "Этот дьявол интересуется только теми, кто бодрствует.",
			BAN_HURTLIZARD = "Этот дьявол не ударит ящера первым.",
			BAN_HURTANIMAL = "Этот дьявол избегает причинять вред животным.",
			BANISH_WATER = "Чтобы изгнать дьявола, нужно наполнить его тело святой водой.",
			BANISH_COFFIN = "Если останки дьявола будут помещены в гроб, он не сможет воскреснуть.",
			BANISH_FORMALDYHIDE = "Чтобы изгнать дьявола, нужно ввести в его безжизненное тело бальзам.",
			BANISH_RUNES = "Если останки дьявола будут помещены в руну, он не сможет воскреснуть.",
			BANISH_CANDLES = "Большое число зажжённых свечей поблизости помешает его воскрешению.",
			BANISH_DESTRUCTION = "Его труп должен быть полностью уничтожен, чтобы предотвратить воскрешение.",
			BANISH_FUNERAL_GARB = "Если тело дьявола одето в похоронные одеяния, он не сможет воскреснуть. Если одежда не подходит по размеру, положите её поверх трупа."
		),
		LAW = list(
			OBLIGATION_FOOD = "Если вы не действуете в целях самообороны, вы должны всегда предлагать жертве еду перед причинением вреда.",
			OBLIGATION_FIDDLE = "Если вы не в непосредственной опасности и вам бросают вызов на музыкальную дуэль, вы должны принять его. Вы не обязаны дуэлиться с одним и тем же человеком дважды.",
			OBLIGATION_DANCEOFF = "Если вы не в непосредственной опасности и вам бросают вызов на танцевальный баттл, вы должны принять его. Вы не обязаны соревноваться с одним и тем же человеком дважды.",
			OBLIGATION_GREET = "Вы должны всегда приветствовать других по фамилии, прежде чем заговорить с ними.",
			OBLIGATION_PRESENCEKNOWN = "Вы должны всегда заявлять о своём присутствии перед атакой.",
			OBLIGATION_SAYNAME = "Вы должны всегда произносить своё истинное имя после того, как кого-то убили.",
			OBLIGATION_ANNOUNCEKILL = "Убив кого-либо, вы должны объявить об этом всем, кто может вас услышать, по возможности через коммуникации.",
			OBLIGATION_ANSWERTONAME = "Если на вас не нападают, вы должны всегда откликаться на своё истинное имя.",
			BAN_HURTWOMAN = "Вы не должны причинять вред женщине, кроме как в целях самообороны.",
			BAN_CHAPEL = "Вы не должны пытаться войти в часовню.",
			BAN_HURTPRIEST = "Вы не должны атаковать священника.",
			BAN_AVOIDWATER = "Вы не должны добровольно касаться мокрых поверхностей.",
			BAN_STRIKEUNCONSCIOUS = "Вы не должны бить без сознания.",
			BAN_HURTLIZARD = "Вы не должны причинять вред ящеру, кроме как в целях самообороны.",
			BAN_HURTANIMAL = "Вы не должны причинять вред несентиентным существам или роботам, кроме как в целях самообороны.",
			BANE_SILVER = "Серебро во всех его формах станет вашей погибелью.",
			BANE_SALT = "Соль нарушит ваши магические способности.",
			BANE_LIGHT = "Ослепляющий свет временно лишит вас возможности использовать атакующие силы.",
			BANE_IRON = "Холодное кованое железо действует на вас как яд.",
			BANE_WHITECLOTHES = "Те, кто одет в безупречно белую одежду, будут бить вас без промаха.",
			BANE_HARVEST = "Плоды урожая станут вашей погибелью.",
			BANE_TOOLBOX = "Ящики с инструментами — плохая новость для вас, и почему-то именно так.",
			BANISH_WATER = "Если ваш труп наполнен святой водой, вы не сможете воскреснуть.",
			BANISH_COFFIN = "Если ваш труп находится в гробу, вы не сможете воскреснуть.",
			BANISH_FORMALDYHIDE = "Если ваш труп забальзамирован, вы не сможете воскреснуть.",
			BANISH_RUNES = "Если ваш труп помещён в руну, вы не сможете воскреснуть.",
			BANISH_CANDLES = "Если рядом с вашим трупом горят свечи, вы не сможете воскреснуть.",
			BANISH_DESTRUCTION = "Если ваш труп уничтожен, вы не сможете воскреснуть.",
			BANISH_FUNERAL_GARB = "Если ваш труп одет в похоронные одеяния, вы не сможете воскреснуть."
		)
	))

//These are also used in the codex gigas, so let's declare them globally.
GLOBAL_LIST_INIT(devil_pre_title, list("Dark ", "Hellish ", "Fallen ", "Fiery ", "Sinful ", "Blood ", "Fluffy "))
GLOBAL_LIST_INIT(devil_title, list("Lord ", "Prelate ", "Count ", "Viscount ", "Vizier ", "Elder ", "Adept "))
GLOBAL_LIST_INIT(devil_syllable, list("hal", "ve", "odr", "neit", "ci", "quon", "mya", "folth", "wren", "geyr", "hil", "niet", "twou", "phi", "coa"))
GLOBAL_LIST_INIT(devil_suffix, list(" the Red", " the Soulless", " the Master", ", the Lord of all things", ", Jr."))
/datum/antagonist/devil
	name = "Devil"
	roundend_category = "devils"
	antagpanel_category = "Devil"
	job_rank = ROLE_DEVIL
	//Don't delete upon mind destruction, otherwise soul re-selling will break.
	delete_on_mind_deletion = FALSE
	threat = 5
	show_to_ghosts = TRUE
	var/obligation
	var/ban
	var/bane
	var/banish
	var/truename
	var/list/datum/mind/soulsOwned = new
	var/reviveNumber = 0
	var/form = BASIC_DEVIL
	var/static/list/devil_spells = typecacheof(list(
		/obj/effect/proc_holder/spell/aimed/fireball/hellish,
		/obj/effect/proc_holder/spell/targeted/conjure_item/summon_pitchfork,
		/obj/effect/proc_holder/spell/targeted/conjure_item/summon_pitchfork/greater,
		/obj/effect/proc_holder/spell/targeted/conjure_item/summon_pitchfork/ascended,
		/obj/effect/proc_holder/spell/targeted/infernal_jaunt,
		/obj/effect/proc_holder/spell/targeted/sintouch,
		/obj/effect/proc_holder/spell/targeted/sintouch/ascended,
		/obj/effect/proc_holder/spell/targeted/summon_contract,
		/obj/effect/proc_holder/spell/targeted/recall_contract,
		/obj/effect/proc_holder/spell/targeted/conjure_item/summon_contract_holder,
		/obj/effect/proc_holder/spell/targeted/conjure_item/violin,
		/obj/effect/proc_holder/spell/targeted/summon_dancefloor))
	var/ascendable = FALSE

/datum/antagonist/devil/threat()
	return ..() + form * 10

/datum/antagonist/devil/can_be_owned(datum/mind/new_owner)
	. = ..()
	return . && (ishuman(new_owner.current) || iscyborg(new_owner.current))

/datum/antagonist/devil/get_admin_commands()
	. = ..()
	.["Переключить возвышение"] = CALLBACK(src,PROC_REF(admin_toggle_ascendable))

/datum/antagonist/devil/proc/admin_toggle_ascendable(mob/admin)
	ascendable = !ascendable
	message_admins("[key_name_admin(admin)] set [owner.current] devil ascendable to [ascendable]")
	log_admin("[key_name_admin(admin)] set [owner.current] devil ascendable to [ascendable])")

/datum/antagonist/devil/admin_add(datum/mind/new_owner,mob/admin)
	switch(alert(admin,"Может ли этот дьявол возвыситься?",,"Да","Нет","Отмена"))
		if("Да")
			ascendable = TRUE
		if("Нет")
			ascendable = FALSE
		else
			return
	new_owner.add_antag_datum(src)
	message_admins("[key_name_admin(admin)] has devil'ed [new_owner.current]. [ascendable ? "(Ascendable)":""]")
	log_admin("[key_name(admin)] has devil'ed [new_owner.current]. [ascendable ? "(Ascendable)":""]")

/datum/antagonist/devil/antag_listing_name()
	return ..() + "([truename])"

/proc/devilInfo(name)
	if(GLOB.allDevils[lowertext(name)])
		return GLOB.allDevils[lowertext(name)]
	else
		var/datum/fakeDevil/devil = new /datum/fakeDevil(name)
		GLOB.allDevils[lowertext(name)] = devil
		return devil

/proc/randomDevilName()
	var/name = ""
	if(prob(65))
		if(prob(35))
			name = pick(GLOB.devil_pre_title)
		name += pick(GLOB.devil_title)
	var/probability = 100
	name += pick(GLOB.devil_syllable)
	while(prob(probability))
		name += pick(GLOB.devil_syllable)
		probability -= 20
	if(prob(40))
		name += pick(GLOB.devil_suffix)
	return name

/proc/randomdevilobligation()
	return pick(OBLIGATION_FOOD, OBLIGATION_FIDDLE, OBLIGATION_DANCEOFF, OBLIGATION_GREET, OBLIGATION_PRESENCEKNOWN, OBLIGATION_SAYNAME, OBLIGATION_ANNOUNCEKILL, OBLIGATION_ANSWERTONAME)

/proc/randomdevilban()
	return pick(BAN_HURTWOMAN, BAN_CHAPEL, BAN_HURTPRIEST, BAN_AVOIDWATER, BAN_STRIKEUNCONSCIOUS, BAN_HURTLIZARD, BAN_HURTANIMAL)

/proc/randomdevilbane()
	return pick(BANE_SALT, BANE_LIGHT, BANE_IRON, BANE_WHITECLOTHES, BANE_SILVER, BANE_HARVEST, BANE_TOOLBOX)

/proc/randomdevilbanish()
	return pick(BANISH_WATER, BANISH_COFFIN, BANISH_FORMALDYHIDE, BANISH_RUNES, BANISH_CANDLES, BANISH_DESTRUCTION, BANISH_FUNERAL_GARB)

/datum/antagonist/devil/proc/add_soul(datum/mind/soul)
	if(soulsOwned.Find(soul))
		return
	soulsOwned += soul
	owner.current.set_nutrition(NUTRITION_LEVEL_FULL)
	to_chat(owner.current, "<span class='warning'>Вы чувствуете насыщение — вы получили новую душу.</span>")
	update_hud()
	switch(SOULVALUE)
		if(0)
			to_chat(owner.current, "<span class='warning'>Ваши инфернальные силы восстановлены.</span>")
			give_appropriate_spells()
		if(BLOOD_THRESHOLD)
			increase_blood_lizard()
		if(TRUE_THRESHOLD)
			increase_true_devil()
		if(ARCH_THRESHOLD)
			increase_arch_devil()

/datum/antagonist/devil/proc/remove_soul(datum/mind/soul)
	if(soulsOwned.Remove(soul))
		check_regression()
		to_chat(owner.current, "<span class='warning'>Вы чувствуете, как душа ускользает из ваших рук.</span>")
		update_hud()

/datum/antagonist/devil/proc/check_regression()
	if(form == ARCH_DEVIL)
		return //arch devil can't regress
	//Yes, fallthrough behavior is intended, so I can't use a switch statement.
	if(form == TRUE_DEVIL && SOULVALUE < TRUE_THRESHOLD)
		regress_blood_lizard()
	if(form == BLOOD_LIZARD && SOULVALUE < BLOOD_THRESHOLD)
		regress_humanoid()
	if(SOULVALUE < 0)
		give_appropriate_spells()
		to_chat(owner.current, "<span class='warning'>В наказание за ваши неудачи все ваши силы, кроме создания контрактов, отозваны.</span>")

/datum/antagonist/devil/proc/regress_humanoid()
	to_chat(owner.current, "<span class='warning'>Ваши силы ослабевают — заключите больше контрактов, чтобы вернуть мощь.</span>")
	if(ishuman(owner.current))
		var/mob/living/carbon/human/H = owner.current
		H.set_species(/datum/species/human, 1)
		H.regenerate_icons()
	give_appropriate_spells()
	if(istype(owner.current.loc, /obj/effect/dummy/phased_mob/slaughter/))
		owner.current.forceMove(get_turf(owner.current))//Fixes dying while jaunted leaving you permajaunted.
	form = BASIC_DEVIL

/datum/antagonist/devil/proc/regress_blood_lizard()
	var/mob/living/carbon/true_devil/D = owner.current
	to_chat(D, "<span class='warning'>Ваши силы ослабевают — заключите больше контрактов, чтобы вернуть мощь.</span>")
	D.oldform.forceMove(D.drop_location())
	owner.transfer_to(D.oldform)
	give_appropriate_spells()
	qdel(D)
	form = BLOOD_LIZARD
	update_hud()


/datum/antagonist/devil/proc/increase_blood_lizard()
	to_chat(owner.current, "<span class='warning'>Вы чувствуете, что ваше человеческое тело вот-вот сбросит кожу. Скоро вы превратитесь в кровавую ящерицу.</span>")
	sleep(50)
	if(ishuman(owner.current))
		var/mob/living/carbon/human/H = owner.current
		H.set_species(/datum/species/lizard, 1)
		H.underwear = "Nude"
		H.undershirt = "Nude"
		H.socks = "Nude"
		H.dna.features["mcolor"] = "511" //A deep red
		H.update_body(TRUE)
	else //Did the devil get hit by a staff of transmutation?
		owner.current.color = "#501010"
	give_appropriate_spells()
	form = BLOOD_LIZARD



/datum/antagonist/devil/proc/increase_true_devil()
	to_chat(owner.current, "<span class='warning'>Вы чувствуете, что ваше нынешнее тело вот-вот сбросит кожу. Скоро вы превратитесь в истинного дьявола.</span>")
	sleep(50)
	var/mob/living/carbon/true_devil/A = new /mob/living/carbon/true_devil(owner.current.loc)
	A.faction |= "hell"
	owner.current.forceMove(A)
	A.oldform = owner.current
	owner.transfer_to(A)
	A.set_name()
	give_appropriate_spells()
	form = TRUE_DEVIL
	update_hud()

/datum/antagonist/devil/proc/increase_arch_devil()
	if(!ascendable)
		return
	var/mob/living/carbon/true_devil/D = owner.current
	to_chat(D, "<span class='warning'>Вы чувствуете, что ваша форма вот-вот возвысится.</span>")
	sleep(50)
	if(!D)
		return
	infernal_darken_cosmos()
	D.visible_message("<span class='warning'>Кожа [D] начинает покрываться шипами.</span>", \
		"<span class='warning'>Ваша плоть начинает создавать вокруг вас щит.</span>")
	sleep(100)
	if(!D)
		return
	D.visible_message("<span class='warning'>Рога на голове [D] медленно растут и удлиняются.</span>", \
		"<span class='warning'>Ваше тело продолжает мутировать. Ваши телепатические способности усиливаются.</span>")
	sleep(90)
	if(!D)
		return
	D.visible_message("<span class='warning'>Тело [D] начинает яростно растягиваться и искажаться.</span>", \
		"<span class='warning'>Вы начинаете разрывать последние барьеры на пути к абсолютной власти.</span>")
	sleep(40)
	if(!D)
		return
	to_chat(D, "<i><b>Да!</b></i>")
	sleep(10)
	if(!D)
		return
	to_chat(D, "<i><b><span class='big'>ДА!!</span></b></i>")
	sleep(10)
	if(!D)
		return
	to_chat(D, "<i><b><span class='reallybig'>ДА--</span></b></i>")
	sleep(1)
	if(!D)
		return
	send_to_playing_players("<font size=5><span class='danger'><b>\"ЛЕНЬ, ГНЕВ, ЧРЕВОУГОДИЕ, УНЫНИЕ, ЗАВИСТЬ, ЖАДНОСТЬ, ГОРДОСТЬ! ПРОБУДИСЬ, ОГОНЬ АДА!!\"</font></span>")
	sound_to_playing_players('sound/hallucinations/veryfar_noise.ogg')
	infernal_ascension_atmosphere(D)
	give_appropriate_spells()
	D.convert_to_archdevil()
	if(istype(D.loc, /obj/effect/dummy/phased_mob/slaughter/))
		D.forceMove(get_turf(D))//Fixes dying while jaunted leaving you permajaunted.
	var/area/A = get_area(owner.current)
	if(A)
		notify_ghosts("Архидьявол возвысился в \the [A.name]. Обратитесь к дьяволу, чтобы получить новую оболочку для своей души.", source = owner.current, action=NOTIFY_ATTACK)
	sleep(50)
	if(!SSticker.mode || !SSticker.mode.devil_ascended)
		SSshuttle.emergency.request(null, set_coefficient = 0.3)
	if(SSticker.mode)
		SSticker.mode.devil_ascended++
	form = ARCH_DEVIL

/datum/antagonist/devil/proc/remove_spells()
	for(var/X in owner.spell_list)
		var/obj/effect/proc_holder/spell/S = X
		if(is_type_in_typecache(S, devil_spells))
			owner.RemoveSpell(S)

/datum/antagonist/devil/proc/give_summon_contract()
	owner.AddSpell(new /obj/effect/proc_holder/spell/targeted/summon_contract(null))
	owner.AddSpell(new /obj/effect/proc_holder/spell/targeted/recall_contract(null))
	owner.AddSpell(new /obj/effect/proc_holder/spell/targeted/conjure_item/summon_contract_holder(null))
	if(obligation == OBLIGATION_FIDDLE)
		owner.AddSpell(new /obj/effect/proc_holder/spell/targeted/conjure_item/violin(null))
	else if(obligation == OBLIGATION_DANCEOFF)
		owner.AddSpell(new /obj/effect/proc_holder/spell/targeted/summon_dancefloor(null))

/datum/antagonist/devil/proc/give_appropriate_spells()
	remove_spells()
	give_summon_contract()
	if(SOULVALUE >= ARCH_THRESHOLD && ascendable)
		give_arch_spells()
	else if(SOULVALUE >= TRUE_THRESHOLD)
		give_true_spells()
	else if(SOULVALUE >= BLOOD_THRESHOLD)
		give_blood_spells()
	else if(SOULVALUE >= 0)
		give_base_spells()

/datum/antagonist/devil/proc/give_base_spells()
	owner.AddSpell(new /obj/effect/proc_holder/spell/aimed/fireball/hellish(null))
	owner.AddSpell(new /obj/effect/proc_holder/spell/targeted/conjure_item/summon_pitchfork(null))

/datum/antagonist/devil/proc/give_blood_spells()
	owner.AddSpell(new /obj/effect/proc_holder/spell/targeted/conjure_item/summon_pitchfork(null))
	owner.AddSpell(new /obj/effect/proc_holder/spell/aimed/fireball/hellish(null))
	owner.AddSpell(new /obj/effect/proc_holder/spell/targeted/infernal_jaunt(null))

/datum/antagonist/devil/proc/give_true_spells()
	owner.AddSpell(new /obj/effect/proc_holder/spell/targeted/conjure_item/summon_pitchfork/greater(null))
	owner.AddSpell(new /obj/effect/proc_holder/spell/aimed/fireball/hellish(null))
	owner.AddSpell(new /obj/effect/proc_holder/spell/targeted/infernal_jaunt(null))
	owner.AddSpell(new /obj/effect/proc_holder/spell/targeted/sintouch(null))

/datum/antagonist/devil/proc/give_arch_spells()
	owner.AddSpell(new /obj/effect/proc_holder/spell/targeted/conjure_item/summon_pitchfork/ascended(null))
	owner.AddSpell(new /obj/effect/proc_holder/spell/targeted/sintouch/ascended(null))

/datum/antagonist/devil/proc/beginResurrectionCheck(mob/living/body)
	if(SOULVALUE>0)
		to_chat(owner.current, "<span class='userdanger'>Ваше тело повреждено настолько, что вы больше не можете им пользоваться. Ценой части вашей силы вы скоро вернётесь к жизни. Оставайтесь в своём теле.</span>")
		sleep(DEVILRESURRECTTIME)
		if (!body ||  body.stat == DEAD)
			if(SOULVALUE>0)
				if(check_banishment(body))
					to_chat(owner.current, "<span class='userdanger'>К сожалению, смертные завершили ритуал, препятствующий вашему воскрешению.</span>")
					return -1
				else
					to_chat(owner.current, "<span class='userdanger'>МЫ СНОВА ЖИВЫ!</span>")
					return hellish_resurrection(body)
			else
				to_chat(owner.current, "<span class='userdanger'>К сожалению, сила ваших контрактов угасла. У вас больше недостаточно мощи для воскрешения.</span>")
				return -1
		else
			to_chat(owner.current, "<span class='danger'>Похоже, вы воскресли без своих инфернальных сил.</span>")
	else
		to_chat(owner.current, "<span class='userdanger'>Ваши инфернальные силы слишком слабы, чтобы воскреснуть.</span>")

/datum/antagonist/devil/proc/check_banishment(mob/living/body)
	switch(banish)
		if(BANISH_WATER)
			if(iscarbon(body))
				var/mob/living/carbon/H = body
				return H.reagents.has_reagent(/datum/reagent/water/holywater)
			return FALSE
		if(BANISH_COFFIN)
			return (body && istype(body.loc, /obj/structure/closet/crate/coffin))
		if(BANISH_FORMALDYHIDE)
			if(iscarbon(body))
				var/mob/living/carbon/H = body
				return H.reagents.has_reagent(/datum/reagent/toxin/formaldehyde)
			return FALSE
		if(BANISH_RUNES)
			if(body)
				for(var/obj/effect/decal/cleanable/crayon/R in range(0,body))
					if (R.name == "rune")
						return TRUE
			return FALSE
		if(BANISH_CANDLES)
			if(body)
				var/count = 0
				for(var/obj/item/candle/C in range(1,body))
					count += C.lit
				if(count>=4)
					return TRUE
			return FALSE
		if(BANISH_DESTRUCTION)
			if(body)
				return FALSE
			return TRUE
		if(BANISH_FUNERAL_GARB)
			if(ishuman(body))
				var/mob/living/carbon/human/H = body
				if(H.w_uniform && istype(H.w_uniform, /obj/item/clothing/under/misc/burial))
					return TRUE
				return FALSE
			else
				for(var/obj/item/clothing/under/misc/burial/B in range(0,body))
					if(B.loc == get_turf(B)) //Make sure it's not in someone's inventory or something.
						return TRUE
				return FALSE

/datum/antagonist/devil/proc/hellish_resurrection(mob/living/body)
	message_admins("[owner.name] (true name is: [truename]) is resurrecting using hellish energy.</a>")
	if(SOULVALUE < ARCH_THRESHOLD || !ascendable) // once ascended, arch devils do not go down in power by any means.
		reviveNumber += LOSS_PER_DEATH
		update_hud()
	if(body)
		body.revive(TRUE, TRUE) //Adminrevive also recovers organs, preventing someone from resurrecting without a heart.
		if(istype(body.loc, /obj/effect/dummy/phased_mob/slaughter/))
			body.forceMove(get_turf(body))//Fixes dying while jaunted leaving you permajaunted.
		if(istype(body, /mob/living/carbon/true_devil))
			var/mob/living/carbon/true_devil/D = body
			if(D.oldform)
				D.oldform.revive(1,0) // Heal the old body too, so the devil doesn't resurrect, then immediately regress into a dead body.
		if(body.stat == DEAD)
			create_new_body()
	else
		create_new_body()
	check_regression()

/datum/antagonist/devil/proc/create_new_body()
	if(GLOB.blobstart.len > 0)
		var/turf/targetturf = get_turf(pick(GLOB.blobstart))
		var/mob/currentMob = owner.current
		if(!currentMob)
			currentMob = owner.get_ghost()
			if(!currentMob)
				message_admins("[owner.name]'s devil resurrection failed due to client logoff.  Aborting.")
				return -1
		if(currentMob.mind != owner)
			message_admins("[owner.name]'s devil resurrection failed due to becoming a new mob.  Aborting.")
			return -1
		currentMob.change_mob_type( /mob/living/carbon/human, targetturf, null, 1)
		var/mob/living/carbon/human/H = owner.current
		H.equip_to_slot_or_del(new /obj/item/clothing/under/rank/civilian/lawyer/black(H), ITEM_SLOT_ICLOTHING)
		H.equip_to_slot_or_del(new /obj/item/clothing/shoes/laceup(H), ITEM_SLOT_FEET)
		H.equip_to_slot_or_del(new /obj/item/storage/briefcase(H), ITEM_SLOT_HANDS)
		H.equip_to_slot_or_del(new /obj/item/pen(H), ITEM_SLOT_LPOCKET)
		if(SOULVALUE >= BLOOD_THRESHOLD)
			H.set_species(/datum/species/lizard, 1)
			H.underwear = "Nude"
			H.undershirt = "Nude"
			H.socks = "Nude"
			H.dna.features["mcolor"] = "511"
			H.update_body(TRUE)
			if(SOULVALUE >= TRUE_THRESHOLD) //Yes, BOTH this and the above if statement are to run if soulpower is high enough.
				var/mob/living/carbon/true_devil/A = new /mob/living/carbon/true_devil(targetturf)
				A.faction |= "hell"
				H.forceMove(A)
				A.oldform = H
				owner.transfer_to(A, TRUE)
				A.set_name()
				if(SOULVALUE >= ARCH_THRESHOLD && ascendable)
					A.convert_to_archdevil()
					form = ARCH_DEVIL
					give_appropriate_spells()
	else
		CRASH("Unable to find a blobstart landmark for hellish resurrection")


/datum/antagonist/devil/proc/update_hud()
	if(iscarbon(owner.current))
		var/mob/living/C = owner.current
		if(C.hud_used && C.hud_used.devilsouldisplay)
			C.hud_used.devilsouldisplay.update_counter(SOULVALUE)

/datum/antagonist/devil/greet()
	to_chat(owner.current, "<span class='warning'><b>Вы помните свою связь с инферном. Вы — [truename], агент ада, дьявол. Вас отправили на план творения не просто так — у вас есть высшая цель. Соблазняйте экипаж грешить и укрепляйте хватку Ада.</b></span>")
	to_chat(owner.current, "<span class='warning'><b>Однако ваша инфернальная форма не лишена слабостей.</b></span>")
	to_chat(owner.current, "Вы не можете применять насилие, чтобы заставить кого-то продать душу.")
	to_chat(owner.current, "Вы не можете намеренно и осознанно причинять физический вред другому дьяволу, кроме себя.")
	to_chat(owner.current, GLOB.lawlorify[LAW][bane])
	to_chat(owner.current, GLOB.lawlorify[LAW][ban])
	to_chat(owner.current, GLOB.lawlorify[LAW][obligation])
	to_chat(owner.current, GLOB.lawlorify[LAW][banish])
	to_chat(owner.current, "<span class='warning'>Помните: экипаж может исследовать ваши слабости, если узнает ваше дьявольское имя.</span><br>")
	.=..()

/datum/antagonist/devil/on_gain()
	truename = randomDevilName()
	ban = randomdevilban()
	bane = randomdevilbane()
	obligation = randomdevilobligation()
	banish = randomdevilbanish()
	GLOB.allDevils[lowertext(truename)] = src

	antag_memory += "Ваше дьявольское истинное имя — [truename]<br>[GLOB.lawlorify[LAW][ban]]<br>Вы не можете применять насилие, чтобы заставить кого-то продать душу.<br>Вы не можете намеренно причинять вред другому дьяволу, кроме себя.<br>[GLOB.lawlorify[LAW][bane]]<br>[GLOB.lawlorify[LAW][obligation]]<br>[GLOB.lawlorify[LAW][banish]]<br>"
	if(issilicon(owner.current))
		var/mob/living/silicon/robot_devil = owner.current
		var/laws = list("Вы не можете применять насилие, чтобы заставить кого-то продать душу.", "Вы не можете намеренно причинять вред другому дьяволу, кроме себя.", GLOB.lawlorify[LAW][ban], GLOB.lawlorify[LAW][obligation], "Добивайтесь своих целей любой ценой.")
		robot_devil.set_law_sixsixsix(laws)
	if(owner.assigned_role == "Clown" && ishuman(owner.current))
		var/mob/living/carbon/human/S = owner.current
		to_chat(S, "<span class='notice'>Ваша инфернальная природа позволила вам преодолеть клоунскую натуру.</span>")
		S.dna.remove_mutation(CLOWNMUT)
	.=..()

/datum/antagonist/devil/on_removal()
	to_chat(owner.current, "<span class='userdanger'>Ваша инфернальная связь разорвана! Вы больше не дьявол!</span>")
	owner.special_role = null // BLUEMOON ADD
	.=..()

/datum/antagonist/devil/apply_innate_effects(mob/living/mob_override)
	give_appropriate_spells()
	owner.current.grant_all_languages(TRUE, TRUE, TRUE, LANGUAGE_DEVIL)
	update_hud()
	.=..()

/datum/antagonist/devil/remove_innate_effects(mob/living/mob_override)
	for(var/X in owner.spell_list)
		var/obj/effect/proc_holder/spell/S = X
		if(is_type_in_typecache(S, devil_spells))
			owner.RemoveSpell(S)
	owner.current.remove_all_languages(LANGUAGE_DEVIL)
	.=..()

/datum/antagonist/devil/proc/printdevilinfo()
	var/list/parts = list()
	parts += "Истинное имя дьявола: [truename]"
	parts += "Запреты дьявола:"
	parts += "[FOURSPACES][GLOB.lawlorify[LORE][ban]]"
	parts += "[FOURSPACES][GLOB.lawlorify[LORE][bane]]"
	parts += "[FOURSPACES][GLOB.lawlorify[LORE][obligation]]"
	parts += "[FOURSPACES][GLOB.lawlorify[LORE][banish]]"
	return parts.Join("<br>")

/datum/antagonist/devil/roundend_report()
	var/list/parts = list()
	parts += printplayer(owner)
	parts += printdevilinfo()
	parts += printobjectives(objectives)
	return parts.Join("<br>")

//A simple super light weight datum for the codex gigas.
/datum/fakeDevil
	var/truename
	var/bane
	var/obligation
	var/ban
	var/banish
	var/ascendable

/datum/fakeDevil/New(name = randomDevilName())
	truename = name
	bane = randomdevilbane()
	obligation = randomdevilobligation()
	ban = randomdevilban()
	banish = randomdevilbanish()
	ascendable = prob(25)
