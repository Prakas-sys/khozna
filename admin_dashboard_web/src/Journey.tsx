import { 
  Map as MapIcon, 
  Activity, 
  UserCheck, 
  Building2, 
  CreditCard,
  MessageSquare
} from 'lucide-react';

export const Journey = () => {
  return (
    <div className="flex-1 overflow-y-auto px-12 py-12 bg-[#F8FAFC]">
      <div className="flex items-center justify-between mb-10">
        <div>
          <h2 className="text-3xl font-bold text-[#0F172A] tracking-tight mb-2">User Journey Map</h2>
          <p className="text-[#64748B] text-sm font-medium">Trace common paths, drop-offs, and critical interactions across the platform.</p>
        </div>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-4 gap-6 mb-8">
        <div className="card-pro p-6 bg-blue-50/50">
          <div className="flex items-center justify-between mb-2">
            <span className="text-[12px] font-bold text-[#2563EB] uppercase">Onboarding</span>
            <UserCheck size={16} className="text-[#2563EB]" />
          </div>
          <p className="text-2xl font-black text-[#0F172A]">82%</p>
          <p className="text-[11px] font-medium text-[#64748B] mt-1">Completion rate</p>
        </div>
        <div className="card-pro p-6">
          <div className="flex items-center justify-between mb-2">
            <span className="text-[12px] font-bold text-[#0F172A] uppercase">Property Setup</span>
            <Building2 size={16} className="text-[#64748B]" />
          </div>
          <p className="text-2xl font-black text-[#0F172A]">45%</p>
          <p className="text-[11px] font-medium text-[#64748B] mt-1">Drop-off at photos</p>
        </div>
        <div className="card-pro p-6">
          <div className="flex items-center justify-between mb-2">
            <span className="text-[12px] font-bold text-[#0F172A] uppercase">First Payment</span>
            <CreditCard size={16} className="text-[#64748B]" />
          </div>
          <p className="text-2xl font-black text-[#0F172A]">91%</p>
          <p className="text-[11px] font-medium text-[#64748B] mt-1">Gateway success rate</p>
        </div>
        <div className="card-pro p-6">
          <div className="flex items-center justify-between mb-2">
            <span className="text-[12px] font-bold text-[#0F172A] uppercase">Support Contact</span>
            <MessageSquare size={16} className="text-[#64748B]" />
          </div>
          <p className="text-2xl font-black text-[#0F172A]">4.2%</p>
          <p className="text-[11px] font-medium text-[#64748B] mt-1">Ticket generation rate</p>
        </div>
      </div>

      <div className="card-pro overflow-hidden">
        <div className="px-6 py-4 bg-white border-b border-[#E2E8F0] flex items-center justify-between">
          <h3 className="text-[14px] font-bold text-[#0F172A] flex items-center gap-2">
            <Activity size={16} className="text-[#2563EB]" /> User Interaction Flows
          </h3>
          <select className="bg-[#F8FAFC] border border-[#E2E8F0] text-[12px] font-semibold text-[#0F172A] rounded-md py-1.5 px-3 outline-none focus:border-[#2563EB]">
            <option>Host Persona</option>
            <option>Guest Persona</option>
          </select>
        </div>

        <div className="p-12 pl-20 relative before:absolute before:inset-0 before:ml-[72px] before:-translate-x-px md:before:mx-auto md:before:translate-x-0 before:h-full before:w-1 before:bg-gradient-to-b before:from-[#2563EB] before:via-[#60A5FA] before:to-[#BFDBFE]">
          {/* Node 1 */}
          <div className="relative flex items-center justify-between md:justify-normal md:odd:flex-row-reverse group mb-16">
            <div className="flex items-center justify-center w-10 h-10 rounded-full border-4 border-white bg-[#2563EB] text-white shadow shrink-0 md:order-1 md:group-odd:-translate-x-1/2 md:group-even:translate-x-1/2 z-10">
              <UserCheck size={16} />
            </div>
            <div className="w-[calc(100%-4rem)] md:w-[calc(50%-3rem)] p-6 rounded-xl border border-[#E2E8F0] bg-white shadow-sm">
              <div className="flex items-center justify-between mb-2">
                <h4 className="font-black text-[#0F172A] text-[14px]">Profile & KYC Creation</h4>
                <span className="text-[11px] font-bold text-[#2563EB] bg-blue-50 px-2 py-0.5 rounded">Start</span>
              </div>
              <p className="text-[13px] text-[#64748B] leading-relaxed">
                Avg time spent: 3m 42s. Most drop-offs occur at the document upload step. Re-engagement email sent after 2 hours.
              </p>
            </div>
          </div>
          
          {/* Node 2 */}
          <div className="relative flex items-center justify-between md:justify-normal md:odd:flex-row-reverse group mb-16">
            <div className="flex items-center justify-center w-10 h-10 rounded-full border-4 border-white bg-[#3B82F6] text-white shadow shrink-0 md:order-1 md:group-odd:-translate-x-1/2 md:group-even:translate-x-1/2 z-10">
              <Building2 size={16} />
            </div>
            <div className="w-[calc(100%-4rem)] md:w-[calc(50%-3rem)] p-6 rounded-xl border border-[#E2E8F0] bg-white shadow-sm">
              <div className="flex items-center justify-between mb-2">
                <h4 className="font-black text-[#0F172A] text-[14px]">Property Listing</h4>
              </div>
              <p className="text-[13px] text-[#64748B] leading-relaxed">
                45% abandonment at the high-res photo requirement. Consider adding a "skip for now" button.
              </p>
            </div>
          </div>

          {/* Node 3 */}
          <div className="relative flex items-center justify-between md:justify-normal md:odd:flex-row-reverse group">
            <div className="flex items-center justify-center w-10 h-10 rounded-full border-4 border-white bg-[#93C5FD] text-white shadow shrink-0 md:order-1 md:group-odd:-translate-x-1/2 md:group-even:translate-x-1/2 z-10">
              <MapIcon size={16} />
            </div>
            <div className="w-[calc(100%-4rem)] md:w-[calc(50%-3rem)] p-6 rounded-xl border border-[#E2E8F0] bg-white shadow-sm">
              <div className="flex items-center justify-between mb-2">
                <h4 className="font-black text-[#0F172A] text-[14px]">Going Live</h4>
                <span className="text-[11px] font-bold text-[#059669] bg-[#ECFDF5] px-2 py-0.5 rounded">Success Goal</span>
              </div>
              <p className="text-[13px] text-[#64748B] leading-relaxed">
                Property becomes visible on the map. Conversion rate from start to live is currently 38%.
              </p>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};
