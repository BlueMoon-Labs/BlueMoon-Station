// These pins can only contain directions (1,2,4,8...) or null.
/datum/integrated_io/dir
	name = "dir pin"

/datum/integrated_io/dir/ask_for_pin_data(mob/user)
	var/new_data = input("Введите действительный номер направления.  \
	Действительные направления:\n\
	Север/Передняя часть = [NORTH],\n\
	Юг/Задняя часть = [SOUTH],\n\
	Восток/Правый борт = [EAST],\n\
	Запад/Порт = [WEST],\n\
	Северо-восток = [NORTHEAST],\n\
	Северо-запад = [NORTHWEST],\n\
	Юго-восток = [SOUTHEAST],\n\
	Юго-запад = [SOUTHWEST]","[src] dir writing") as null|num
	if(isnum(new_data) && holder.check_interactivity(user) )
		to_chat(user, "<span class='notice'>Вы вводите [new_data] в пины.</span>")
		write_data_to_pin(new_data)

/datum/integrated_io/dir/write_data_to_pin(var/new_data)
	if(isnull(new_data) || (new_data in GLOB.alldirs/* + list(UP, DOWN)*/))
		data = new_data
		holder.on_data_written()

/datum/integrated_io/dir/display_pin_type()
	return IC_FORMAT_DIR

/datum/integrated_io/dir/display_data(var/input)
	if(!isnull(data))
		return "([dir2text(data)])"
	return ..()
