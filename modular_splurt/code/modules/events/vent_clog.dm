/datum/round_event_control/scrubber_overflow/cope_and_seethe
	name = "Copium Flood"
	typepath = /datum/round_event/scrubber_overflow/cope_and_seethe
	enabled = FALSE

/datum/round_event/scrubber_overflow/cope_and_seethe/announce()
	priority_announce("Мы обнаружили высокий уровень Агрессии на станции. Для борьбы с этим мы будем использовать массовое количество копиума. Пожалуйста, держитесь подальше от вентиляционных отверстий, пока давление не выровняется.", "Центральное Командование")

/datum/round_event/scrubber_overflow/cope_and_seethe
	safer_chems = list(
		/datum/reagent/drug/copium
	)

/datum/round_event/scrubber_overflow/cope_and_seethe/start()
	for (var/obj/machinery/atmospherics/components/unary/vent in scrubbers)
		if (vent && vent.loc && !vent.welded)
			var/datum/reagents/R = new/datum/reagents(1000)
			R.my_atom = vent
			R.add_reagent(/datum/reagent/drug/copium, 5)

			var/datum/effect_system/smoke_spread/chem/smoke = new
			smoke.set_up(R, 7, get_turf(vent), TRUE)
			smoke.start()
		CHECK_TICK

/datum/round_event_control/scrubber_overflow/female
	name = "Clogged Vents: Girlcum"
	typepath = /datum/round_event/scrubber_overflow/female
	// Компромисс с прода: кам-ивенты живут только в эксте и лайте, в боевых динамиках их нет.
	// Целевая частота "раз в 5-8 экст" задана явным весом и гейтом типов раундов напрямую,
	// поэтому метка mild: профильный множитель disruptive задавил бы её ниже согласованной.
	weight = 8
	max_occurrences = 1
	required_round_type = list(ROUNDTYPE_EXTENDED, ROUNDTYPE_DYNAMIC_LIGHT)
	disruption = DIRECTOR_DISRUPTION_MILD
	category = EVENT_CATEGORY_JANITORIAL

/datum/round_event/scrubber_overflow/female
	safer_chems = list(
		/datum/reagent/consumable/semen/femcum
	)
	reagents_amount = 100

/datum/round_event/scrubber_overflow/female/announce()
	priority_announce("Сеть скрубберов испытывает противодавление из-за откуда-то взявшегося в них СКВИРТА. Может произойти некоторое разбрызгивание содержимого.", "Атмосферная Тревога", 'sound/announcer/classic/ventclog.ogg')

/datum/round_event/scrubber_overflow/female/start()
	for(var/obj/machinery/atmospherics/components/unary/vent in scrubbers)
		if(vent && vent.loc && !vent.welded)
			var/datum/reagents/R = new/datum/reagents(1000)
			R.my_atom = vent
			R.add_reagent(/datum/reagent/consumable/semen/femcum, reagents_amount)

			var/datum/effect_system/foam_spread/foam = new
			foam.set_up(200, get_turf(vent), R)
			foam.start()
		CHECK_TICK

/datum/round_event_control/scrubber_overflow/male
	name = "Clogged Vents: Semen"
	typepath = /datum/round_event/scrubber_overflow/male
	// Компромисс с прода: см. комментарий у Girlcum выше - только экста/лайт, "раз в 5-8 экст".
	weight = 8
	max_occurrences = 1
	required_round_type = list(ROUNDTYPE_EXTENDED, ROUNDTYPE_DYNAMIC_LIGHT)
	disruption = DIRECTOR_DISRUPTION_MILD
	category = EVENT_CATEGORY_JANITORIAL

/datum/round_event/scrubber_overflow/male
	safer_chems = list(
		/datum/reagent/consumable/semen
	)
	reagents_amount = 100

/datum/round_event/scrubber_overflow/male/announce()
	priority_announce("Сеть скрубберов испытывает противодавление из-за откуда-то взявшегося в них СЕМЕНИ. Может произойти некоторое разбрызгивание содержимого.", "Атмосферная Тревога", 'sound/announcer/classic/ventclog.ogg')

