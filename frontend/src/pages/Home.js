import { jsx as _jsx, jsxs as _jsxs } from "react/jsx-runtime";
import { useMemo } from 'react';
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
    return (_jsxs("div", { children: [_jsx(Navbar, {}), _jsx("div", { className: "container", children: _jsxs(motion.div, { className: "row", initial: { opacity: 0, y: 20 }, animate: { opacity: 1, y: 0 }, transition: { duration: 0.6 }, children: [_jsx("div", { className: "col", children: _jsxs("div", { className: "panel", children: [_jsx("div", { style: { marginBottom: 12, fontWeight: 600 }, children: "Wallet" }), _jsx(WalletConnect, {})] }) }), _jsx("div", { className: "col", children: _jsx(SavingsChart, { data: data }) })] }) })] }));
}
