import { useState } from 'react';
import { 
  Landmark, 
  Globe, 
  ShieldCheck, 
  AlertTriangle,
  Save,
  RotateCcw
} from 'lucide-react';

export const Settings = () => {
  const [maintenanceMode, setMaintenanceMode] = useState(false);
  const [commissionRate, setCommissionRate] = useState('12.5');
  const [threshold, setThreshold] = useState('5000');
  const [currency, setCurrency] = useState('NPR');
  const [timezone, setTimezone] = useState('Asia/Kathmandu');

  return (
    <div className="flex-1 overflow-y-auto px-12 py-12 bg-[#F8FAFC]">
      <div className="flex items-center justify-between mb-10">
        <div>
          <h2 className="text-3xl font-bold text-[#0F172A] tracking-tight mb-2">System Settings</h2>
          <p className="text-[#64748B] text-sm font-medium">Manage global platform rules, regional settings, and access controls.</p>
        </div>
        <div className="flex gap-4">
          <button className="px-6 py-2.5 bg-white border border-[#E2E8F0] text-[#64748B] rounded-lg text-[13px] font-bold hover:bg-[#F8FAFC] transition-all shadow-sm flex items-center gap-2">
            <RotateCcw size={16} />
            Discard Changes
          </button>
          <button className="px-6 py-2.5 bg-[#2563EB] text-white rounded-lg text-[13px] font-bold hover:bg-blue-700 transition-all shadow-sm flex items-center gap-2">
            <Save size={16} />
            Save Configuration
          </button>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-8 pb-20">
        
        {/* Left Column - Main Settings */}
        <div className="lg:col-span-2 flex flex-col gap-8">
          
          {/* Financial Parameters */}
          <div className="card-pro overflow-hidden">
            <div className="border-b border-[#E2E8F0] px-6 py-5 bg-white flex items-center gap-3">
              <div className="w-8 h-8 rounded-lg bg-blue-50 flex items-center justify-center text-blue-600">
                <Landmark size={18} />
              </div>
              <h3 className="text-[16px] font-bold text-[#0F172A]">Platform Fees & Financials</h3>
            </div>
            <div className="p-6 grid grid-cols-2 gap-6 bg-white">
              <div>
                <label className="block text-[12px] font-bold text-[#64748B] mb-2 uppercase tracking-wide">Global Commission Rate (%)</label>
                <input 
                  type="number" 
                  value={commissionRate}
                  onChange={(e) => setCommissionRate(e.target.value)}
                  className="w-full bg-[#F8FAFC] border border-[#E2E8F0] text-[#0F172A] font-bold rounded-lg px-4 py-3 focus:outline-none focus:border-[#2563EB] transition-all"
                />
              </div>
              <div>
                <label className="block text-[12px] font-bold text-[#64748B] mb-2 uppercase tracking-wide">Min. Payout Threshold (NPR)</label>
                <input 
                  type="number" 
                  value={threshold}
                  onChange={(e) => setThreshold(e.target.value)}
                  className="w-full bg-[#F8FAFC] border border-[#E2E8F0] text-[#0F172A] font-bold rounded-lg px-4 py-3 focus:outline-none focus:border-[#2563EB] transition-all"
                />
              </div>
            </div>
          </div>

          {/* Regional Defaults */}
          <div className="card-pro overflow-hidden">
            <div className="border-b border-[#E2E8F0] px-6 py-5 bg-white flex items-center gap-3">
              <div className="w-8 h-8 rounded-lg bg-emerald-50 flex items-center justify-center text-emerald-600">
                <Globe size={18} />
              </div>
              <h3 className="text-[16px] font-bold text-[#0F172A]">Regional Defaults</h3>
            </div>
            <div className="p-6 grid grid-cols-2 gap-6 bg-white">
              <div>
                <label className="block text-[12px] font-bold text-[#64748B] mb-2 uppercase tracking-wide">Default Currency</label>
                <select 
                  value={currency}
                  onChange={(e) => setCurrency(e.target.value)}
                  className="w-full bg-[#F8FAFC] border border-[#E2E8F0] text-[#0F172A] font-bold rounded-lg px-4 py-3 focus:outline-none focus:border-[#2563EB] transition-all appearance-none"
                >
                  <option value="NPR">NPR - Nepalese Rupee</option>
                  <option value="USD">USD - US Dollar</option>
                  <option value="INR">INR - Indian Rupee</option>
                </select>
              </div>
              <div>
                <label className="block text-[12px] font-bold text-[#64748B] mb-2 uppercase tracking-wide">System Timezone</label>
                <select 
                  value={timezone}
                  onChange={(e) => setTimezone(e.target.value)}
                  className="w-full bg-[#F8FAFC] border border-[#E2E8F0] text-[#0F172A] font-bold rounded-lg px-4 py-3 focus:outline-none focus:border-[#2563EB] transition-all appearance-none"
                >
                  <option value="Asia/Kathmandu">Asia/Kathmandu (NPT)</option>
                  <option value="UTC">UTC Standard Time</option>
                </select>
              </div>
            </div>
          </div>

          {/* Role Permissions */}
          <div className="card-pro overflow-hidden">
            <div className="border-b border-[#E2E8F0] px-6 py-5 bg-white flex items-center justify-between">
              <div className="flex items-center gap-3">
                <div className="w-8 h-8 rounded-lg bg-orange-50 flex items-center justify-center text-orange-600">
                  <ShieldCheck size={18} />
                </div>
                <h3 className="text-[16px] font-bold text-[#0F172A]">Role Permissions (RBAC)</h3>
              </div>
              <button className="text-[12px] font-bold text-[#2563EB] hover:text-[#1E40AF]">Manage Roles</button>
            </div>
            <div className="bg-white">
              <table className="w-full text-left border-collapse">
                <thead className="bg-[#F8FAFC] border-b border-[#E2E8F0]">
                  <tr>
                    <th className="py-3 px-6 text-[11px] font-bold text-[#64748B] uppercase">Permission Level</th>
                    <th className="py-3 px-6 text-[11px] font-bold text-[#64748B] uppercase text-center">Support</th>
                    <th className="py-3 px-6 text-[11px] font-bold text-[#64748B] uppercase text-center">Manager</th>
                    <th className="py-3 px-6 text-[11px] font-bold text-[#64748B] uppercase text-center">Super Admin</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-[#E2E8F0]">
                  {[
                    { label: 'View User Data', s: true, m: true, a: true },
                    { label: 'Modify Financial Records', s: false, m: true, a: true },
                    { label: 'System Configuration', s: false, m: false, a: true },
                  ].map((row, idx) => (
                    <tr key={idx}>
                      <td className="py-4 px-6 text-[13px] font-semibold text-[#0F172A]">{row.label}</td>
                      <td className="py-4 px-6 text-center">
                        <span className={`inline-block w-4 h-4 rounded-full ${row.s ? 'bg-green-500' : 'bg-gray-200'}`}></span>
                      </td>
                      <td className="py-4 px-6 text-center">
                        <span className={`inline-block w-4 h-4 rounded-full ${row.m ? 'bg-green-500' : 'bg-gray-200'}`}></span>
                      </td>
                      <td className="py-4 px-6 text-center">
                        <span className={`inline-block w-4 h-4 rounded-full ${row.a ? 'bg-green-500' : 'bg-gray-200'}`}></span>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>
        </div>

        {/* Right Column - Status */}
        <div className="flex flex-col gap-8">
          <div className="card-pro overflow-hidden border-[#EF4444]/30">
            <div className="bg-[#FEF2F2] border-b border-[#EF4444]/20 px-6 py-5 flex items-center gap-3">
              <div className="w-8 h-8 rounded-lg bg-white flex items-center justify-center text-red-500 shadow-sm">
                <AlertTriangle size={18} />
              </div>
              <h3 className="text-[16px] font-bold text-red-600">System Status</h3>
            </div>
            <div className="p-6 bg-white space-y-6">
              <p className="text-[13px] font-medium text-[#64748B] leading-relaxed">
                Enable maintenance mode to temporarily restrict public access to the Khozna platform. Active admins will remain logged in.
              </p>
              
              <div className={`p-4 rounded-xl border transition-all ${maintenanceMode ? 'bg-red-50 border-red-200' : 'bg-[#F8FAFC] border-[#E2E8F0]'}`}>
                <div className="flex items-center justify-between mb-2">
                  <span className={`text-[13px] font-bold ${maintenanceMode ? 'text-red-700' : 'text-[#0F172A]'}`}>
                    Maintenance Mode
                  </span>
                  <button 
                    onClick={() => setMaintenanceMode(!maintenanceMode)}
                    className={`relative w-12 h-6 rounded-full transition-colors ${maintenanceMode ? 'bg-red-500' : 'bg-[#CBD5E1]'}`}
                  >
                    <span className={`absolute top-1 left-1 bg-white w-4 h-4 rounded-full transition-transform ${maintenanceMode ? 'translate-x-6' : 'translate-x-0'}`}></span>
                  </button>
                </div>
                <p className="text-[11px] font-medium text-[#64748B]">
                  {maintenanceMode ? 'Currently enabled. Users will see a maintenance page.' : 'Currently disabled. System operating normally.'}
                </p>
              </div>
            </div>
          </div>
        </div>

      </div>
    </div>
  );
};
