/datum/design/nanites
	name = "None"
	desc = "Предупреждение разработчику: если вы это видите..."
	id = "default_nanites"
	build_type = NANITE_COMPILER
	construction_time = 50
	category = list()
	research_icon = 'icons/obj/device.dmi'
	research_icon_state = "nanite_program"
	var/program_type = /datum/nanite_program

////////////////////UTILITY NANITES//////////////////////////////////////

/datum/design/nanites/metabolic_synthesis
	name = "Metabolic Synthesis"
	desc = "Наниты используют метаболизм носителя для ускорения размножения, применяя избыточное питание как топливо."
	id = "metabolic_nanites"
	program_type = /datum/nanite_program/metabolic_synthesis
	category = list("Utility Nanites")

/datum/design/nanites/viral
	name = "Viral Replica"
	desc = "Наниты постоянно посылают зашифрованные сигналы, пытаясь насильственно скопировать собственную программу в другие скопления нанитов."
	id = "viral_nanites"
	program_type = /datum/nanite_program/viral
	category = list("Utility Nanites")

/datum/design/nanites/research
	name = "Distributed Computing"
	desc = "Наниты помогают серверам исследований, выполняя часть вычислений и увеличивая генерацию очков исследований."
	id = "research_nanites"
	program_type = /datum/nanite_program/research
	category = list("Utility Nanites")

/datum/design/nanites/researchplus
	name = "Neural Network"
	desc = "Наниты объединяют мозги носителей в нейронную исследовательскую сеть, которая становится эффективнее с увеличением общего числа носителей. Сеть можно перегрузить для увеличения отдачи исследований."
	id = "researchplus_nanites"
	program_type = /datum/nanite_program/researchplus
	category = list("Utility Nanites")

/datum/design/nanites/monitoring
	name = "Monitoring"
	desc = "Наниты следят за жизненными показателями и местоположением носителя, передавая их в сеть датчиков скафандра."
	id = "monitoring_nanites"
	program_type = /datum/nanite_program/monitoring
	category = list("Utility Nanites")

/datum/design/nanites/self_scan
	name = "Host Scan"
	desc = "Наниты выводят носителю подробные результаты сканирования тела."
	id = "selfscan_nanites"
	program_type = /datum/nanite_program/self_scan
	category = list("Utility Nanites")

/datum/design/nanites/dermal_button
	name = "Dermal Button"
	desc = "Отображает кнопку на коже носителя, с помощью которой можно отправить сигнал нанитам."
	id = "dermal_button_nanites"
	program_type = /datum/nanite_program/dermal_button
	category = list("Utility Nanites")

/datum/design/nanites/stealth
	name = "Stealth"
	desc = "Наниты скрывают свою активность и программу от поверхностных сканов."
	id = "stealth_nanites"
	program_type = /datum/nanite_program/stealth
	category = list("Utility Nanites")

/datum/design/nanites/reduced_diagnostics
	name = "Reduced Diagnostics"
	desc = "Отключает часть энергозатратных диагностик нанитов, из-за чего они не могут передать список своих программ портативным сканерам. Это экономит энергию и немного ускоряет размножение."
	id = "red_diag_nanites"
	program_type = /datum/nanite_program/reduced_diagnostics
	category = list("Utility Nanites")

/datum/design/nanites/access
	name = "Subdermal ID"
	desc = "Наниты хранят права доступа ID носителя в подкожной магнитной полосе. Обновляются при срабатывании, копируя текущие права носителя."
	id = "access_nanites"
	program_type = /datum/nanite_program/access
	category = list("Utility Nanites")

/datum/design/nanites/relay
	name = "Relay"
	desc = "Наниты принимают и ретранслируют сигналы нанитов на большие расстояния."
	id = "relay_nanites"
	program_type = /datum/nanite_program/relay
	category = list("Utility Nanites")

//new era add
/datum/design/nanites/signaler
	name = "Signaler"
	desc = "Наниты принимают и отправляют радиосигналы."
	id = "signaler_nanites"
	program_type = /datum/nanite_program/signaler
	category = list("Utility Nanites")

