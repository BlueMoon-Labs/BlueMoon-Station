/obj/item/toy/plush
	var/can_you_fuck_plush = TRUE // TRUE - Да, можно сунуть в игрушку флешлайт. FALSE - Нет, нельзя. // Сделано чтобы предотвратить "нон-кон" именных игрушек. Ставить по усмотрению автора игрушки.

/obj/item/toy/plush/bm
	name = "Aiko Plushie"
	desc = "Wow... Aiko plushie!"
	icon_state = "aiko"
	icon = 'modular_bluemoon/icons/obj/toys/plushes.dmi'
	lefthand_file = 'modular_bluemoon/icons/mob/inhands/items/plushes_lefthand.dmi'
	righthand_file = 'modular_bluemoon/icons/mob/inhands/items/plushes_righthand.dmi'

/obj/item/toy/plush/bm/shark
	name = "Shark Plushie"
	desc = "A soft shark plushie for soft men. Mostly known as 'Blahaj', but some call it 'The IKEA shark'."
	icon_state = "blahaj"
	attack_verb = list("gnawed", "gnashed", "chewed")
	squeak_override = list('modular_bluemoon/sound/voice/rawr.ogg' = 1)

/obj/item/toy/plush/bm/shark/grey
	name = "Shark Grey Plushie"
	icon_state = "blahaj-grey"

/obj/item/toy/plush/bm/shark/purple
	name = "Shark Purple Plushie"
	icon_state = "blahaj-purple"

/obj/item/toy/plush/bm/shark/orange
	name = "Shark Orange Plushie"
	icon_state = "blahaj-orange"

/obj/item/toy/plush/bm/shark/yellow
	name = "Shark Yellow Plushie"
	icon_state = "blahaj-yellow"

/obj/item/toy/plush/bm/shark/red
	name = "Shark Red Plushie"
	icon_state = "blahaj-red"

/obj/item/toy/plush/bm/shark/green
	name = "Shark Green Plushie"
	icon_state = "blahaj-green"

/obj/item/toy/plush/bm/shark/judas
	name = "Judas Shark Plush"
	icon_state = "blahaj-judas"

/obj/item/toy/plush/bm/rouny
	name = "Rouny Plushie"
	desc = "A plushie depicting a xenomorph runner, made to commemorate the centenary of the Battle of LV-426. Much cuddlier than the real thing."
	icon_state = "rouny"
	attack_verb = list("slashed", "bit", "charged")

/obj/item/toy/plush/bm/ada
	name = "Ada plushie"
	desc = "Плюшевая игрушка серой кошки с яркими, как изумруды, глазками. Язык прикреплён небрежно. Крылья в комплект не входят."
	icon_state = "ada"
	squeak_override = list('modular_citadel/sound/voice/nya.ogg' = 1)

/obj/item/toy/plush/bm/kiirava
	name = "Kiirava Plushie"
	desc = "Выглядит как ящерка с телом оливково-зеленого цвета. У нее непропорционально большая голова с двумя огромными глазами: один черный, а другой розовый. У ящерки маленькие треугольные рожки по бокам головы и крошечный рот, который почти незаметен."
	icon_state = "kiirava"
	attack_verb = list("gnawed", "gnashed", "chewed")
	squeak_override = list('modular_bluemoon/sound/voice/rawr.ogg' = 1)

/obj/item/toy/plush/bm/emma
	name = "Emma plushie"
	desc = "An adorable stuffed toy resembling a vulp."
	icon_state = "emma"
	can_random_spawn = FALSE
	attack_verb = list("yipped", "geckered", "yapped")

/obj/item/toy/plush/bm/emma/shiro
	name = "Shiro plushie"
	icon_state = "shiro"

/obj/item/toy/plush/bm/emma/raita
	name = "Raita plushie"
	icon_state = "raita"

/obj/item/toy/plush/bm/emma/aiko
	name = "Aiko Plushie"
	icon_state = "aiko"

/obj/item/toy/plush/bm/emma/rozgo
	name = "Rozgo Plushie"
	icon_state = "rozgo"
	item_state = "aiko"

/obj/item/toy/plush/bm/emma/taliza
	name = "Siya Taliza Plushie"
	icon_state = "siya"
	item_state = "aiko"

/obj/item/toy/plush/bm/emma/red
	name = "Red plushie"
	icon_state = "red"

