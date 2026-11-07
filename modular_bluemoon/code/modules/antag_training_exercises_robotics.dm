#define ANTAG_TRAINING_RIPLEY_CABLE 5
#define ANTAG_TRAINING_RIPLEY_METAL 5
#define ANTAG_TRAINING_RIPLEY_RODS 10

/datum/antag_training_exercise/drill/robotics
	sector = "robotics"

/datum/antag_training_exercise/drill/robotics/cyborg
	id = "robotics_cyborg"
	name = "Собери киборга"
	desc = "Тело-донор, MMI и учебная рама выдаются рядом с вами. Извлеките мозг на операционном столе, вставьте его в MMI, а MMI - в раму."
	difficulty = 2
	par_time = 2 MINUTES
	target_required = FALSE
	steps = list(/datum/antag_training_exercise_step/drill/brain_out, /datum/antag_training_exercise_step/drill/brain_mmi, /datum/antag_training_exercise_step/drill/mmi_frame)

/datum/antag_training_exercise/drill/robotics/cyborg/setup(datum/antag_training_session/session)
	var/list/spots = free_spots(session, 2)
	if(length(spots) < 2 || !target_slot_free(session))
		return FALSE
	var/datum/antag_training_exercise_run/run = session.exercise_run
	run.add_prop(new /obj/item/robot_suit/prebuilt/training(spots[1]), FALSE)
	run.add_prop(new /obj/item/mmi(spots[2]), FALSE)
	var/datum/antag_training_sector/workshop = session.arena.sectors[sector]
	var/obj/structure/table/optable/table = locate() in workshop.sector_area
	prepare_target(session, "corpse", table ? get_turf(table) : get_turf(session.current_body))
	return TRUE

/datum/antag_training_exercise_step/drill/brain_out
	name = "Извлеките мозг"
	hint = "Положите тело-донор на операционный стол, выберите голову, накройте её хирургической простынёй и выберите Organ manipulation: скальпель, ретрактор, пила, зажим, снова скальпель, затем зажимом достаньте мозг. Инструменты и простыня - в комплекте «Робототехник» на вкладке «Начать»."

/datum/antag_training_exercise_step/drill/brain_out/attach(datum/antag_training_exercise_run/owner)
	. = ..()
	var/mob/living/carbon/human/donor = owner.find_prop(/mob/living/carbon/human)
	if(!donor)
		return
	RegisterSignal(donor, COMSIG_PARENT_QDELETING, PROC_REF(on_donor_deleted))
	if(donor.mind)
		RegisterSignal(donor.mind, COMSIG_MIND_TRANSFER, PROC_REF(on_transfer))

/datum/antag_training_exercise_step/drill/brain_out/proc/on_donor_deleted()
	SIGNAL_HANDLER
	run.finish(FALSE, "тело-донор удалено раньше, чем из него достали мозг")

/datum/antag_training_exercise_step/drill/brain_out/proc/on_transfer(datum/mind/source, mob/living/new_body)
	SIGNAL_HANDLER
	if(isbrain(new_body) && istype(new_body.loc, /obj/item/organ/brain))
		run.add_prop(new_body.loc, FALSE)
		complete()

/datum/antag_training_exercise_step/drill/brain_mmi
	name = "Вставьте мозг в MMI"
	hint = "Возьмите мозг и нажмите им на MMI: один выдан рядом с вами, ещё несколько лежат в мастерской."

/datum/antag_training_exercise_step/drill/brain_mmi/attach(datum/antag_training_exercise_run/owner)
	. = ..()
	var/obj/item/organ/brain/brain = owner.find_prop(/obj/item/organ/brain)
	if(brain)
		RegisterSignal(brain, COMSIG_MOVABLE_MOVED, PROC_REF(on_brain_moved))

/datum/antag_training_exercise_step/drill/brain_mmi/proc/on_brain_moved(obj/item/organ/brain/source)
	SIGNAL_HANDLER
	if(istype(source.loc, /obj/item/mmi))
		complete()

