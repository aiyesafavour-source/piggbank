import React from 'react';
import { Area, AreaChart, CartesianGrid, ResponsiveContainer, Tooltip, XAxis, YAxis } from 'recharts';

export type SavingsPoint = { date: string; value: number };

export default function SavingsChart({ data }: { data: SavingsPoint[] }) {
  return (
    <div className="panel">
      <div style={{ marginBottom: 8, fontWeight: 600 }}>Savings</div>
      <div style={{ width: '100%', height: 260 }}>
        <ResponsiveContainer>
          <AreaChart data={data} margin={{ top: 10, right: 10, bottom: 0, left: 0 }}>
            <defs>
              <linearGradient id="colorA" x1="0" y1="0" x2="0" y2="1">
                <stop offset="5%" stopColor="var(--accent)" stopOpacity={0.6} />
                <stop offset="95%" stopColor="var(--accent)" stopOpacity={0} />
              </linearGradient>
            </defs>
            <CartesianGrid strokeDasharray="3 3" opacity={0.2} />
            <XAxis dataKey="date" tick={{ fill: 'var(--text)' }} />
            <YAxis tick={{ fill: 'var(--text)' }} />
            <Tooltip contentStyle={{ background: 'var(--panel)', border: '0.5px solid rgba(255,255,255,0.1)' }} labelStyle={{ color: 'var(--text)' }} />
            <Area type="monotone" dataKey="value" stroke="var(--accent)" fillOpacity={1} fill="url(#colorA)" />
          </AreaChart>
        </ResponsiveContainer>
      </div>
    </div>
  );
}