/obj/item/toy/plush/bm/emma/allta
	name = "Allta Plushie"
	icon_state = "allta"
	item_state = "aiko"
	squeak_override = list(
		'modular_bluemoon/SmiLeY/sounds/allta_mew1.ogg' = 1,
		'modular_bluemoon/SmiLeY/sounds/allta_mew2.ogg' = 1,
		'modular_bluemoon/SmiLeY/sounds/allta_mew3.ogg' = 1
	)

/obj/item/toy/plush/bm/emma/zlatchek
	name = "Zlat plushie"
	desc = "Прапорщик - Ебучий койот. Примечание: Не доверяйте ему огнестрельное оружие."
	icon_state = "zlat"
	squeak_override = list('modular_bluemoon/SmiLeY/sounds/zlatchek.ogg' = 1)

/obj/item/toy/plush/bm/tiamat
	name = "Tiamat plushie"
	desc = "Some cat-like plushie. Oh, his eyes shining!"
	icon_state = "tiamat"
	can_random_spawn = FALSE
	squeak_override = list(
		'modular_splurt/sound/voice/mrowl.ogg' = 1,
		'modular_splurt/sound/voice/meow_meme.ogg' = 1,
		'modular_bluemoon/SmiLeY/sounds/tiamat_mrrp1.ogg' = 1,
		'modular_bluemoon/SmiLeY/sounds/tiamat_mrrp2.ogg' = 1,
		'modular_bluemoon/SmiLeY/sounds/tiamat_meow1.ogg' = 1,
		'modular_bluemoon/SmiLeY/sounds/tiamat_meow2.ogg' = 1,
		'modular_bluemoon/SmiLeY/sounds/tiamat_meow3.ogg' = 1
	)

/obj/item/toy/plush/bm/manul
	name = "Medic Ma'Nu"
	desc = "The label sewn onto the plush tajaran's clothes says, ''Limited edition of the NPC from the medical department.'' The toy smells of pine trees. It is under the pine trees that its owner is." //Rest In Peace, dear friend Manul.
	icon_state = "manul"
	item_state = "manul"
	icon = 'modular_bluemoon/icons/obj/toys/plushes.dmi'
	lefthand_file = 'modular_bluemoon/icons/mob/inhands/items/plushes_lefthand.dmi'
	righthand_file = 'modular_bluemoon/icons/mob/inhands/items/plushes_righthand.dmi'
	squeak_override = list(
		'modular_bluemoon/SmiLeY/sounds/manul1.ogg' = 1,
		'modular_bluemoon/SmiLeY/sounds/manul2.ogg' = 1
	)

/obj/item/toy/plush/bm/stasik
	name = "Stasik"
	desc = "Игрушка XXXL размера, на бирке красуется надпись Стасик."
	icon_state = "stasik"
	squeak_override = list('modular_bluemoon/sound/voice/stasik_volcahara.ogg' = 1)

/obj/item/toy/plush/bm/rainbow_cat
	name = "Rainbow cat"
	desc = "Нанотехнологическая игрушка, созданная в стенах научных комплексов НТ. Видимо яркие переливающиеся цвета их рук дело."
	icon_state = "rainbow"
	item_state = "rainbow"
	squeak_override = list('modular_bluemoon/SmiLeY/sounds/allta_mew1.ogg' = 1)

/obj/item/toy/plush/bm/atmosian
	name = "Atmosian Plushie"
	desc = "Очаровательная мягкая игрушка, напоминающая храброго атмосианина. К сожалению, он не устранит разгерметизацию за вас."
	icon_state = "plush_atmosian"
	attack_verb = list("thumped", "whomped", "bumped")
	resistance_flags = FIRE_PROOF

/obj/item/toy/plush/bm/laska
	name = "Lotti Plushie"
	desc = " Мягкая игрушка в форме кошки легко утолит вашу жажду объятий и ласки, от неё вы можете почувствовать легкий аромат пепла и сладковато ягодного вкуса."
	icon_state = "laska"
	squeak_override = list(
		'modular_bluemoon/SmiLeY/sounds/tiamat_mrrp1.ogg' = 1,
		'modular_bluemoon/SmiLeY/sounds/tiamat_mrrp2.ogg' = 1,
		'modular_bluemoon/SmiLeY/sounds/tiamat_meow1.ogg' = 1
	)

