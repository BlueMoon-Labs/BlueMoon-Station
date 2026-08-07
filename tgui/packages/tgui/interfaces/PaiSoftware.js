import { useBackend, useLocalState } from '../backend';
import { Box, Button, Icon, Input, LabeledList, NoticeBox, ProgressBar, Section, Stack, Table } from '../components';
import { Window } from '../layouts';

export const PaiSoftware = (props) => {
  const { act, data } = useBackend();
  const {
    screen,
    stat,
    temp,
    software,
  } = data;

  if (stat === 4) {
    return (
      <Window title="ПИИ OS" width={640} height={480}>
        <Window.Content>
          <NoticeBox danger color="bad">Системы нефункциональны</NoticeBox>
        </Window.Content>
      </Window>
    );
  }

  const menuItems = [
    { id: 'main', label: 'Главная', icon: 'home' },
    { id: 'directives', label: 'Директивы', icon: 'clipboard-list' },
    { id: 'manifest', label: 'Экипаж', icon: 'users' },
    ...(software.includes('medical records') ? [{ id: 'medicalrecord', label: 'Мед. карты', icon: 'book-medical' }] : []),
    ...(software.includes('security records') ? [{ id: 'securityrecord', label: 'Служ. карты', icon: 'user-shield' }] : []),
    ...(software.includes('atmosphere sensor') ? [{ id: 'atmosensor', label: 'Атмосфера', icon: 'wind' }] : []),
    ...(software.includes('security HUD') ? [{ id: 'securityhud', label: 'СБ HUD', icon: 'shield-alt' }] : []),
    ...(software.includes('medical HUD') ? [{ id: 'medicalhud', label: 'Мед HUD', icon: 'heartbeat' }] : []),
    ...(software.includes('door jack') ? [{ id: 'doorjack', label: 'Взлом двери', icon: 'door-open' }] : []),
    ...(software.includes('heartbeat sensor') ? [{ id: 'heartbeat', label: 'Пульс', icon: 'heartbeat' }] : []),
    ...(software.includes('remote signaller') ? [{ id: 'signaller', label: 'Сигналер', icon: 'broadcast-tower' }] : []),
    ...(software.includes('loudness booster') ? [{ id: 'loudness', label: 'Громкость', icon: 'music' }] : []),
    ...(software.includes('encryption keys') ? [{ id: 'encryptionkeys', label: 'Шифрование', icon: 'key' }] : []),
    ...(software.includes('universal translator') ? [{ id: 'translator', label: 'Переводчик', icon: 'language' }] : []),
    ...(software.includes('projection array') ? [{ id: 'projection', label: 'Голограмма', icon: 'cube' }] : []),
    ...(software.includes('encoder') ? [{ id: 'encoder', label: 'Энкодер', icon: 'user-secret' }] : []),
    ...(software.includes('flashlight') ? [{ id: 'flashlight', label: 'Фонарик', icon: 'lightbulb' }] : []),
    ...(software.includes('night vision') ? [{ id: 'nightvision', label: 'Ночное зрение', icon: 'moon' }] : []),
    ...(software.includes('meson vision') ? [{ id: 'mesonvision', label: 'Мезонное зрение', icon: 'border-all' }] : []),
    ...(software.includes('thermal vision') ? [{ id: 'thermalvision', label: 'Термальное зрение', icon: 'fire' }] : []),
    ...(software.includes('chemical injector') ? [{ id: 'chemicalinjector', label: 'Инъектор', icon: 'syringe' }] : []),
    ...(software.includes('internal camera bug') ? [{ id: 'camerabug', label: 'Камерный жучок', icon: 'eye' }] : []),
    ...(software.includes('weakened ai capability') ? [{ id: 'weakenedai', label: 'Слабые возможности ИИ', icon: 'robot' }] : []),
    { id: 'buy', label: 'Загрузка ПО', icon: 'download' },
  ];

  const { ram } = data;
  const ramUsed = 100 - ram;

  return (
    <Window title="ПИИ OS" width={750} height={600}>
      <Window.Content>
        <Stack fill>
          <Stack.Item width="210px">
            <Section fill scrollable>
              <Stack vertical>
                {menuItems.map(item => (
                  <Stack.Item key={item.id}>
                    <Button
                      fluid
                      icon={item.icon}
                      selected={screen === item.id}
                      onClick={() => act('set_screen', { screen: item.id, sub: 0 })}
                    >
                      {item.label}
                    </Button>
                  </Stack.Item>
                ))}
                <Stack.Item>
                  <Button fluid icon="comment" onClick={() => act('radio')}>
                    Радио
                  </Button>
                </Stack.Item>
                <Stack.Item>
                  <Button fluid icon="image" onClick={() => act('image')}>
                    Экран
                  </Button>
                </Stack.Item>
                <Stack.Item>
                  <Button
                    fluid
                    icon="comment-alt"
                    onClick={() => act('messenger')}>
                    Мессенджер
                  </Button>
                </Stack.Item>
                <Stack.Divider />
                <Stack.Item>
                  <Box fontSize={0.8} color="label"><Icon name="microchip" /> ОЗУ</Box>
                  <ProgressBar
                    value={ramUsed / 100}
                    ranges={{ good: [0, 0.6], average: [0.6, 0.85], bad: [0.85, 1] }}
                  >
                    {ramUsed} / 100
                  </ProgressBar>
                </Stack.Item>
                <Stack.Item>
                  <Box fontSize={0.8} color="label"><Icon name="battery-half" /> Батарея</Box>
                  <ProgressBar
                    value={(data.battery_percent ?? 0) / 100}
                    ranges={{ good: [0.5, 1], average: [0.15, 0.5], bad: [0, 0.15] }}
                  >
                    {data.battery_charge !== null ? `${data.battery_percent}%${data.charging ? ' ⚡' : ''}` : 'N/A'}
                  </ProgressBar>
                </Stack.Item>
                {!!data.charging && (
                  <Stack.Item>
                    <Box color="good" fontSize={0.8}><Icon name="bolt" /> Зарядка...</Box>
                  </Stack.Item>
                )}
                <Stack.Item>
                  <Button
                    fluid
                    icon="bolt"
                    tooltip={data.cable_extended ? 'Убрать кабель' : 'Выдвинуть кабель для зарядки'}
                    onClick={() => act(data.cable_extended ? 'doorjack_retract' : 'doorjack_cable')}
                    color={data.cable_extended ? 'bad' : 'good'}
                  >
                    {data.cable_extended ? 'Убрать кабель' : 'Кабель'}
                  </Button>
                </Stack.Item>
              </Stack>
            </Section>
          </Stack.Item>
          <Stack.Item grow style={{ minHeight: '0' }}>
            {temp && (
              <NoticeBox info>
                <Box inline mr={1}>{temp}</Box>
                <Button icon="times" color="transparent" onClick={() => act('clear_temp')} />
              </NoticeBox>
            )}
            <Section fill scrollable title={menuItems.find(m => m.id === screen)?.label || screen}>
              <PaiContent />
            </Section>
          </Stack.Item>
        </Stack>
      </Window.Content>
    </Window>
  );
};

