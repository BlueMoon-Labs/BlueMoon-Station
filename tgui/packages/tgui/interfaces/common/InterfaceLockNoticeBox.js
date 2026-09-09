import { useBackend } from '../../backend';
import { Button, Flex, NoticeBox } from '../../components';

/**
 * This component by expects the following fields to be returned
 * from ui_data:
 *
 * - siliconUser: boolean
 * - locked: boolean
 *
 * And expects the following ui_act action to be implemented:
 *
 * - lock - for toggling the lock as a silicon user.
 *
 * All props can be redefined if you want custom behavior, but
 * it's preferred to stick to defaults.
 *
 * Тексты вынесены в пропсы с английскими значениями по умолчанию: переведённые
 * интерфейсы задают свои, не трогая остальных потребителей компонента.
 */
export const InterfaceLockNoticeBox = (props) => {
  const { act, data } = useBackend();
  const {
    siliconUser = data.siliconUser,
    locked = data.locked,
    onLockStatusChange = () => act('lock'),
    accessText = 'an ID card',
    lockLabel = 'Interface lock status:',
    lockedText = 'Locked',
    unlockedText = 'Unlocked',
    swipeText = `Swipe ${accessText} to ${locked ? 'unlock' : 'lock'} this interface.`,
  } = props;
  // For silicon users
  if (siliconUser) {
    return (
      <NoticeBox color="grey">
        <Flex align="center">
          <Flex.Item>
            {lockLabel}
          </Flex.Item>
          <Flex.Item grow={1} />
          <Flex.Item>
            <Button
              m={0}
              color={locked ? 'red' : 'green'}
              icon={locked ? 'lock' : 'unlock'}
              content={locked ? lockedText : unlockedText}
              onClick={() => {
                if (onLockStatusChange) {
                  onLockStatusChange(!locked);
                }
              }} />
          </Flex.Item>
        </Flex>
      </NoticeBox>
    );
  }
  // For everyone else
  return (
    <NoticeBox>
      {swipeText}
    </NoticeBox>
  );
};
