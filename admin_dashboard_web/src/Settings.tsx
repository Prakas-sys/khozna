import { useState } from 'react';
import { 
  Landmark, 
  Globe, 
  ShieldCheck, 
  AlertTriangle,
  Save,
  RotateCcw,
  Circle,
  ChevronDown
} from 'lucide-react';

export const Settings = () => {
  const [maintenanceMode, setMaintenanceMode] = useState(false);
  const [commissionRate, setCommissionRate] = useState('12.5');
  const [threshold, setThreshold] = useState('5000');
  const [currency, setCurrency] = useState('NPR');
  const [timezone, setTimezone] = useState('Asia/Kathmandu');

  return (
    <div className="flex-1 overflow-y-auto px-8 py-8 bg-[#FAFAFA]">
      <div className="flex items-center justify-between mb-8">
        <div>
          <h2 className="text-[22px] font-semibold text-[#171717] tracking-tight mb-1">System Architecture</h2>
          <p className="text-[#737373] text-[13px]">Manage global parameters and platform governance filters.</p>
        </div>
        <div className="flex gap-2.5">
          <button className="h-9 px-4 bg-white border border-[#E5E5E5] text-[#525252] rounded-lg text-[12px] font-semibold hover:bg-[#FAFAFA] transition-all shadow-xs flex items-center gap-2">
            <RotateCcw size={14} strokeWidth={1.5} />
            Discard
          </button>
          <button className="h-9 px-4 bg-[#171717] text-white rounded-lg text-[12px] font-semibold hover:bg-[#0A0A0A] transition-all shadow-sm flex items-center gap-2">
            <Save size={14} strokeWidth={1.5} />
            Apply Changes
          </button>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6 pb-20">
        
        {/* Left Column - Main Settings */}
        <div className="lg:col-span-2 flex flex-col gap-6">
          
          {/* Financial Parameters */}
          <div className="card-minimal overflow-hidden shadow-xs">
            <div className="border-b border-[#E5E5E5] px-6 py-4 bg-white flex items-center gap-3">
              <Landmark size={16} strokeWidth={1.5} className="text-[#737373]" />
              <h3 className="text-[13px] font-semibold text-[#171717]">Fiscal Parameters</h3>
            </div>
            <div className="p-6 grid grid-cols-2 gap-6 bg-white">
              <div>
                <label className="block text-[10px] font-semibold text-[#A3A3A3] mb-2 uppercase tracking-widest">Global Commission (%)</label>
                <input 
                  type="number" 
                  value={commissionRate}
                  onChange={(e) => setCommissionRate(e.target.value)}
                  className="w-full bg-[#FAFAFA] border border-[#E5E5E5] text-[#171717] font-semibold rounded-lg px-4 py-2.5 focus:outline-none focus:border-[#171717] transition-all text-[13px]"
                />
              </div>
              <div>
                <label className="block text-[10px] font-semibold text-[#A3A3A3] mb-2 uppercase tracking-widest">Payout Threshold (NPR)</label>
                <input 
                  type="number" 
                  value={threshold}
                  onChange={(e) => setThreshold(e.target.value)}
                  className="w-full bg-[#FAFAFA] border border-[#E5E5E5] text-[#171717] font-semibold rounded-lg px-4 py-2.5 focus:outline-none focus:border-[#171717] transition-all text-[13px]"
                />
              </div>
            </div>
          </div>

          {/* Regional Defaults */}
          <div className="card-minimal overflow-hidden shadow-xs">
            <div className="border-b border-[#E5E5E5] px-6 py-4 bg-white flex items-center gap-3">
              <Globe size={16} strokeWidth={1.5} className="text-[#737373]" />
              <h3 className="text-[13px] font-semibold text-[#171717]">Regional Localization</h3>
            </div>
            <div className="p-6 grid grid-cols-2 gap-6 bg-white">
              <div className="relative">
                <label className="block text-[10px] font-semibold text-[#A3A3A3] mb-2 uppercase tracking-widest">Base Currency</label>
                <select 
                  value={currency}
                  onChange={(e) => setCurrency(e.target.value)}
                  className="w-full bg-[#FAFAFA] border border-[#E5E5E5] text-[#171717] font-semibold rounded-lg px-4 py-2.5 focus:outline-none focus:border-[#171717] transition-all appearance-none text-[13px]"
                >
                  <option value="NPR">Nepalese Rupee (NPR)</option>
                  <option value="USD">US Dollar (USD)</option>
                </select>
                <ChevronDown size={14} className="absolute right-3 bottom-3 text-[#A3A3A3] pointer-events-none" />
              </div>
              <div className="relative">
                <label className="block text-[10px] font-semibold text-[#A3A3A3] mb-2 uppercase tracking-widest">System Timezone</label>
                <select 
                  value={timezone}
                  onChange={(e) => setTimezone(e.target.value)}
                  className="w-full bg-[#FAFAFA] border border-[#E5E5E5] text-[#171717] font-semibold rounded-lg px-4 py-2.5 focus:outline-none focus:border-[#171717] transition-all appearance-none text-[13px]"
                >
                  <option value="Asia/Kathmandu">Kathmandu (NPT)</option>
                  <option value="UTC">Universal (UTC)</option>
                </select>
                <ChevronDown size={14} className="absolute right-3 bottom-3 text-[#A3A3A3] pointer-events-none" />
              </div>
            </div>
          </div>

          {/* Role Permissions */}
          <div className="card-minimal overflow-hidden shadow-xs">
            <div className="border-b border-[#E5E5E5] px-6 py-4 bg-white flex items-center justify-between">
              <div className="flex items-center gap-3">
                <ShieldCheck size={16} strokeWidth={1.5} className="text-[#737373]" />
                <h3 className="text-[13px] font-semibold text-[#171717]">Access Permissions</h3>
              </div>
            </div>
            <div className="overflow-x-auto">
              <table className="w-full text-left border-collapse">
                <thead className="bg-[#FAFAFA] border-b border-[#E5E5E5]">
                  <tr>
                    <th className="py-3 px-6 text-[10px] font-semibold text-[#A3A3A3] uppercase tracking-wider">Protocol</th>
                    <th className="py-3 px-6 text-[10px] font-semibold text-[#A3A3A3] uppercase tracking-wider text-center">Support</th>
                    <th className="py-3 px-6 text-[10px] font-semibold text-[#A3A3A3] uppercase tracking-wider text-center">Manager</th>
                    <th className="py-3 px-6 text-[10px] font-semibold text-[#A3A3A3] uppercase tracking-wider text-center">Admin</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-[#F5F5F5]">
                  {[
                    { label: 'Read-only Access', s: true, m: true, a: true },
                    { label: 'Fiscal Modification', s: false, m: true, a: true },
                    { label: 'System Overwrite', s: false, m: false, a: true },
                  ].map((row, idx) => (
                    <tr key={idx} className="bg-white">
                      <td className="py-4 px-6 text-[12px] font-medium text-[#171717]">{row.label}</td>
                      <td className="py-4 px-6 text-center">
                        <Circle size={8} fill={row.s ? "#171717" : "transparent"} className={row.s ? "inline-block text-[#171717]" : "inline-block text-[#E5E5E5]"} />
                      </td>
                      <td className="py-4 px-6 text-center">
                        <Circle size={8} fill={row.m ? "#171717" : "transparent"} className={row.m ? "inline-block text-[#171717]" : "inline-block text-[#E5E5E5]"} />
                      </td>
                      <td className="py-4 px-6 text-center">
                        <Circle size={8} fill={row.a ? "#171717" : "transparent"} className={row.a ? "inline-block text-[#171717]" : "inline-block text-[#E5E5E5]"} />
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>
        </div>

        {/* Right Column - Status */}
        <div className="flex flex-col gap-6">
          <div className="card-minimal overflow-hidden border-rose-100 bg-rose-50/5">
            <div className="border-b border-rose-100 px-6 py-4 bg-white/50 flex items-center gap-3">
              <AlertTriangle size={16} strokeWidth={1.5} className="text-rose-500" />
              <h3 className="text-[13px] font-semibold text-rose-600">Infrastructure Status</h3>
            </div>
            <div className="p-6 space-y-6">
              <p className="text-[12px] text-[#737373] leading-relaxed">
                Global maintenance switch. Activation restricts interaction for all non-administrative accounts across mobile and web interfaces.
              </p>
              
              <div className={`p-4 rounded-xl border transition-all ${maintenanceMode ? 'bg-rose-50/50 border-rose-200' : 'bg-[#FAFAFA] border-[#E5E5E5]'}`}>
                <div className="flex items-center justify-between mb-2">
                  <span className={`text-[12px] font-semibold ${maintenanceMode ? 'text-rose-600' : 'text-[#171717]'}`}>
                    Maintenance Protocol
                  </span>
                  <button 
                    onClick={() => setMaintenanceMode(!maintenanceMode)}
                    className={`relative w-9 h-5 rounded-full transition-colors flex items-center px-1 ${maintenanceMode ? 'bg-rose-500' : 'bg-[#D4D4D4]'}`}
                  >
                    <span className={`bg-white w-3.5 h-3.5 rounded-full transition-transform duration-200 shadow-sm ${maintenanceMode ? 'translate-x-3.5' : 'translate-x-0'}`}></span>
                  </button>
                </div>
                <p className="text-[11px] text-[#A3A3A3]">
                   Status: {maintenanceMode ? 'Active / restricted' : 'System nominal'}
                </p>
              </div>
            </div>
          </div>
        </div>

      </div>
    </div>
  );
};
