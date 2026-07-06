import { useBackend } from '../../../backend';
import { Stack } from '../../../components';
import { PrefRow } from '../components/PrefRow';

const PREF_TOGGLES: { key: string; label: string; flag: string; tooltip?: string }[] = [
  { key: 'verb_consent', label: 'Lewd вербы', flag: 'verb_consent', tooltip: 'Разрешить другим игрокам использовать эротические команды-вербы на вашем персонаже' },
  { key: 'ranged_verb_pref', label: 'Lewd вербы с расстояния', flag: 'ranged_verb_pref', tooltip: 'Позволяет использовать команды-вербы на других персонажей с расстояния' },
  { key: 'lewd_verb_sounds', label: 'Звуки lewd вербов', flag: 'lewd_verb_sounds', tooltip: 'Воспроизводить звуковые эффекты при использовании эротических вербов' },
  { key: 'arousable', label: 'Возбуждение', flag: 'arousable', tooltip: 'Ваш персонаж может испытывать возбуждение от игровых взаимодействий' },
  { key: 'sexknotting', label: 'Завязывание узлов (Knotting)', flag: 'sexknotting', tooltip: 'Блокировка соединения после завершения полового акта (анатомическая особенность)' },
  { key: 'genital_examine', label: 'Текст осмотра гениталий', flag: 'genital_examine', tooltip: 'Показывать текстовое описание гениталий персонажа при осмотре' },
  { key: 'vore_examine', label: 'Текст осмотра вор', flag: 'vore_examine', tooltip: 'Показывать текстовое описание внутренностей персонажа при осмотре (для вор-контента)' },
  { key: 'medihound_sleeper', label: 'Проглатывание мед-дроном', flag: 'medihound_sleeper', tooltip: 'Разрешить мед-дрону засасывать вас внутрь для лечения' },
  { key: 'eating_noises', label: 'Звуки поедания (вор)', flag: 'eating_noises', tooltip: 'Воспроизводить звуки при вор-поедании других персонажей' },
  { key: 'digestion_noises', label: 'Звуки переваривания', flag: 'digestion_noises', tooltip: 'Воспроизводить звуки при переваривании в животе' },
  { key: 'trash_forcefeed', label: 'Кормление мусором', flag: 'trash_forcefeed', tooltip: 'Разрешить кормить вас несъедобными предметами и мусором' },
  { key: 'forced_fem', label: 'Принудительная феминизация', flag: 'forced_fem', tooltip: 'Разрешить смену пола на женский против вашей воли через игровые механики' },
  { key: 'forced_masc', label: 'Принудительная маскулинизация', flag: 'forced_masc', tooltip: 'Разрешить смену пола на мужской против вашей воли через игровые механики' },
  { key: 'hypno', label: 'Lewd гипноз', flag: 'hypno', tooltip: 'Разрешить гипнотическое воздействие левд-характера' },
  { key: 'bimbofication', label: 'Бимбофикация', flag: 'bimbofication', tooltip: 'Разрешить изменение тела и сознания в сторону бимбо-состояния' },
  { key: 'breast_enlargement', label: 'Увеличение груди', flag: 'breast_enlargement', tooltip: 'Разрешить изменение размера груди через игровые механики' },
  { key: 'penis_enlargement', label: 'Увеличение пениса', flag: 'penis_enlargement', tooltip: 'Разрешить изменение размера пениса через игровые механики' },
  { key: 'butt_enlargement', label: 'Увеличение попы', flag: 'butt_enlargement', tooltip: 'Разрешить изменение размера ягодиц через игровые механики' },
  { key: 'belly_inflation', label: 'Вздутие живота', flag: 'belly_inflation', tooltip: 'Разрешить вздутие живота (результат вор, беременности или иных механик)' },
  { key: 'never_hypno', label: 'Гипноз (воздействие)', flag: 'never_hypno', tooltip: 'Включает гипнотическое воздействие на вашего персонажа' },
  { key: 'no_aphro', label: 'Афродизиаки', flag: 'no_aphro', tooltip: 'Включает воздействие афродизиаков, приворотов и препаратов, повышающих возбуждение' },
  { key: 'no_ass_slap', label: 'Шлепки по попе', flag: 'no_ass_slap', tooltip: 'Разрешить другим игрокам шлёпать вашего персонажа по попе' },
  { key: 'no_auto_wag', label: 'Автоматическое виляние хвостом', flag: 'no_auto_wag', tooltip: 'Автоматически вилять хвостом при возбуждении или других эмоциях' },
  { key: 'chastity_pref', label: 'Взаимодействие с поясом верности', flag: 'chastity_pref', tooltip: 'Разрешить надевать и снимать с вас пояс верности' },
  { key: 'stimulation_pref', label: 'Модификаторы стимуляции', flag: 'stimulation_pref', tooltip: 'Применять модификаторы стимуляции гениталий от навыков, расы и прочего' },
  { key: 'edging_pref', label: 'Эджинг', flag: 'edging_pref', tooltip: 'Разрешить отказ в разрядке во время полового акта (эджинг)' },
  { key: 'cum_onto_pref', label: 'Покрытие спермой', flag: 'cum_onto_pref', tooltip: 'Разрешить покрытие вашего персонажа спермой других (или наоборот)' },
  { key: 'sex_jitter', label: 'Дрожь при сексе', flag: 'sex_jitter', tooltip: 'Визуальная дрожь персонажа во время полового акта' },
  { key: 'no_disco_dance', label: 'Танцевать возле диско-шара', flag: 'no_disco_dance', tooltip: 'Автоматически танцевать при нахождении рядом с диско-шаром' },
];

export const ContentSection = (props, context) => {
  const { act, data } = useBackend(context);

  const mid = Math.ceil(PREF_TOGGLES.length / 2);
  const leftCol = PREF_TOGGLES.slice(0, mid);
  const rightCol = PREF_TOGGLES.slice(mid);

  const renderRow = ({ key, label, flag, tooltip }) => (
    <PrefRow
      key={key}
      label={label}
      checked={data[key]}
      tooltip={tooltip}
      onClick={() => act('pref', { pref: flag })}
    />
  );

  return (
    <Stack fill>
      <Stack.Item basis="50%">
        <Stack vertical>{leftCol.map(renderRow)}</Stack>
      </Stack.Item>
      <Stack.Item basis="50%">
        <Stack vertical>{rightCol.map(renderRow)}</Stack>
      </Stack.Item>
    </Stack>
  );
};
