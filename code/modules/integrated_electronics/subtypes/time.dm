/obj/item/integrated_circuit/time
	name = "time circuit"
	desc = "Теперь вы можете создать свои собственные часы!"
	complexity = 1
	inputs = list()
	outputs = list()
	category_text = "Время"

/obj/item/integrated_circuit/time/delay
	name = "two-sec delay circuit"
	desc = "Это позволяет посылать импульсный сигнал с некоторой задержкой, что важно для обеспечения надлежащего процесса управления в сложной машине.  \
	Эта схема настроена на отправку импульса с задержкой в две секунды."
	icon_state = "delay-20"
	var/delay = 20
	activators = list("входящий"= IC_PINTYPE_PULSE_IN,"исходящий" = IC_PINTYPE_PULSE_OUT)
	spawn_flags = IC_SPAWN_DEFAULT|IC_SPAWN_RESEARCH
	power_draw_per_use = 2

/obj/item/integrated_circuit/time/delay/do_work()
	addtimer(CALLBACK(src, PROC_REF(activate_pin), 2), delay)

/obj/item/integrated_circuit/time/delay/five_sec
	name = "five-sec delay circuit"
	desc = "Это позволяет посылать импульсный сигнал с некоторой задержкой, что важно для обеспечения надлежащего процесса управления в сложной машине.  \
	Эта схема настроена на отправку импульса с задержкой в пять секунд."
	icon_state = "delay-50"
	delay = 50
	spawn_flags = IC_SPAWN_DEFAULT|IC_SPAWN_RESEARCH

/obj/item/integrated_circuit/time/delay/one_sec
	name = "one-sec delay circuit"
	desc = "Это позволяет посылать импульсный сигнал с некоторой задержкой, что важно для обеспечения надлежащего процесса управления в сложной машине.  \
	Эта схема настроена на отправку импульса с задержкой в одну секунду."
	icon_state = "delay-10"
	delay = 10
	spawn_flags = IC_SPAWN_DEFAULT|IC_SPAWN_RESEARCH

/obj/item/integrated_circuit/time/delay/half_sec
	name = "half-sec delay circuit"
	desc = "Это позволяет посылать импульсный сигнал с некоторой задержкой, что важно для обеспечения надлежащего процесса управления в сложной машине.  \
	Эта схема настроена на отправку импульса с задержкой в половину секунды."
	icon_state = "delay-5"
	delay = 5
	spawn_flags = IC_SPAWN_DEFAULT|IC_SPAWN_RESEARCH

/obj/item/integrated_circuit/time/delay/tenth_sec
	name = "tenth-sec delay circuit"
	desc = "Это позволяет посылать импульсный сигнал с некоторой задержкой, что важно для обеспечения надлежащего процесса управления в сложной машине.  \
	Эта схема настроена на отправку импульса с задержкой в одну десятую секунды."
	icon_state = "delay-1"
	delay = 1
	spawn_flags = IC_SPAWN_DEFAULT|IC_SPAWN_RESEARCH

/obj/item/integrated_circuit/time/delay/custom
	name = "custom delay circuit"
	desc = "Это позволяет отправлять импульсный сигнал с задержкой, определяемой десятыми долями секунды, что имеет решающее значение для обеспечения надлежащего управления \
	в сложной машине. Задержка в этой схеме может быть настроена в диапазоне от 1/10 секунды до одного часа. \
	Задержка обновляется при получении импульса."
	extended_desc = "Задержка определяется в десятых долях секунды. Например, 4 будет означать задержку в 0,4 секунды, или 15 - в 1,5 секунды."
	icon_state = "delay"
	inputs = list("время задержки" = IC_PINTYPE_NUMBER)
	spawn_flags = IC_SPAWN_RESEARCH

/obj/item/integrated_circuit/time/delay/custom/do_work()
	var/delay_input = get_pin_data(IC_INPUT, 1)
	if(delay_input && isnum(delay_input) )
		var/new_delay = clamp(delay_input ,1 ,36000) //An hour.
		delay = new_delay

	..()

/obj/item/integrated_circuit/time/ticker
	name = "ticker circuit"
	desc = "Эта схема автоматически посылает импульс каждые четыре секунды."
	icon_state = "tick-m"
	complexity = 4
	var/delay = 4 SECONDS
	var/next_fire = 0
	var/is_running = FALSE
	inputs = list("включить тиканье" = IC_PINTYPE_BOOLEAN)
	activators = list("выходящий импульс" = IC_PINTYPE_PULSE_OUT)
	spawn_flags = IC_SPAWN_RESEARCH
	power_draw_per_use = 4

/obj/item/integrated_circuit/time/ticker/Destroy()
	if(is_running)
		STOP_PROCESSING(SSfastprocess, src)
	return ..()

