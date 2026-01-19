import { useBackend } from '../backend';
import { Box, Button, Collapsible, Dropdown, Flex, LabeledList, NoticeBox, Section } from '../components';
import { Window } from '../layouts';

export const MailAdminPanel = (props, context) => {
  return (
    <Window title="Панель управления почтой" width={900} height={600} theme="admin" resizable>
      <Window.Content scrollable overflow="auto">
        <SubsystemInfoReadout />
        <PlayerChoosingPanel />
        <MailCreationPanel />
      </Window.Content>
    </Window>
  );
};

export const SubsystemInfoReadout = (props, context) => {
  const { act, data } = useBackend(context);

  const {
    total_mails,
    unopen_mails,
    waiting_mails,
    next_fire,
  } = data;

  return (
    <Collapsible title="Общая Информация" open>
      <Section>
        <LabeledList>
          <LabeledList.Item
            label="Главное хранилище"
            color="green"
            buttons={
              <Button
                icon="space-shuttle"
                tooltip="Прыгнуть к главному хранилищу с почтой."
                onClick={() => act('jump_to_storage')}
              />
            } />
          <LabeledList.Item
            label="Всего писем за раунд"
            color="green">
            {total_mails}
          </LabeledList.Item>
          <LabeledList.Item label="Писем, ждующих отправки" color="yellow">
            {waiting_mails}
          </LabeledList.Item>
          <LabeledList.Item label="Неоткрытых писем" color="red">
            {unopen_mails}
          </LabeledList.Item>
          <LabeledList.Item label="Cледующий запуск подсистемы" color="blue">
            {next_fire}
          </LabeledList.Item>
        </LabeledList>
      </Section>
    </Collapsible>
  );
};

export const PlayerChoosingPanel = (props, context) => {
  const { act, data } = useBackend(context);

  const {
    player_names,
    chosen_player_name,
    chosen_player_ckey,
    chosen_player_assignment,
  } = data;

  return (
    <Collapsible title="Выбор Игрока" open>
      <Section
        title="Получатель"
        buttons={
          chosen_player_name ? (
            <Button
              icon="check"
              content="Проверить веса писем"
              tooltip="Узнать веса (шансы выпадения) отдельных паттернов писем."
              onClick={() => act('check_weights')}
            />
          ) : ''
        }>
      <Flex>
        <LabeledList>
          <LabeledList.Item label="Выбор" labelColor="green">
            <Dropdown
              width="100%"
              selected="Выберите игрока..."
              options={player_names}
              onSelected={(value) => act("select_player", { player_name: value })}
            />
          </LabeledList.Item>
            {player_names ? (
              <div>
                <LabeledList.Item label="Имя игрока" labelColor="green">
                  {chosen_player_name}
                </LabeledList.Item>
                <LabeledList.Item label="Сикей игрока" labelColor="green">
                  {chosen_player_ckey}
                </LabeledList.Item>
                <LabeledList.Item label="Роль игрока" labelColor="green">
                  {chosen_player_assignment}
                </LabeledList.Item>
              </div>
            ) : (
              <NoticeBox>
                Игрок не выбран.
              </NoticeBox>
            )}
        </LabeledList>
      </Flex>
      </Section>
    </Collapsible>
  );
};

export const MailCreationPanel = (props, context) => {
  const { act, data } = useBackend(context);

  const {
    available_categories,
    available_patterns,
    chosen_player_name,
    info_on_displayed_pattern,
  } = data;

  return (
      <Collapsible title="Выбор шаблона" open>
        <Section>
          <Flex>
            <LabeledList>
              <LabeledList.Item
                label="Категория"
                labelColor="green"
              >
                <Dropdown
                  width="100%"
                  selected="Выберите категорию..."
                  options={available_categories}
                  onSelected={(value) => act("choose_category", { chosen_category: value })}
                />
              </LabeledList.Item>
              <LabeledList.Item
                label="Шаблон"
                labelColor="green"
              >
                {available_patterns ? (
                  <Dropdown
                    width="100%"
                    selected="Выберите шаблон..."
                    options={available_patterns}
                    onSelected={(value) => act("choose_pattern", { chosen_pattern: value })}
                  />
                ) : (
                  <NoticeBox>
                    Категория не выбрана.
                  </NoticeBox>
                )}
              </LabeledList.Item>
                <Flex>
                  {info_on_displayed_pattern ? (
                    <div>
                      <LabeledList.Item label="Категория шаблона" labelColor="green">
                        {info_on_displayed_pattern["category"]}
                      </LabeledList.Item>
                      <LabeledList.Item label="Изначальный вес шаблона"
                        labelColor="green"
                        color={info_on_displayed_pattern["weight"] === "0" ? "bad" : "yellow"}>
                        {info_on_displayed_pattern["weight"]}
                      </LabeledList.Item>
                      <LabeledList.Item label="Описание шаблона" labelColor="green">
                        <Box inline width="200px" mx="1px">
                          {info_on_displayed_pattern["desc"]}
                        </Box>
                      </LabeledList.Item>
                      <LabeledList.Item label="Ограничения" labelColor="yellow" color="red">
                        <Box inline width="200px" mx="1px">
                          {info_on_displayed_pattern["restriction_string"]}
                        </Box>
                      </LabeledList.Item>
                      <LabeledList.Item label="Изначальное содержимое" labelColor="yellow">
                        <Box inline width="200px" mx="1px">
                          {info_on_displayed_pattern["contents"]}
                        </Box>
                      </LabeledList.Item>
                      <LabeledList.Item label="Действия" labelColor="yellow">
                        <Button
                          icon="shopping-cart"
                          content="В хранилище"
                          color="green"
                          disabled={!chosen_player_name}
                          tooltip="Создать письмо по выбранному шаблону и отправить в главное хранилище"
                          onClick={() => act('create_in_storage')}
                        />
                        <Button
                          icon="download"
                          content="Под собой"
                          color="yellow"
                          disabled={!chosen_player_name}
                          tooltip="Создать письмо по выбранному шаблону под собой"
                          onClick={() => act('create_under_me')}
                        />
                        <Button
                          icon="paper-plane"
                          content="Под получателем"
                          color="bad"
                          disabled={!chosen_player_name}
                          tooltip="Создать письмо по выбранному шаблону под ногами получателя"
                          onClick={() => act('create_under_them')}
                        />
                      </LabeledList.Item>
                    </div>
                  ) : (
                    <NoticeBox>
                      Шаблон не выбран.
                    </NoticeBox>
                  )}
                </Flex>
            </LabeledList>
          </Flex>
        </Section>
      </Collapsible>
  );
};
