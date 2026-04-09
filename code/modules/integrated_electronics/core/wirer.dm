#define WIRE		"wire"
#define WIRING		"wiring"
#define UNWIRE		"unwire"
#define UNWIRING	"unwiring"

/obj/item/integrated_electronics/wirer
	name = "circuit wirer"
	desc = "Это небольшой набор инструментов для работы с проводами, в который входят катушка с проволокой, электрический паяльник, кусачки и другие приспособления. \
	Используемые провода, как правило, подходят для небольших электронных устройств, таких как печатные платы и макетные платы, в отличие от более толстых проводов, \
	применяемых для передачи электроэнергии или данных."
	icon = 'icons/obj/assemblies/electronic_tools.dmi'
	icon_state = "wirer-wire"
	flags_1 = CONDUCT_1
	w_class = WEIGHT_CLASS_SMALL
	var/mode = WIRE

/obj/item/integrated_electronics/wirer/update_icon()
	icon_state = "wirer-[mode]"

/obj/item/integrated_electronics/wirer/wire(var/datum/integrated_io/io, mob/user)
	if(!io.holder.assembly)
		to_chat(user, "<span class='warning'>Сначала необходимо закрепить [io.holder] внутри корпуса.</span>")
		return
	switch(mode)
		if(WIRE)
			selected_io = io
			to_chat(user, "<span class='notice'>Вы подключаете кабель передачи данных к каналу передачи данных [selected_io.name] устройства [selected_io.holder].</span>")
			mode = WIRING
			update_icon()
		if(WIRING)
			if(io == selected_io)
				to_chat(user, "<span class='warning'>Подключать [selected_io.name] из [selected_io.holder] к самому себе не имеет смысла.</span>")
				return
			if(io.io_type != selected_io.io_type)
				to_chat(user, "<span class='warning'>Эти два типа каналов несовместимы.  Первый представляет собой [selected_io.io_type], \
                а второй - [io.io_type].</span>")
				return
			if(io.holder.assembly && io.holder.assembly != selected_io.holder.assembly)
				to_chat(user, "<span class='warning'>И [io.holder], и [selected_io.holder] должны находиться в одном корпусе.</span>")
				return
			selected_io.connect_pin(io)

			to_chat(user, "<span class='notice'>Вы подключаете [selected_io.name] устройства [selected_io.holder] к [io.name] устройства [io.holder].</span>")
			mode = WIRE
			update_icon()
			selected_io.holder.interact(user) // This is to update the UI.
			selected_io = null

		if(UNWIRE)
			selected_io = io
			if(!io.linked.len)
				to_chat(user, "<span class='warning'>К каналу данных [selected_io] ничего не подключено.</span>")
				selected_io = null
				return
			to_chat(user, "<span class='notice'>Вы готовитесь отсоединить кабель передачи данных от канала [selected_io.name] устройства [selected_io.holder].</span>")
			mode = UNWIRING
			update_icon()
			return

		if(UNWIRING)
			if(io == selected_io)
				to_chat(user, "<span class='warning'>Невозможно подключить выводы друг к другу, поэтому отключение [selected_io.holder] от \
                того же самого вывода не имеет смысла.</span>")
				return
			if(selected_io in io.linked)
				selected_io.disconnect_pin(io)
				to_chat(user, "<span class='notice'>Вы отсоединяете [selected_io.name] из [selected_io.holder] от \
                [io.name] из [io.holder].</span>")
				selected_io.holder.interact(user) // This is to update the UI.
				selected_io = null
				mode = UNWIRE
				update_icon()
			else
				to_chat(user, "<span class='warning'>[selected_io.name] из [selected_io.holder] и [io.name] из [io.holder] с именем \
                не подключены друг к другу.</span>")
				return

/obj/item/integrated_electronics/wirer/attack_self(mob/user)
	switch(mode)
		if(WIRE)
			mode = UNWIRE
		if(WIRING)
			if(selected_io)
				to_chat(user, "<span class='notice'>Вы решили не прокладывать кабель для передачи данных.</span>")
			selected_io = null
			mode = WIRE
		if(UNWIRE)
			mode = WIRE
		if(UNWIRING)
			if(selected_io)
				to_chat(user, "<span class='notice'>Вы решили не отключать канал передачи данных.</span>")
			selected_io = null
			mode = UNWIRE
	update_icon()
	to_chat(user, "<span class='notice'>Вы устанавливаете режим \the [src] в [mode].</span>")

#undef WIRE
#undef WIRING
#undef UNWIRE
#undef UNWIRING
