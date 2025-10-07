import { jsx as _jsx, jsxs as _jsxs } from "react/jsx-runtime";
import { useTheme } from '../lib/theme';
import { motion } from 'framer-motion';
export default function Navbar() {
    const { theme, toggle } = useTheme();
    return (_jsxs(motion.div, { className: "nav", initial: { y: -20, opacity: 0 }, animate: { y: 0, opacity: 1 }, transition: { duration: 0.5 }, children: [_jsx("div", { style: { fontWeight: 700 }, children: "PiggyBank" }), _jsx("div", { style: { display: 'flex', gap: 12, alignItems: 'center' }, children: _jsxs("button", { className: "btn", onClick: toggle, children: [theme === 'dark' ? 'Light' : 'Dark', " mode"] }) })] }));
}