/datum/design/nanites/repeater
	name = "Signal Repeater"
	desc = "При срабатывании отправляет ещё один сигнал нанитам, при необходимости с задержкой."
	id = "repeater_nanites"
	program_type = /datum/nanite_program/sensor/repeat
	category = list("Utility Nanites")

/datum/design/nanites/relay_repeater
	name = "Relay Signal Repeater"
	desc = "При срабатывании отправляет ещё один сигнал на канал ретрансляции, при необходимости с задержкой."
	id = "relay_repeater_nanites"
	program_type = /datum/nanite_program/sensor/relay_repeat
	category = list("Utility Nanites")

/datum/design/nanites/emp
	name = "Electromagnetic Resonance"
	desc = "При срабатывании наниты создают электромагнитный импульс вокруг носителя. Повредит другие программы нанитов!"
	id = "emp_nanites"
	program_type = /datum/nanite_program/emp
	category = list("Utility Nanites")

/datum/design/nanites/spreading
	name = "Infective Exo-Locomotion"
	desc = "Наниты приобретают способность короткое время выживать вне человеческого тела, а также образовывать новые колонии без процесса интеграции, что даёт крайне заразный штамм нанитов. Обходит антивирусную защиту."
	id = "spreading_nanites"
	program_type = /datum/nanite_program/spreading
	category = list("Utility Nanites")

/datum/design/nanites/nanite_sting
	name = "Nanite Sting"
	desc = "При срабатывании выпускает почти невидимый шип из нанитов, который пытается заразить ближайшего не-носителя копией скопления нанитов носителя."
	id = "nanite_sting_nanites"
	program_type = /datum/nanite_program/nanite_sting
	category = list("Utility Nanites")

/datum/design/nanites/mitosis
	name = "Mitosis"
	desc = "Наниты получают способность к саморепликации, используя блюспейс вместо шаблона. Это резко ускоряет размножение, но из-за дефектных копий иногда вызывает программные ошибки. Несовместимо с синхронизацией с облаком."
	id = "mitosis_nanites"
	program_type = /datum/nanite_program/mitosis
	category = list("Utility Nanites")

/datum/design/nanites/antiviral
	name = "Enhanced Error Correction"
	desc = "Наниты самостоятельно распространяются и дублируют память хранения своей программы, предотвращая вирусный захват."
	id = "antiviral_nanites"
	program_type = /datum/nanite_program/lockout/antiviral
	category = list("Utility Nanites")

/datum/design/nanites/hostile_lockdown
	name = "Hostile Lockdown"
	desc = "Наниты постоянно шифруют и перемешивают собственные секторы управления, не позволяя консолям управлять ими. Кроме того, если носитель — синтетический организм с врождённым контролем над штаммами нанитов, это также помешает ему воздействовать на наниты."
	id = "hostile_lockdown"
	program_type = /datum/nanite_program/lockout/hostile_lockdown
	category = list("Utility Nanites")

////////////////////MEDICAL NANITES//////////////////////////////////////
/datum/design/nanites/regenerative
	name = "Accelerated Regeneration"
	desc = "Наниты усиливают естественную регенерацию носителя, ускоряя заживление."
	id = "regenerative_nanites"
	program_type = /datum/nanite_program/regenerative
	category = list("Medical Nanites")

/datum/design/nanites/regenerative_advanced
	name = "Bio-Reconstruction"
	desc = "Наниты вручную восстанавливают и заменяют органические клетки, действуя намного быстрее обычной регенерации. Однако программа не различает повреждённые и неповреждённые клетки и расходует наниты, даже если эффекта нет."
	id = "regenerative_plus_nanites"
	program_type = /datum/nanite_program/regenerative_advanced
	category = list("Medical Nanites")

/datum/design/nanites/temperature
	name = "Temperature Adjustment"
	desc = "Наниты поддерживают внутреннюю температуру носителя на идеальном уровне."
	id = "temperature_nanites"
	program_type = /datum/nanite_program/temperature
	category = list("Medical Nanites")