/obj/item/toy/plush/bm/plushy_savannah
	name = "Plushy Savannah"
	desc = "A plush felinigger for hard lesbian-sex and hugs."
	icon_state = "savannah"
	squeak_override = list('modular_bluemoon/sound/voice/moans.ogg' = 1)

/obj/item/toy/plush/bm/gaston
	name = "Gaston"
	desc = "Игрушка фиолетового цвета, её хозяин кажется так сильно любит фиолетовый, что красит буквально всё в этот цвет. Также эта игрушка кого-то явно напоминает из сотрудников на станции."
	icon_state = "gaston_toaster"
	attack_verb = list("beeped", "booped", "pinged")
	squeak_override = list('sound/machines/beep.ogg' = 1)

/obj/item/toy/plush/bm/grayson
	name = "Grayson plush"
	desc = "дорогая плюшевая игрушка! Сделана явно на заказ (и явно любителем прятатся в шкафах)"
	icon_state = "grayson"
	squeak_override = list('modular_bluemoon/sound/voice/graysonplush.ogg' = 1)

/obj/item/toy/plush/bm/who
	name = "security officer plushie"
	desc = "A stuffed toy that resembles a Nanotrasen operative. He smells like burnt cotton."
	icon_state = "who"
	attack_verb = list("shot", "nuked", "detonated")
	squeak_override = list('modular_bluemoon/sound/plush/security_1.ogg' = 9, 'modular_bluemoon/sound/plush/security_2.ogg' = 1)
	can_you_fuck_plush = FALSE // Стыгся не хотел бы, чтобы его игрушку ебали.

/obj/item/toy/plush/bm/qm
	name = "supply chief plushie"
	desc = "A stuffed toy that resembles a Cargonia Chief. Looks like a fallen economy."
	icon_state = "qm"
	attack_verb = list("bleated", "rammed", "kicked")

/obj/item/toy/plush/bm/judas
	name = "yellow shark plushie"
	desc = "An adorable stuffed plushie that resembles a yellow security shark."
	icon_state = "judas"
	squeak_override = list('modular_splurt/sound/voice/barks/undertale/voice_alphys.ogg' = 1)
	can_random_spawn = FALSE

/obj/item/toy/plush/bm/judas/vance
	name = "Vance plushie"
	desc = "A plush rodent, she smells like cheese and xenobiology!"
	icon_state = "vance"
	squeak_override = list(
		'sound/items/toysqueak1.ogg' = 1,
		'sound/items/toysqueak2.ogg' = 1,
		'sound/items/toysqueak3.ogg' = 1
	)

/obj/item/toy/plush/bm/omega
	name = "Omega plushie"
	desc = "This plushie really has an empty noggin and zero thoughts about commiting something especially cruel."
	icon_state = "omega"
	attack_verb = list("shot", "nuked", "detonated")
	squeak_override = list('modular_bluemoon/sound/plush/ooh.ogg' = 1)

/obj/item/toy/plush/bm/bao
	name = "Stupid cat plush"
	desc = "Every time you hug this toy, your IQ drops, but is it worth stopping because of this?."
	icon_state = "plushie_bao"
	squeak_override = list('modular_bluemoon/sound/plush/bao_sex.ogg' = 1)

/obj/item/toy/plush/bm/asgore
	name = "Bergentrückung plushie"
	desc = "Король подземной сказки."
	icon_state = "asgore"
	squeak_override = list('modular_bluemoon/sound/plush/savepoint.ogg' = 1)

/obj/item/toy/plush/bm/cirno
	name = "Cirno plushie"
	desc = "Чирно? Сырно? Даже она не знает как правильно произносить."
	icon_state = "cirno"
	squeak_override = list('modular_bluemoon/sound/plush/baka-cirno.ogg' = 1)

/obj/item/toy/plush/bm/doctor_k
	name = "Doctor K plushie"
	desc = "Это не входило в его планы."
	icon_state = "doctor_k"
	squeak_override = list('modular_bluemoon/sound/plush/miss.ogg' = 1)

/obj/item/toy/plush/bm/puro
	name = "Puro plushie"
	desc = "Он любит читать книжки."
	icon_state = "puro"
	squeak_override = list('modular_bluemoon/sound/plush/jump.ogg' = 1)

/obj/item/toy/plush/bm/hank
	name = "Hank plushie"
	desc = "Молчалив."
	icon_state = "hank"
	squeak_override = list('modular_bluemoon/sound/plush/grunt-kill.ogg' = 1)

