
//Reminders-
// If you add something to this list, please group it by type and sort it alphabetically instead of just jamming it in like an animal
// cost = 700- Minimum cost, or infinite points are possible.
//////////////////////////////////////////////////////////////////////////////
//////////////////////// Engine Construction /////////////////////////////////
//////////////////////////////////////////////////////////////////////////////

/datum/supply_pack/engine
	group = "Engine Construction"
	crate_type = /obj/structure/closet/crate/engineering

/datum/supply_pack/engine/am_jar
	name = "Antimatter Containment Jar Crate"
	desc = "Два баллона антиматерии, упакованные в один ящик."
	cost = 2300
	contains = list(/obj/item/am_containment,
					/obj/item/am_containment)
	crate_name = "antimatter jar crate"

/datum/supply_pack/engine/am_core
	name = "Antimatter Control Crate"
	desc = "Мозг двигателя на антиматерии, это устройство, несомненно, научит энергосистему станции истинному значению реальной энергии."
	cost = 5200
	contains = list(/obj/machinery/power/am_control_unit)
	crate_name = "antimatter control crate"

/datum/supply_pack/engine/am_shielding
	name = "Antimatter Shielding Crate"
	desc = "Содержит девять деталей двигателя антиматерии, каким-то образом втиснутых в ящик."
	cost = 2500
	contains = list(/obj/item/am_shielding_container,
					/obj/item/am_shielding_container,
					/obj/item/am_shielding_container,
					/obj/item/am_shielding_container,
					/obj/item/am_shielding_container,
					/obj/item/am_shielding_container,
					/obj/item/am_shielding_container,
					/obj/item/am_shielding_container,
					/obj/item/am_shielding_container) //9 shields: 3x3 containment and a core
	crate_name = "antimatter shielding crate"

/datum/supply_pack/engine/emitter
	name = "Emitter Crate"
	desc = "Полезно для питания генераторов силового поля. Содержит два эммитера. Для открытия требуется доступ CE."
	cost = 1750
	access = ACCESS_CE
	contains = list(/obj/machinery/power/emitter,
					/obj/machinery/power/emitter)
	crate_name = "emitter crate"
	crate_type = /obj/structure/closet/crate/secure/engineering
	dangerous = TRUE

/datum/supply_pack/engine/field_gen
	name = "Field Generator Crate"
	desc = "Обычно это единственное, что стоит между станцией и страшной смертью. Питается от эммитеров. Содержит два генератора поля."
	cost = 1750
	contains = list(/obj/machinery/field/generator,
					/obj/machinery/field/generator)
	crate_name = "field generator crate"

/datum/supply_pack/engine/grounding_rods
	name = "Grounding Rod Crate"
	desc = "Четыре заземляющих стержня гарантированно удержат под контролем любую наглую молнию Теслы."
	cost = 2200
	contains = list(/obj/machinery/power/grounding_rod,
					/obj/machinery/power/grounding_rod,
					/obj/machinery/power/grounding_rod,
					/obj/machinery/power/grounding_rod)
	crate_name = "grounding rod crate"
	crate_type = /obj/structure/closet/crate/engineering/electrical

/datum/supply_pack/engine/mason
	name = "M.A.S.O.N RIG Crate"
	desc = "Редкий M.A.S.O.N RIG, предоставляющий высокую защиту от радиации и давления, ценой скорости."
	cost = 15000
	access = ACCESS_ENGINE
	contains = list(/obj/item/clothing/suit/space/hardsuit/ancient/mason)
	crate_name = "M.A.S.O.N Rig"
	crate_type = /obj/structure/closet/crate/secure/engineering