/datum/design/nanites/purging
	name = "Blood Purification"
	desc = "Наниты выводят токсины и химикаты из крови носителя."
	id = "purging_nanites"
	program_type = /datum/nanite_program/purging
	category = list("Medical Nanites")

/datum/design/nanites/purging_corruption
	name = "Purge Corruption"
	desc = "Наниты очищают схемы позитронного мозга носителя от коррозии."
	id = "purging_synth_nanites"
	program_type = /datum/nanite_program/purging_synth
	category = list("Medical Nanites")

/datum/design/nanites/purging_advanced
	name = "Selective Blood Purification"
	desc = "Наниты выводят токсины и опасные химикаты из крови носителя, не трогая полезные вещества. Дополнительные вычисления, требуемые для анализа химикатов, значительно увеличивают расход нанитов."
	id = "purging_plus_nanites"
	program_type = /datum/nanite_program/purging_advanced
	category = list("Medical Nanites")

/datum/design/nanites/brain_heal
	name = "Neural Regeneration"
	desc = "Наниты восстанавливают нейронные связи в мозге носителя, устраняя повреждения мозга и лёгкие травмы."
	id = "brainheal_nanites"
	program_type = /datum/nanite_program/brain_heal
	category = list("Medical Nanites")

/datum/design/nanites/brain_heal_advanced
	name = "Neural Reimaging"
	desc = "Наниты способны создавать резервные копии и восстанавливать нейронные связи носителя, потенциально заменяя целые участки утраченного или повреждённого вещества мозга."
	id = "brainheal_plus_nanites"
	program_type = /datum/nanite_program/brain_heal_advanced
	category = list("Medical Nanites")

/datum/design/nanites/blood_restoring
	name = "Blood Regeneration"
	desc = "Наниты стимулируют и ускоряют выработку клеток крови у носителя."
	id = "bloodheal_nanites"
	program_type = /datum/nanite_program/blood_restoring
	category = list("Medical Nanites")

/datum/design/nanites/repairing
	name = "Mechanical Repair"
	desc = "Наниты ремонтируют повреждения механических конечностей носителя."
	id = "repairing_nanites"
	program_type = /datum/nanite_program/repairing
	category = list("Medical Nanites")

/datum/design/nanites/defib
	name = "Defibrillation"
	desc = "При срабатывании наниты посылают дефибриллирующий разряд в сердце носителя."
	id = "defib_nanites"
	program_type = /datum/nanite_program/defib
	category = list("Medical Nanites")

/datum/design/nanites/hard_reboot
	name = "Hard Reboot Protocol"
	desc = "Наномашины хранят протоколы перезагрузки позитронного мозга носителя."
	id = "hard_reboot_nanites"
	program_type = /datum/nanite_program/hard_reboot
	category = list("Medical Nanites")

/datum/design/nanites/heal_wounds
	name = "Recovery Wounds"
	desc = "Наниты расходуют себя для восстановления тела, заменяя повреждения и тем самым заживляя раны."
	id = "heal_wounds_nanites"
	program_type = /datum/nanite_program/heal_wounds
	category = list("Medical Nanites")


////////////////////AUGMENTATION NANITES//////////////////////////////////////

/datum/design/nanites/nervous
	name = "Nerve Support"
	desc = "Наниты работают как вторичная нервная система, сокращая время оглушения носителя."
	id = "nervous_nanites"
	program_type = /datum/nanite_program/nervous
	category = list("Augmentation Nanites")

/datum/design/nanites/hardening
	name = "Dermal Hardening"
	desc = "Наниты формируют сетку под кожей носителя, защищая его от ударов в ближнем бою и пуль."
	id = "hardening_nanites"
	program_type = /datum/nanite_program/hardening
	category = list("Augmentation Nanites")

/datum/design/nanites/refractive
	name = "Dermal Refractive Surface"
	desc = "Наниты образуют мембрану над кожей носителя, снижая эффект лазерных и энергетических атак."
	id = "refractive_nanites"
	program_type = /datum/nanite_program/refractive
	category = list("Augmentation Nanites")

