# Атмосфера на DM

Атмосфера реализована целиком на DM, без Auxmos (Rust).

- **Газ:** хранение в `gas_mixture.gases` (моли по id), `temperature`, `volume`. Все операции (get_moles, merge, transfer_to, react и т.д.) в `code/__DEFINES/native_atmos_bindings.dm` и в `gas_mixture.dm`.
- **Реакции:** цикл по `SSair.gas_reactions`, проверка min_requirements, вызов `reaction.react(src, holder)` в `gas_mixture/react()`.
- **Обработка тайлов:** вызовы process_turf_* заглушены (возврат 0), перенос воздуха между тайлами не считается. Реакции в трубах, баллонах и в снятых порциях (огонь) работают.
