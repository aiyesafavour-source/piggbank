import React, { useMemo } from 'react';
import Navbar from '../components/Navbar';
import { WalletConnect } from '../components/WalletConnect';
import SavingsChart from '../components/SavingsChart';
import { motion } from 'framer-motion';

export default function Home() {
  const data = useMemo(() => {
    const now = Date.now();
    return Array.from({ length: 12 }).map((_, i) => ({
      date: new Date(now - (11 - i) * 86400000).toLocaleDateString(),
      value: Math.max(0, Math.round(1000 + i * 120 + (Math.sin(i) * 100))),
    }));
  }, []);

  return (
    <div>
      <Navbar />
      <div className="container">
        <motion.div className="row" initial={{ opacity: 0, y: 20 }} animate={{ opacity: 1, y: 0 }} transition={{ duration: 0.6 }}>
          <div className="col">
            <div className="panel">
              <div style={{ marginBottom: 12, fontWeight: 600 }}>Wallet</div>
              <WalletConnect />
            </div>
          </div>
          <div className="col">
            <SavingsChart data={data} />
          </div>
        </motion.div>
      </div>
    </div>
  );
}


