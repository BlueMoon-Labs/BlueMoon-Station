//These circuits convert one variable to another.
/obj/item/integrated_circuit/converter
	complexity = 2
	inputs = list("input")
	outputs = list("output")
	activators = list("конвертировать" = IC_PINTYPE_PULSE_IN, "при конвертировании" = IC_PINTYPE_PULSE_OUT)
	category_text = "Конвертеры"
	power_draw_per_use = 10

/obj/item/integrated_circuit/converter/num2text
	name = "number to string"
	desc = "Эта схема позволяет преобразовать числовую переменную в строку."
	extended_desc = "Из-за ограничений схемы переменные с значением null/false будут выводить строку 0."
	icon_state = "num-string"
	inputs = list("A" = IC_PINTYPE_NUMBER,
		"B" = IC_PINTYPE_NUMBER,
		"C" = IC_PINTYPE_NUMBER,
		"D" = IC_PINTYPE_NUMBER,
		"E" = IC_PINTYPE_NUMBER,
		"F" = IC_PINTYPE_NUMBER,
		"G" = IC_PINTYPE_NUMBER,
		"H" = IC_PINTYPE_NUMBER,
	)
	outputs = list(
		"A" = IC_PINTYPE_STRING,
		"B" = IC_PINTYPE_STRING,
		"C" = IC_PINTYPE_STRING,
		"D" = IC_PINTYPE_STRING,
		"E" = IC_PINTYPE_STRING,
		"F" = IC_PINTYPE_STRING,
		"G" = IC_PINTYPE_STRING,
		"H" = IC_PINTYPE_STRING,
	)
	spawn_flags = IC_SPAWN_DEFAULT|IC_SPAWN_RESEARCH

/obj/item/integrated_circuit/converter/num2text/do_work()
	pull_data()

	for(var/i = 0 to inputs.len)
		var/incoming = get_pin_data(IC_INPUT, i)
		if (!isnull(incoming))
			set_pin_data(IC_OUTPUT, i,num2text(incoming))
		else if(!incoming)
			set_pin_data(IC_OUTPUT, i, null)
	push_data()
	activate_pin(2)

/obj/item/integrated_circuit/converter/text2num
	name = "string to number"
	desc = "Эта схема позволяет преобразовать строку в число."
	icon_state = "string-num"
	inputs = list(
		"A" = IC_PINTYPE_STRING,
		"B" = IC_PINTYPE_STRING,
		"C" = IC_PINTYPE_STRING,
		"D" = IC_PINTYPE_STRING,
		"E" = IC_PINTYPE_STRING,
		"F" = IC_PINTYPE_STRING,
		"G" = IC_PINTYPE_STRING,
		"H" = IC_PINTYPE_STRING,
	)
	outputs = list(
		"A" = IC_PINTYPE_NUMBER,
		"B" = IC_PINTYPE_NUMBER,
		"C" = IC_PINTYPE_NUMBER,
		"D" = IC_PINTYPE_NUMBER,
		"E" = IC_PINTYPE_NUMBER,
		"F" = IC_PINTYPE_NUMBER,
		"G" = IC_PINTYPE_NUMBER,
		"H" = IC_PINTYPE_NUMBER,
	)
	spawn_flags = IC_SPAWN_DEFAULT|IC_SPAWN_RESEARCH

/obj/item/integrated_circuit/converter/text2num/do_work()
	pull_data()
	for(var/i = 1 to inputs.len)
		set_pin_data(IC_OUTPUT, i,text2num(get_pin_data(IC_INPUT, i)) )
	push_data()
	activate_pin(2)

/obj/item/integrated_circuit/converter/ref2text
	name = "reference to string"
	desc = "Эта схема позволяет преобразовать ссылку на какой-либо объект в строку, а именно в имя этой ссылки."
	icon_state = "ref-string"
	inputs = list("ввод" = IC_PINTYPE_REF)
	outputs = list("вывод" = IC_PINTYPE_STRING)
	spawn_flags = IC_SPAWN_DEFAULT|IC_SPAWN_RESEARCH

/obj/item/integrated_circuit/converter/ref2text/do_work()
	var/result = null
	pull_data()
	var/atom/A = get_pin_data(IC_INPUT, 1)
	if(A && istype(A))
		result = A.name

	set_pin_data(IC_OUTPUT, 1, result)
	push_data()
	activate_pin(2)