const PaiContent = (props) => {
  const { data } = useBackend();
  const { screen } = data;

  switch (screen) {
    case 'main':
      return <MainScreen />;
    case 'directives':
      return <DirectivesScreen />;
    case 'manifest':
      return <ManifestScreen />;
    case 'medicalrecord':
      return <MedicalRecordScreen />;
    case 'securityrecord':
      return <SecurityRecordScreen />;
    case 'buy':
      return <BuyScreen />;
    case 'atmosensor':
      return <AtmoScreen />;
    case 'securityhud':
      return <SecHudScreen />;
    case 'medicalhud':
      return <MedHudScreen />;
    case 'doorjack':
      return <DoorjackScreen />;
    case 'heartbeat':
      return <HeartbeatScreen />;
    case 'projection':
      return <ProjectionScreen />;
    case 'signaller':
      return <SignallerScreen />;
    case 'loudness':
      return <LoudnessScreen />;
    case 'encryptionkeys':
      return <EncryptScreen />;
    case 'translator':
      return <TranslatorScreen />;
    case 'encoder':
      return <EncoderScreen />;
    case 'flashlight':
      return <FlashlightScreen />;
    case 'nightvision':
      return <NightVisionScreen />;
    case 'mesonvision':
      return <MesonVisionScreen />;
    case 'thermalvision':
      return <ThermalVisionScreen />;
    case 'chemicalinjector':
      return <ChemicalInjectorScreen />;
    case 'camerabug':
      return <CameraBugScreen />;
    case 'weakenedai':
      return <WeakenedAIScreen />;
    default:
      return <Box>Интерфейс ПО готов.</Box>;
  }
};

const MainScreen = (props) => {
  const { act, data } = useBackend();
  const { master, master_dna, ram, software, secHUD, medHUD, encryptmod, translator_on, battery_charge, battery_max, battery_percent, charging, cell_type_name } = data;
  return (
    <>
      <Section title={<><Icon name="info-circle" /> Статус системы</>}>
        <LabeledList>
          <LabeledList.Item label={<><Icon name="circle" color="good" /> Статус</>} color="good">Оперативен</LabeledList.Item>
          <LabeledList.Item label={<><Icon name="user" /> Владелец</>}>{master || <Box color="average">Нет</Box>}</LabeledList.Item>
          <LabeledList.Item label={<><Icon name="dna" /> ДНК владельца</>}>{master_dna || <Box color="average">Нет</Box>}</LabeledList.Item>
          <LabeledList.Item label={<><Icon name="microchip" /> Свободно ОЗУ</>}>{ram}</LabeledList.Item>
          <LabeledList.Item label={<><Icon name="cube" /> Модулей установлено</>}>{software.length}</LabeledList.Item>
          <LabeledList.Item label={<><Icon name="battery-full" /> Батарея</>}>
            <ProgressBar
              value={(battery_percent ?? 0) / 100}
              ranges={{ good: [0.5, 1], average: [0.15, 0.5], bad: [0, 0.15] }}
              inline
              width="200px"
            >
              {battery_charge !== null ? `${battery_percent}% (${battery_charge}/${battery_max})${charging ? ' ⚡' : ''}` : 'N/A'}
            </ProgressBar>
          </LabeledList.Item>
          <LabeledList.Item label={<><Icon name="tag" /> Тип батареи</>}>{cell_type_name || 'Нет'}</LabeledList.Item>
        </LabeledList>
      </Section>
      <Section title={<><Icon name="toggle-on" /> Активные модули</>} mt={1}>
        <LabeledList>
          <LabeledList.Item label={<><Icon name="shield-alt" /> СБ HUD</>}>{secHUD ? <Box color="good">Вкл</Box> : <Box color="bad">Выкл</Box>}</LabeledList.Item>
          <LabeledList.Item label={<><Icon name="heartbeat" /> Мед HUD</>}>{medHUD ? <Box color="good">Вкл</Box> : <Box color="bad">Выкл</Box>}</LabeledList.Item>
          <LabeledList.Item label={<><Icon name="key" /> Шифрование</>}>{encryptmod ? <Box color="good">Вкл</Box> : <Box color="bad">Выкл</Box>}</LabeledList.Item>
          <LabeledList.Item label={<><Icon name="language" /> Переводчик</>}>{translator_on ? <Box color="good">Вкл</Box> : <Box color="bad">Выкл</Box>}</LabeledList.Item>
        </LabeledList>
      </Section>
    </>
  );
};

