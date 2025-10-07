import React from 'react';
import { useTheme } from '../lib/theme';
import { motion } from 'framer-motion';

export default function Navbar() {
  const { theme, toggle } = useTheme();

  return (
    <motion.div className="nav" initial={{ y: -20, opacity: 0 }} animate={{ y: 0, opacity: 1 }} transition={{ duration: 0.5 }}>
      <div style={{ fontWeight: 700 }}>PiggyBank</div>
      <div style={{ display: 'flex', gap: 12, alignItems: 'center' }}>
        <button className="btn" onClick={toggle}>{theme === 'dark' ? 'Light' : 'Dark'} mode</button>
      </div>
    </motion.div>
  );
}