/obj/item/integrated_circuit/converter/refcode
	name = "reference encoder"
	desc = "Эта схема может кодировать ссылку в виде строки, которую затем может прочитать схема декодирования ссылок."
	icon_state = "ref-string"
	inputs = list("ввод" = IC_PINTYPE_REF)
	outputs = list("вывод" = IC_PINTYPE_STRING)
	spawn_flags = IC_SPAWN_DEFAULT|IC_SPAWN_RESEARCH

/obj/item/integrated_circuit/converter/refcode/do_work()
	var/result = null
	pull_data()
	var/atom/A = get_pin_data(IC_INPUT, 1)
	if(A && istype(A))
		result = strtohex(XorEncrypt(REF(A), SScircuit.cipherkey))

	set_pin_data(IC_OUTPUT, 1, result)
	push_data()
	activate_pin(2)

/obj/item/integrated_circuit/converter/refdecode
	name = "reference decoder"
	desc = "Эта схема может преобразовывать кодированную ссылку в действительную."
	icon_state = "ref-string"
	inputs = list("ввод" = IC_PINTYPE_STRING)
	outputs = list("вывод" = IC_PINTYPE_REF)
	spawn_flags = IC_SPAWN_DEFAULT|IC_SPAWN_RESEARCH
	var/dec

/obj/item/integrated_circuit/converter/refdecode/do_work()
	pull_data()
	dec = XorEncrypt(hextostr(get_pin_data(IC_INPUT, 1), TRUE), SScircuit.cipherkey)
	set_pin_data(IC_OUTPUT, 1, WEAKREF(locate(dec)))
	push_data()
	activate_pin(2)

/obj/item/integrated_circuit/converter/lowercase
	name = "lowercase string converter"
	desc = "эта схема обеспечит вывод строки строчными буквами."
	icon_state = "lowercase"
	inputs = list("ввод" = IC_PINTYPE_STRING)
	outputs = list("вывод" = IC_PINTYPE_STRING)
	spawn_flags = IC_SPAWN_DEFAULT|IC_SPAWN_RESEARCH

/obj/item/integrated_circuit/converter/lowercase/do_work()
	var/result = null
	pull_data()
	var/incoming = get_pin_data(IC_INPUT, 1)
	if(!isnull(incoming))
		result = lowertext(incoming)

	set_pin_data(IC_OUTPUT, 1, result)
	push_data()
	activate_pin(2)

/obj/item/integrated_circuit/converter/uppercase
	name = "uppercase string converter"
	desc = "В РЕЗУЛЬТАТЕ СТРОКА БУДЕТ ВЫВЕДЕНА ЗАГЛАВНЫМИ БУКВАМИ."
	icon_state = "uppercase"
	inputs = list("ввод" = IC_PINTYPE_STRING)
	outputs = list("вывод" = IC_PINTYPE_STRING)
	spawn_flags = IC_SPAWN_DEFAULT|IC_SPAWN_RESEARCH

/obj/item/integrated_circuit/converter/uppercase/do_work()
	var/result = null
	pull_data()
	var/incoming = get_pin_data(IC_INPUT, 1)
	if(!isnull(incoming))
		result = uppertext(incoming)

	set_pin_data(IC_OUTPUT, 1, result)
	push_data()
	activate_pin(2)

/obj/item/integrated_circuit/converter/concatenator
	name = "concatenator"
	desc = "Эта функция позволяет объединить до 8 строк в одну строку длиной не более 512 символов."
	complexity = 4
	inputs = list()
	outputs = list("результат" = IC_PINTYPE_STRING)
	activators = list("объединить" = IC_PINTYPE_PULSE_IN, "при объединении" = IC_PINTYPE_PULSE_OUT)
	spawn_flags = IC_SPAWN_DEFAULT|IC_SPAWN_RESEARCH
	var/number_of_pins = 8
	var/max_string_length = 512

/obj/item/integrated_circuit/converter/concatenator/Initialize(mapload)
	for(var/i = 1 to number_of_pins)
		inputs["ввод [i]"] = IC_PINTYPE_STRING
	. = ..()