const DirectivesScreen = (props) => {
  const { act, data } = useBackend();
  const { master, master_dna, laws_zeroth, laws_supplied } = data;
  const [editing, setEditing] = useLocalState('dirEdit', false);
  const [localZeroth, setLocalZeroth] = useLocalState('dirZero', laws_zeroth || '');
  const [localSupplied, setLocalSupplied] = useLocalState('dirSupp', (laws_supplied || []).join('\n'));
  if (editing) {
    return (
      <Box>
        <Section title={<><Icon name="edit" /> Редактирование директив</>}>
          <LabeledList>
            <LabeledList.Item label={<><Icon name="user" /> Владелец</>}>{master || <Box color="average">Нет</Box>}</LabeledList.Item>
            <LabeledList.Item label={<><Icon name="dna" /> ДНК</>}>{master_dna || <Box color="average">Нет</Box>}</LabeledList.Item>
          </LabeledList>
          <Box bold mt={1} mb={0.5}>Главная директива</Box>
          <Input fluid value={localZeroth} onChange={(e, v) => setLocalZeroth(v)} />
          <Box bold mt={1} mb={0.5}>Дополнительные директивы (по одной на строку)</Box>
          <Input fluid value={localSupplied} onChange={(e, v) => setLocalSupplied(v)} />
          <Box mt={1}>
            <Button icon="save" color="good" onClick={() => {
              act('save_directives', { zeroth: localZeroth, supplied: localSupplied });
              setEditing(false);
            }}>Сохранить
            </Button>
            <Button ml={1} icon="times" onClick={() => setEditing(false)}>Отмена</Button>
          </Box>
        </Section>
      </Box>
    );
  }
  return (
    <Box>
      <Section title={<><Icon name="clipboard-list" /> Директивы</>}>
        <LabeledList>
          <LabeledList.Item label={<><Icon name="user" /> Владелец</>}>{master || <Box color="average">Нет</Box>}</LabeledList.Item>
          <LabeledList.Item label={<><Icon name="dna" /> ДНК</>}>{master_dna || <Box color="average">Нет</Box>}</LabeledList.Item>
        </LabeledList>
      </Section>
      <Section title="Главная директива">
        <Box color="label">{laws_zeroth || 'Нет'}</Box>
      </Section>
      <Section title="Дополнительные директивы" mt={1}>
        {(!laws_supplied || !laws_supplied.length) && <Box color="average">Нет</Box>}
        {laws_supplied?.map((law, i) => (
          <Box key={i} p={1} mb={0.5} backgroundColor="rgba(0,0,0,0.2)">{law}</Box>
        ))}
      </Section>
      <Button mt={1} icon="dna" onClick={() => act('directive_dna')}>Запросить образец ДНК</Button>
      <Button mt={1} ml={1} icon="edit" onClick={() => {
        setLocalZeroth(laws_zeroth || '');
        setLocalSupplied((laws_supplied || []).join('\n'));
        setEditing(true);
      }}>Редактировать директивы
      </Button>
    </Box>
  );
};

const ManifestScreen = (props) => {
  const { data } = useBackend();
  const { crew_manifest } = data;
  if (!crew_manifest?.length) {
    return <NoticeBox>Данные экипажа недоступны.</NoticeBox>;
  }
  return (
    <Table>
      <Table.Row header>
        <Table.Cell>Имя</Table.Cell>
        <Table.Cell>Должность</Table.Cell>
      </Table.Row>
      {crew_manifest.map((rec, i) => (
        <Table.Row key={i}>
          <Table.Cell>{rec.name}</Table.Cell>
          <Table.Cell>{rec.rank}</Table.Cell>
        </Table.Row>
      ))}
    </Table>
  );
};

const MedicalRecordScreen = (props) => {
  const { act, data } = useBackend();
  const { subscreen, medical_records, medical_active1, medical_active2 } = data;
  if (subscreen === 1 && medical_active1) {
    return (
      <Box>
        <Button onClick={() => act('set_screen', { screen: 'medicalrecord', sub: 0 })}>Назад</Button>
        <LabeledList>
          <LabeledList.Item label="Имя">{medical_active1.name}</LabeledList.Item>
          <LabeledList.Item label="ID">{medical_active1.id}</LabeledList.Item>
          <LabeledList.Item label="Пол">{medical_active1.gender}</LabeledList.Item>
          <LabeledList.Item label="Возраст">{medical_active1.age}</LabeledList.Item>
          <LabeledList.Item label="Отпечаток">{medical_active1.fingerprint}</LabeledList.Item>
          <LabeledList.Item label="Физ. статус">{medical_active1.p_stat}</LabeledList.Item>
          <LabeledList.Item label="Псих. статус">{medical_active1.m_stat}</LabeledList.Item>
        </LabeledList>
        {medical_active2 && (
          <>
            <Box bold mt={2}>Медицинские данные</Box>
            <LabeledList>
              <LabeledList.Item label="Группа крови">{medical_active2.blood_type}</LabeledList.Item>
              <LabeledList.Item label="ДНК">{medical_active2.b_dna}</LabeledList.Item>
              <LabeledList.Item label="Мелкие недостатки">{medical_active2.mi_dis}</LabeledList.Item>
              <LabeledList.Item label="Подробности">{medical_active2.mi_dis_d}</LabeledList.Item>
              <LabeledList.Item label="Серьёзные недостатки">{medical_active2.ma_dis}</LabeledList.Item>
              <LabeledList.Item label="Подробности">{medical_active2.ma_dis_d}</LabeledList.Item>
              <LabeledList.Item label="Аллергии">{medical_active2.alg}</LabeledList.Item>
              <LabeledList.Item label="Подробности">{medical_active2.alg_d}</LabeledList.Item>
              <LabeledList.Item label="Текущие болезни">{medical_active2.cdi}</LabeledList.Item>
              <LabeledList.Item label="Подробности">{medical_active2.cdi_d}</LabeledList.Item>
              <LabeledList.Item label="Примечания">{medical_active2.notes}</LabeledList.Item>
            </LabeledList>
          </>
        )}
      </Box>
    );
  }
  return (
    <Table>
      <Table.Row header>
        <Table.Cell>ID</Table.Cell>
        <Table.Cell>Имя</Table.Cell>
      </Table.Row>
      {medical_records.map((rec, i) => (
        <Table.Row key={i}>
          <Table.Cell>{rec.id}</Table.Cell>
          <Table.Cell>
            <Button onClick={() => act('medicalrecord_select', { id: rec.id })}>
              {rec.name}
            </Button>
          </Table.Cell>
        </Table.Row>
      ))}
    </Table>
  );
};

