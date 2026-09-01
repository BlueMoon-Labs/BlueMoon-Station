//nutrition
/datum/mood_event/fat
	mood_change = -4

/datum/mood_event/fat/add_effects(param)
	. = ..()
	var/mob/living/carbon/human/owner_mob = owner_mob()
	description = span_warning("<B>Я так[owner_mob.ru_aya_oy()] толст[owner_mob.ru_aya()]...</B>\n") //muh fatshaming
	description_robotic = span_warning("<B>Я перезаряже[owner_mob.ru_a()] энергией...</B>\n")

/datum/mood_event/wellfed
	mood_change = 6

/datum/mood_event/wellfed/add_effects(param)
	. = ..()
	var/mob/living/carbon/human/owner_mob = owner_mob()
	description = span_nicegreen("Я нае[owner_mob.ru_sya()]!\n")
	description_robotic = span_nicegreen("Я полностью заряжен[owner_mob.ru_a()].\n")

/datum/mood_event/fed
	description = span_nicegreen("У меня недавно был перекус.\n")
	description_robotic = span_nicegreen("Моя батарея заряжена.\n")
	mood_change = 3

/datum/mood_event/hungry
	description = span_warning("Я начинаю немного голодать.\n")
	description_robotic = span_warning("Я начинаю терять заряд.\n")
	mood_change = -8

/datum/mood_event/starving
	description = span_boldwarning("Я голодаю!\n")
	description_robotic = span_boldwarning("Малый заряд энергии, включён энергосберегающий режим!\n")
	mood_change = -15

//charge
/datum/mood_event/supercharged
	description = "<span class='boldwarning'>Я не могу держать в себе всю эту энергию, нужно срочно её выплеснуть!</span>\n"
	mood_change = -10

/datum/mood_event/overcharged
	description = "<span class='warning'>Ощущаю у себя опасный избыток энергии, лучше бы выпустить немного.</span>\n"
	mood_change = -4

/datum/mood_event/charged
	description = "<span class='nicegreen'>Я чувствую, как энергия течёт по венам!</span>\n"
	mood_change = 6

/datum/mood_event/lowpower
	description = "<span class='warning'>Мой запас энергии истощается, надо бы подзарядиться.</span>\n"
	mood_change = -6

/datum/mood_event/decharged
	description = "<span class='boldwarning'>Мне срочно нужна энергия!</span>\n"
	mood_change = -10

//Disgust
/datum/mood_event/gross
	mood_change = -2

/datum/mood_event/gross/add_effects(param)
	. = ..()
	var/mob/living/carbon/human/owner_mob = owner_mob()
	description = "<span class='warning'>Я увидел[owner_mob.ru_a()] нечто мерзкое.</span>\n"

/datum/mood_event/verygross
	description = "<span class='warning'>Кажется, меня сейчас вырвет...</span>\n"
	mood_change = -5

/datum/mood_event/disgusted
	description = "<span class='boldwarning'>Господи, это было отвратительно...</span>\n"
	mood_change = -8

/datum/mood_event/disgust/bad_smell
	description = "<span class='warning'>В помещении что-то гниет.</span>\n"
	mood_change = -3

/datum/mood_event/disgust/nauseating_stench
	description = "<span class='warning'>Вонь разлагающегося тела невыносима!</span>\n"
	mood_change = -7

//Generic needs events
/datum/mood_event/favorite_food
	description = "<span class='nicegreen'>Мне понравилась эта еда.</span>\n"
	mood_change = 3
	timeout = 2400

/datum/mood_event/favorite_food/russian
	description = "<span class='nicegreen'>Ммм... наконец-то, блядь, нормальная еда... водка!</span>\n"
	mood_change = 6
	timeout = 4800

/datum/mood_event/gross_food
	description = "<span class='warning'>Мне вообще не понравилась эта еда.</span>\n"
	mood_change = -2
	timeout = 2400

/datum/mood_event/disgusting_food
	description = "<span class='warning'>Эта еда была отвратительна!</span>\n"
	mood_change = -4
	timeout = 2400

/datum/mood_event/nice_shower
	mood_change = 2
	timeout = 3 MINUTES

/datum/mood_event/nice_shower/add_effects(param)
	. = ..()
	var/mob/living/carbon/human/owner_mob = owner_mob()
	description = "<span class='nicegreen'>Я недавно сходил[owner_mob.ru_a()] в душ.</span>\n"
