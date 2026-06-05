import { 
  Map as MapIcon, 
  Activity, 
  UserCheck, 
  Building2, 
  CreditCard,
  MessageSquare,
  BarChart3
} from 'lucide-react';

export const Journey = () => {
  return (
    <div className="flex-1 overflow-y-auto px-8 py-8 bg-[#FAFAFA]">
      <div className="mb-8">
        <h2 className="text-[22px] font-semibold text-[#171717] tracking-tight mb-1">User Journey Map</h2>
        <p className="text-[#737373] text-[13px]">Telemetry and conversion funnels for platform interaction flows.</p>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-4 gap-4 mb-8">
        {[
          { label: 'Onboarding', icon: <UserCheck size={16} strokeWidth={1.5} />, color: 'text-blue-500' },
          { label: 'Property Setup', icon: <Building2 size={16} strokeWidth={1.5} />, color: 'text-orange-500' },
          { label: 'First Payment', icon: <CreditCard size={16} strokeWidth={1.5} />, color: 'text-emerald-500' },
          { label: 'Support Contact', icon: <MessageSquare size={16} strokeWidth={1.5} />, color: 'text-rose-500' },
        ].map((item, idx) => (
          <div key={idx} className="card-minimal p-5">
            <div className="flex items-center justify-between mb-4">
              <span className="text-[#A3A3A3]">{item.icon}</span>
              <span className="text-[11px] font-medium text-[#A3A3A3] uppercase tracking-wider">{item.label}</span>
            </div>
            <p className="text-[14px] font-medium text-[#D4D4D4] italic">No data yet</p>
            <p className="text-[11px] text-[#A3A3A3] mt-2">Funnel data inactive</p>
          </div>
        ))}
      </div>

      <div className="card-minimal overflow-hidden">
        <div className="px-6 py-4 bg-white border-b border-[#E5E5E5] flex items-center justify-between">
          <h3 className="text-[13px] font-semibold text-[#171717] flex items-center gap-2">
            <Activity size={16} strokeWidth={1.5} className="text-[#171717]" /> Interaction Flows
          </h3>
          <select className="bg-[#FAFAFA] border border-[#E5E5E5] text-[12px] font-medium text-[#525252] rounded-lg py-1.5 px-3 outline-none focus:border-[#A3A3A3] transition-colors">
            <option>Host Persona</option>
            <option>Guest Persona</option>
          </select>
        </div>

        <div className="p-12 pl-20 relative before:absolute before:inset-0 before:ml-[72px] before:-translate-x-px md:before:mx-auto md:before:translate-x-0 before:h-full before:w-[1px] before:bg-[#E5E5E5]">
          {/* Node 1 */}
          <div className="relative flex items-center justify-between md:justify-normal md:odd:flex-row-reverse group mb-16">
            <div className="flex items-center justify-center w-9 h-9 rounded-full border border-[#E5E5E5] bg-white text-[#171717] shadow-sm shrink-0 md:order-1 md:group-odd:-translate-x-1/2 md:group-even:translate-x-1/2 z-10 transition-colors group-hover:border-[#A3A3A3]">
              <UserCheck size={16} strokeWidth={1.5} />
            </div>
            <div className="w-[calc(100%-4rem)] md:w-[calc(50%-3rem)] p-6 rounded-xl border border-[#E5E5E5] bg-white shadow-xs group-hover:border-[#D4D4D4] transition-all">
              <div className="flex items-center justify-between mb-2">
                <h4 className="font-semibold text-[#171717] text-[14px]">Profile & KYC Creation</h4>
                <span className="text-[10px] font-medium text-[#171717] bg-[#F5F5F5] px-2 py-0.5 rounded uppercase tracking-wider">Start</span>
              </div>
              <p className="text-[13px] text-[#737373] leading-relaxed">
                Initial entry point for all service providers. Conversion analytics will be updated upon telemetry integration.
              </p>
            </div>
          </div>
          
          {/* Node 2 */}
          <div className="relative flex items-center justify-between md:justify-normal md:odd:flex-row-reverse group mb-16">
            <div className="flex items-center justify-center w-9 h-9 rounded-full border border-[#E5E5E5] bg-white text-[#171717] shadow-sm shrink-0 md:order-1 md:group-odd:-translate-x-1/2 md:group-even:translate-x-1/2 z-10 transition-colors group-hover:border-[#A3A3A3]">
              <Building2 size={16} strokeWidth={1.5} />
            </div>
            <div className="w-[calc(100%-4rem)] md:w-[calc(50%-3rem)] p-6 rounded-xl border border-[#E5E5E5] bg-white shadow-xs group-hover:border-[#D4D4D4] transition-all">
              <div className="flex items-center justify-between mb-2">
                <h4 className="font-semibold text-[#171717] text-[14px]">Property Listing</h4>
              </div>
              <p className="text-[13px] text-[#737373] leading-relaxed">
                Verification of property details and listing publication.
              </p>
            </div>
          </div>

          {/* Node 3 */}
          <div className="relative flex items-center justify-between md:justify-normal md:odd:flex-row-reverse group">
            <div className="flex items-center justify-center w-9 h-9 rounded-full border border-[#E5E5E5] bg-white text-[#171717] shadow-sm shrink-0 md:order-1 md:group-odd:-translate-x-1/2 md:group-even:translate-x-1/2 z-10 transition-colors group-hover:border-[#A3A3A3]">
              <MapIcon size={16} strokeWidth={1.5} />
            </div>
            <div className="w-[calc(100%-4rem)] md:w-[calc(50%-3rem)] p-6 rounded-xl border border-[#E5E5E5] bg-white shadow-xs group-hover:border-[#D4D4D4] transition-all">
              <div className="flex items-center justify-between mb-2">
                <h4 className="font-semibold text-[#171717] text-[14px]">Marketplace Activation</h4>
                <span className="text-[10px] font-medium text-emerald-600 bg-emerald-50 px-2 py-0.5 rounded uppercase tracking-wider">Goal</span>
              </div>
              <p className="text-[13px] text-[#737373] leading-relaxed">
                Property becomes live and searchable for guests across the platform.
              </p>
            </div>
          </div>
        </div>
      </div>

      <div className="mt-8 p-6 bg-white border border-[#E5E5E5] rounded-xl flex items-center justify-between">
        <div className="flex items-center gap-4">
          <div className="w-10 h-10 bg-[#FAFAFA] rounded-lg border border-[#E5E5E5] flex items-center justify-center text-[#737373]">
            <BarChart3 size={20} strokeWidth={1.5} />
          </div>
          <div>
            <p className="text-[14px] font-semibold text-[#171717]">Telemetry Integration</p>
            <p className="text-[12px] text-[#737373]">Platform analytics hooks are in progress. Real data will sync once the segment pipeline is live.</p>
          </div>
        </div>
      </div>
    </div>
  );
};
