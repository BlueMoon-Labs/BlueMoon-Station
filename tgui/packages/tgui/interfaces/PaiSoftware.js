import { useBackend } from '../backend';
import { Box, Button, Icon, LabeledList, NoticeBox, ProgressBar, Section, Stack, Table } from '../components';
import { Window } from '../layouts';

export const PaiSoftware = (props, context) => {
  const { act, data } = useBackend(context);
  const {
    screen,
    stat,
    temp,
    software,
    messenger_unread,
  } = data;

  if (stat === 4) {
    return (
      <Window title="pAI OS" width={640} height={480}>
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
    ...(software.includes('camera jack') ? [{ id: 'camerajack', label: 'Взлом камеры', icon: 'video' }] : []),
    ...(software.includes('heartbeat sensor') ? [{ id: 'heartbeat', label: 'Пульс', icon: 'heartbeat' }] : []),
    ...(software.includes('remote signaller') ? [{ id: 'signaller', label: 'Сигналер', icon: 'broadcast-tower' }] : []),
    ...(software.includes('loudness booster') ? [{ id: 'loudness', label: 'Громкость', icon: 'music' }] : []),
    ...(software.includes('encryption keys') ? [{ id: 'encryptionkeys', label: 'Шифрование', icon: 'key' }] : []),
    ...(software.includes('universal translator') ? [{ id: 'translator', label: 'Переводчик', icon: 'language' }] : []),
    ...(software.includes('projection array') ? [{ id: 'projection', label: 'Голограмма', icon: 'cube' }] : []),
    ...(software.includes('encoder') ? [{ id: 'encoder', label: 'Энкодер', icon: 'user-secret' }] : []),
    ...(software.includes('thermal vision') ? [{ id: 'thermalvision', label: 'Термальное зрение', icon: 'fire' }] : []),
    ...(software.includes('chemical injector') ? [{ id: 'chemicalinjector', label: 'Инъектор', icon: 'syringe' }] : []),
    { id: 'buy', label: 'Загрузка ПО', icon: 'download' },
  ];

  const { ram } = data;
  const ramUsed = 100 - ram;

  return (
    <Window title="pAI OS" width={750} height={600}>
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
                <Stack.Item>
                  <Button
                    fluid
                    icon="reply"
                    color={messenger_unread > 0 ? 'good' : null}
                    onClick={() => act('quick_reply')}>
                    Быстрый ответ
                    {messenger_unread > 0 && (
                      <Box inline ml={1}>
                        ({messenger_unread})
                      </Box>
                    )}
                  </Button>
                </Stack.Item>
                <Stack.Item mt={1}>
                  <Box fontSize={0.8} color="label">Память</Box>
                  <ProgressBar
                    value={ramUsed}
                    minValue={0}
                    maxValue={100}
                    ranges={{ good: [0, 60], average: [60, 85], bad: [85, 100] }}
                  >
                    {ramUsed} / 100
                  </ProgressBar>
                </Stack.Item>
              </Stack>
            </Section>
          </Stack.Item>
          <Stack.Item grow>
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

const PaiContent = (props, context) => {
  const { data } = useBackend(context);
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
    case 'camerajack':
      return <CameraJackScreen />;
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
    case 'thermalvision':
      return <ThermalVisionScreen />;
    case 'chemicalinjector':
      return <ChemicalInjectorScreen />;
    default:
      return <Box>Интерфейс ПО готов.</Box>;
  }
};

const MainScreen = (props, context) => {
  const { data } = useBackend(context);
  const { master, master_dna, ram, software, secHUD, medHUD, encryptmod, translator_on } = data;
  return (
    <>
      <Section title="Статус системы">
        <LabeledList>
          <LabeledList.Item label="Статус" color="good">Оперативен</LabeledList.Item>
          <LabeledList.Item label="Владелец">{master || 'Нет'}</LabeledList.Item>
          <LabeledList.Item label="ДНК владельца">{master_dna || 'Нет'}</LabeledList.Item>
          <LabeledList.Item label="Свободно ОЗУ">{ram}</LabeledList.Item>
          <LabeledList.Item label="Модулей установлено">{software.length}</LabeledList.Item>
        </LabeledList>
      </Section>
      <Section title="Активные модули" mt={1}>
        <LabeledList>
          <LabeledList.Item label="СБ HUD">{secHUD ? <Box color="good">Вкл</Box> : <Box color="bad">Выкл</Box>}</LabeledList.Item>
          <LabeledList.Item label="Мед HUD">{medHUD ? <Box color="good">Вкл</Box> : <Box color="bad">Выкл</Box>}</LabeledList.Item>
          <LabeledList.Item label="Шифрование">{encryptmod ? <Box color="good">Вкл</Box> : <Box color="bad">Выкл</Box>}</LabeledList.Item>
          <LabeledList.Item label="Переводчик">{translator_on ? <Box color="good">Вкл</Box> : <Box color="bad">Выкл</Box>}</LabeledList.Item>
        </LabeledList>
      </Section>
    </>
  );
};

const DirectivesScreen = (props, context) => {
  const { act, data } = useBackend(context);
  const { master, master_dna, laws_zeroth, laws_supplied } = data;
  return (
    <Box>
      <Box bold mb={1}>Директивы</Box>
      <LabeledList>
        <LabeledList.Item label="Владелец">{master || 'Нет'}</LabeledList.Item>
        <LabeledList.Item label="ДНК">{master_dna || 'Нет'}</LabeledList.Item>
      </LabeledList>
      <Box mt={1}><b>Главная директива:</b></Box>
      <Box>{laws_zeroth || 'Нет'}</Box>
      <Box mt={1}><b>Дополнительные директивы:</b></Box>
      {(!laws_supplied || !laws_supplied.length) && <Box>Нет</Box>}
      {laws_supplied?.map((law, i) => (
        <Box key={i}>&nbsp;&nbsp;{law}</Box>
      ))}
      <Button mt={1} onClick={() => act('directive_dna')}>Запросить образец ДНК</Button>
    </Box>
  );
};

const ManifestScreen = (props, context) => {
  const { data } = useBackend(context);
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

const MedicalRecordScreen = (props, context) => {
  const { act, data } = useBackend(context);
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

const SecurityRecordScreen = (props, context) => {
  const { act, data } = useBackend(context);
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

const BuyScreen = (props, context) => {
  const { act, data } = useBackend(context);
  const { ram, software, available_software } = data;
  const ramUsed = 100 - ram;
  return (
    <>
      <Section title="Статус памяти">
        <ProgressBar
          value={ramUsed}
          minValue={0}
          maxValue={100}
          ranges={{ good: [0, 60], average: [60, 85], bad: [85, 100] }}
        >
          {ramUsed} / 100 ОЗУ использовано — {ram} свободно
        </ProgressBar>
      </Section>
      <Section title="Доступное ПО" mt={1}>
        <Table>
          <Table.Row header>
            <Table.Cell>ПО</Table.Cell>
            <Table.Cell>Стоимость</Table.Cell>
            <Table.Cell>Статус</Table.Cell>
          </Table.Row>
          {Object.keys(available_software).map(key => {
            const cost = available_software[key];
            const installed = software.includes(key);
            const canAfford = ram >= cost;
            return (
              <Table.Row key={key}>
                <Table.Cell>{key}</Table.Cell>
                <Table.Cell>{cost} ОЗУ</Table.Cell>
                <Table.Cell>
                  {installed ? (
                    <Box>
                      <Box color="good" inline mr={1}><Icon name="check" /> Установлено</Box>
                      <Button
                        icon="trash"
                        color="red"
                        onClick={() => act('uninstall', { uninstall: key })}
                      >
                        Удалить
                      </Button>
                    </Box>
                  ) : (
                    <Button
                      disabled={!canAfford}
                      onClick={() => act('buy', { buy: key })}
                    >
                      {canAfford ? 'Загрузить' : 'Недостаточно ОЗУ'}
                    </Button>
                  )}
                </Table.Cell>
              </Table.Row>
            );
          })}
        </Table>
      </Section>
    </>
  );
};

const AtmoScreen = (props, context) => {
  const { act, data } = useBackend(context);
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

const SecHudScreen = (props, context) => {
  const { act, data } = useBackend(context);
  const { secHUD } = data;
  return (
    <Box>
      <Box mb={1}>
        Модуль распознавания лиц {secHUD ? <Box inline color="good">включён</Box> : <Box inline color="bad">отключён</Box>}.
      </Box>
      <Button onClick={() => act('toggle_sec_hud')}>
        {secHUD ? 'Отключить' : 'Включить'} распознавание лиц
      </Button>
    </Box>
  );
};

const MedHudScreen = (props, context) => {
  const { act, data } = useBackend(context);
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
        <Box bold mt={1}>Результаты биоскана: {bioscan.name}</Box>
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
      </Box>
    );
  }
  return (
    <Box>
      <Box mb={1}>
        Медицинский анализатор {medHUD ? <Box inline color="good">включён</Box> : <Box inline color="bad">отключён</Box>}.
      </Box>
      <Button onClick={() => act('toggle_med_hud')}>
        {medHUD ? 'Отключить' : 'Включить'} мед. анализ
      </Button>
      <Button mt={1} onClick={() => act('medical_bioscan')}>Биоскан носителя</Button>
    </Box>
  );
};

const DoorjackScreen = (props, context) => {
  const { act, data } = useBackend(context);
  const { cable_extended, cable_connected, hackprogress, hacking } = data;
  return (
    <Section title="Статус взлома шлюза">
      <LabeledList>
        <LabeledList.Item label="Кабель">
          {!cable_extended ? (
            <Box color="bad">Убран</Box>
          ) : !cable_connected ? (
            <Box color="average">Выдвинут (не подключён)</Box>
          ) : (
            <Box color="good">Подключён</Box>
          )}
        </LabeledList.Item>
        {hacking && (
          <LabeledList.Item label="Прогресс">
            <ProgressBar value={hackprogress} minValue={0} maxValue={100}>
              {hackprogress}%
            </ProgressBar>
          </LabeledList.Item>
        )}
      </LabeledList>
      {!cable_extended && (
        <Button mt={1} onClick={() => act('doorjack_cable')}>Выдвинуть кабель</Button>
      )}
      {cable_connected && !hacking && (
        <Button mt={1} onClick={() => act('doorjack_start')}>Начать взлом шлюза</Button>
      )}
      {hacking && (
        <Button mt={1} color="bad" onClick={() => act('doorjack_cancel')}>Отменить взлом</Button>
      )}
    </Section>
  );
};

const SignallerScreen = (props, context) => {
  const { act, data } = useBackend(context);
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

const LoudnessScreen = (props, context) => {
  const { act } = useBackend(context);
  return (
    <Box>
      <Button onClick={() => act('loudness_open')}>Открыть синтезатор</Button>
    </Box>
  );
};

const EncryptScreen = (props, context) => {
  const { act, data } = useBackend(context);
  const { encryptmod } = data;
  return (
    <Box>
      <Box mb={1}>
        Модуль шифрования {encryptmod ? <Box inline color="good">включён</Box> : <Box inline color="bad">отключён</Box>}.
      </Box>
      {!encryptmod && (
        <Button onClick={() => act('toggle_encrypt')}>Активировать порты шифрования</Button>
      )}
    </Box>
  );
};

const TranslatorScreen = (props, context) => {
  const { act, data } = useBackend(context);
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

const CameraJackScreen = (props, context) => {
  const { act, data } = useBackend(context);
  const { cable_extended, cable_connected, hackprogress, hacking } = data;
  return (
    <Section title="Статус взлома камеры">
      <LabeledList>
        <LabeledList.Item label="Кабель">
          {!cable_extended ? (
            <Box color="bad">Убран</Box>
          ) : !cable_connected ? (
            <Box color="average">Выдвинут (не подключён)</Box>
          ) : (
            <Box color="good">Подключён</Box>
          )}
        </LabeledList.Item>
        {hacking && (
          <LabeledList.Item label="Прогресс">
            <ProgressBar value={hackprogress} minValue={0} maxValue={100}>
              {hackprogress}%
            </ProgressBar>
          </LabeledList.Item>
        )}
      </LabeledList>
      {!cable_extended && (
        <Button mt={1} onClick={() => act('doorjack_cable')}>Выдвинуть кабель</Button>
      )}
      {cable_connected && !hacking && (
        <Button mt={1} onClick={() => act('camerajack_start')}>Начать взлом камеры</Button>
      )}
      {hacking && (
        <Button mt={1} color="bad" onClick={() => act('camerajack_cancel')}>Отменить взлом</Button>
      )}
    </Section>
  );
};

const HeartbeatScreen = (props, context) => {
  const { act, data } = useBackend(context);
  const { heartbeat_sensor } = data;
  return (
    <Box>
      <Box mb={1}>
        Сенсор пульса {heartbeat_sensor ? <Box inline color="good">включён</Box> : <Box inline color="bad">отключён</Box>}.
      </Box>
      <Button onClick={() => act('toggle_heartbeat')}>
        {heartbeat_sensor ? 'Отключить' : 'Включить'} сенсор пульса
      </Button>
      <NoticeBox info mt={1}>
        При включении сенсор будет отслеживать состояние биологического носителя и предупреждать о критических изменениях здоровья.
      </NoticeBox>
    </Box>
  );
};

const ProjectionScreen = (props, context) => {
  const { act, data } = useBackend(context);
  const { holoform, emitterhealth, emittermaxhealth } = data;
  const healthPercent = (emitterhealth / emittermaxhealth) * 100;
  return (
    <Box>
      <Box mb={1}>
        Голохассис {holoform ? <Box inline color="good">развёрнут</Box> : <Box inline color="bad">свёрнут</Box>}.
      </Box>
      <LabeledList>
        <LabeledList.Item label="Целостность эмиттера">
          <ProgressBar value={healthPercent} minValue={0} maxValue={100} ranges={{ good: [50, 100], average: [20, 50], bad: [0, 20] }}>
            {emitterhealth} / {emittermaxhealth}
          </ProgressBar>
        </LabeledList.Item>
      </LabeledList>
      <Button mt={1} onClick={() => act('toggle_projection')}>
        {holoform ? 'Свернуть голохассис' : 'Развернуть голохассис'}
      </Button>
    </Box>
  );
};

const EncoderScreen = (props, context) => {
  const { act, data } = useBackend(context);
  const { encoder_active, encoder_name, encoder_job } = data;
  return (
    <Box>
      <Box mb={1}>
        Энкодер {encoder_active ? <Box inline color="good">активен</Box> : <Box inline color="bad">неактивен</Box>}.
      </Box>
      {encoder_active && (
        <LabeledList>
          <LabeledList.Item label="Имя">{encoder_name || '—'}</LabeledList.Item>
          <LabeledList.Item label="Должность">{encoder_job || '—'}</LabeledList.Item>
        </LabeledList>
      )}
      <Button mt={1} onClick={() => act('toggle_encoder')}>
        {encoder_active ? 'Деактивировать' : 'Активировать'}
      </Button>
    </Box>
  );
};

const ThermalVisionScreen = (props, context) => {
  const { act, data } = useBackend(context);
  const { thermal_vision } = data;
  return (
    <Box>
      <Box mb={1}>
        Термальное зрение {thermal_vision ? <Box inline color="good">включено</Box> : <Box inline color="bad">выключено</Box>}.
      </Box>
      <Button onClick={() => act('toggle_thermal_vision')}>
        {thermal_vision ? 'Отключить' : 'Включить'}
      </Button>
    </Box>
  );
};

const ChemicalInjectorScreen = (props, context) => {
  const { act, data } = useBackend(context);
  const { chemical_injector, chemical_storage, chemical_max } = data;
  return (
    <Box>
      <Box mb={1}>
        Химический инъектор {chemical_injector ? <Box inline color="good">активен</Box> : <Box inline color="bad">неактивен</Box>}.
      </Box>
      <LabeledList>
        <LabeledList.Item label="Запас">
          {chemical_storage ?? 0} / {chemical_max ?? 30} юнитов
        </LabeledList.Item>
      </LabeledList>
      <Button mt={1} onClick={() => act('toggle_chemical_injector')}>
        {chemical_injector ? 'Отключить' : 'Активировать'}
      </Button>
      {chemical_injector && (
        <Button mt={1} ml={1} onClick={() => act('inject_chemicals')}>
          Впрыснуть реагенты
        </Button>
      )}
    </Box>
  );
};