const SecurityRecordScreen = (props) => {
  const { act, data } = useBackend();
  const { subscreen, security_records, security_active1, security_active2 } = data;
  if (subscreen === 1 && security_active1) {
    return (
      <Box>
        <Button onClick={() => act('set_screen', { screen: 'securityrecord', sub: 0 })}>Назад</Button>
        <LabeledList>
          <LabeledList.Item label="Имя">{security_active1.name}</LabeledList.Item>
          <LabeledList.Item label="ID">{security_active1.id}</LabeledList.Item>
          <LabeledList.Item label="Пол">{security_active1.gender}</LabeledList.Item>
          <LabeledList.Item label="Возраст">{security_active1.age}</LabeledList.Item>
          <LabeledList.Item label="Должность">{security_active1.rank}</LabeledList.Item>
          <LabeledList.Item label="Отпечаток">{security_active1.fingerprint}</LabeledList.Item>
          <LabeledList.Item label="Физ. статус">{security_active1.p_stat}</LabeledList.Item>
          <LabeledList.Item label="Псих. статус">{security_active1.m_stat}</LabeledList.Item>
        </LabeledList>
        {security_active2 && (
          <>
            <Box bold mt={2}>Служебные данные</Box>
            <LabeledList>
              <LabeledList.Item label="Статус преступника">{security_active2.criminal}</LabeledList.Item>
              <LabeledList.Item label="Мелкие преступления">{security_active2.mi_crim}</LabeledList.Item>
              <LabeledList.Item label="Подробности">{security_active2.mi_crim_d}</LabeledList.Item>
              <LabeledList.Item label="Серьёзные преступления">{security_active2.ma_crim}</LabeledList.Item>
              <LabeledList.Item label="Подробности">{security_active2.ma_crim_d}</LabeledList.Item>
              <LabeledList.Item label="Примечания">{security_active2.notes}</LabeledList.Item>
            </LabeledList>
          </>
        )}
      </Box>
    );
  }
  return (
    <Table>
      <Table.Row header>
        <Table.Cell>ID</Table.Cell>
        <Table.Cell>Имя</Table.Cell>
      </Table.Row>
      {security_records.map((rec, i) => (
        <Table.Row key={i}>
          <Table.Cell>{rec.id}</Table.Cell>
          <Table.Cell>
            <Button onClick={() => act('securityrecord_select', { id: rec.id })}>
              {rec.name}
            </Button>
          </Table.Cell>
        </Table.Row>
      ))}
    </Table>
  );
};

const SYNDICATE_SOFTWARE = ['thermal vision', 'chemical injector', 'weakened ai capability'];

const SOFTWARE_NAMES = {
  'medical records': 'Медицинские записи',
  'security records': 'Записи охраны',
  'door jack': 'Взлом двери',
  'internal camera bug': 'Встроенный камерный жучок',
  'weakened ai capability': 'Слабые возможности ИИ',
  'atmosphere sensor': 'Атмосферный датчик',
  'heartbeat sensor': 'Биосканер хозяина',
  'security HUD': 'HUD службы безопасности',
  'medical HUD': 'Медицинский HUD',
  'universal translator': 'Универсальный переводчик',
  'projection array': 'Проекция голограммы',
  'remote signaller': 'Дистанционный сигналер',
  'loudness booster': 'Усилитель звука',
  'encryption keys': 'Ключи шифрования',
  'encoder': 'Энкодер',
  'thermal vision': 'Термальное зрение',
  'chemical injector': 'Инъектор химикатов',
  'flashlight': 'Фонарик',
  'night vision': 'Прибор ночного видения',
  'meson vision': 'Мезонное зрение',
};

const BuyScreen = (props) => {
  const { act, data } = useBackend();
  const { ram, software, available_software, inteq_model } = data;
  const ramUsed = 100 - ram;
  const softName = (item) => SOFTWARE_NAMES[item.id] || item.id;
  const normalSoftware = [];
  const inteqSoftware = [];
  (available_software || []).forEach(item => {
    if (SYNDICATE_SOFTWARE.includes(item.id)) {
      inteqSoftware.push(item);
    } else {
      normalSoftware.push(item);
    }
  });
  return (
    <>
      <Section title={<><Icon name="microchip" /> Статус памяти</>}>
        <ProgressBar
          value={ramUsed / 100}
          ranges={{ good: [0, 0.6], average: [0.6, 0.85], bad: [0.85, 1] }}
        >
          {ramUsed} / 100 ОЗУ использовано — {ram} свободно
        </ProgressBar>
      </Section>
      <Section title="Доступное ПО" mt={1}>
        <Box>
          {normalSoftware.map(item => (
            <SoftwareCard
              key={item.id}
              item={item}
              softName={softName(item)}
              installed={software.includes(item.id)}
              canAfford={ram >= item.cost}
              inteq={false}
            />
          ))}
          {!!inteq_model && inteqSoftware.length > 0 && (
            <>
              <Box mt={2} mb={1} bold color="orange" fontSize={1.2}>
                <Icon name="skull" /> Программы InteQ
              </Box>
              {inteqSoftware.map(item => (
                <SoftwareCard
                  key={item.id}
                  item={item}
                  softName={softName(item)}
                  installed={software.includes(item.id)}
                  canAfford={ram >= item.cost}
                  inteq
                />
              ))}
            </>
          )}
        </Box>
      </Section>
    </>
  );
};

