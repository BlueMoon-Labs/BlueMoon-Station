///This is the standard 'baseline' NIF model.
/obj/item/organ/cyberimp/brain/nif/standard
	name = "Standard Type NIF"
	desc = "«Standard-Type» — классификация высококачественных нанитовых имплант-каркасов. В эту категорию в основном входят каркасы с высокой надёжностью, безупречной интеграцией с пользователем и сочетанием объёма памяти и вычислительной мощности, достаточных для запуска широкого спектра программ."
	manufacturer_notes = "Хотя бесчисленные производители выпускают собственные реализации NIF — открытые или нет, — в галактике существует меньше тысячи моделей Standard-Type. Они стали результатом почти пяти лет улучшений старых моделей Framework и довольно желанны, поскольку их крайне сложно «самодельничать»."

/obj/item/organ/cyberimp/brain/nif/roleplay_model
	name = "Econo-Deck Type NIF"
	desc = "«Econo-Deck» — классификация нанитовых имплант-каркасов пониженного качества. Обычно это небрендовые «экономичные» подделки более качественных каркасов с батареями низшего класса, устаревшими и рискованными схемами сборки и куда более грубой калибровкой под пользователя."
	manufacturer_notes = "Большинство сайтов энтузиастов и хардкорных пользователей, корпоративные неврологи и разработчики «софтов, такие как Ковен Альтспейс, не рекомендуют покупать их. Несмотря на доступность для обывателя, в кругах пользователей Framework принято считать, что на устройстве, напрямую подключённом к нервной системе, экономить нельзя; поэтому Econo-Deck обычно оказываются в руках по-настоящему отчаявшихся, преступников или выходят из мастерских как «самоделки»."

	max_power_level = 500
	max_nifsofts = 3
	calibration_time = 15 SECONDS
	max_durability = 50
	death_durability_loss = 10


/obj/item/organ/cyberimp/brain/nif/roleplay_model/cheap
	name = "Trial-Lite Type NIF"
	desc = "«Trial-Lite» — классификация временных нанитовых имплант-каркасов. Обычно их распространяют на промомероприятиях, для использования с узкоспециализированными NIFSoft или в некоторых корпоративных дилерских центрах, чтобы дать потенциальным пользователям взглянуть на технологию. Обычно каркасы Trial-Lite не «связываются» со своим пользователем по-настоящему: они образуют крайне слабое соединение, а затем в течение нескольких часов растворяются в рассыпавшиеся мёртвые наномашины, которые обычно выдыхают."
	manufacturer_notes = "Обычно каркасы Trial-Lite не «связываются» со своим пользователем: образуют крайне слабое соединение, а затем в течение нескольких часов растворяются в мёртвые наномашины, которые выдыхают. До сих пор невозможно продлить срок службы Trial-Lite NIF из-за их крайне низкокачественной конструкции и программирования."
	nif_persistence = FALSE

/obj/item/autosurgeon/nif/disposable //Disposable, as in the fact that this only lasts for one shift
	name = "Econo-Deck Type Autosurgeon"
	starting_organ = /obj/item/organ/cyberimp/brain/nif/roleplay_model/cheap
	uses = 1

/obj/item/organ/cyberimp/brain/nif/standard/ghost_role
	nif_persistence = FALSE
	is_calibrated = TRUE

/obj/item/autosurgeon/nif/ghost_role
	name = "Enhanced Standard Type NIF Autosurgeon"
	starting_organ = /obj/item/organ/cyberimp/brain/nif/standard/ghost_role
	uses = 1