#define BASIC_NEKO_SKIN "Silly Neko Plushie"
#define ANGRY_NEKO_SKIN "Angry Neko Plushie"
/obj/item/toy/plush/bm/silly_neko_plushie
	name = BASIC_NEKO_SKIN
	desc = "Cмешная плюшевая игрушка в виде забавной кошки, на бирке написано 'Осторожно, дешёвый, радиоактивный материал может вызвать уменьшение члена'."
	icon_state = "silly_neko_plushie"
	attack_verb = list("meows", "nya", "purrs")
	squeak_override = list(
		'modular_bluemoon/sound/plush/nekoark/necoarc-nyeh.ogg' = 1,
		'modular_bluemoon/sound/plush/nekoark/necoarc-1.ogg' = 1,
		'modular_bluemoon/sound/plush/nekoark/necoarc-2.ogg' = 1,
		'modular_bluemoon/sound/plush/nekoark/necoarc-3.ogg' = 1,
		'modular_bluemoon/sound/plush/nekoark/necoarc-4.ogg' = 1,
		'modular_bluemoon/sound/plush/nekoark/necoarc-5.ogg' = 1
	)
	always_reskinnable = TRUE
	unique_reskin = list(
		BASIC_NEKO_SKIN = list(RESKIN_ICON_STATE = "silly_neko_plushie", RESKIN_ITEM_STATE = "silly_neko_plushie"),
		ANGRY_NEKO_SKIN = list(RESKIN_ICON_STATE = "angry__neko_plushie", RESKIN_ITEM_STATE = "angry__neko_plushie")
	)
	COOLDOWN_DECLARE(change_neko_cooldown)

/obj/item/toy/plush/bm/silly_neko_plushie/reskin_obj(mob/user)
	. = ..()
	name = current_skin
	if(COOLDOWN_FINISHED(src, change_neko_cooldown))
		COOLDOWN_START(src, change_neko_cooldown, 6 SECONDS)
		switch(current_skin)
			if(BASIC_NEKO_SKIN)
				say("Burunya")
				playsound(src, 'modular_bluemoon/sound/plush/nekoark/burunya.ogg', 50, 1)
			else
				say("Dori dori dori dori")
				playsound(src, 'modular_bluemoon/sound/plush/nekoark/neco-arc-dori.ogg', 50, 1)
	if(ismob(loc))
		var/mob/M = loc
		M.update_inv_hands()

#undef BASIC_NEKO_SKIN
#undef ANGRY_NEKO_SKIN

/obj/item/toy/plush/bm/belinsky
	name = "Belinsky plushie"
	desc = "A toy that looks a lot like Kolyan Belinsky. Bushy moustache, eye patch, brown turtleneck. Everything in place."
	icon_state = "belinsky"
	squeak_override = list('modular_bluemoon/sound/plush/bel1.ogg' = 1, 'modular_bluemoon/sound/plush/bel2.ogg' = 9,)
	can_you_fuck_plush = FALSE

/obj/item/toy/plush/bm/belinsky/AltClick(mob/user)
	. = ..()
	if(iscarbon(user))
		var/mob/living/carbon/M = user
		if(M.client && M.client.ckey == "krashly")
			say("Свои! Свои!")

/obj/item/toy/plush/bm/tiamat/sierra_iris_plushie
	name = "I.R.I.S. plushie"
	desc = "От неё исходит характерный металлический запах.."
	icon_state = "iris"
	can_you_fuck_plush = FALSE

/obj/item/toy/plush/bm/millie
	name = "Millie plush"
	desc = "A cute pink girl. The soft silicone gives off a pleasant strawberry-raspberry scent. When you squeeze the doll slightly, her tongue comes out in a funny way."
	icon_state = "millie"
	squeak_override = list(
		'modular_bluemoon/sound/plush/milp1.ogg' = 1,
		'modular_bluemoon/sound/plush/milp2.ogg' = 1,
		'modular_bluemoon/sound/plush/milp3.ogg' = 1,
		'modular_bluemoon/sound/plush/milp4.ogg' = 1,
		'modular_bluemoon/sound/plush/milp5.ogg' = 1,
		'modular_bluemoon/sound/plush/milp6.ogg' = 1
		)
	var/obj/item/dildo/flared/huge/clash_target

/obj/item/toy/plush/bm/millie/Moved()
	. = ..()
	if(clash_target)
		return
	var/obj/item/dildo/flared/huge/P = locate() in range(1, src)
	if(P && istype(P.loc, /turf/open) && !P.clashing)
		clash_of_the_plushies(P)