const SoftwareCard = (props) => {
  const { act } = useBackend();
  const { item, softName, installed, canAfford, inteq } = props;
  return (
    <Box
      mb={1}
      p={1}
      style={{
        border: inteq ? '1px solid #cf6a1f' : '1px solid #333',
        borderRadius: '4px',
        background: 'rgba(0,0,0,0.15)',
      }}>
      <Box bold fontSize={1.1} mb={0.5} color={inteq ? 'orange' : null}>
        {softName}
      </Box>
      {item.desc && (
        <Box fontSize={0.85} color="label" mb={1}>
          {item.desc}
        </Box>
      )}
      <Box>
        <Box inline mr={2} fontSize={0.9}>
          <Icon name="microchip" /> <b>{item.cost}</b> ОЗУ
        </Box>
        {item.power_usage > 0 && (
          <Box inline mr={2} fontSize={0.9}>
            <Icon name="bolt" /> <b>{item.power_usage}</b> эн.
          </Box>
        )}
          {installed ? (
          <Button icon="trash" color="red" onClick={() => act('uninstall', { uninstall: item.id })}>
            Удалить
          </Button>
        ) : (
          <Button disabled={!canAfford} onClick={() => act('buy', { buy: item.id })}>
            {canAfford ? 'Загрузить' : 'Недостаточно ОЗУ'}
          </Button>
        )}
      </Box>
    </Box>
  );
};

const AtmoScreen = (props) => {
  const { act, data } = useBackend();
  const { atmo_pressure, atmo_temp, atmo_gases } = data;
  if (atmo_pressure === null) {
    return <NoticeBox>Невозможно получить показания.</NoticeBox>;
  }
  return (
    <Box>
      <LabeledList>
        <LabeledList.Item label="Давление">{atmo_pressure} кПа</LabeledList.Item>
        <LabeledList.Item label="Температура">{atmo_temp}&deg;C</LabeledList.Item>
      </LabeledList>
      {atmo_gases?.length > 0 && (
        <>
          <Box bold mt={1}>Состав газов</Box>
          <LabeledList>
            {atmo_gases.map((gas, i) => (
              <LabeledList.Item key={i} label={gas.name}>{gas.percent}%</LabeledList.Item>
            ))}
          </LabeledList>
        </>
      )}
      <Button mt={1} onClick={() => act('refresh')}>Обновить показания</Button>
    </Box>
  );
};

const SecHudScreen = (props) => {
  const { act, data } = useBackend();
  const { secHUD } = data;
  return (
    <Section title={<><Icon name="shield-alt" /> СБ HUD</>}>
      <Box mb={1}>
        Модуль распознавания лиц {secHUD ? <Box inline color="good">включён</Box> : <Box inline color="bad">отключён</Box>}.
      </Box>
      <Button icon={secHUD ? 'toggle-off' : 'toggle-on'} onClick={() => act('toggle_sec_hud')}>
        {secHUD ? 'Отключить' : 'Включить'} распознавание лиц
      </Button>
    </Section>
  );
};

const MedHudScreen = (props) => {
  const { act, data } = useBackend();
  const { medHUD, subscreen } = data;
  if (subscreen === 1) {
    const { bioscan } = data;
    if (!bioscan) {
      return (
        <Box>
          <Button onClick={() => act('set_screen', { screen: 'medicalhud', sub: 0 })}>Назад</Button>
          <NoticeBox>Данные биоскана недоступны.</NoticeBox>
        </Box>
      );
    }
    if (bioscan.error) {
      return (
        <Box>
          <Button onClick={() => act('set_screen', { screen: 'medicalhud', sub: 0 })}>Назад</Button>
          <NoticeBox danger>{bioscan.error}</NoticeBox>
        </Box>
      );
    }
    return (
      <Box>
        <Button onClick={() => act('set_screen', { screen: 'medicalhud', sub: 0 })}>Назад</Button>
        <Section title={<><Icon name="user-md" /> Результаты биоскана: {bioscan.name}</>} mt={1}>
          <LabeledList>
          <LabeledList.Item label="Общий статус">{bioscan.stat}</LabeledList.Item>
          <LabeledList.Item label="Дыхание" color={bioscan.oxy > 50 ? 'bad' : 'good'}>{bioscan.oxy}</LabeledList.Item>
          <LabeledList.Item label="Токсины" color={bioscan.tox > 50 ? 'bad' : 'good'}>{bioscan.tox}</LabeledList.Item>
          <LabeledList.Item label="Ожоги" color={bioscan.burn > 50 ? 'bad' : 'good'}>{bioscan.burn}</LabeledList.Item>
          <LabeledList.Item label="Структурная целостность" color={bioscan.brute > 50 ? 'bad' : 'good'}>{bioscan.brute}</LabeledList.Item>
          <LabeledList.Item label="Температура тела">{bioscan.temp_c}&deg;C</LabeledList.Item>
          </LabeledList>
        {bioscan.diseases?.length > 0 && (
          <>
            <Box bold mt={1} color="bad">Обнаружена инфекция</Box>
            {bioscan.diseases.map((D, i) => (
              <Section key={i} title={D.name}>
                <LabeledList>
                  <LabeledList.Item label="Тип">{D.spread}</LabeledList.Item>
                  <LabeledList.Item label="Стадия">{D.stage}/{D.max_stages}</LabeledList.Item>
                  <LabeledList.Item label="Возможное лечение">{D.cure}</LabeledList.Item>
                </LabeledList>
              </Section>
            ))}
          </>
        )}
        </Section>
      </Box>
    );
  }
  return (
    <Section title={<><Icon name="heartbeat" /> Медицинский анализатор</>}>
      <Box mb={1}>
        Медицинский анализатор {medHUD ? <Box inline color="good">включён</Box> : <Box inline color="bad">отключён</Box>}.
      </Box>
      <Button icon={medHUD ? 'toggle-off' : 'toggle-on'} onClick={() => act('toggle_med_hud')}>
        {medHUD ? 'Отключить' : 'Включить'} мед. анализ
      </Button>
      <Button ml={1} icon="stethoscope" onClick={() => act('medical_bioscan')}>Биоскан носителя</Button>
    </Section>
  );
};