/datum/antag_training_exercise_step/drill/mmi_frame
	name = "Вставьте MMI в раму"
	hint = "Учебная рама киборга стоит на полу рядом с вами. Нажмите на неё MMI с мозгом."

/datum/antag_training_exercise_step/drill/mmi_frame/attach(datum/antag_training_exercise_run/owner)
	. = ..()
	var/obj/item/organ/brain/brain = owner.find_prop(/obj/item/organ/brain)
	var/obj/item/mmi/mmi = brain?.loc
	// Мозг входит в MMI раньше своего brainmob: сразу после вставки разум ещё у мозга.
	var/datum/mind/donor_mind = brain?.brainmob?.mind || (istype(mmi) ? mmi.brainmob?.mind : null)
	if(donor_mind)
		RegisterSignal(donor_mind, COMSIG_MIND_TRANSFER, PROC_REF(on_transfer))

/datum/antag_training_exercise_step/drill/mmi_frame/proc/on_transfer(datum/mind/source, mob/living/new_body)
	SIGNAL_HANDLER
	if(iscyborg(new_body))
		run.add_prop(new_body, FALSE)
		complete()

/datum/antag_training_exercise/drill/robotics/ripley
	id = "robotics_ripley"
	name = "Собери Рипли"
	desc = "Шасси Рипли и ящик с деталями, платами и материалами выдаются рядом с вами, инструменты - в комплекте «Робототехник». Соберите мех по шагам: конечности, гидравлика и проводка, платы, модули, обшивка."
	difficulty = 3
	par_time = 3 MINUTES
	steps = list(/datum/antag_training_exercise_step/drill/ripley, /datum/antag_training_exercise_step/drill/ripley/wiring, /datum/antag_training_exercise_step/drill/ripley/boards, /datum/antag_training_exercise_step/drill/ripley/modules, /datum/antag_training_exercise_step/drill/ripley/plating)
	var/static/list/kit = list(
		/obj/item/mecha_parts/part/ripley_torso = 1,
		/obj/item/mecha_parts/part/ripley_left_arm = 1,
		/obj/item/mecha_parts/part/ripley_right_arm = 1,
		/obj/item/mecha_parts/part/ripley_left_leg = 1,
		/obj/item/mecha_parts/part/ripley_right_leg = 1,
		/obj/item/circuitboard/mecha/ripley/main = 1,
		/obj/item/circuitboard/mecha/ripley/peripherals = 1,
		/obj/item/stock_parts/scanning_module = 1,
		/obj/item/stock_parts/capacitor = 1,
		/obj/item/stock_parts/cell/high = 1,
		/obj/item/stack/cable_coil = ANTAG_TRAINING_RIPLEY_CABLE,
		/obj/item/stack/sheet/metal = ANTAG_TRAINING_RIPLEY_METAL,
		/obj/item/stack/rods = ANTAG_TRAINING_RIPLEY_RODS,
	)

/datum/antag_training_exercise/drill/robotics/ripley/setup(datum/antag_training_session/session)
	var/list/spots = free_spots(session, 2)
	if(length(spots) < 2)
		return FALSE
	var/datum/antag_training_exercise_run/run = session.exercise_run
	run.add_prop(new /obj/item/mecha_parts/chassis/ripley(spots[1]), FALSE)
	var/obj/structure/closet/crate/crate = new(spots[2])
	run.add_prop(crate, FALSE)
	for(var/part_type in kit)
		run.add_prop(ispath(part_type, /obj/item/stack) ? new part_type(crate, kit[part_type]) : new part_type(crate), FALSE)
	return TRUE

/// Шаг сборки Рипли засчитывается, когда компонент сборки шасси прошёл свой этап.
/datum/antag_training_exercise_step/drill/ripley
	name = "Соберите шасси"
	hint = "Достаньте детали из ящика и нажмите на шасси торсом, обеими руками и обеими ногами в любом порядке."

/datum/antag_training_exercise_step/drill/ripley/attach(datum/antag_training_exercise_run/owner)
	. = ..()
	var/obj/item/mecha_parts/chassis/ripley/chassis = owner.find_prop(/obj/item/mecha_parts/chassis/ripley)
	if(!chassis)
		return
	RegisterSignal(chassis, COMSIG_PARENT_ATTACKBY, PROC_REF(on_attackby))
	RegisterSignal(chassis, COMSIG_PARENT_QDELETING, PROC_REF(on_chassis_deleted))