/datum/design/nanites/coagulating
	name = "Vein Repressurization"
	desc = "Наниты перенаправляют кровоток от открытых ран, резко снижая скорость кровотечения."
	id = "coagulating_nanites"
	program_type = /datum/nanite_program/coagulating
	category = list("Augmentation Nanites")

/datum/design/nanites/conductive
	name = "Electric Conduction"
	desc = "Наниты работают как заземляющий стержень для электрических разрядов, защищая носителя. Разряды всё ещё могут повредить сами наниты."
	id = "conductive_nanites"
	program_type = /datum/nanite_program/conductive
	category = list("Augmentation Nanites")

/datum/design/nanites/adrenaline
	name = "Adrenaline Burst"
	desc = "При срабатывании наниты выбрасывают порцию адреналина, выводя носителя из оглушения и временно увеличивая его скорость."
	id = "adrenaline_nanites"
	program_type = /datum/nanite_program/adrenaline
	category = list("Augmentation Nanites")

/datum/design/nanites/mindshield
	name = "Mental Barrier"
	desc = "Наниты образуют защитную мембрану вокруг мозга носителя, ограждая его от аномальных воздействий, пока активны."
	id = "mindshield_nanites"
	program_type = /datum/nanite_program/mindshield
	category = list("Augmentation Nanites")

////////////////////DEFECTIVE NANITES//////////////////////////////////////

/datum/design/nanites/glitch
	name = "Glitch"
	desc = "Тяжёлое программное повреждение, из-за которого наниты постепенно разрушаются."
	id = "glitch_nanites"
	program_type = /datum/nanite_program/glitch
	category = list("Defective Nanites")

/datum/design/nanites/necrotic
	name = "Necrosis"
	desc = "Наниты без разбора атакуют внутренние ткани, вызывая обширные повреждения."
	id = "necrotic_nanites"
	program_type = /datum/nanite_program/necrotic
	category = list("Defective Nanites")

/datum/design/nanites/toxic
	name = "Toxin Buildup"
	desc = "Наниты вызывают медленное, но постоянное накопление токсинов в организме носителя."
	id = "toxic_nanites"
	program_type = /datum/nanite_program/toxic
	category = list("Defective Nanites")

/datum/design/nanites/suffocating
	name = "Hypoxemia"
	desc = "Наниты мешают крови носителя эффективно поглощать кислород."
	id = "suffocating_nanites"
	program_type = /datum/nanite_program/suffocating
	category = list("Defective Nanites")

/datum/design/nanites/brain_misfire
	name = "Brain Misfire"
	desc = "Наниты вмешиваются в работу нейронных путей, вызывая лёгкие психические расстройства."
	id = "brainmisfire_nanites"
	program_type = /datum/nanite_program/brain_misfire
	category = list("Defective Nanites")

/datum/design/nanites/skin_decay
	name = "Dermalysis"
	desc = "Наниты атакуют клетки кожи, вызывая раздражение, сыпь и лёгкие повреждения."
	id = "skindecay_nanites"
	program_type = /datum/nanite_program/skin_decay
	category = list("Defective Nanites")

/datum/design/nanites/nerve_decay
	name = "Nerve Decay"
	desc = "Наниты атакуют нервы носителя, вызывая нарушение координации и кратковременные приступы паралича."
	id = "nervedecay_nanites"
	program_type = /datum/nanite_program/nerve_decay
	category = list("Defective Nanites")

/datum/design/nanites/brain_decay
	name = "Brain-Eating Nanites"
	desc = "Повреждает клетки мозга, постепенно снижая когнитивные функции носителя."
	id = "braindecay_nanites"
	program_type = /datum/nanite_program/brain_decay
	category = list("Defective Nanites")

////////////////////WEAPONIZED NANITES/////////////////////////////////////

/datum/design/nanites/flesh_eating
	name = "Cellular Breakdown"
	desc = "Наниты разрушают клеточные структуры в организме носителя, нанося дробящий урон."
	id = "flesheating_nanites"
	program_type = /datum/nanite_program/flesh_eating
	category = list("Weaponized Nanites")

