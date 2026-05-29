/obj/item/electronic_assembly/proc/ie_legacy_ui_interact(mob/user, obj/item/integrated_circuit/circuit_pins)
	if(!user || !check_interactivity(user))
		return

	var/total_part_size = return_total_size()
	var/total_complexity = return_total_complexity()
	var/datum/browser/popup = new(user, "scannernew", name, 800, 630)
	popup.add_stylesheet("scannernew", 'html/browser/assembly_ui.css')

	var/HTML = "<html><head>[UTF8HEADER]<title>[name]</title></head>\
		<body><table><thead><tr> \
		<a href='?src=[REF(src)]'>Refresh</a>  |  <a href='?src=[REF(src)];rename=1'>Rename</a>  |  <a href='?src=[REF(src)];ie_ui_mode=tgui'>TGUI interface</a><br> \
		[total_part_size]/[max_components] ([round((total_part_size / max_components) * 100, 0.1)]%) space taken up in the assembly.<br> \
		[total_complexity]/[max_complexity] ([round((total_complexity / max_complexity) * 100, 0.1)]%) maximum complexity.<br>"
	if(battery)
		HTML += "[round(battery.charge, 0.1)]/[battery.maxcharge] ([round(battery.percent(), 0.1)]%) cell charge. <a href='?src=[REF(src)];remove_cell=1'>Remove</a>"
	else
		HTML += "<span class='danger'>No power cell detected!</span>"
	HTML += "</tr></thead>"

	if(!circuit_pins || !istype(circuit_pins, /obj/item/integrated_circuit) || !(circuit_pins in assembly_components))
		if(assembly_components.len > 0)
			circuit_pins = assembly_components[1]

	HTML += "<tr><td width=200px><div class=scrollleft>Components:<br><nobr>"

	var/builtin_components = ""
	var/removables = ""
	var/remove_num = 1

	for(var/obj/item/integrated_circuit/circuit in assembly_components)
		if(!circuit.removable)
			if(circuit == circuit_pins)
				builtin_components += "[circuit.displayed_name]<br>"
			else
				builtin_components += "<a href='?src=[REF(src)]'>[circuit.displayed_name]</a><br>"
		else
			removables += "<a href='?src=[REF(src)];component=[REF(circuit)];change_pos=1' style='text-decoration:none;'>[remove_num].</a> | "
			if(circuit == circuit_pins)
				removables += "[circuit.displayed_name]<br>"
			else
				removables += "<a href='?src=[REF(src)];component=[REF(circuit)]'>[circuit.displayed_name]</a><br>"
			remove_num++

	if(builtin_components)
		HTML += "<hr> Built in:<br> [builtin_components] <hr> Removable: <br>"

	HTML += removables

	HTML += "</nobr></div></td><td valign='top'><div class=scrollright>"

	if(!circuit_pins || !istype(circuit_pins, /obj/item/integrated_circuit))
		if(assembly_components.len > 0)
			circuit_pins = assembly_components[1]

	if(circuit_pins)
		HTML += "<div valign='middle'>[circuit_pins.displayed_name]<br>"

		HTML += "<a href='?src=[REF(src)];component=[REF(circuit_pins)]'>Refresh</a> | \
		<a href='?src=[REF(src)];component=[REF(circuit_pins)];rename_component=1'>Rename</a> | \
		<a href='?src=[REF(src)];component=[REF(circuit_pins)];scan=1'>Copy Ref</a> | \
		<a href='?src=[REF(src)];component=[REF(circuit_pins)];interact=1'>Interact</a>"
		if(circuit_pins.removable)
			HTML += " | <a href='?src=[REF(src)];component=[REF(circuit_pins)];remove=1'>Remove</a>"
		HTML += "</div><br>"

		var/table_edge_width = "30%"
		var/table_middle_width = "40%"

		HTML += "<table border='1' style='undefined;table-layout: fixed; position: absolute; left: 210; right: 2;'><colgroup>\
			<col style='width: [table_edge_width]'>\
			<col style='width: [table_middle_width]'>\
			<col style='width: [table_edge_width]'>\
			</colgroup>"

		var/row_height = max(circuit_pins.inputs.len, circuit_pins.outputs.len, 1)

		for(var/i = 1 to row_height)
			HTML += "<tr>"
			for(var/j = 1 to 3)
				var/datum/integrated_io/io = null
				var/words = ""
				var/height = 1
				switch(j)
					if(1)
						io = circuit_pins.get_pin_ref(IC_INPUT, i)
						if(io)
							words += "<b><a href='?src=[REF(circuit_pins)];act=wire;pin=[REF(io)]'>[io.display_pin_type()] [io.name]</a> \
							<a href='?src=[REF(circuit_pins)];act=data;pin=[REF(io)]'>[io.display_data(io.data)]</a></b><br>"
							if(io.linked.len)
								words += "<ul>"
								for(var/k in io.linked)
									var/datum/integrated_io/linked = k
									words += "<li><a href='?src=[REF(circuit_pins)];act=unwire;pin=[REF(io)];link=[REF(linked)]'>[linked]</a> \
									@ <a href='?src=[REF(linked.holder)]'>[linked.holder.displayed_name]</a></li>"
								words += "</ul>"

							if(circuit_pins.outputs.len > circuit_pins.inputs.len)
								height = 1
					if(2)
						if(i == 1)
							words += "[circuit_pins.displayed_name]<br>[circuit_pins.name != circuit_pins.displayed_name ? "([circuit_pins.name])":""]<hr>[circuit_pins.desc]"
							height = row_height
						else
							continue
					if(3)
						io = circuit_pins.get_pin_ref(IC_OUTPUT, i)
						if(io)
							words += "<b><a href='?src=[REF(circuit_pins)];act=wire;pin=[REF(io)]'>[io.display_pin_type()] [io.name]</a> \
							<a href='?src=[REF(circuit_pins)];act=data;pin=[REF(io)]'>[io.display_data(io.data)]</a></b><br>"
							if(io.linked.len)
								words += "<ul>"
								for(var/k in io.linked)
									var/datum/integrated_io/linked = k
									words += "<li><a href='?src=[REF(circuit_pins)];act=unwire;pin=[REF(io)];link=[REF(linked)]'>[linked]</a> \
									@ <a href='?src=[REF(linked.holder)]'>[linked.holder.displayed_name]</a></li>"
								words += "</ul>"

							if(circuit_pins.inputs.len > circuit_pins.outputs.len)
								height = 1
				HTML += "<td align='center' rowspan='[height]'>[words]</td>"
			HTML += "</tr>"

		for(var/activator in circuit_pins.activators)
			var/datum/integrated_io/io = activator
			var/words = ""

			words += "<b><a href='?src=[REF(circuit_pins)];act=wire;pin=[REF(io)]'>[io]</a> \
				<a href='?src=[REF(circuit_pins)];act=data;pin=[REF(io)]'>[io.data?"\<PULSE OUT\>":"\<PULSE IN\>"]</a></b><br>"
			if(io.linked.len)
				words += "<ul>"
				for(var/k in io.linked)
					var/datum/integrated_io/linked = k
					words += "<li><a href='?src=[REF(circuit_pins)];act=unwire;pin=[REF(io)];link=[REF(linked)]'>[linked]</a> \
					@ <a href='?src=[REF(linked.holder)]'>[linked.holder.displayed_name]</a></li>"
				words += "</ul>"

			HTML += "<tr><td colspan='3' align='center'>[words]</td></tr>"

		HTML += "<tr>\
			<br><font color='FFFFFF' class=lowtext>Complexity: [circuit_pins.complexity]\
			<br>Cooldown per use: [circuit_pins.cooldown_per_use/10] sec"
		if(circuit_pins.ext_cooldown)
			HTML += "<br>External manipulation cooldown: [circuit_pins.ext_cooldown/10] sec"
		if(circuit_pins.power_draw_idle)
			HTML += "<br>Power Draw: [circuit_pins.power_draw_idle] W (Idle)"
		if(circuit_pins.power_draw_per_use)
			HTML += "<br>Power Draw: [circuit_pins.power_draw_per_use] W (Active)"
		HTML += "<br>[circuit_pins.extended_desc]</font></tr></table></div>"

	HTML += "</div></td></tr></table></body></html>"

	popup.set_content(HTML)
	popup.open()

