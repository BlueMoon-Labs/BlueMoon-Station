// Embedded signaller used in anomalies.
/obj/item/assembly/signaler/anomaly
	name = "anomaly core"
	desc = "Обезвреженное ядро аномалии. Скорее всего, оно будет полезно для науки."
	icon_state = "anomaly_core"
	max_integrity = 1000
	//item_state = "electronic"
	lefthand_file = 'icons/mob/inhands/misc/devices_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/misc/devices_righthand.dmi'
	resistance_flags = FIRE_PROOF
	var/anomaly_type = /obj/effect/anomaly

/obj/item/assembly/signaler/anomaly/examine(mob/user)
	. = ..()
	var/healthpercent = (obj_integrity/max_integrity) * 100
	switch(healthpercent)
		if(50 to 99)
			. += span_warning("Выглядит слегка поврежденным.")
		if(25 to 50)
			. += span_warning("Выглядит крайне поврежденным.")
		if(0 to 25)
			. += span_warning("Вот-вот развалится!")

/obj/item/assembly/signaler/anomaly/receive_signal(datum/signal/signal)
	if(!signal)
		return FALSE
	if(signal.data["code"] != code)
		return FALSE
	if(suicider)
		manual_suicide(suicider)
	for(var/obj/effect/anomaly/A in get_turf(src))
		A.anomalyNeutralize()
	return TRUE

/obj/item/assembly/signaler/anomaly/deconstruct(disassembled)
	if(!disassembled)
		new /obj/effect/decal/cleanable/ash(get_turf(src))
	return ..()

/obj/item/assembly/signaler/anomaly/manual_suicide(mob/living/carbon/user)
	user.visible_message(span_suicide("[user] искажается телом, как только начинает реагировать на флуктуации [src]!"))
	//user.set_suicide(TRUE)
	user.suicide_log()
	user.gib()

/obj/item/assembly/signaler/anomaly/attackby(obj/item/I, mob/user, params)
	if(I.tool_behaviour == TOOL_ANALYZER)
		to_chat(user, span_notice("Анализ... Нестабильное поле вокруг [src] колеблется флуктуациями частоты [format_frequency(aSignal.frequency)] и кода [aSignal.code]."))
	return ..()

//Anomaly cores
/obj/item/assembly/signaler/anomaly/pyro
	name = "\improper pyroclastic anomaly core"
	desc = "Обезвреженное ядро пирокластической аномалии. Тёплое на ощупь. Скорее всего, оно будет полезно для науки."
	icon_state = "pyro_core"
	anomaly_type = /obj/effect/anomaly/pyro

/obj/item/assembly/signaler/anomaly/grav
	name = "\improper gravitational anomaly core"
	desc = "Обезвреженное ядро гравитационной аномалии. Кажется гораздо тяжелее, чем выглядит. Скорее всего, оно будет полезно для науки."
	icon_state = "grav_core"
	anomaly_type = /obj/effect/anomaly/grav

/obj/item/assembly/signaler/anomaly/flux
	name = "\improper flux anomaly core"
	desc = "Обезвреженное ядро флукс-аномалии. От прикосновения кожа начинает покалывать. Скорее всего, оно будет полезно для науки."
	icon_state = "flux_core"
	anomaly_type = /obj/effect/anomaly/flux

/obj/item/assembly/signaler/anomaly/bluespace
	name = "\improper bluespace anomaly core"
	desc = "Обезвреженное ядро блюспейс-аномалии. Постоянно мерцает, то появляясь, то исчезая из виду. Скорее всего, оно будет полезно для науки."
	icon_state = "anomaly_core"
	anomaly_type = /obj/effect/anomaly/bluespace

/obj/item/assembly/signaler/anomaly/vortex
	name = "\improper vortex anomaly core"
	desc = "Обезвреженное ядро вихревой аномалии. Не может усидеть на месте, словно на него действует невидимая сила. Скорее всего, оно будет полезно для науки."
	icon_state = "vortex_core"
	anomaly_type = /obj/effect/anomaly/bhole

/obj/item/assembly/signaler/anomaly/dimensional
	name = "\improper dimensional anomaly core"
	desc = "Обезвреженное ядро пространственной аномалии. Отражённые на его поверхности предметы выглядят как-то неправильно. Скорее всего, оно будет полезно для науки."
	icon_state = "dimensional_core"
	anomaly_type = /obj/effect/anomaly/dimensional

/obj/item/assembly/signaler/anomaly/ectoplasm
	name = "\improper ectoplasm anomaly core"
	desc = "Обезвреженное ядро эктоплазменной аномалии. Если поднести его ближе, внутри можно услышать тихий шёпот. Скорее всего, оно будет полезно для науки."
	icon_state = "dimensional_core"
	anomaly_type = /obj/effect/anomaly/ectoplasm

/obj/item/assembly/signaler/anomaly/poly
	name = "\improper polymorph anomaly core"
	desc = "Обезвреженное ядро полиморфной аномалии. Кажется гораздо тяжелее, чем выглядит. Скорее всего, оно будет полезно для науки."
	icon_state = "vortex_core"
	anomaly_type = /obj/effect/anomaly/poly

/obj/item/assembly/signaler/anomaly/fog
	name = "\improper fog anomaly core"
	desc = "Обезвреженное ядро туманной аномалии. Постоянно выпускает густую завесу быстро исчезающего дыма."
	icon_state = "dimensional_core"
	anomaly_type = /obj/effect/anomaly/fog