/datum/design/nanites/poison
	name = "Poisoning"
	desc = "Наниты доставляют ядовитые химикаты к внутренним органам носителя, вызывая токсический урон и рвоту."
	id = "poison_nanites"
	program_type = /datum/nanite_program/poison
	category = list("Weaponized Nanites")

/datum/design/nanites/memory_leak
	name = "Memory Leak"
	desc = "Эта программа вторгается в область памяти, используемую другими программами, вызывая частые повреждения и ошибки."
	id = "memleak_nanites"
	program_type = /datum/nanite_program/memory_leak
	category = list("Weaponized Nanites")

/datum/design/nanites/aggressive_replication
	name = "Aggressive Replication"
	desc = "Наниты поглощают органическую материю для ускорения размножения, повреждая носителя."
	id = "aggressive_nanites"
	program_type = /datum/nanite_program/aggressive_replication
	category = list("Weaponized Nanites")

/datum/design/nanites/meltdown
	name = "Meltdown"
	desc = "Вызывает внутренний расплав внутри нанитов, нанося внутренние ожоги носителю и быстро уничтожая популяцию нанитов. При активации устанавливает порог безопасности нанитов на 0."
	id = "meltdown_nanites"
	program_type = /datum/nanite_program/meltdown
	category = list("Weaponized Nanites")

/datum/design/nanites/cryo
	name = "Cryogenic Treatment"
	desc = "Наниты быстро отводят тепло через кожу носителя, снижая его температуру."
	id = "cryo_nanites"
	program_type = /datum/nanite_program/cryo
	category = list("Weaponized Nanites")

/datum/design/nanites/pyro
	name = "Sub-Dermal Combustion"
	desc = "Наниты накапливают горючие жидкости под кожей носителя, а затем поджигают их."
	id = "pyro_nanites"
	program_type = /datum/nanite_program/pyro
	category = list("Weaponized Nanites")

/datum/design/nanites/heart_stop
	name = "Heart-Stopper"
	desc = "При срабатывании останавливает сердце носителя; повторное срабатывание запускает его снова."
	id = "heartstop_nanites"
	program_type = /datum/nanite_program/heart_stop
	category = list("Weaponized Nanites")

/datum/design/nanites/explosive
	name = "Chain Detonation"
	desc = "При срабатывании взрывает все наниты внутри носителя цепной реакцией."
	id = "explosive_nanites"
	program_type = /datum/nanite_program/explosive
	category = list("Weaponized Nanites")

/datum/design/nanites/mind_control
	name = "Mind Control"
	desc = "Наниты впечатывают абсолютную директиву в мозг носителя, пока активны."
	id = "mindcontrol_nanites"
	program_type = /datum/nanite_program/comm/mind_control
	category = list("Weaponized Nanites")

////////////////////SUPPRESSION NANITES//////////////////////////////////////

/datum/design/nanites/shock
	name = "Electric Shock"
	desc = "При срабатывании наниты бьют носителя током. Уничтожает много нанитов!"
	id = "shock_nanites"
	program_type = /datum/nanite_program/shocking
	category = list("Suppression Nanites")

/datum/design/nanites/stun
	name = "Neural Shock"
	desc = "При срабатывании наниты посылают импульс по нервам носителя, обездвиживая его на короткое время."
	id = "stun_nanites"
	program_type = /datum/nanite_program/stun
	category = list("Suppression Nanites")

/datum/design/nanites/sleepy
	name = "Sleep Induction"
	desc = "При срабатывании наниты вызывают быструю нарколепсию."
	id = "sleep_nanites"
	program_type = /datum/nanite_program/sleepy
	category = list("Suppression Nanites")

/datum/design/nanites/paralyzing
	name = "Paralysis"
	desc = "Наниты активно подавляют нервные импульсы, фактически парализуя носителя."
	id = "paralyzing_nanites"
	program_type = /datum/nanite_program/paralyzing
	category = list("Suppression Nanites")