/datum/supply_pack/engine/PA
	name = "Particle Accelerator Crate"
	desc = "Сверхмассивная Сингулярность или сверхмощный шар Тесла - идеальный способ оживить любую вечеринку! Этот набор содержит все, что вам нужно, чтобы построить свой собственный ускоритель частиц! Возрастное ограничение от 10 лет и старше."
	cost = 3750
	contains = list(/obj/structure/particle_accelerator/fuel_chamber,
					/obj/machinery/particle_accelerator/control_box,
					/obj/structure/particle_accelerator/particle_emitter/center,
					/obj/structure/particle_accelerator/particle_emitter/left,
					/obj/structure/particle_accelerator/particle_emitter/right,
					/obj/structure/particle_accelerator/power_box,
					/obj/structure/particle_accelerator/end_cap)
	crate_name = "particle accelerator crate"

/datum/supply_pack/engine/collector
	name = "Radiation Collector Crate"
	desc = "Содержит три радиационных накопителя. Полезно при получении энергии с кристалла Суперматерии или Сингулярности"
	cost = 2750
	contains = list(/obj/machinery/power/rad_collector,
					/obj/machinery/power/rad_collector,
					/obj/machinery/power/rad_collector)
	crate_name = "collector crate"

/datum/supply_pack/engine/sing_gen
	name = "Singularity Generator Crate"
	desc = "Ключ к раскрытию силы Лорда Сингулятора. Ускоритель частиц в комплект не входит."
	cost = 6000
	contains = list(/obj/machinery/the_singularitygen)
	crate_name = "singularity generator crate"

/datum/supply_pack/engine/sing_buster
	name = "Singularity Buster Kit Crate"
	desc = "Ключ к раскрытию слабости Лорда Сингулятора. Навыки владения в комплект не входят."
	cost = 6000
	contains = list(/obj/item/storage/lockbox/anti_singulo)
	crate_name = "Singularity Buster Kit Crate"

/datum/supply_pack/engine/solar
	name = "Solar Panel Crate"
	desc = "Вступите в Greenpeace с этим набором. Содержит двадцать одну солнечную панель, печатную плату управления солнечными панелями и трекер. Если у вас есть какие-либо вопросы, пожалуйста, ознакомьтесь с прилагаемой инструкцией."
	cost = 2850
	contains  = list(/obj/item/solar_assembly,
					/obj/item/solar_assembly,
					/obj/item/solar_assembly,
					/obj/item/solar_assembly,
					/obj/item/solar_assembly,
					/obj/item/solar_assembly,
					/obj/item/solar_assembly,
					/obj/item/solar_assembly,
					/obj/item/solar_assembly,
					/obj/item/solar_assembly,
					/obj/item/solar_assembly,
					/obj/item/solar_assembly,
					/obj/item/solar_assembly,
					/obj/item/solar_assembly,
					/obj/item/solar_assembly,
					/obj/item/solar_assembly,
					/obj/item/solar_assembly,
					/obj/item/solar_assembly,
					/obj/item/solar_assembly,
					/obj/item/solar_assembly,
					/obj/item/solar_assembly,
					/obj/item/circuitboard/computer/solar_control,
					/obj/item/electronics/tracker,
					/obj/item/paper/guides/jobs/engi/solars)
	crate_name = "solar panel crate"
	crate_type = /obj/structure/closet/crate/engineering/electrical

/datum/supply_pack/engine/supermatter_shard
	name = "Supermatter Shard Crate"
	desc = "Сила небес сконденсировалась в единый кристалл. Для открытия требуется доступ CE."
	cost = 10000
	access = ACCESS_CE
	contains = list(/obj/machinery/power/supermatter_crystal/shard)
	crate_name = "supermatter shard crate"
	crate_type = /obj/structure/closet/crate/secure/engineering
	dangerous = TRUE

/datum/supply_pack/engine/tesla_coils
	name = "Tesla Coil Crate"
	desc = "Будь то высоковольтные розетки, создание исследовательских точек или просто старая добрая генерация электроэнергии: этот комплект из четырех катушек Тесла может сделать все это!"
	cost = 3500
	contains = list(/obj/machinery/power/tesla_coil,
					/obj/machinery/power/tesla_coil,
					/obj/machinery/power/tesla_coil,
					/obj/machinery/power/tesla_coil)
	crate_name = "tesla coil crate"
	crate_type = /obj/structure/closet/crate/engineering/electrical

