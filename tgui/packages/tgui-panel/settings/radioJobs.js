// Классы тега должности в рации приходят из get_radio_job_style() в
// code/game/say.dm. Умолчания dark/light повторяют ChatRadioJobs.scss.
export const RADIO_JOB_GROUPS = [
  {
    name: 'Отделы станции',
    ids: ['cmd', 'sec', 'eng', 'med', 'sci', 'cargo', 'srv', 'law', 'asst',
      'silicon', 'unk'],
  },
  {
    name: 'Роли вне станции',
    ids: ['centcom', 'synd', 'inteq', 'tarkon', 'pirate', 'sol', 'nri',
      'hotel'],
  },
];

// legacy - прежний цвет фракции в режиме "По профессии (как раньше)",
// если в режиме по отделам он другой.
export const RADIO_JOB_PALETTE = [
  { id: 'cmd', name: 'Командование', sample: 'Captain', dark: '#fcdf03', light: '#8a6d00' },
  { id: 'sec', name: 'Служба безопасности', sample: 'Security Officer', dark: '#dd3535', light: '#b31b1b' },
  { id: 'eng', name: 'Инженерия', sample: 'Station Engineer', dark: '#f37746', light: '#b8460f' },
  { id: 'med', name: 'Медицина', sample: 'Medical Doctor', dark: '#57b8f0', light: '#1f6f9e' },
  { id: 'sci', name: 'Наука', sample: 'Scientist', dark: '#c68cfa', light: '#8237c4' },
  { id: 'cargo', name: 'Снабжение', sample: 'Cargo Technician', dark: '#b88646', light: '#8a5a1c' },
  { id: 'srv', name: 'Сервис', sample: 'Bartender', dark: '#6ca729', light: '#43751a' },
  { id: 'law', name: 'Юристы', sample: 'Internal Affairs Agent', dark: '#ff69d7', light: '#b8128a' },
  { id: 'asst', name: 'Ассистенты', sample: 'Assistant', dark: '#1ecc43', light: '#16782e' },
  { id: 'silicon', name: 'Синтетики', sample: 'AI', dark: '#9e9e9e', light: '#5f5f5f' },
  { id: 'unk', name: 'Прочие', sample: 'Stowaway', dark: '#b0b0b0', light: '#6e6e6e' },
  { id: 'centcom', name: 'ЦК', sample: 'CentCom Official', dark: '#2681a5', light: '#1b6585' },
  { id: 'synd', name: 'Синдикат', sample: 'Syndicate Admiral', dark: '#a85a5c', light: '#7a2e30', legacy: '#8f4a4b' },
  { id: 'inteq', name: 'InteQ', sample: 'InteQ Mercenary', dark: '#e58200', light: '#a65c00' },
  { id: 'tarkon', name: 'Таркон', sample: 'Tarkon Driller', dark: '#f37746', light: '#b8460f' },
  { id: 'pirate', name: 'Пираты', sample: 'Pirate Captain', dark: '#fafafa', light: '#3c3c3c' },
  { id: 'sol', name: 'СолФед', sample: 'SolFed Marine', dark: '#6a6aff', light: '#2a2ad0', legacy: '#3434fd' },
  { id: 'nri', name: 'НРИ', sample: 'NRI Soldier', dark: '#36c9a6', light: '#0d6e5f', legacy: '#ff4444' },
  { id: 'hotel', name: 'Отель', sample: 'Hotel Staff', dark: '#6ca729', light: '#43751a' },
];

export const RADIO_JOB_COLOR_MODES = [
  {
    id: 'department',
    name: 'По отделу',
    tooltip: 'Все профессии отдела одного цвета, с любым альт-названием'
      + ' и наклейкой фракции. Роли вне станции - в цвет своей стороны.',
  },
  {
    id: 'legacy',
    name: 'По профессии (как раньше)',
    tooltip: 'Прежняя раскраска: фракция в названии важнее отдела,'
      + ' у ГП и Представителя NT цвет командования, клоун розовый.',
  },
  {
    id: 'none',
    name: 'Без цвета',
    tooltip: 'Тег должности в цвет канала рации.',
  },
];

export const RADIO_JOB_HEAD_MARKS = [
  { id: 'none', name: 'Нет', tooltip: 'Главы выглядят как все.' },
  { id: 'icon', name: 'Звезда', tooltip: 'Перед тегом главы стоит звёздочка.' },
  {
    id: 'bold',
    name: 'Жирный',
    tooltip: 'Теги рядовых пишутся обычным шрифтом, теги глав - жирным.',
  },
  {
    id: 'command',
    name: 'Цвет командования',
    tooltip: 'Тег главы в цвет командования, а не своего отдела.'
      + ' Работает и в режиме "Без цвета".',
  },
];

export const RADIO_JOB_IDS = RADIO_JOB_PALETTE.map(entry => entry.id);

export const RADIO_JOB_DEFAULTS = {
  radioJobColorMode: 'department',
  radioJobHeadMark: 'icon',
  radioJobColorNames: false,
  radioJobIcons: true,
  radioJobColors: {},
};
