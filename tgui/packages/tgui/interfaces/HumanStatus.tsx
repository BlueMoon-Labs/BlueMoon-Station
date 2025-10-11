import { useBackend } from '../backend';
import { Window } from '../layouts';
import { Section, Flex, Box, Divider, ProgressBar } from '../components';

type HumanStatusData = {
  mob_icon?: string;
  damage_descriptions?: string[];
  hunger_text?: string;
  thirst_text?: string;
  fatigue_text?: string;
  blood_text?: string;
  sanity_text?: string;
  sanity_value?: number;
  mood_text?: string;
  mood_value?: number;
  mood_events?: string[];
  overall_text?: string;
  temp_text?: string;
};

export const HumanStatus = (props, context) => {
  const { data } = useBackend<HumanStatusData>(context);
  const {
    mob_icon,
    damage_descriptions = [],
    hunger_text = 'Нет данных',
    thirst_text = 'Нет данных',
    fatigue_text = 'Нет данных',
    blood_text = 'Нет данных',
    sanity_text = 'Неизвестно',
    sanity_value = 0,
    mood_text = 'Неизвестно',
    mood_value = 0,
    mood_events = ['Нет данных о состоянии.'],
    overall_text = 'Неизвестно',
    temp_text = 'Неизвестно',
  } = data;

  const colorizeText = (text: string) => {
    return text
      .replace(/<span class='warning'>/g, "<span style='color: #ffa500; font-weight: bold;'>")
      .replace(/<span class='bad'>/g, "<span style='color: #ff0000; font-weight: bold;'>")
      .replace(/<span class='good'>/g, "<span style='color: #00ff00;'>")
      .replace(/<span class='nicegreen'>/g, "<span style='color: #00ff0d; font-weight:bold;'>")
      .replace(/<span class='boldwarning'>/g, "<span style='color: #ff4500; font-weight: bold;'>")
      .replace(/<span class='userlove'>/g, "<span style='color: #ef0acc; font-weight: bold;'>")
      .replace(/span>/g, "</span>");
  };

  const getDamageColor = (desc: string) => {
    if (desc.match(/тяж|множествен/i)) return '#ff4040';
    if (desc.match(/глубок|выраженн/i)) return '#ff7b00';
    if (desc.match(/ушиб|ссадин|поврежден/i)) return '#ffd500';
    return '#cccccc';
  };

  return (
    <Window
      width={1000}
      height={600}
      title="Состояние"
      resizable={false}
      theme="dark"
      style={{
        background:
          'radial-gradient(circle at 20% 30%, rgba(0, 255, 255, 0.07), transparent 70%), linear-gradient(160deg, #1a1f22 0%, #0c0c0e 100%)',
        boxShadow:
          '0 0 25px rgba(0,255,255,0.15), inset 0 0 30px rgba(0,0,0,0.7)',
        border: '1px solid rgba(0,255,255,0.1)',
      }}
    >
      <Window.Content
        style={{
          background:
            'linear-gradient(180deg, rgba(20,20,25,0.9) 0%, rgba(10,10,15,0.95) 100%)',
          borderRadius: '10px',
          boxShadow:
            'inset 0 0 25px rgba(0,0,0,0.8), 0 0 20px rgba(0,255,255,0.08)',
          padding: '4px',
        }}
      >
        <Flex height="100%" align="center" justify="space-between">
          {/* Левая панель — физическое состояние */}
          <Box
            width="25%"
            height="95%"
            p={1.5}
            backgroundColor="rgba(20, 20, 20, 0.7)"
            style={{
              borderRadius: '8px',
              boxShadow: 'inset 0 0 10px rgba(0,0,0,0.6)',
              overflowY: 'auto',
            }}
          >
            <Section title="Физическое состояние">
              <Box color="label" mb={1}>
                Общее состояние: {overall_text}
              </Box>
              <Box color="label" mb={1}>
                Температура тела: {temp_text}
              </Box>
            </Section>

            <Divider mt={1} mb={1} />

            <Section title="Повреждения">
              {damage_descriptions.length ? (
                damage_descriptions.map((desc, i) => (
                  <Box
                    key={i}
                    mb={0.5}
                    style={{
                      color: getDamageColor(desc),
                      fontWeight: 'bold',
                    }}
                    dangerouslySetInnerHTML={{ __html: colorizeText(desc) }}
                  />
                ))
              ) : (
                <Box color="label" italic>
                  Повреждений не обнаружено.
                </Box>
              )}
            </Section>
            </Box>
          {/* Центральная зона — кукла */}
          <Flex
            direction="column"
            align="center"
            justify="center"
            width="45%"
            height="95%"
          >
            <Box
              width="100%"
              height="100%"
              style={{
                aspectRatio: '1 / 1',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                borderRadius: '10px',
                border: '2px dashed rgba(255,255,255,0.15)',
                boxShadow:
                  '0 0 15px rgba(0,255,255,0.1), inset 0 0 8px rgba(0,0,0,0.5)',
                backgroundColor: 'rgba(255,255,255,0.02)',
                position: 'relative',
                overflow: 'hidden',
              }}
            >
              {mob_icon ? (
                <img
                  src={`data:image/png;base64,${mob_icon}`}
                  alt="human doll"
                  style={{
                    position: 'absolute',
                    top: '50%',
                    left: '50%',
                    transform: 'translate(-50%, -50%)',
                    imageRendering: 'pixelated',
                    width: 'auto',
                    height: 'auto',
                    maxWidth: '70%',
                    maxHeight: '70%',
                    filter: 'drop-shadow(0 0 6px rgba(0,255,255,0.3))',
                    transition: 'max-width 0.3s ease, max-height 0.3s ease',
                  }}
                />
              ) : (
                <Box color="label" fontSize="16px" textAlign="center">
                  Здесь будет кукла персонажа
                </Box>
              )}
            </Box>
          </Flex>

          {/* Правая панель — ментальное состояние и нужды */}
          <Box
            width="25%"
            height="95%"
            p={1.5}
            backgroundColor="rgba(15, 15, 15, 0.75)"
            style={{
              borderRadius: '8px',
              boxShadow: 'inset 0 0 10px rgba(0,0,0,0.6)',
              overflowY: 'auto',
            }}
          >
            <Section title="Ментальное состояние">
              <Box mb={1}>
                <Box color="label">Рассудок:</Box>
                <ProgressBar
                  value={sanity_value / 100}
                  ranges={{
                    good: [0.6, Infinity],
                    average: [0.3, 0.6],
                    bad: [-Infinity, 0.3],
                  }}
                />
                <Box color="good" mt={0.5}>
                  {sanity_text}
                </Box>
              </Box>

              <Box mt={2} mb={1}>
                <Box color="label">Настроение:</Box>
                <ProgressBar
                  value={mood_value / 10}
                  ranges={{
                    good: [0.6, Infinity],
                    average: [0.3, 0.6],
                    bad: [-Infinity, 0.3],
                  }}
                />
                <Box color="good" mt={0.5}>
                  {mood_text}
                </Box>
              </Box>

              <Divider mt={2} mb={2} />

              <Box bold color="label" mb={1}>
                Факторы:
              </Box>
              {mood_events.length ? (
                mood_events.map((desc, i) => (
                  <Box
                    key={i}
                    mb={0.5}
                    dangerouslySetInnerHTML={{ __html: colorizeText(desc) }}
                  />
                ))
              ) : (
                <Box color="label" italic>
                  Мне не на что сейчас реагировать.
                </Box>
              )}
            </Section>

            <Divider mt={2} mb={2} />

            <Section title="Нужды">
              <Box color="label" mb={1}>
                Голод: {hunger_text}
              </Box>
              <Box color="label" mb={1}>
                Жажда: {thirst_text}
              </Box>
            </Section>
          </Box>
        </Flex>
      </Window.Content>
    </Window>
  );
};