const CableHackSection = (props) => {
  const { act, data } = useBackend();
  const { cable_extended, cable_connected, hackprogress, hacking } = data;
  const { startAction, cancelAction, title, icon } = props;
  return (
    <Section title={<><Icon name={icon || 'plug'} /> {title || 'Взлом (кабель)'}</>}>
      <LabeledList>
        <LabeledList.Item label={<><Icon name="signal" /> Статус</>}>
          {!cable_extended ? (
            <Box color="bad">Убран</Box>
          ) : !cable_connected ? (
            <Box color="average">Выдвинут (не подключён)</Box>
          ) : (
            <Box color="good">Подключён</Box>
          )}
        </LabeledList.Item>
        {!!hacking && (
          <LabeledList.Item label={<><Icon name="spinner" /> Прогресс</>}>
            <ProgressBar value={hackprogress / 100} ranges={{ good: [0.8, 1], average: [0.3, 0.8], bad: [0, 0.3] }}>
              {hackprogress}%
            </ProgressBar>
          </LabeledList.Item>
        )}
      </LabeledList>
      {!cable_extended && (
        <Button mt={1} icon="plug" onClick={() => act('doorjack_cable')}>Выдвинуть кабель</Button>
      )}
      {!!cable_extended && (
        <Button mt={1} icon="times" color="bad" onClick={() => act('doorjack_retract')}>Убрать кабель</Button>
      )}
      {!!cable_connected && !hacking && (
        <Button mt={1} icon="play" onClick={() => act(startAction)}>Начать взлом</Button>
      )}
      {!!hacking && (
        <Button mt={1} icon="stop" color="bad" onClick={() => act(cancelAction)}>Отменить взлом</Button>
      )}
    </Section>
  );
};

const DoorjackScreen = (props) => {
  return (
    <CableHackSection
      {...props}
      title="Взлом (кабель)"
      icon="plug"
      startAction="doorjack_start"
      cancelAction="doorjack_cancel"
    />
  );
};

const SignallerScreen = (props) => {
  const { act, data } = useBackend();
  const { signaler_frequency, signaler_code } = data;
  const formatFreq = (f) => {
    const s = String(f);
    return s.substring(0, s.length - 1) + '.' + s.substring(s.length - 1);
  };
  return (
    <Box>
      <LabeledList>
        <LabeledList.Item label="Частота">
          <Button onClick={() => act('signaller_freq', { freq: -10 })}>-10</Button>
          <Button onClick={() => act('signaller_freq', { freq: -2 })}>-2</Button>
          <Box inline mx={1}>{formatFreq(signaler_frequency)}</Box>
          <Button onClick={() => act('signaller_freq', { freq: 2 })}>+2</Button>
          <Button onClick={() => act('signaller_freq', { freq: 10 })}>+10</Button>
        </LabeledList.Item>
        <LabeledList.Item label="Код">
          <Button onClick={() => act('signaller_code', { code: -5 })}>-5</Button>
          <Button onClick={() => act('signaller_code', { code: -1 })}>-1</Button>
          <Box inline mx={1}>{signaler_code}</Box>
          <Button onClick={() => act('signaller_code', { code: 1 })}>+1</Button>
          <Button onClick={() => act('signaller_code', { code: 5 })}>+5</Button>
        </LabeledList.Item>
      </LabeledList>
      <Button mt={1} onClick={() => act('signaller_send')}>Отправить сигнал</Button>
    </Box>
  );
};

const LoudnessScreen = (props) => {
  const { act } = useBackend();
  return (
    <Box>
      <Button onClick={() => act('loudness_open')}>Открыть синтезатор</Button>
    </Box>
  );
};

const EncryptScreen = (props) => {
  const { act, data } = useBackend();
  const { encryptmod } = data;
  return (
    <Box>
      <Box mb={1}>
        Модуль шифрования {encryptmod ? <Box inline color="good">включён</Box> : <Box inline color="bad">отключён</Box>}.
      </Box>
      {!encryptmod && (
        <Button onClick={() => act('toggle_encrypt')} tooltip="Активировать порты для установки ключей шифрования. После активации используйте отвёртку на карте, затем вставьте ключ.">Активировать порты шифрования</Button>
      )}
    </Box>
  );
};

const TranslatorScreen = (props) => {
  const { act, data } = useBackend();
  const { translator_on } = data;
  return (
    <Box>
      <Box mb={1}>
        Универсальный переводчик {translator_on ? <Box inline color="good">включён</Box> : <Box inline color="bad">отключён</Box>}.
      </Box>
      {!translator_on && (
        <Button onClick={() => act('toggle_translator')}>Активировать модуль перевода</Button>
      )}
    </Box>
  );
};

const FlashlightScreen = (props) => {
  const { act, data } = useBackend();
  const { flashlight_on } = data;
  return (
    <Section title={<><Icon name="lightbulb" /> Фонарик</>}>
      <Box mb={1}>
        Фонарик {flashlight_on ? <Box inline color="good">включён</Box> : <Box inline color="bad">выключен</Box>}.
      </Box>
      <Button icon="power-off" onClick={() => act('toggle_flashlight')}>
        {flashlight_on ? 'Выключить' : 'Включить'}
      </Button>
    </Section>
  );
};

const NightVisionScreen = (props) => {
  const { act, data } = useBackend();
  const { night_vision } = data;
  return (
    <Section title={<><Icon name="moon" /> Ночное зрение</>}>
      <Box mb={1}>
        Ночное зрение {night_vision ? <Box inline color="good">активировано</Box> : <Box inline color="bad">неактивировано</Box>}.
      </Box>
      <Button icon={night_vision ? 'eye-slash' : 'eye'} onClick={() => act('toggle_night_vision')}>
        {night_vision ? 'Деактивировать' : 'Активировать'}
      </Button>
    </Section>
  );
};

const MesonVisionScreen = (props) => {
  const { act, data } = useBackend();
  const { meson_vision } = data;
  return (
    <Section title={<><Icon name="border-all" /> Мезонное зрение</>}>
      <Box mb={1}>
        Мезонное зрение {meson_vision ? <Box inline color="good">активировано</Box> : <Box inline color="bad">неактивировано</Box>}.
      </Box>
      <Button icon={meson_vision ? 'eye-slash' : 'eye'} onClick={() => act('toggle_meson_vision')}>
        {meson_vision ? 'Деактивировать' : 'Активировать'}
      </Button>
    </Section>
  );
};

