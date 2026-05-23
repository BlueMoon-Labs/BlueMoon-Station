#define MAX_ION_DRIFT_SPEED 8	// Отвечает за максимальную скорость полёта интегралки без стабилизаторов. 6 примерно соответствует максимальной скорости платы locomotion.
#define ION_ACCEL_PER_PULSE 0.8	// Отвечает за силу импульса, прибавляемого во время пульсации трастера при выключенном стабилизаторе

/obj/item/integrated_circuit/manipulation/ion_thruster

	name = "ion propulsion module"
	desc = "Module designed for moving assemblies in zero gravity conditions"
	icon_state = "locomotion"
	extended_desc = "Простейший ионный двигатель. Позволяет перемещать интегральную схему исключительно в условиях нулевой гравитации. \
		Пульсация пина 'thrust towards dir' заставит конструкцию переместиться на 1 шаг в заданном в 'dir' направлении, если на неё не воздействуют гравитационные силы. \
		Пин 'stabilizers' переключает встроенный стабилизатор, позволяя стабилизировать интегральную конструкцию в пространстве."
	w_class = WEIGHT_CLASS_SMALL
	complexity = 8
	cooldown_per_use = 1
	ext_cooldown = 4
	inputs = list("stabilizers" = IC_PINTYPE_BOOLEAN, "direction" = IC_PINTYPE_DIR)	// Включение стабилизатора меняет логику работы трастера на обычный step, и активно гасит инерцию во время движения
	inputs_default = list("1" = FALSE)
	outputs = list("obstacle" = IC_PINTYPE_REF)
	activators = list("propel towards dir" = IC_PINTYPE_PULSE_IN, "on thrust" = IC_PINTYPE_PULSE_OUT,"blocked" = IC_PINTYPE_PULSE_OUT)
	spawn_flags = IC_SPAWN_RESEARCH
	action_flags = IC_ACTION_MOVEMENT
	power_draw_per_use = 500	// Расход энергии в несколько раз выше обычного локомоушена
	limit_per_assembly = 1

/obj/item/integrated_circuit/manipulation/ion_thruster/ext_moved(oldLoc, dir)	// electronic_assembly/moved() вызывает drift_handler, после чего вызывает данную процедуру в схеме. Мы используем её для гашения инерции.
	if(!assembly || has_gravity(assembly) || !assembly.drift_handler || !get_pin_data(IC_INPUT, 1))	// В иных случаях процедура не имеет смысла
		return
	assembly.inertia_dir = 0
	QDEL_NULL(assembly.drift_handler)	// Гасим drift_handler, вызванный родительским moved()
	return

/obj/item/integrated_circuit/manipulation/ion_thruster/proc/emit_thrust_sparks(turf/T)
	var/obj/effect/particle_effect/sparks/S = new(T, TRUE, 10)
	S.color = list(0.2,0,0, 0,0.4,0, 0,0,1)

/obj/item/integrated_circuit/manipulation/ion_thruster/do_work()
	..()
	var/turf/T = get_turf(src)
	if(!T || !assembly)
		return FALSE
	if(assembly.anchored || !assembly.can_move() || has_gravity(assembly))	// При наличии гравитации, интегралку стоит перемещать обычным Locomotion
		activate_pin(3)
		return FALSE
	if(assembly.loc == T)
		var/datum/integrated_io/wanted_dir = inputs[2]
		if(isnum(wanted_dir.data))
			if(!get_pin_data(IC_INPUT, 1))	// При выключенных стабилизаторах используем Ньютоновские импульсы
				var/angle = dir2angle(wanted_dir.data)
				if(!assembly.drift_handler)	// Первичный импульс
					new /datum/drift_handler(assembly, angle, TRUE, 0, ION_ACCEL_PER_PULSE)
				else
					assembly.drift_handler.newtonian_impulse(angle, 0, ION_ACCEL_PER_PULSE, MAX_ION_DRIFT_SPEED)
				emit_thrust_sparks(T)
				activate_pin(2)
				return TRUE
			if(step(assembly, wanted_dir.data))	// При включенных стабилизаторах используем стандартный step
				emit_thrust_sparks(T)
				activate_pin(2)
				return TRUE
			else
				if(assembly.collw)
					set_pin_data(IC_OUTPUT, 1, WEAKREF(assembly.collw))
					push_data()
				activate_pin(3)
				return FALSE
	return FALSE

#undef MAX_ION_DRIFT_SPEED
#undef ION_ACCEL_PER_PULSE