/obj/item/toy/plush/bm/millie/proc/clash_of_the_plushies(obj/item/dildo/flared/huge/P)
	clash_target = P
	P.clashing = TRUE
	say("Палка для мастурбации!")
	P.say("Дура кошачья...")
	var/a_winnar_is
	var/victory_chance = 10
	for(var/i in 1 to 10) //We only fight ten times max
		if(QDELETED(src))
			P.clashing = FALSE
			return
		if(QDELETED(P))
			clash_target = null
			return
		if(!Adjacent(P))
			visible_message("<span class='warning'>The two plushies angrily flail at each other before giving up.</span>")
			clash_target = null
			P.clashing = FALSE
			return
		playsound(src, 'sound/magic/clockwork/ratvar_attack.ogg', 50, TRUE, frequency = 2)
		sleep(2.4)
		if(QDELETED(src))
			P.clashing = FALSE
			return
		if(QDELETED(P))
			clash_target = null
			return
		if(prob(victory_chance))
			a_winnar_is = src
			break
		P.SpinAnimation(5, 0)
		sleep(5)
		if(QDELETED(src))
			P.clashing = FALSE
			return
		if(QDELETED(P))
			clash_target = null
			return
		playsound(P, 'sound/magic/clockwork/narsie_attack.ogg', 50, TRUE, frequency = 2)
		sleep(3.3)
		if(QDELETED(src))
			P.clashing = FALSE
			return
		if(QDELETED(P))
			clash_target = null
			return
		if(prob(victory_chance))
			a_winnar_is = P
			break
		SpinAnimation(5, 0)
		victory_chance += 10
		sleep(5)
	if(!a_winnar_is)
		a_winnar_is = pick(src, P)
	if(a_winnar_is == src)
		say("Секс ликвидирован")
		playsound(src, 'sound/magic/clockwork/anima_fragment_attack.ogg', 50, TRUE, frequency = 2)
		playsound(P, 'sound/magic/demon_dies.ogg', 50, TRUE, frequency = 2)
		var/obj/effect/decal/cleanable/semen/femcum/V = new /obj/effect/decal/cleanable/semen/femcum(get_turf(src))
		V.desc = "Да, вам не показалось, это сделала игрушка."
		qdel(P)
		clash_target = null
	else
		P.say("Очередная розовая шлюха повержена")
		playsound(src, 'sound/magic/clockwork/anima_fragment_death.ogg', 62, TRUE, frequency = 2)
		playsound(P, 'sound/magic/demon_attack1.ogg', 50, TRUE, frequency = 2)
		var/datum/reagents/R = new(1)
		R.my_atom = P
		R.add_reagent(/datum/reagent/drug/aphrodisiac, 1)
		var/datum/effect_system/smoke_spread/chem/smoke = new
		smoke.set_up(R, 1, get_turf(P), FALSE)
		sleep(5)
		smoke.start()
		qdel(src)
		P.clashing = FALSE

///////////////////////////////////////////////
#define LOVE_INTERACTION_COOLDOWN 10 SECONDS

/obj/item/toy/plush/bm/lissara
	name = "Lissara plush"
	desc = "Очаровательная мягкая игрушка в форме миниатюрной ламии. Её гладкое тело приятно тянется под пальцами, а хвост — гибкий, словно зовёт обвиться вокруг запястья. При лёгком нажатии на животик игрушка тихо шипит, а её тонкий язычок чуть высовывается наружу."
	icon_state = "lissara"
	attack_verb = list("bitten", "hissed", "tail slapped")
	squeak_override = list('modular_citadel/sound/voice/hiss.ogg' = 6,
	'modular_splurt/sound/voice/raptor_purr.ogg' = 1
	)
	var/obj/item/toy/plush/bm/araminta/love_target
	var/last_love_interaction = 0

/obj/item/toy/plush/bm/lissara/Moved()
	. = ..()

	// Ограничение по процессу и времени на срабатывания
	if(!love_target && istype(src.loc, /turf/open) && world.time - last_love_interaction >= LOVE_INTERACTION_COOLDOWN)
		var/obj/item/toy/plush/bm/araminta/P = locate() in range(1, src)
		if(P && istype(P.loc, /turf/open) && !P.love_target && world.time - P.last_love_interaction >= LOVE_INTERACTION_COOLDOWN)
			spawn(1) // Что-то меняет пиксельную позицую после и так решаем приколы с бросками
				if(istype(src.loc, /turf/open) && istype(P.loc, /turf/open)) // Изъятие из контейнера изначально считается как на открытом турфе, поэтому перепроверяем еще раз
					loving_interaction(P)

