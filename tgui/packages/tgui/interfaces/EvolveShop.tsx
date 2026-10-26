import { useBackend } from '../backend';
import {
  BlockQuote,
  Box,
  Button,
  Collapsible,
  Divider,
  Flex,
  NoticeBox,
  ProgressBar,
  Section,
  Stack,
} from '../components';
import { Window } from '../layouts';

type EvolveShopContext = {
  abilities: Ability[];
  current_stage: number;
  current_evolve_points: number;
};

type Ability = {
  name: string;
  desc: string;
  icon: string;
  stage_required: number;
  can_purchase: boolean;
};

export const EvolveShop = () => {
  const { act, data } = useBackend<EvolveShopContext>();

  return (
    <Window width={900} height={520}>
      <Window.Content scrollable>
        {/* Шапка с текущей стадией и прогрессом */}
        <Section
          fill={false}
          title={`Ваша текущая стадия: ${data.current_stage}`}
        >
          <Flex direction="column">
            <Flex.Item grow={0}>
              <BlockQuote>
                Это меню для развития вашей латексной сущности. В зависимости
                от стадии открываются новые способности. Ниже представлен ваш
                прогресс по очкам эволюции.
              </BlockQuote>
            </Flex.Item>

            <Divider />

            <Flex.Item grow={0}>
              <Stack align="center" justify="space-between">
                <Stack.Item>
                  <Box bold>Прогресс эволюции</Box>
                </Stack.Item>
              </Stack>
              <ProgressBar
                ranges={{
                  good: [0.6, 1],
                  average: [0.2, 0.6],
                  bad: [-Infinity, 0.2],
                }}
                value={data.current_evolve_points}
              />
            </Flex.Item>
          </Flex>
        </Section>

        {/* Описание стадий */}
        <Section fill title="Описание стадий">
          {/* Первая стадия */}
          <StageSection
            title="Первая стадия"
            actionLabel="Эволюционировать до 1 стадии"
            onEvolve={() => act('evolve_to_stage', { stage: 1 })}
          >
            <BlockQuote>
              Более-менее сформировавшийся паразит, способный самостоятельно
              найти себе хозяина с помощью хитрых уловок. Все еще не умеет быть
              полезным для своего носителя, но этого достаточно, чтобы иметь
              способы насытиться.
            </BlockQuote>

            <Collapsible title="Список способностей стадии">
              <StageAbilitiesGrid
                abilities={data.abilities.filter(
                  (ability) => ability.stage_required === 1,
                )}
                onClickAbility={(ability) =>
                  act('evolve', { abilityName: ability.name })
                }
              />
            </Collapsible>
          </StageSection>

          {/* Вторая стадия */}
          <StageSection
            title="Вторая стадия"
            actionLabel="Эволюционировать до 2 стадии"
            onEvolve={() => act('evolve_to_stage', { stage: 2 })}
          >
            <BlockQuote>
              Готовый для охоты организм, уже способный эффективно скрываться в
              теле носителя и обладающий продвинутыми методами «кормления»,
              становясь полезным для носителя и входя с ним в симбиоз.
            </BlockQuote>

            <Collapsible title="Список способностей стадии">
              <StageAbilitiesGrid
                abilities={data.abilities.filter(
                  (ability) => ability.stage_required === 2,
                )}
                onClickAbility={(ability) =>
                  act('evolve', { abilityName: ability.name })
                }
              />
            </Collapsible>
          </StageSection>

          {/* Третья стадия */}
          <StageSection
            title="Третья стадия"
            actionLabel="Эволюционировать до 3 стадии"
            onEvolve={() => act('evolve_to_stage', { stage: 3 })}
          >
            <BlockQuote>
              По-настоящему серьёзное и почти неуловимое существо, дающее
              невероятное наслаждение и силы носителю и способное передвигаться
              без помощи тела хозяина, обретя самостоятельность.
            </BlockQuote>

            <Collapsible title="Список способностей стадии">
              <StageAbilitiesGrid
                abilities={data.abilities.filter(
                  (ability) => ability.stage_required === 3,
                )}
                onClickAbility={(ability) =>
                  act('evolve', { abilityName: ability.name })
                }
              />
            </Collapsible>
          </StageSection>
        </Section>
      </Window.Content>
    </Window>
  );
};

const StageSection = (props) => {
  const { title, actionLabel, onEvolve, children } = props;

  return (
    <Section
      fill={false}
      title={title}
      buttons={
        <Button icon="dna" onClick={onEvolve}>
          {actionLabel}
        </Button>
      }
    >
      {children}
    </Section>
  );
};

/** Сетка способностей по 3 карточки в ряд. */
const StageAbilitiesGrid = (props: {
  abilities: Ability[];
  onClickAbility: (ability: Ability) => void;
}) => {
  const { abilities, onClickAbility } = props;

  if (!abilities || abilities.length === 0) {
    return <NoticeBox>Нет доступных способностей для этой стадии.</NoticeBox>;
  }

  return (
    <Box mt={0.5}>
      <Flex
        direction="row"
        wrap="wrap"
        align="stretch"
      >
        {abilities.map((ability) => (
          <Flex.Item
            key={ability.name}
            grow={0}
            basis="33%"
            mx={0.25}
            my={0.25}
            style={{
              minWidth: '260px',
              maxWidth: '33%',
            }}
          >
            <Box
              className="candystripe"
              p={0.5}
              style={{
                borderRadius: '4px',
                boxShadow: '0 0 2px rgba(0,0,0,0.6)',
                display: 'flex',
                flexDirection: 'column',
                height: '100%',
              }}
            >
              <Button
                fluid
                onClick={() => onClickAbility(ability)}
                color={ability.can_purchase ? 'primary' : 'default'}
                disabled={!ability.can_purchase}
              >
                <Box
                  style={{
                    display: 'flex',
                    alignItems: 'center',
                    gap: '6px',
                  }}
                >
                  <img
                    src={`data:image/jpeg;base64, ${ability.icon}`}
                    alt="Спрайт"
                    style={{
                      imageRendering: 'pixelated',
                      width: '32px',
                      height: '32px',
                    }}
                  />
                  <Box bold>{ability.name}</Box>
                </Box>
              </Button>
            </Box>
          </Flex.Item>
        ))}
      </Flex>
    </Box>
  );
};