/datum/supply_pack/engine/tesla_gen
	name = "Tesla Generator Crate"
	desc = "Ключ к раскрытию мощи шара Теслы. Ускоритель частиц в комплект не входит."
	cost = 7000
	contains = list(/obj/machinery/the_singularitygen/tesla)
	crate_name = "tesla generator crate"
/datum/supply_pack/engine/fuel_rod
	name = "Uranium Fuel Rod crate"
	desc = "Два дополнительных топливных стержня для использования в реакторе, требуется доступ СЕ. Внимание: Радиоактивный"
	cost = 3000
	access = ACCESS_CE
	contains = list(/obj/item/fuel_rod,
					/obj/item/fuel_rod)
	crate_name = "Uranium-235 Fuel Rod crate"
	crate_type = /obj/structure/closet/crate/secure/radiation // BLUEMOON CHANGE fix of the contamination shit after arrival
	dangerous = TRUE

/datum/supply_pack/engine/bananium_fuel_rod
	name = "Bananium Fuel Rod crate"
	desc = "Два топливных стержня, предназначенных для утилизации и размножения бананиума в реакторе, требуется доступ СЕ. Внимание: Радиоактивный"
	cost = 4000
	access = ACCESS_CE // Nag your local CE
	contains = list(/obj/item/fuel_rod/material/bananium,
					/obj/item/fuel_rod/material/bananium)
	crate_name = "Bluespace Crystal Fuel Rod crate"
	crate_type = /obj/structure/closet/crate/secure/radiation // BLUEMOON CHANGE fix of the contamination shit after arrival
	dangerous = TRUE
	contraband = TRUE

/datum/supply_pack/engine/crystallizer
	name = "Crystallizer Board"
	desc = "Плата для сборки кристаллярия — машины для кристаллизации и отверждения газов. Компоненты и трубы в комплект не входят."
	cost = 4000
	contains = list(/obj/item/circuitboard/machine/crystallizer)
	crate_name = "crystallizer board crate"

/datum/supply_pack/engine/hfr
	name = "Hypertorus Fusion Reactor Kit"
	desc = "Набор для сборки реактора термоядерного синтеза (ХФР). Содержит ядро, четыре угловых блока, порты подачи топлива и модулятора, отвода отходов и интерфейс. Разместите боксы в сетке 3x3 и активируйте мультитулом на ядре. Требуется доступ СЕ."
	cost = 15000
	access = ACCESS_CE
	contains = list(/obj/item/hfr_box/core,
					/obj/item/hfr_box/corner,
					/obj/item/hfr_box/corner,
					/obj/item/hfr_box/corner,
					/obj/item/hfr_box/corner,
					/obj/item/hfr_box/body/fuel_input,
					/obj/item/hfr_box/body/moderator_input,
					/obj/item/hfr_box/body/waste_output,
					/obj/item/hfr_box/body/interface)
	crate_name = "Hypertorus Fusion Reactor Kit"
	crate_type = /obj/structure/closet/crate/secure/engineering
	dangerous = TRUE

/datum/supply_pack/engine/reactor
	name = "RMBK Nuclear Reactor Kit" // (not) a toy
	desc = "Содержит реакторный маяк и 3 реакторных пульта. Урановые стержни в комплект не входят."
	cost = 12000
	access = ACCESS_CE
	contains = list(/obj/item/survivalcapsule/reactor,
					/obj/machinery/computer/reactor/control_rods/cargo,
					/obj/machinery/computer/reactor/stats/cargo,
					/obj/machinery/computer/reactor/fuel_rods/cargo,
					/obj/item/paper/fluff/rbmkcargo,
					/obj/item/book/manual/wiki/rbmk)
	crate_name = "Build Your Own Reactor Kit"
	crate_type = /obj/structure/closet/crate/secure/engineering
	dangerous = TRUE