/obj/item/toy/plush/bm/lissara/proc/loving_interaction(obj/item/toy/plush/bm/araminta/partner)
	var/turf/start = get_turf(src)
	var/turf/end = get_turf(partner)

	if(!start || !end) // На всякий случай
		return

	love_target = partner
	partner.love_target = src

	last_love_interaction = world.time
	partner.last_love_interaction = world.time

	var/list/original_pixel_offsets = list()
	for(var/obj/item/toy/plush/plushe in list(src, partner))
		// Сохраняем оригинальные позиции
		original_pixel_offsets[plushe] = list(
			"pixel_x" = plushe.pixel_x,
			"pixel_y" = plushe.pixel_y
		)
		// Останавливаем бросок и таскание
		plushe.forceMove(get_turf(plushe))
		qdel(plushe.throwing)

	// Проверяем: на одном ли тайле находятся игрушки
	var/same_tile = get_turf(src) == get_turf(partner)

	// Получаем координаты с учётом тайла и pixel-смещения
	var/x1 = same_tile ? src.pixel_x : src.x * 32 + src.pixel_x
	var/y1 = same_tile ? src.pixel_y : src.y * 32 + src.pixel_y
	var/x2 = same_tile ? partner.pixel_x : partner.x * 32 + partner.pixel_x
	var/y2 = same_tile ? partner.pixel_y : partner.y * 32 + partner.pixel_y

	var/dx = x2 - x1
	var/dy = y2 - y1

	var/distance = sqrt(dx * dx + dy * dy)

	// Целевое расстояние между игрушками
	var/const/target_distance = 16
	var/const/tolerance = 5

	// Нужно ли анимировать
	var/need_animate = abs(distance - target_distance) > tolerance

	if(need_animate)
		var/delta = (target_distance - distance) / 2.0

		var/norm_x = dx / max(distance, 1)
		var/norm_y = dy / max(distance, 1)

		var/shift_x = round(norm_x * delta)
		var/shift_y = round(norm_y * delta)

		if(same_tile)
			// Просто двигаем pixel_x / pixel_y
			animate(src, pixel_x = src.pixel_x - shift_x, pixel_y = src.pixel_y - shift_y, time = 6)
			animate(partner, pixel_x = partner.pixel_x + shift_x, pixel_y = partner.pixel_y + shift_y, time = 6)
		else
			// Смещаем абсолютные координаты, потом пересчитываем обратно
			var/final_x1 = x1 - shift_x
			var/final_y1 = y1 - shift_y
			var/final_x2 = x2 + shift_x
			var/final_y2 = y2 + shift_y

			animate(src, pixel_x = final_x1 - (src.x * 32), pixel_y = final_y1 - (src.y * 32), time = 6)
			animate(partner, pixel_x = final_x2 - (partner.x * 32), pixel_y = final_y2 - (partner.y * 32), time = 6)

	// Диалог
	src.say(pick(
		"Привет, дорогая~",
		"Скучала по тебе~",
		"Ты прекрасна, как и всегда~",
		"Наконец-то мы вместе~",
		"Ты такая теплая~",
		"Ара~",
		"Обними меня крепче~",
		"Моя кошечка~"))

	partner.say(pick(
		"Приветик, любимая~",
		"Люблю тебя~",
		"Обожаю~",
		"Лисс~",
		"Моя змейка~",
		"Я так скучала по тебе~",
		"Ты моя, навсегда~",
		"Иди сюда, моя красавица~"))

	var/heart_broken = FALSE // Если игрушки разняли, что бы не играть анимацию

	for(var/i = 1, i <= 4, i++)
		if(src.loc != start || partner.loc != end) // Если игрушки передвинули в процессе
			var/static/list/heart_broken_say = list(
				"Не-ет!",
				"Не разлучай нас!",
				"Верни меня!",
				"Почему ты вмешался?!",
				"Не забирай её у меня!",
				"Это жестоко!",
				"Я просто хотела быть с ней!"
			)
			src.say(pick(heart_broken_say))
			partner.say(pick(heart_broken_say))
			heart_broken = TRUE
			break
		new /obj/effect/temp_visual/heart(get_turf(src))
		new /obj/effect/temp_visual/heart(get_turf(partner))
		if(i % 2 == 0)
			playsound(partner.loc, pick(GLOB.lewd_kiss_sounds), 90, TRUE, -1)
		else
			playsound(src.loc, pick(GLOB.lewd_kiss_sounds), 90, TRUE, -1)
		sleep(8)

	if(need_animate)
		for(var/obj/item/toy/plush/plushe in list(src, partner))
			var/list/offsets = original_pixel_offsets[plushe]
			if(heart_broken)
				plushe.pixel_x = offsets["pixel_x"]
				plushe.pixel_y = offsets["pixel_y"]
			else
				animate(plushe, pixel_x = offsets["pixel_x"], pixel_y = offsets["pixel_y"], time = 6)
	love_target = null
	partner.love_target = null


