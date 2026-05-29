import { useBackend } from '../backend';
import { Window } from '../layouts';

export const LawManager = (props, context) => {
  const { act, data } = useBackend(context);
  const { laws = [] } = data;

  return (
    <Window
      width={600}
      height={550}
      title="DIRECTIVE_CORE_V4.2">
      <div className="TerminalContainer">
        <div className="CrtLines" />

        <div className="TopBar">
          <div className="StatusBlock">
            <span className="Pulse" />
            <span className="SystemText">SYSTEM_READY // DIRECTIVES_LOADED</span>
          </div>
          <button
            type="button"
            className="BroadcastBtn"
            onClick={() => act('state_laws')}>
            {'>'} EXECUTE_BROADCAST
          </button>
        </div>

        <div className="LawGrid scrollable">
          {laws.length === 0 ? (
            <div className="ErrorMessage">FATAL: NO_DIRECTIVES_IN_MEMORY</div>
          ) : (
            laws.map((law, idx) => (
              <div
                key={law.id}
                className={`LawCard ${law.type} ${law.active ? 'IsActive' : 'IsMuted'}`}
                style={{ animationDelay: `${idx * 0.05}s` }}>

                <div className="CardHeader">
                  <button
                    type="button"
                    className="ToggleAction"
                    onClick={() => act('toggle_law', { type: law.type, index: law.index })}>
                    <span className="CheckIcon">
                      {law.active ? '[X]' : '[ ]'}
                    </span>
                    <span className="DirectiveLabel">Директива:</span>
                    <span className="LawNumber">{law.name}</span>
                  </button>
                  <div className="TypeTag">{law.type.toUpperCase()}</div>
                </div>

                <div className="LawBody">
                  {law.text}
                </div>
              </div>
            ))
          )}
        </div>
      </div>

      <style>{`
        .TerminalContainer {
          position: relative; background: #06080a; color: #00ffcc;
          height: 100%; display: flex; flex-direction: column;
          font-family: 'Consolas', 'Monaco', monospace; padding: 20px;
          overflow: hidden; border: 1px solid #1a2228;
        }

        .CrtLines {
          position: absolute; inset: 0;
          background: linear-gradient(rgba(18, 16, 16, 0) 50%, rgba(0, 0, 0, 0.1) 50%);
          background-size: 100% 4px; pointer-events: none; z-index: 5;
        }

        .TopBar {
          display: flex; justify-content: space-between; align-items: center;
          border-bottom: 2px solid #00ffcc33; padding-bottom: 12px; margin-bottom: 20px;
        }

        .BroadcastBtn {
          background: rgba(0, 255, 204, 0.05); border: 1px solid #00ffcc;
          color: #00ffcc; padding: 6px 15px; cursor: pointer;
          font-weight: bold; transition: all 0.2s;
          text-shadow: 0 0 8px rgba(0, 255, 204, 0.5);
        }

        .BroadcastBtn:hover {
          background: #00ffcc; color: #000; box-shadow: 0 0 20px #00ffcc;
        }

        .LawCard {
          background: rgba(255, 255, 255, 0.02); margin-bottom: 15px;
          padding: 15px; border-left: 2px solid #222;
          animation: slideIn 0.3s ease-out forwards; opacity: 0;
        }

        @keyframes slideIn { from { opacity: 0; transform: translateX(-5px); } to { opacity: 1; transform: translateX(0); } }

        .LawCard.IsActive { border-left-color: #00ffcc; background: rgba(0, 255, 204, 0.03); }
        .LawCard.IsMuted { opacity: 0.3; filter: grayscale(0.8); }

        /* Нулевой закон / Zeroth */
        .LawCard.zeroth { border-left-color: #ff3366; background: rgba(255, 51, 102, 0.05); }
        .LawCard.zeroth .DirectiveLabel { color: #ff3366 !important; text-shadow: 0 0 10px #ff3366; }
        .LawCard.zeroth .CheckIcon { color: #ff3366; }

        .ToggleAction {
          background: none; border: none; color: inherit;
          display: flex; align-items: center; cursor: pointer; padding: 0;
        }

        .CheckIcon {
          font-weight: bold; margin-right: 12px; font-size: 1.2em;
          color: #00ffcc; width: 30px;
        }

        .DirectiveLabel {
          color: #fff; font-weight: bold; margin-right: 8px;
          text-transform: uppercase; letter-spacing: 1px;
          text-shadow: 0 0 5px rgba(255, 255, 255, 0.3);
        }

        .LawNumber { font-size: 1.1em; color: #00ffcc; }

        .TypeTag {
          font-size: 0.7em; background: rgba(0,0,0,0.5);
          padding: 2px 8px; border: 1px solid rgba(0, 255, 204, 0.2);
        }

        .LawBody {
          margin-top: 10px; padding-left: 42px; line-height: 1.5;
          color: #a0aec0; font-size: 0.95em;
        }

        .scrollable { overflow-y: auto; flex-grow: 1; padding-right: 10px; }
        .scrollable::-webkit-scrollbar { width: 4px; }
        .scrollable::-webkit-scrollbar-thumb { background: #00ffcc22; }
      `}</style>
    </Window>
  );
};