/datum/design/nanites/fake_death
	name = "Death Simulation"
	desc = "Наниты вводят носителя в комоподобное состояние, способное обмануть большинство медицинских сканеров."
	id = "fakedeath_nanites"
	program_type = /datum/nanite_program/fake_death
	category = list("Suppression Nanites")

/datum/design/nanites/pacifying
	name = "Pacification"
	desc = "Наниты подавляют центр агрессии в мозге, не позволяя носителю напрямую причинять вред другим."
	id = "pacifying_nanites"
	program_type = /datum/nanite_program/pacifying
	category = list("Suppression Nanites")

/datum/design/nanites/blinding
	name = "Blindness"
	desc = "Наниты подавляют зрительные нервы носителя, ослепляя его, пока активны."
	id = "blinding_nanites"
	program_type = /datum/nanite_program/blinding
	category = list("Suppression Nanites")

/datum/design/nanites/mute
	name = "Mute"
	desc = "Наниты подавляют речь носителя, лишая его голоса, пока активны."
	id = "mute_nanites"
	program_type = /datum/nanite_program/mute
	category = list("Suppression Nanites")

/datum/design/nanites/voice
	name = "Skull Echo"
	desc = "Наниты воспроизводят синтезированное сообщение в черепе носителя."
	id = "voice_nanites"
	program_type = /datum/nanite_program/comm/voice
	category = list("Suppression Nanites")

/datum/design/nanites/speech
	name = "Forced Speech"
	desc = "При срабатывании наниты заставляют носителя произнести заранее запрограммированную фразу."
	id = "speech_nanites"
	program_type = /datum/nanite_program/comm/speech
	category = list("Suppression Nanites")

/datum/design/nanites/hallucination
	name = "Hallucination"
	desc = "Наниты заставляют носителя видеть и слышать то, чего нет на самом деле."
	id = "hallucination_nanites"
	program_type = /datum/nanite_program/comm/hallucination
	category = list("Suppression Nanites")

/datum/design/nanites/good_mood
	name = "Happiness Enhancer"
	desc = "Наниты синтезируют серотонин в мозге носителя, создавая искусственное чувство счастья."
	id = "good_mood_nanites"
	program_type = /datum/nanite_program/good_mood
	category = list("Suppression Nanites")

/datum/design/nanites/bad_mood
	name = "Happiness Suppressor"
	desc = "Наниты подавляют выработку серотонина в мозге носителя, создавая искусственное состояние депрессии."
	id = "bad_mood_nanites"
	program_type = /datum/nanite_program/bad_mood
	category = list("Suppression Nanites")

////////////////////SENSOR NANITES//////////////////////////////////////

/datum/design/nanites/sensor_health
	name = "Health Sensor"
	desc = "Наниты отправляют сигнал, когда здоровье носителя выше/ниже определённого процента."
	id = "sensor_health_nanites"
	program_type = /datum/nanite_program/sensor/health
	category = list("Sensor Nanites")

/datum/design/nanites/sensor_damage
	name = "Damage Sensor"
	desc = "Наниты отправляют сигнал, когда определённый вид урона у носителя выше/ниже заданного значения."
	id = "sensor_damage_nanites"
	program_type = /datum/nanite_program/sensor/damage
	category = list("Sensor Nanites")

/datum/design/nanites/sensor_crit
	name = "Critical Health Sensor"
	desc = "Наниты отправляют сигнал, когда носитель впервые достигает критического состояния."
	id = "sensor_crit_nanites"
	program_type = /datum/nanite_program/sensor/crit
	category = list("Sensor Nanites")

/datum/design/nanites/sensor_death
	name = "Death Sensor"
	desc = "Наниты отправляют сигнал, когда обнаруживают, что носитель мёртв."
	id = "sensor_death_nanites"
	program_type = /datum/nanite_program/sensor/death
	category = list("Sensor Nanites")

/datum/design/nanites/sensor_voice
	name = "Voice Sensor"
	desc = "Отправляет сигнал, когда наниты слышат заданное слово или предложение."
	id = "sensor_voice_nanites"
	program_type = /datum/nanite_program/sensor/voice
	category = list("Sensor Nanites")