/datum/antag_training_exercise_step/drill/ripley/proc/on_attackby(obj/item/mecha_parts/chassis/ripley/source)
	SIGNAL_HANDLER
	var/datum/component/construction/mecha/construction = source.GetComponent(/datum/component/construction/mecha)
	if(construction && construction.index > stage_end(construction))
		complete()

/// Сколько шагов сборки меха должно остаться позади.
/datum/antag_training_exercise_step/drill/ripley/proc/stage_end(datum/component/construction/mecha/construction)
	return 0

/datum/antag_training_exercise_step/drill/ripley/proc/on_chassis_deleted(obj/item/mecha_parts/chassis/ripley/source)
	SIGNAL_HANDLER
	run.finish(FALSE, "шасси уничтожено до окончания сборки")

/datum/antag_training_exercise_step/drill/ripley/wiring
	name = "Подключите гидравлику и проводку"
	hint = "Затяните гидравлику гаечным ключом, закрепите отвёрткой, проложите кабель и подровняйте проводку кусачками."

/datum/antag_training_exercise_step/drill/ripley/wiring/New()
	. = ..()
	hint = "Затяните гидравлику гаечным ключом, закрепите отвёрткой, проложите [ANTAG_TRAINING_RIPLEY_CABLE] отрезков кабеля и подровняйте проводку кусачками. Осмотр шасси подсказывает следующий шаг."

/datum/antag_training_exercise_step/drill/ripley/wiring/stage_end(datum/component/construction/mecha/construction)
	return length(construction.get_frame_steps())

/datum/antag_training_exercise_step/drill/ripley/boards
	name = "Установите платы"
	hint = "Вставьте главную плату Рипли и закрепите её отвёрткой, затем так же плату периферии."

/datum/antag_training_exercise_step/drill/ripley/boards/stage_end(datum/component/construction/mecha/construction)
	return length(construction.get_frame_steps()) + length(construction.get_circuit_steps())

/datum/antag_training_exercise_step/drill/ripley/modules
	name = "Установите модули"
	hint = "Вставьте сканер, конденсатор и батарею, каждый закрепите отвёрткой."

/datum/antag_training_exercise_step/drill/ripley/modules/stage_end(datum/component/construction/mecha/construction)
	return length(construction.get_frame_steps()) + length(construction.get_circuit_steps()) + length(construction.get_stockpart_steps())

/datum/antag_training_exercise_step/drill/ripley/plating
	name = "Обшейте мех"
	hint = "Наложите листы металла, затяните гаечным ключом и приварите, затем прутья и снова сварка."

/datum/antag_training_exercise_step/drill/ripley/plating/New()
	. = ..()
	hint = "Наложите [ANTAG_TRAINING_RIPLEY_METAL] листов металла, затяните гаечным ключом и приварите, затем [ANTAG_TRAINING_RIPLEY_RODS] прутьев и снова сварка. Сварочный аппарат должен быть включён."

/datum/antag_training_exercise_step/drill/ripley/plating/on_attackby(obj/item/mecha_parts/chassis/ripley/source)
	return

/// Последняя сварка заменяет шасси готовым мехом и удаляет шасси.
/datum/antag_training_exercise_step/drill/ripley/plating/on_chassis_deleted(obj/item/mecha_parts/chassis/ripley/source)
	var/datum/component/construction/mecha/construction = source.GetComponent(/datum/component/construction/mecha)
	var/obj/vehicle/sealed/mecha/working/ripley/mech = locate() in get_turf(source)
	if(!construction || construction.index <= length(construction.steps) || !mech)
		return ..()
	run.add_prop(mech, FALSE)
	complete()

#undef ANTAG_TRAINING_RIPLEY_CABLE
#undef ANTAG_TRAINING_RIPLEY_METAL
#undef ANTAG_TRAINING_RIPLEY_RODS