/obj/item/toy/plush/bm/araminta
	name = "Araminta plush"
	desc = "Плюшевая игрушка, вооруженная белыми лапками, готова совершить величайшее ограбление — украсть ваше свободное время."
	icon_state = "araminta"
	attack_verb = list("meow", "nya", "purrs")
	squeak_override = list('modular_bluemoon/SmiLeY/sounds/allta_mew1.ogg' = 1,
	'modular_bluemoon/sound/voice/short_purr_silent.ogg' = 1
	)
	var/obj/item/toy/plush/bm/lissara/love_target
	var/last_love_interaction = 0

/obj/item/toy/plush/bm/araminta/Moved()
	. = ..()

	// Ограничение по процессу и времени на срабатывания
	if(!love_target && istype(src.loc, /turf/open) && world.time - last_love_interaction >= LOVE_INTERACTION_COOLDOWN)
		var/obj/item/toy/plush/bm/lissara/P = locate() in range(1, src)
		if(P && istype(P.loc, /turf/open) && !P.love_target && world.time - P.last_love_interaction >= LOVE_INTERACTION_COOLDOWN)
			spawn(1) // Что-то меняет пиксельную позицую после и так решаем приколы с бросками
				if(istype(src.loc, /turf/open) && istype(P.loc, /turf/open)) // Изъятие из контейнера изначально считается как на открытом турфе, поэтому перепроверяем еще раз
					P.loving_interaction(src)

#undef LOVE_INTERACTION_COOLDOWN
///////////////////////////////////////////////

/obj/item/toy/plush/bm/stasik/artemq
	name = "Artems toy plush"
	desc = "Вы видите игрушку,одетую в стандатную форму inteQ. Смотря в удивленное плюшевое лицо,она вам подозрительно кого-то напоминает. Точно можно сказать что игрушка кого то испугалась. Но кого мог испугаться плюшевый интековец?"
	icon_state = "artems"
	squeak_override = list('modular_bluemoon/sound/voice/graysonplush.ogg' = 2, 'modular_bluemoon/sound/voice/stasik_volcahara.ogg' = 1,)

/obj/item/toy/plush/bm/carrion
	name = "Monster plushie"
	desc = "One of the many monsters bred by geneticists. This one is made of synthetic materials, very soft, and can be used as an anti-stress tool. Especially for fans!"
	icon_state = "carrion"
	attack_verb = list("squish", "glorp", "blorp")
	squeak_override = list('modular_bluemoon/sound/voice/fleshy_squish.ogg' = 1)

/obj/item/toy/plush/bm/loki
	name = "Loki plushie"
	desc = "Плюшевая версия зелёного авали по имени Локи. Игрушка приятная на ощупь, её поверхность покрыта мягкими пушинками, а на передних лапках и основании хвоста имеются искусственные перья. Пахнет лаймом и мятой. При нажатии на игрушку воспроизводится тихое чириканье, а ушки слегка шевелятся."
	icon_state = "loki"
	squeak_override = list('modular_splurt/sound/voice/chirp.ogg' = 2, 'modular_splurt/sound/voice/teshtrill.ogg' = 1,)

/obj/item/toy/plush/bm/uchi
	name = "Uchi plushie"
	desc = "Эта игрушка в форме авали достаточно мягка на ощупь и притягивает своим ярковатым видом, от нее пахнет очистителем и мылом. Безмятежная улыбка на ней внушает спокойствие и легкую радость, а держа долго ее в руках, появляется смутное желание оттирать каждое пятнышко на своем рабочем месте.  Искусственные перья на лапах игрушки чуть-чуть щекочут руки держащего."
	icon_state = "yuchi"
	squeak_override = list('modular_splurt/sound/voice/chirp.ogg' = 2, 'modular_splurt/sound/voice/teshtrill.ogg' = 1,)