/obj/item/integrated_circuit/converter/concatenator/do_work()
	var/result = null
	var/spamprotection
	for(var/k in 1 to inputs.len)
		var/I = get_pin_data(IC_INPUT, k)
		if(!isnull(I))
			if((result ? length(result) : 0) + length(I) > max_string_length)
				spamprotection = (result ? length(result) : 0) + length(I)
				break
			result = result + I

	if(spamprotection >= max_string_length*1.75 && assembly)
		if(assembly.fingerprintslast)
			var/mob/M = get_mob_by_key(assembly.fingerprintslast)
			var/more = ""
			if(M)
				more = "[ADMIN_LOOKUPFLW(M)] "
			message_admins("A concatenator circuit has greatly exceeded its [max_string_length] character limit with a total of [spamprotection] characters, and has been deleted. Assembly last touched by [more ? more : assembly.fingerprintslast].")
			investigate_log("A concatenator circuit has greatly exceeded its [max_string_length] character limit with a total of [spamprotection] characters, and has been deleted. Assembly last touched by [assembly.fingerprintslast].", INVESTIGATE_CIRCUIT)
		else
			message_admins("A concatenator circuit has greatly exceeded its [max_string_length] character limit with a total of [spamprotection] characters, and has been deleted. No associated key.")
			investigate_log("A concatenator circuit has greatly exceeded its [max_string_length] character limit with a total of [spamprotection] characters, and has been deleted. No associated key.", INVESTIGATE_CIRCUIT)
		qdel(assembly)
		return

	set_pin_data(IC_OUTPUT, 1, result)
	push_data()
	activate_pin(2)

/obj/item/integrated_circuit/converter/concatenator/small
	name = "small concatenator"
	desc = "Эта схема позволяет объединить до 4 строк в одну строку длиной не более 256 символов."
	complexity = 2
	number_of_pins = 4
	max_string_length = 256

/obj/item/integrated_circuit/converter/concatenator/large
	name = "large concatenator"
	desc = "Эта схема позволяет объединить до 16 строк в одну строку длиной не более 1024 символов."
	complexity = 6
	number_of_pins = 16
	max_string_length = 1024

/obj/item/integrated_circuit/converter/separator
	name = "separator"
	desc = "Эта функция разбивает одну строку на две в указанном месте."
	extended_desc = "Эта схема разбивает заданную строку на две части на основе самой строки и значения индекса. \
    Индекс разбивает строку <b>после</b> заданного индекса, включая пробелы. Таким образом, строка 'a person' с индексом '3' \
    будет разбита на 'a p' и 'erson'."
	icon_state = "split"
	complexity = 4
	inputs = list(
		"строка для разделения" = IC_PINTYPE_STRING,
		"индекс" = IC_PINTYPE_NUMBER,
		)
	outputs = list(
		"до индекса" = IC_PINTYPE_STRING,
		"после индекса" = IC_PINTYPE_STRING
		)
	activators = list("разделить" = IC_PINTYPE_PULSE_IN, "при разделении" = IC_PINTYPE_PULSE_OUT)
	spawn_flags = IC_SPAWN_DEFAULT|IC_SPAWN_RESEARCH

/obj/item/integrated_circuit/converter/separator/do_work()
	var/text = get_pin_data(IC_INPUT, 1)
	var/index = get_pin_data(IC_INPUT, 2)

	var/split = min(index+1, length(text))

	var/before_text = copytext_char(text, 1, split)
	var/after_text = copytext_char(text, split)

	set_pin_data(IC_OUTPUT, 1, before_text)
	set_pin_data(IC_OUTPUT, 2, after_text)
	push_data()

	activate_pin(2)

/obj/item/integrated_circuit/converter/indexer
	name = "indexer"
	desc = "Эта схема принимает строку и значение индекса, а затем возвращает символ, расположенный в строке по указанному индексу."
	extended_desc = "Убедитесь, что индекс не превышает и не меньше длины строки. В противном случае схема вернет пустой результат."
	icon_state = "split"
	complexity = 4
	inputs = list(
		"строка" = IC_PINTYPE_STRING,
		"индекс" = IC_PINTYPE_NUMBER,
		)
	outputs = list(
		"найденный символ" = IC_PINTYPE_STRING
		)
	activators = list("индексировать" = IC_PINTYPE_PULSE_IN, "при индексации" = IC_PINTYPE_PULSE_OUT)
	spawn_flags = IC_SPAWN_DEFAULT|IC_SPAWN_RESEARCH

