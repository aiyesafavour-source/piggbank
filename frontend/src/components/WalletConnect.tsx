import React from 'react';
import { useAccount, useConnect, useDisconnect } from 'wagmi';

export function WalletConnect() {
  const { address, isConnected } = useAccount();
  const { connect, connectors, status, error } = useConnect();
  const { disconnect } = useDisconnect();

  if (isConnected) {
    return (
      <div style={{ display: 'flex', gap: 12, alignItems: 'center' }}>
        <span>Connected: {address}</span>
        <button onClick={() => disconnect()}>Disconnect</button>
      </div>
    );
  }

  return (
    <div style={{ display: 'flex', gap: 12, alignItems: 'center' }}>
      {connectors.map((c) => (
        <button key={c.uid} onClick={() => connect({ connector: c })} disabled={!c.ready}>
          Connect {c.name}
        </button>
      ))}
      {status === 'connecting' && <span>Connecting...</span>}
      {error && <span style={{ color: 'red' }}>{error.message}</span>}
    </div>
  );
}