/obj/item/toy/plush/bm/catshark
	name = "Catshark"
	desc = "Плюшевая игрушка странной.. акулы? Кошки? Не разобрать, но от неё очень сильно тянет клубничными сырками. Кажется внутри есть механизм что приводит игрушку в движение... и он заклинил."
	icon_state = "catshark"
	attack_verb = list("Rawr", "Meow", "Meowr")
	squeak_override = list(
		'modular_bluemoon/sound/plush/catshark1.ogg' = 1,
		'modular_bluemoon/sound/plush/catshark2.ogg' = 1
	)

/obj/item/toy/plush/bm/chellicoll
	name = "Sosona"
	desc = "Акула с глупой мордой"
	icon_state = "chellicoll"
	attack_verb = list("Rawrs")
	squeak_override = list('modular_bluemoon/sound/voice/rawr.ogg' = 1)

/obj/item/toy/plush/bm/fred
	name = "Fred"
	desc = "Это камень. Его зовут Фред."
	icon_state = "fred"
	attack_verb = list("Smash")

/obj/item/toy/plush/bm/roxie
	name = "Roxie"
	desc = "Это камень. Ее зовут Рокси. Выглядит миленько с бантиком."
	icon_state = "roxie"
	attack_verb = list("Smash")

/obj/item/toy/plush/bm/Sheya
	name = "Vampire"
	desc = "Вампирша, одетая в готическую одежду"
	icon_state = "sheya"
	icon = 'modular_bluemoon/icons/obj/toys/plushies 32x48.dmi'
	attack_verb = list("bit")
	can_you_fuck_plush = FALSE

/obj/item/toy/plush/bm/Sheya/slime
	name = "Sheya"
	desc = "Слайм, выглядящая как лиса, представляющая что она тигр."
	icon_state = "sheya_slime"
	icon = 'modular_bluemoon/icons/obj/toys/plushies 32x48.dmi'
	attack_verb = list("squish", "glorp", "blorp")
	squeak_override = list('modular_bluemoon/sound/voice/fleshy_squish.ogg' = 1)
	can_you_fuck_plush = FALSE

/obj/item/toy/plush/bm/Sheya/melting
	name = "Melting love"
	desc = "Слайм с сердцем на груди и на голове, вместо ног у неё лужа слизи."
	icon_state = "sheya_melting"
	icon = 'modular_bluemoon/icons/obj/toys/plushes.dmi'
	attack_verb = list("squish", "glorp", "blorp")
	squeak_override = list('modular_bluemoon/sound/voice/fleshy_squish.ogg' = 1)
	can_you_fuck_plush = FALSE

/obj/item/toy/plush/bm/vella
	name = "Vella plushie"
	desc = "Почти плюшевая игрушка, наполнение которой по каким-то неведомым законам физики стало прозрачным. На ощупь очень сильно напоминает слизьку, а запах выдаёт гамму разнообразных ягодных ноток."
	icon_state = "vella"
	squeak_override = list('modular_splurt/sound/voice/catpeople/cat_mrrp1.ogg' = 1)

/obj/item/toy/plush/bm/belfor
	name = "Belfor plushie"
	desc = "Белая как сахарная вата игрушка кота-учёного Синдиката. Его пушистый хвост в форме запятой лишь добавляет контраста. От него пахнет бридингом. Стоп.. что такое бридинг?"
	icon_state = "belfor"
	squeak_override = list('modular_splurt/sound/voice/meow_meme.ogg' = 1, 'modular_splurt/sound/voice/woof.ogg' = 1)

/obj/item/toy/plush/bm/koteykomya
	name = "Silly kitty plushie"
	desc = "У неё осуждающий взгляд, как будто она в курсе всего, что вы когда-либо делали не так."
	icon_state = "koteykomya"
	squeak_override = list('modular_bluemoon/sound/plush/Koteyko_bad_smell.ogg' = 1, 'modular_bluemoon/sound/plush/Koteyko_rotting.ogg' = 1, 'modular_bluemoon/sound/plush/Koteyko_dicks_and_butts.ogg' = 1)
