import { resolveAsset } from '../assets';
import { useBackend } from '../backend';
import { Box, Button, Section } from '../components';
import { Window } from '../layouts';

export const BattleArcade = (props, context) => {
  const { act, data } = useBackend(context);
  const {
    ui_panel,
    player_current_hp,
    player_current_mp,
    max_hp,
    max_mp,
    player_gold,
    equipped_gear = [],
  } = data;
  return (
    <Window width={420} height={450}>
      <Window.Content>
        <Section textAlign="center">
          <Box bold>Характеристики игрока</Box>
          <Box mt={0.5}>
            ХП:{' '}
            <span style={{ color: '#c91212' }}>
              {player_current_hp}/{max_hp}
            </span>{' '}
            | МП:{' '}
            <span style={{ color: '#0783b5' }}>
              {player_current_mp}/{max_mp}
            </span>{' '}
            |{' '}
            <span style={{ color: '#b8c10b' }}>
              {player_gold || 0}
            </span>
            G
          </Box>
          <Box mt={0.5}>
            {!equipped_gear.length && 'Снаряжение не экипировано!'}
            {equipped_gear.map((gear, index) => (
              <Box key={index}>
                {gear.slot}: {gear.name}
              </Box>
            ))}
          </Box>
        </Section>
        {ui_panel === 'Shop' ? (
          <ShopPanel />
        ) : ui_panel === 'World Map' ? (
          <WorldMapPanel />
        ) : ui_panel === 'Battle' ? (
          <BattlePanel />
        ) : ui_panel === 'Between Battle' ? (
          <BetweenBattlePanel />
        ) : (
          <GameOverPanel />
        )}
      </Window.Content>
    </Window>
  );
};

const ShopPanel = (props, context) => {
  const { act, data } = useBackend(context);
  const { shop_items, cost_of_items, unlocked_world_modifier } = data;
  return (
    <Section textAlign="center">
      <Box bold>Добро пожаловать в таверну!</Box>
      <Box mt={1}>
        <img
          src={resolveAsset('shopkeeper.png')}
          style={{ width: '64px' }}
        />
      </Box>
      <Box m={1}>
        Осмотрите наши товары или отдохните. Я позабочусь о том,
        чтобы вы спокойно выспались, без ограблений и засад.
      </Box>
      {shop_items.map((item, index) => (
        <Button
          key={index}
          icon="shield"
          fluid
          onClick={() => act('buy_item', { purchasing_item: item })}>
          {item}: {cost_of_items * unlocked_world_modifier}G
        </Button>
      ))}
      <Button icon="bed" fluid onClick={() => act('sleep')}>
        Отдохнуть {cost_of_items / 2}G
      </Button>
      <Button icon="arrow-left" fluid onClick={() => act('leave')}>
        Покинуть таверну
      </Button>
    </Section>
  );
};

const WorldMapPanel = (props, context) => {
  const { act, data } = useBackend(context);
  const { all_worlds, latest_unlocked_world_position } = data;
  return (
    <Section textAlign="center">
      <Box>
        <Button color="transparent" icon="map" /> КАРТА МИРА{' '}
        <Button color="transparent" icon="map" />
      </Box>
      <Box m={1}>
        Чем дальше вы продвинетесь, тем сложнее будут враги,
        но тем больше наград вы получите.
      </Box>
      <Button icon="home" fluid onClick={() => act('enter_inn')}>
        Войти в таверну
      </Button>
      {all_worlds.map((world, index) => (
        <Button
          key={index}
          disabled={index >= latest_unlocked_world_position}
          icon="fist-raised"
          fluid
          onClick={() => act('start_fight', { selected_arena: world })}>
          {world}
        </Button>
      ))}
    </Section>
  );
};

const BattlePanel = (props, context) => {
  const { act, data } = useBackend(context);
  const {
    attack_types,
    enemy_icon_id,
    enemy_name,
    enemy_max_hp,
    enemy_hp,
    enemy_mp,
    feedback_message,
  } = data;
  return (
    <Section textAlign="center">
      {feedback_message && (
        <Box color="yellow" mb={1}>
          {feedback_message}
        </Box>
      )}
      <Box>
        ХП {enemy_name}: {enemy_hp}/{enemy_max_hp}
      </Box>
      <Box>
        МП {enemy_name}: {enemy_mp}
      </Box>
      <Box my={1}>
        <img
          src={resolveAsset(enemy_icon_id)}
          style={{ width: '80px' }}
        />
      </Box>
      {attack_types.map((attack, index) => (
        <Button
          key={index}
          icon="fist-raised"
          fluid
          tooltip={attack.tooltip}
          onClick={() => act(attack.name)}>
          {attack.name}
        </Button>
      ))}
      <Button.Confirm
        icon="shoe-prints"
        fluid
        confirmContent="Точно сбежать?"
        onClick={() => act('flee')}>
        Сбежать (потеря половины золота)
      </Button.Confirm>
    </Section>
  );
};

const BetweenBattlePanel = (props, context) => {
  const { act, data } = useBackend(context);
  return (
    <Section textAlign="center">
      <Box my={1}>
        <img
          src={resolveAsset('fireplace.png')}
          style={{ width: '80px' }}
        />
      </Box>
      <Box m={1}>
        Наступает ночь. Вы можете попытаться отдохнуть — это полностью
        восстановит здоровье и ману перед следующим боем, но есть
        риск засады, и вы начнёте бой без исцеления.
      </Box>
      <Button icon="bed" fluid onClick={() => act('continue_with_rest')}>
        Попытаться уснуть
      </Button>
      <Button
        icon="fire"
        fluid
        onClick={() => act('continue_without_rest')}>
        Продолжить без сна
      </Button>
      <Button
        icon="shoe-prints"
        fluid
        onClick={() => act('abandon_quest')}>
        Покинуть поход
      </Button>
    </Section>
  );
};

const GameOverPanel = (props, context) => {
  const { act, data } = useBackend(context);
  return (
    <Section textAlign="center">
      <Box color="red" fontSize="32px" m={1} bold>
        Игра окончена
      </Box>
      <Box fontSize="15px">
        <Button
          lineHeight={2}
          fluid
          icon="arrow-left"
          onClick={() => act('restart')}>
          Главное меню
        </Button>
      </Box>
    </Section>
  );
};