/datum/round_event/scrubber_overflow/male/start()
	for(var/obj/machinery/atmospherics/components/unary/vent in scrubbers)
		if(vent && vent.loc && !vent.welded)
			var/datum/reagents/R = new/datum/reagents(1000)
			R.my_atom = vent
			R.add_reagent(/datum/reagent/consumable/semen, reagents_amount)

			var/datum/effect_system/foam_spread/foam = new
			foam.set_up(200, get_turf(vent), R)
			foam.start()
		CHECK_TICK

/datum/round_event_control/scrubber_overflow/crocin
	name = "Aphrodisiac Flood"
	typepath = /datum/round_event/scrubber_overflow/crocin
	admin_setup = list()
	// Тот же компромисс, что и у кам-ивентов выше: только экста/лайт, редкий явный вес.
	weight = 10
	max_occurrences = 1
	required_round_type = list(ROUNDTYPE_EXTENDED, ROUNDTYPE_DYNAMIC_LIGHT)
	disruption = DIRECTOR_DISRUPTION_MILD

/datum/round_event/scrubber_overflow/crocin
	safer_chems = list(
		/datum/reagent/drug/aphrodisiac
	)
	reagents_amount = 100
	var/reagent = /datum/reagent/drug/aphrodisiac

/datum/round_event/scrubber_overflow/crocin/announce()
	priority_announce("Мы обнаружили снижение уровня похоти на станции. Чтобы исправить это, мы будем использовать большое количество легкого афродизиака. Пожалуйста, держитесь подальше от вентиляционных отверстий, пока розовый газ не рассеется.", "Центральное Командование")

/datum/round_event/scrubber_overflow/crocin/start()
	for(var/obj/machinery/atmospherics/components/unary/vent in scrubbers)
		if(vent && vent.loc && !vent.welded)
			var/datum/reagents/R = new(1000)
			R.my_atom = vent
			R.add_reagent(reagent, reagents_amount)

			var/datum/effect_system/smoke_spread/chem/smoke = new
			smoke.set_up(R, 10, get_turf(vent), FALSE)
			smoke.start()
		CHECK_TICK

/datum/round_event_control/scrubber_overflow/crocin/hexacrocin
	name = "Strong Aphrodisiac Flood"
	typepath = /datum/round_event/scrubber_overflow/crocin/hexacrocin
	admin_setup = list()
	enabled = FALSE //Only adminspawn because this one causes brain damage

/datum/round_event/scrubber_overflow/crocin/hexacrocin
	safer_chems = list(
		/datum/reagent/drug/aphrodisiacplus
	)
	reagent = /datum/reagent/drug/aphrodisiacplus

/datum/round_event/scrubber_overflow/crocin/hexacrocin/announce()
	priority_announce("Мы обнаружили опасно низкий уровень похоти на станции. Чтобы исправить это, мы будем использовать большое количество сильных афродизиаков. Пожалуйста, не подходите к вентиляционным отверстиям, пока розовый газ не рассеется, если вы хотите избежать повреждения мозга.", "Центральное Командование")

/datum/round_event_control/scrubber_overflow/beer
	name = "Clogged Vents: Beer"
	typepath = /datum/round_event/scrubber_overflow/beer
	enabled = FALSE
	description = "Spits out beer through the scrubber system."

/datum/round_event/scrubber_overflow/beer
	reagents_amount = 100

/datum/round_event/scrubber_overflow/beer/announce()
	priority_announce("Сеть скрубберов испытывает противодавление из-за пива. Возможен некоторый выброс содержимого.", "Центральное Командование", 'sound/announcer/classic/ventclog.ogg')

/datum/round_event/scrubber_overflow/beer/start()
	for(var/obj/machinery/atmospherics/components/unary/vent in scrubbers)
		if(vent && vent.loc && !vent.welded)
			var/datum/reagents/R = new/datum/reagents(1000)
			R.my_atom = vent
			R.add_reagent(/datum/reagent/consumable/ethanol/beer, reagents_amount)

			var/datum/effect_system/foam_spread/foam = new
			foam.set_up(200, get_turf(vent), R)
			foam.start()
		CHECK_TICK