/obj/item/integrated_circuit/converter/indexer/do_work()
	var/strin = get_pin_data(IC_INPUT, 1)
	var/ind = get_pin_data(IC_INPUT, 2)
	if(ind > 0 && ind <= length(strin))
		set_pin_data(IC_OUTPUT, 1, strin[ind])
	else
		set_pin_data(IC_OUTPUT, 1, "")
	push_data()
	activate_pin(2)

/obj/item/integrated_circuit/converter/findstring
	name = "find text"
	desc = "Выводит индекс символа в строке или возвращает 0."
	extended_desc = "Первый контакт - это строка, которую нужно проанализировать. Второй контакт - это искомый образец. \
    Например, если ввести фразу 'my wife has caught on fire', указав 'has' в качестве образца, вы получите позицию 9. \
    Эта схема не учитывает регистр и не игнорирует пробелы."
	complexity = 4
	inputs = list(
		"строка" = IC_PINTYPE_STRING,
		"образец" = IC_PINTYPE_STRING,
		)
	outputs = list(
		"позиция" = IC_PINTYPE_NUMBER
		)
	activators = list("поиск" = IC_PINTYPE_PULSE_IN, "после поиска" = IC_PINTYPE_PULSE_OUT, "найдено" = IC_PINTYPE_PULSE_OUT, "не найдено" = IC_PINTYPE_PULSE_OUT)
	spawn_flags = IC_SPAWN_DEFAULT|IC_SPAWN_RESEARCH



/obj/item/integrated_circuit/converter/findstring/do_work()
	var/position = findtext(get_pin_data(IC_INPUT, 1),get_pin_data(IC_INPUT, 2))

	set_pin_data(IC_OUTPUT, 1, position)
	push_data()

	activate_pin(2)
	if(position)
		activate_pin(3)
	else
		activate_pin(4)

/obj/item/integrated_circuit/converter/stringlength
	name = "get length"
	desc = "Эта схема вернет количество символов в строке."
	complexity = 1
	inputs = list(
		"строка" = IC_PINTYPE_STRING
		)
	outputs = list(
		"длина" = IC_PINTYPE_NUMBER
		)
	activators = list("получить длину" = IC_PINTYPE_PULSE_IN, "при получении" = IC_PINTYPE_PULSE_OUT)
	spawn_flags = IC_SPAWN_DEFAULT|IC_SPAWN_RESEARCH

/obj/item/integrated_circuit/converter/stringlength/do_work()
	set_pin_data(IC_OUTPUT, 1, length(get_pin_data(IC_INPUT, 1)))
	push_data()

	activate_pin(2)

/obj/item/integrated_circuit/converter/exploders
	name = "string exploder"
	desc = "Эта функция разбивает одну строку на список строк."
	extended_desc = "Эта схема разбивает заданную строку на список строк на основе самой строки и заданного разделителя. \
    Например, строка 'eat this burger' будет преобразована в list('eat', 'this', 'burger'). Если не указать разделитель, будет получен список \
    всех отдельных символов."
	icon_state = "split"
	complexity = 4
	inputs = list(
		"строка для разделения" = IC_PINTYPE_STRING,
		"разделитель" = IC_PINTYPE_STRING,
		)
	outputs = list(
		"список" = IC_PINTYPE_LIST
		)
	activators = list("разделить" = IC_PINTYPE_PULSE_IN, "при разделении" = IC_PINTYPE_PULSE_OUT)
	spawn_flags = IC_SPAWN_DEFAULT|IC_SPAWN_RESEARCH

/obj/item/integrated_circuit/converter/exploders/do_work()
	var/strin = get_pin_data(IC_INPUT, 1)
	var/delimiter = get_pin_data(IC_INPUT, 2)
	if(delimiter == null)
		set_pin_data(IC_OUTPUT, 1, text2charlist(strin))
	else
		set_pin_data(IC_OUTPUT, 1, splittext(strin, delimiter))
	push_data()

	activate_pin(2)

/obj/item/integrated_circuit/converter/radians2degrees
	name = "radians to degrees converter"
	desc = "Преобразует радианы в градусы."
	inputs = list("радианы" = IC_PINTYPE_NUMBER)
	outputs = list("градусы" = IC_PINTYPE_NUMBER)
	spawn_flags = IC_SPAWN_DEFAULT|IC_SPAWN_RESEARCH

