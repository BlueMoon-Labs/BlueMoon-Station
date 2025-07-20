import { Button, Flex, Section } from 'tgui/components';
import { sendMessage } from 'tgui/backend';
import { useEmotes } from './hooks';


export const EmotePanel = (props, context) => {
  const TGUI_PANEL_EMOTE_TYPE_DEFAULT = 1
  const TGUI_PANEL_EMOTE_TYPE_CUSTOM = 2
  const TGUI_PANEL_EMOTE_TYPE_ME = 3

  const emotes = useEmotes(context);

  const emoteList = [];
  for (const name in emotes.list) {
    let type = emotes.list[name]?.type;
    switch (type) {
      case TGUI_PANEL_EMOTE_TYPE_DEFAULT:
        emoteList.push({ type, name, key: emotes.list[name]["key"] });
        break;
      case TGUI_PANEL_EMOTE_TYPE_CUSTOM:
        emoteList.push({ type, name, key: emotes.list[name]["key"], message_override: emotes.list[name]["message_override"] });
        break;
      case TGUI_PANEL_EMOTE_TYPE_ME:
        emoteList.push({ type, name, message: emotes.list[name]["message"] });
        break;
      default:
        continue;
    }
  }

  const emoteCreate = () => sendMessage({
    type: 'emotes/create',
  });

  const emoteExecute = name => sendMessage({
    type: 'emotes/execute',
    payload: { name },
  });

  const emoteContextAction = name => sendMessage({
    type: 'emotes/contextAction',
    payload: { name },
  });

  return (
    <Section>
      <Flex align="center" style={{ 'flex-wrap': 'wrap' }}>
        {emoteList
          .sort((a, b) => { return a.name.localeCompare(b.name); })
          .map(emote => {
            let color = "blue";
            let tooltip = "";
            switch (emote.type) {
              case TGUI_PANEL_EMOTE_TYPE_DEFAULT:
                tooltip = `*${emote.key}`;
                break;
              case TGUI_PANEL_EMOTE_TYPE_CUSTOM:
                color = "purple";
                tooltip = `*${emote.key} | "${emote.message_override}\"`;
                break;
              case TGUI_PANEL_EMOTE_TYPE_ME:
                color = "orange";
                tooltip = `\"${emote.message}\"`;
                break;
              default:
                tooltip = "ОШИБКА: НЕИЗВЕСТНЫЙ ТИП ЭМОЦИИ'"
                break;
            }
            return (
              <Flex.Item mx={0.5} mt={1} key={emote.name}>
                <Button
                  content={emote.name}
                  onClick={() => emoteExecute(emote.name)}
                  onContextMenu={(e) => {
                    e.preventDefault();
                    emoteContextAction(emote.name);
                  }}
                  tooltip={tooltip}
                  color = {color}
                />
              </Flex.Item>
            )
        })}
        <Flex.Item mx={0.5} mt={1}>
          <Button
            icon="plus"
            color="green"
            onClick={() => emoteCreate()}
          />
        </Flex.Item>
      </Flex>
    </Section>
  );
};
