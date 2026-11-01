import { Window } from '../../layouts';
import { NetrunContent } from './Content';
import { NoticeToasts } from './NoticeToasts';

export const NetrunTerminal = () => {
  return (
    <Window width={1280} height={800} theme="ntos">
      <Window.Content fitted>
        <NetrunContent />
        <NoticeToasts />
      </Window.Content>
    </Window>
  );
};
