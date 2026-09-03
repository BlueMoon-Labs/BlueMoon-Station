import { NtosWindow } from '../layouts';
import { NtosCyborgRemoteMonitorContent } from './NtosCyborgRemoteMonitor';

export const NtosCyborgRemoteMonitorSyndicate = (props) => {
  return (
    <NtosWindow
      width={600}
      height={800}
      theme="syndicate">
      <NtosWindow.Content overflow="auto">
        <NtosCyborgRemoteMonitorContent />
      </NtosWindow.Content>
    </NtosWindow>
  );
};