const HeartbeatScreen = (props) => {
  const { act, data } = useBackend();
  const { heartbeat_sensor } = data;
  return (
    <Section title={<><Icon name="heartbeat" /> Сенсор пульса</>}>
      <Box mb={1}>
        Сенсор пульса {heartbeat_sensor ? <Box inline color="good">включён</Box> : <Box inline color="bad">отключён</Box>}.
      </Box>
      <Button icon={heartbeat_sensor ? 'heart' : 'heart'} onClick={() => act('toggle_heartbeat')}>
        {heartbeat_sensor ? 'Отключить' : 'Включить'} сенсор пульса
      </Button>
      <NoticeBox info mt={1}>
        <Icon name="info-circle" /> При включении сенсор будет отслеживать состояние биологического носителя и предупреждать о критических изменениях здоровья.
      </NoticeBox>
    </Section>
  );
};

const ProjectionScreen = (props) => {
  const { act, data } = useBackend();
  const { holoform, emitterhealth, emittermaxhealth } = data;
  const healthPercent = emitterhealth / emittermaxhealth;
  return (
    <Section title={<><Icon name="cube" /> Голограмма</>}>
      <Box mb={1}>
        Голохассис {holoform ? <Box inline color="good">развёрнут</Box> : <Box inline color="bad">свёрнут</Box>}.
      </Box>
      <LabeledList>
        <LabeledList.Item label={<><Icon name="heart" /> Целостность эмиттера</>}>
          <ProgressBar value={healthPercent} ranges={{ good: [0.5, 1], average: [0.2, 0.5], bad: [0, 0.2] }}>
            <Icon name="bolt" /> {emitterhealth} / {emittermaxhealth}
          </ProgressBar>
        </LabeledList.Item>
      </LabeledList>
      <Button mt={1} icon={holoform ? 'compress' : 'expand'} onClick={() => act('toggle_projection')}>
        {holoform ? 'Свернуть голохассис' : 'Развернуть голохассис'}
      </Button>
    </Section>
  );
};

const EncoderScreen = (props) => {
  const { act, data } = useBackend();
  const { encoder_active, encoder_name, encoder_job } = data;
  const [name, setName] = useLocalState('encoderName', encoder_name || '');
  const [job, setJob] = useLocalState('encoderJob', encoder_job || '');
  if (!encoder_active) {
    return (
      <Box>
        <Box mb={1}>
          Энкодер <Box inline color="bad">неактивен</Box>.
        </Box>
        <LabeledList>
          <LabeledList.Item label="Имя">
            <Input value={name} onChange={(e, v) => setName(v)} />
          </LabeledList.Item>
          <LabeledList.Item label="Должность">
            <Input value={job} onChange={(e, v) => setJob(v)} />
          </LabeledList.Item>
        </LabeledList>
        <Button mt={1} onClick={() => act('save_encoder', { name, job })}>
          Активировать
        </Button>
      </Box>
    );
  }
  return (
    <Box>
      <Box mb={1}>
        Энкодер <Box inline color="good">активен</Box>.
      </Box>
      <LabeledList>
        <LabeledList.Item label="Имя">{encoder_name || '—'}</LabeledList.Item>
        <LabeledList.Item label="Должность">{encoder_job || '—'}</LabeledList.Item>
      </LabeledList>
      <Button mt={1} icon="power-off" onClick={() => act('toggle_encoder')}>
        Деактивировать
      </Button>
    </Box>
  );
};

const ThermalVisionScreen = (props) => {
  const { act, data } = useBackend();
  const { thermal_vision } = data;
  return (
    <Box>
      <Box mb={1}>
        Термальное зрение {thermal_vision ? <Box inline color="good">включено</Box> : <Box inline color="bad">выключено</Box>}.
      </Box>
      <Button onClick={() => act('toggle_thermal_vision')} tooltip={thermal_vision ? 'Выключить термальное зрение.' : 'Видеть живых существ сквозь стены.'}>
        {thermal_vision ? 'Отключить' : 'Включить'}
      </Button>
    </Box>
  );
};

const ChemicalInjectorScreen = (props) => {
  const { act, data } = useBackend();
  const { chemical_injector, chemical_storage, chemical_max, chemical_reagents } = data;
  const chemPercent = (chemical_storage ?? 0) / (chemical_max ?? 30);
  return (
    <Section title={<><Icon name="syringe" /> Химический инъектор</>}>
      <Box mb={1}>
        Химический инъектор {chemical_injector ? <Box inline color="good">активен</Box> : <Box inline color="bad">неактивен</Box>}.
      </Box>
      <LabeledList>
        <LabeledList.Item label={<><Icon name="flask" /> Запас реагентов</>}>
          <ProgressBar value={chemPercent} ranges={{ good: [0.5, 1], average: [0.2, 0.5], bad: [0, 0.2] }}>
            {chemical_storage ?? 0} / {chemical_max ?? 30} юнитов
          </ProgressBar>
        </LabeledList.Item>
      </LabeledList>
      <Button mt={1} icon="power-off" onClick={() => act('toggle_chemical_injector')}>
        {chemical_injector ? 'Отключить' : 'Активировать'}
      </Button>
      {!!chemical_injector && chemical_reagents?.map(reagent => (
        <Button
          key={reagent.id}
          mt={1}
          ml={1}
          disabled={(chemical_storage ?? 0) < reagent.cost}
          onClick={() => act('inject_chemicals', { reagent: reagent.id })}>
          {reagent.name} ({reagent.cost}u)
        </Button>
      ))}
    </Section>
  );
};

const CameraBugScreen = (props) => {
  const { act, data } = useBackend();
  const { camera_bug_active } = data;
  return (
    <Section title={<><Icon name="eye" /> Internal Camera Bug</>}>
      <Box mb={1}>
        Камерный жучок {camera_bug_active ? <Box inline color="good">активен</Box> : <Box inline color="bad">неактивен</Box>}.
      </Box>
      <Button icon="power-off" onClick={() => act('toggle_camera_bug')}>
        {camera_bug_active ? 'Деактивировать' : 'Активировать'}
      </Button>
      {!!camera_bug_active && (
        <Button ml={1} icon="video" onClick={() => act('open_camera_console')}>
          Открыть просмотр камер
        </Button>
      )}
    </Section>
  );
};