/obj/item/integrated_circuit/converter/radians2degrees/do_work()
	var/result = null
	pull_data()
	var/incoming = get_pin_data(IC_INPUT, 1)
	if(!isnull(incoming))
		result = TODEGREES(incoming)

	set_pin_data(IC_OUTPUT, 1, result)
	push_data()
	activate_pin(2)

/obj/item/integrated_circuit/converter/degrees2radians
	name = "degrees to radians converter"
	desc = "Преобразует градусы в радианы."
	inputs = list("градусы" = IC_PINTYPE_NUMBER)
	outputs = list("радианы" = IC_PINTYPE_NUMBER)
	spawn_flags = IC_SPAWN_DEFAULT|IC_SPAWN_RESEARCH

/obj/item/integrated_circuit/converter/degrees2radians/do_work()
	var/result = null
	pull_data()
	var/incoming = get_pin_data(IC_INPUT, 1)
	if(!isnull(incoming))
		result = TORADIANS(incoming)

	set_pin_data(IC_OUTPUT, 1, result)
	push_data()
	activate_pin(2)


/obj/item/integrated_circuit/converter/abs_to_rel_coords
	name = "abs to rel coordinate converter"
	desc = "С помощью этой функции можно легко преобразовать абсолютные координаты в относительные."
	extended_desc = "Помните, что оба набора входных координат должны быть абсолютными."
	complexity = 1
	inputs = list(
		"X1" = IC_PINTYPE_NUMBER,
		"Y1" = IC_PINTYPE_NUMBER,
		"X2" = IC_PINTYPE_NUMBER,
		"Y2" = IC_PINTYPE_NUMBER
		)
	outputs = list(
		"X" = IC_PINTYPE_NUMBER,
		"Y" = IC_PINTYPE_NUMBER
		)
	activators = list("рассчитать относительные координаты" = IC_PINTYPE_PULSE_IN, "при конвертации" = IC_PINTYPE_PULSE_OUT)
	spawn_flags = IC_SPAWN_DEFAULT|IC_SPAWN_RESEARCH

/obj/item/integrated_circuit/converter/abs_to_rel_coords/do_work()
	var/x1 = get_pin_data(IC_INPUT, 1)
	var/y1 = get_pin_data(IC_INPUT, 2)

	var/x2 = get_pin_data(IC_INPUT, 3)
	var/y2 = get_pin_data(IC_INPUT, 4)

	if(!isnull(x1) && !isnull(y1) && !isnull(x2) && !isnull(y2))
		set_pin_data(IC_OUTPUT, 1, x1 - x2)
		set_pin_data(IC_OUTPUT, 2, y1 - y2)

	push_data()
	activate_pin(2)

/obj/item/integrated_circuit/converter/rel_to_abs_coords
	name = "rel to abs coordinate converter"
	desc = "С помощью этой схемы преобразуйте относительные координаты в абсолютные."
	extended_desc = "Следует помнить, что только один набор входных координат должен быть абсолютным, а другой - относительным. \
    Выходные координаты будут представлять собой абсолютную форму входных относительных координат."
	complexity = 1
	inputs = list(
		"X1" = IC_PINTYPE_NUMBER,
		"Y1" = IC_PINTYPE_NUMBER,
		"X2" = IC_PINTYPE_NUMBER,
		"Y2" = IC_PINTYPE_NUMBER
		)
	outputs = list(
		"X" = IC_PINTYPE_NUMBER,
		"Y" = IC_PINTYPE_NUMBER
		)
	activators = list("рассчитать абсолютные координаты" = IC_PINTYPE_PULSE_IN, "при конвертации" = IC_PINTYPE_PULSE_OUT)
	spawn_flags = IC_SPAWN_DEFAULT|IC_SPAWN_RESEARCH

/obj/item/integrated_circuit/converter/rel_to_abs_coords/do_work()
	var/x1 = get_pin_data(IC_INPUT, 1)
	var/y1 = get_pin_data(IC_INPUT, 2)

	var/x2 = get_pin_data(IC_INPUT, 3)
	var/y2 = get_pin_data(IC_INPUT, 4)

	if(!isnull(x1) && !isnull(y1) && !isnull(x2) && !isnull(y2))
		set_pin_data(IC_OUTPUT, 1, x1 + x2)
		set_pin_data(IC_OUTPUT, 2, y1 + y2)

	push_data()
	activate_pin(2)