/obj/item/integrated_circuit/proc/ie_legacy_ui_interact_chip(mob/user)
	if(!user || !check_interactivity(user))
		return

	var/table_edge_width = "30%"
	var/table_middle_width = "40%"

	var/datum/browser/popup = new(user, "scannernew", name, 800, 630)
	popup.add_stylesheet("scannernew", 'html/browser/assembly_ui.css')

	var/HTML = "<html><head>[UTF8HEADER]<title>[src.displayed_name]</title></head><body> \
		<div align='center'> \
		<table border='1' style='undefined;table-layout: fixed; width: 80%'>"

	HTML += "<a href='?src=[REF(src)]'>Refresh</a>  |  \
		<a href='?src=[REF(src)];rename=1'>Rename</a>  |  \
		<a href='?src=[REF(src)];scan=1'>Copy Ref</a>  |  \
		<a href='?src=[REF(src)];ie_ui_mode=tgui'>TGUI interface</a>"

	HTML += "<br><colgroup> \
		<col style='width: [table_edge_width]'> \
		<col style='width: [table_middle_width]'> \
		<col style='width: [table_edge_width]'> \
		</colgroup>"

	var/row_height = max(inputs.len, outputs.len, 1)

	for(var/i = 1 to row_height)
		HTML += "<tr>"
		for(var/j = 1 to 3)
			var/datum/integrated_io/io = null
			var/words = ""
			var/height = 1
			switch(j)
				if(1)
					io = get_pin_ref(IC_INPUT, i)
					if(io)
						words += "<b><a href='?src=[REF(src)];act=wire;pin=[REF(io)]'>[io.display_pin_type()] [io.name]</a> \
							<a href='?src=[REF(src)];act=data;pin=[REF(io)]'>[io.display_data(io.data)]</a></b><br>"
						if(io.linked.len)
							words += "<ul>"
							for(var/k in io.linked)
								var/datum/integrated_io/linked = k
								words += "<li><a href='?src=[REF(src)];act=unwire;pin=[REF(io)];link=[REF(linked)]'>[linked]</a> \
									@ <a href='?src=[REF(linked.holder)]'>[linked.holder.displayed_name]</a></li>"
							words += "</ul>"

						if(outputs.len > inputs.len)
							height = 1
				if(2)
					if(i == 1)
						words += "[displayed_name]<br>[name != displayed_name ? "([name])":""]<hr>[desc]"
						height = row_height
					else
						continue
				if(3)
					io = get_pin_ref(IC_OUTPUT, i)
					if(io)
						words += "<b><a href='?src=[REF(src)];act=wire;pin=[REF(io)]'>[io.display_pin_type()] [io.name]</a> \
							<a href='?src=[REF(src)];act=data;pin=[REF(io)]'>[io.display_data(io.data)]</a></b><br>"
						if(io.linked.len)
							words += "<ul>"
							for(var/k in io.linked)
								var/datum/integrated_io/linked = k
								words += "<li><a href='?src=[REF(src)];act=unwire;pin=[REF(io)];link=[REF(linked)]'>[linked]</a> \
									@ <a href='?src=[REF(linked.holder)]'>[linked.holder.displayed_name]</a></li>"
							words += "</ul>"

						if(inputs.len > outputs.len)
							height = 1
			HTML += "<td align='center' rowspan='[height]'>[words]</td>"
		HTML += "</tr>"

	for(var/activator in activators)
		var/datum/integrated_io/io = activator
		var/words = ""

		words += "<b><a href='?src=[REF(src)];act=wire;pin=[REF(io)]'>[io]</a> \
			<a href='?src=[REF(src)];act=data;pin=[REF(io)]'>[io.data?"\<PULSE OUT\>":"\<PULSE IN\>"]</a></b><br>"

		if(io.linked.len)
			words += "<ul>"
			for(var/k in io.linked)
				var/datum/integrated_io/linked = k
				words += "<li><a href='?src=[REF(src)];act=unwire;pin=[REF(io)];link=[REF(linked)]'>[linked]</a> \
					@ <a href='?src=[REF(linked.holder)]'>[linked.holder.displayed_name]</a></li>"
			words += "</ul>"

		HTML += "<tr><td colspan='3' align='center'>[words]</td></tr>"

	HTML += "</table></div> \
		<br>Complexity: [complexity] \
		<br>Cooldown per use: [cooldown_per_use/10] sec"

	if(ext_cooldown)
		HTML += "<br>External manipulation cooldown: [ext_cooldown/10] sec"
	if(power_draw_idle)
		HTML += "<br>Power Draw: [power_draw_idle] W (Idle)"
	if(power_draw_per_use)
		HTML += "<br>Power Draw: [power_draw_per_use] W (Active)"

	HTML += "<br>[extended_desc]</body></html>"

	popup.set_content(HTML)
	popup.open()
