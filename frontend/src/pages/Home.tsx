import React from 'react';
import { WalletConnect } from '../components/WalletConnect';

export default function Home() {
  return (
    <div style={{ padding: 24 }}>
      <h1>PiggyBank dApp</h1>
      <WalletConnect />
    </div>
  );
}