/obj/item/integrated_circuit/converter/adv_rel_to_abs_coords
	name = "advanced rel to abs coordinate converter"
	desc = "С помощью этой схемы можно легко преобразовать относительные координаты в абсолютные."
	extended_desc = "Для вывода абсолютных координат этой схеме требуется лишь один набор относительных входных данных."
	complexity = 2
	inputs = list(
		"X" = IC_PINTYPE_NUMBER,
		"Y" = IC_PINTYPE_NUMBER,
		)
	outputs = list(
		"X" = IC_PINTYPE_NUMBER,
		"Y" = IC_PINTYPE_NUMBER
		)
	activators = list("рассчитать абсолютные координаты" = IC_PINTYPE_PULSE_IN, "при конвертации" = IC_PINTYPE_PULSE_OUT)
	spawn_flags = IC_SPAWN_DEFAULT|IC_SPAWN_RESEARCH

/obj/item/integrated_circuit/converter/adv_rel_to_abs_coords/do_work()
	var/turf/T = get_turf(src)

	if(!T)
		return

	var/x1 = get_pin_data(IC_INPUT, 1)
	var/y1 = get_pin_data(IC_INPUT, 2)

	if(!isnull(x1) && !isnull(y1))
		set_pin_data(IC_OUTPUT, 1, T.x + x1)
		set_pin_data(IC_OUTPUT, 2, T.y + y1)

	push_data()
	activate_pin(2)

/obj/item/integrated_circuit/converter/hsv2hex
	name = "hsv to hexadecimal"
	desc = "Эта схема позволяет преобразовать цвет в формате HSV (оттенок, насыщенность и яркость) в шестнадцатеричный код RGB."
	extended_desc = "Первый ввод управляет оттенком (0-359), второй - интенсивностью оттенка (0-255), а третий - яркостью оттенка (0 - черный, 127 - нормальный, 255 - белый)."
	icon_state = "hsv-hex"
	inputs = list(
		"оттенок" = IC_PINTYPE_NUMBER,
		"насыщенность" = IC_PINTYPE_NUMBER,
		"яркость" = IC_PINTYPE_NUMBER
	)
	outputs = list("шестнадцатеричный RGB" = IC_PINTYPE_COLOR)
	spawn_flags = IC_SPAWN_DEFAULT|IC_SPAWN_RESEARCH

/obj/item/integrated_circuit/converter/hsv2hex/do_work()
	var/result = null
	pull_data()
	var/hue = get_pin_data(IC_INPUT, 1)
	var/saturation = get_pin_data(IC_INPUT, 2)
	var/value = get_pin_data(IC_INPUT, 3)
	if(isnum(hue)&&isnum(saturation)&&isnum(value))
		result = HSVtoRGB(hsv(AngleToHue(hue),saturation,value))

	set_pin_data(IC_OUTPUT, 1, result)
	push_data()
	activate_pin(2)

/obj/item/integrated_circuit/converter/rgb2hex
	name = "rgb to hexadecimal"
	desc = "Эта схема позволяет преобразовать цвет в формате RGB (красный, зеленый, синий) в шестнадцатеричный код RGB."
	extended_desc = "Первый вывод регулирует интенсивность красного цвета, второй - зеленого, а третий - синего. Диапазон значений для всех выводов составляет от 0 до 255."
	icon_state = "rgb-hex"
	inputs = list(
		"красный" = IC_PINTYPE_NUMBER,
		"зелёный" = IC_PINTYPE_NUMBER,
		"синий" = IC_PINTYPE_NUMBER
	)
	outputs = list("шестнадцатеричный RGB" = IC_PINTYPE_COLOR)
	spawn_flags = IC_SPAWN_DEFAULT|IC_SPAWN_RESEARCH

/obj/item/integrated_circuit/converter/rgb2hex/do_work()
	var/result = null
	pull_data()
	var/red = get_pin_data(IC_INPUT, 1)
	var/green = get_pin_data(IC_INPUT, 2)
	var/blue = get_pin_data(IC_INPUT, 3)
	if(isnum(red)&&isnum(green)&&isnum(blue))
		result = rgb(red,green,blue)

	set_pin_data(IC_OUTPUT, 1, result)
	push_data()
	activate_pin(2)