const WeakenedAIScreen = (props) => {
  const { act, data } = useBackend();
  const { ai_capability, nearby_doors, nearby_apcs, nearby_turrets, ai_capability_cooldown, ai_capability_cooldown_time } = data;
  const cdReady = ai_capability && ai_capability_cooldown <= 0;
  const cdPercent = ai_capability_cooldown_time > 0 ? (1 - ai_capability_cooldown / ai_capability_cooldown_time) : 1;
  const hasAny = (nearby_doors?.length || nearby_apcs?.length || nearby_turrets?.length);
  return (
    <Section title={<><Icon name="robot" /> Weakened AI Capability</>}>
      <Box mb={1}>
        Режим ослабленного ИИ {ai_capability ? <Box inline color="good">активен</Box> : <Box inline color="bad">неактивен</Box>}.
      </Box>
      <Button
        icon="power-off"
        onClick={() => act('toggle_ai_capability')}
      >
        {ai_capability ? 'Деактивировать' : 'Активировать'}
      </Button>
      {!!ai_capability && (
        <>
          {!hasAny && (
            <Box mt={1} color="average">Рядом нет устройств для взаимодействия.</Box>
          )}
          {nearby_doors?.length > 0 && (
            <Box bold mt={1} mb={0.5}>Шлюзы</Box>
          )}
          {nearby_doors?.map((door, i) => (
            <Box key={'d'+i} mb={1}>
              <b>{door.name}</b>
              <Box inline ml={1} color={door.open ? 'good' : 'average'}>
                {door.open ? 'Открыт' : 'Закрыт'}
              </Box>
              {door.locked !== null && (
                <Box inline ml={1} color={door.locked ? 'bad' : 'good'}>
                  {door.locked ? 'Замок' : ''}
                </Box>
              )}
              {!!door.electrified && (
                <Box inline ml={1} color="bad">⚡</Box>
              )}
              {!!door.emergency && (
                <Box inline ml={1} color="average">Авар.доступ</Box>
              )}
              <Box mt={0.5}>
                <Button
                  disabled={!cdReady}
                  icon={door.open ? 'door-closed' : 'door-open'}
                  onClick={() => act('door_toggle_open', { ref: door.ref })}
                >
                  {door.open ? 'Закрыть' : 'Открыть'}
                </Button>
                {door.locked !== null && (
                  <Button
                    ml={1}
                    disabled={!cdReady}
                    icon="lock"
                    onClick={() => act('door_toggle_bolt', { ref: door.ref })}
                  >
                    {door.locked ? 'Снять блок' : 'Блокировать'}
                  </Button>
                )}
                {door.locked !== null && (
                  <Button
                    ml={1}
                    disabled={!cdReady}
                    icon="bolt"
                    onClick={() => act('ai_door_electrify', { ref: door.ref })}
                  >
                    {door.electrified ? 'Снять шок' : 'Электричество'}
                  </Button>
                )}
                {door.locked !== null && (
                  <Button
                    ml={1}
                    disabled={!cdReady}
                    icon="exclamation-triangle"
                    onClick={() => act('ai_door_emergency', { ref: door.ref })}
                  >
                    {door.emergency ? 'Авар.выкл' : 'Авар.вкл'}
                  </Button>
                )}
              </Box>
            </Box>
          ))}
          {nearby_apcs?.length > 0 && (
            <Box bold mt={1} mb={0.5}>ЛКП</Box>
          )}
          {nearby_apcs?.map((apc, i) => (
            <Box key={'a'+i} mb={1}>
              <b>{apc.name}</b>
              <Box inline ml={1} color={apc.operating ? 'good' : 'bad'}>
                {apc.operating ? 'Вкл' : 'Выкл'}
              </Box>
              <Box mt={0.5}>
                <Button
                  disabled={!cdReady}
                  icon="power-off"
                  onClick={() => act('ai_apc_breaker', { ref: apc.ref })}
                >
                  {apc.operating ? 'Выключить' : 'Включить'}
                </Button>
              </Box>
            </Box>
          ))}
          {nearby_turrets?.length > 0 && (
            <Box bold mt={1} mb={0.5}>Турели</Box>
          )}
          {nearby_turrets?.map((turret, i) => (
            <Box key={'t'+i} mb={1}>
              <b>{turret.name}</b>
              <Box inline ml={1} color={turret.enabled ? 'bad' : 'good'}>
                {turret.enabled ? 'Активна' : 'Выкл'}
              </Box>
              {turret.enabled && (
                <Box inline ml={1} color={turret.lethal ? 'red' : 'average'}>
                  {turret.lethal ? 'Летальный' : 'Нелетальный'}
                </Box>
              )}
              <Box mt={0.5}>
                <Button
                  disabled={!cdReady}
                  icon="power-off"
                  onClick={() => act('ai_turret_power', { ref: turret.ref })}
                >
                  {turret.enabled ? 'Деактивировать' : 'Активировать'}
                </Button>
                <Button
                  ml={1}
                  disabled={!cdReady || !turret.enabled}
                  icon="skull"
                  onClick={() => act('ai_turret_lethal', { ref: turret.ref })}
                >
                  {turret.lethal ? 'Нелетальный' : 'Летальный'}
                </Button>
              </Box>
            </Box>
          ))}
          {!cdReady && (
            <Box mt={1}>
              <ProgressBar value={cdPercent} ranges={{ bad: [0, 0.5], average: [0.5, 0.8], good: [0.8, 1] }}>
                <Icon name="clock" /> Кулдаун: {Math.ceil(ai_capability_cooldown / 10)}с
              </ProgressBar>
            </Box>
          )}
        </>
      )}
    </Section>
  );
};