/datum/design/nanites/sensor_nanite_volume
	name = "Nanite Volume Sensor"
	desc = "Наниты отправляют сигнал, когда запас нанитов выше/ниже определённого процента."
	id = "sensor_nanite_volume"
	program_type = /datum/nanite_program/sensor/nanite_volume
	category = list("Sensor Nanites")

////////////////////NANITE PROTOCOLS//////////////////////////////////////
//Note about the category name: The UI cuts the last 8 characters from the category name to remove the " Nanites" in the other categories
//Because of this, Protocols was getting cut down to "P", so i had to add some padding
/datum/design/nanites/kickstart
	name = "Kickstart Protocol"
	desc = "Протокол репликации: наниты сосредоточиваются на раннем росте, резко ускоряя размножение на несколько минут после первоначальной имплантации."
	id = "kickstart_nanites"
	program_type = /datum/nanite_program/protocol/kickstart
	category = list("Protocols_Nanites")

/datum/design/nanites/factory
	name = "Factory Protocol"
	desc = "Протокол репликации: наниты строят внутри носителя матрицу-фабрику, постепенно увеличивая скорость размножения. Фабрика разрушается, если протокол неактивен."
	id = "factory_nanites"
	program_type = /datum/nanite_program/protocol/factory
	category = list("Protocols_Nanites")

/datum/design/nanites/pyramid
	name = "Pyramid Protocol"
	desc = "Протокол репликации: наниты применяют альтернативный кооперативный протокол размножения, более эффективный, пока уровень насыщения выше 80%."
	id = "pyramid_nanites"
	program_type = /datum/nanite_program/protocol/pyramid
	category = list("Protocols_Nanites")

/datum/design/nanites/offline
	name = "Eclipse Protocol"
	desc = "Протокол репликации: пока носитель спит или находится без сознания, наниты используют меньшее противодействие для более быстрого размножения."
	id = "offline_nanites"
	program_type = /datum/nanite_program/protocol/offline
	category = list("Protocols_Nanites")

/datum/design/nanites/synergy
	name = "Synergy Protocol"
	desc = "Протокол репликации: наниты синхронизируют свои задачи и процессы внутри носителя, увеличивая скорость размножения пропорционально текущему объёму нанитов."
	id = "synergy_nanites"
	program_type = /datum/nanite_program/protocol/synergy
	category = list("Protocols_Nanites")

/datum/design/nanites/hive
	name = "Hive Protocol"
	desc = "Протокол хранения: наниты используют более эффективную решётчатую укладку для хранения объёма, увеличивая максимальный объём у носителя."
	id = "hive_nanites"
	program_type = /datum/nanite_program/protocol/hive
	category = list("Protocols_Nanites")

/datum/design/nanites/zip
	name = "Zip Protocol"
	desc = "Протокол хранения: наниты разбираются и уплотняются в неактивном состоянии, значительно увеличивая максимальный объём у носителя. Однако процесс немного замедляет скорость размножения."
	id = "zip_nanites"
	program_type = /datum/nanite_program/protocol/zip
	category = list("Protocols_Nanites")

/datum/design/nanites/free_range
	name = "Free-range Protocol"
	desc = "Протокол хранения: наниты отказываются от стандартных протоколов хранения в пользу более дешёвого и органичного подхода. Максимальный объём снижается, но скорость размножения растёт."
	id = "free_range_nanites"
	program_type = /datum/nanite_program/protocol/free_range
	category = list("Protocols_Nanites")

/datum/design/nanites/unsafe_storage
	name = "S.L.O. Protocol"
	desc = "Протокол хранения: «S.L.O.P.» — протокол переопределения уровня хранения — полностью отключает обычные для нанитов меры безопасности, позволяя им достигать гораздо более высоких уровней насыщения, но с риском внутреннего урона носителю."
	id = "unsafe_storage_nanites"
	program_type = /datum/nanite_program/protocol/unsafe_storage
	category = list("Protocols_Nanites")