/obj/item/integrated_circuit/time/ticker/on_data_written()
	var/do_tick = get_pin_data(IC_INPUT, 1)
	if(do_tick && !is_running)
		is_running = TRUE
		tick()
	else if(!do_tick && is_running)
		is_running = FALSE


/obj/item/integrated_circuit/time/ticker/proc/tick()
	if(is_running)
		addtimer(CALLBACK(src, PROC_REF(tick)), delay)
		if(world.time > next_fire)
			next_fire = world.time + delay
			activate_pin(1)


/obj/item/integrated_circuit/time/ticker/custom
	name = "custom ticker"
	desc = "Эта усовершенствованная схема автоматически посылает импульс через каждый заданный интервал, измеряемый десятыми долями секунды."
	extended_desc ="Эта усовершенствованная схема автоматически посылает импульс через каждый заданный интервал, измеряемый десятыми долями секунды. \
	Например, при установке значения пина времени на 4 импульс будет посылаться каждые 0,4 секунды, или 15 импульсов - каждые 1,5 секунды."
	icon_state = "tick-f"
	complexity = 8
	delay = 2 SECONDS
	inputs = list("включить тиканье" = IC_PINTYPE_BOOLEAN,"время задержки" = IC_PINTYPE_NUMBER)
	spawn_flags = IC_SPAWN_RESEARCH
	power_draw_per_use = 8

/obj/item/integrated_circuit/time/ticker/custom/on_data_written()
	var/delay_input = get_pin_data(IC_INPUT, 2)
	if(delay_input && isnum(delay_input) )
		var/new_delay = clamp(delay_input ,1 ,1 HOURS)
		delay = new_delay
	..()

/obj/item/integrated_circuit/time/ticker/fast
	name = "fast ticker"
	desc = "Эта усовершенствованная схема автоматически посылает импульс каждые две секунды."
	icon_state = "tick-f"
	complexity = 6
	delay = 2 SECONDS
	spawn_flags = IC_SPAWN_RESEARCH
	power_draw_per_use = 8

/obj/item/integrated_circuit/time/ticker/slow
	name = "slow ticker"
	desc = "Эта простая схема автоматически посылает импульс каждые шесть секунд."
	icon_state = "tick-s"
	complexity = 2
	delay = 6 SECONDS
	spawn_flags = IC_SPAWN_DEFAULT|IC_SPAWN_RESEARCH
	power_draw_per_use = 2

/obj/item/integrated_circuit/time/clock
	name = "integrated clock (NT Common Time)"
	desc = "Показывает вам, который час в обычном времени Нанотразена."				//round time
	icon_state = "clock"
	inputs = list()
	outputs = list(
		"время" = IC_PINTYPE_STRING,
		"часы" = IC_PINTYPE_NUMBER,
		"минуты" = IC_PINTYPE_NUMBER,
		"секунды" = IC_PINTYPE_NUMBER,
		"absolute decisecond elapsed time" = IC_PINTYPE_NUMBER // КАКИМ ХУЕМ Я ЭТО ПЕРЕВОДИТЬ ДОЛЖЕН
		)
	activators = list("получить время" = IC_PINTYPE_PULSE_IN, "при получении времени" = IC_PINTYPE_PULSE_OUT)
	spawn_flags = IC_SPAWN_DEFAULT|IC_SPAWN_RESEARCH
	power_draw_per_use = 2

/obj/item/integrated_circuit/time/clock/proc/get_time()
	return world.time

/obj/item/integrated_circuit/time/clock/do_work()
	var/current_time = get_time()
	set_pin_data(IC_OUTPUT, 1, time2text(current_time, "hh:mm:ss") )
	set_pin_data(IC_OUTPUT, 2, text2num(time2text(current_time, "hh") ) )
	set_pin_data(IC_OUTPUT, 3, text2num(time2text(current_time, "mm") ) )
	set_pin_data(IC_OUTPUT, 4, text2num(time2text(current_time, "ss") ) )
	set_pin_data(IC_OUTPUT, 5, current_time)
	push_data()
	activate_pin(2)

/obj/item/integrated_circuit/time/clock/station
	name = "integrated clock (Station Time)"
	desc = "Сообщает вам текущее время в терминах и с поправкой на вашу местную станцию или планету"

/obj/item/integrated_circuit/time/clock/station/get_time()
	return STATION_TIME(FALSE, world.time)

/obj/item/integrated_circuit/time/clock/bluespace
	name = "integrated clock (Bluespace Absolute Time)"
	desc = "Показывает текущее время в абсолютном времени Bluespace, на которое не влияет местное замедление времени или другие явления."

/obj/item/integrated_circuit/time/clock/bluespace/get_time()
	return REALTIMEOFDAY
