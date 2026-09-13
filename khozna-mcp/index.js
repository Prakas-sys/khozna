import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import { createClient } from "@supabase/supabase-js";
import { z } from "zod";

// ─── Supabase Setup (service role — full admin access) ──────────────────────
const SUPABASE_URL = "https://qjpeablwokiuhfaopdbi.supabase.co";
const SERVICE_KEY  = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFqcGVhYmx3b2tpdWhmYW9wZGJpIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3MTU2OTEyOCwiZXhwIjoyMDg3MTQ1MTI4fQ.ZyV6x5yvPaKxITcpOeBVHsbefVirDem5qrRiruYQnN8";

const db = createClient(SUPABASE_URL, SERVICE_KEY, {
  auth: { autoRefreshToken: false, persistSession: false },
});

// ─── MCP Server ─────────────────────────────────────────────────────────────
const server = new McpServer({
  name: "khozna-admin",
  version: "1.0.0",
});

// ════════════════════════════════════════════════════════════════════════════
// TOOL: audit_dashboard
// Claude can call this to get a full overview and audit the dashboard
// ════════════════════════════════════════════════════════════════════════════
server.tool(
  "audit_dashboard",
  "Get a complete audit of the Khozna admin dashboard — total users, new users this week, pending KYC, reports, suspended users, bookings, payments. Use this to review and rate the platform health.",
  {},
  async () => {
    const now = new Date();
    const weekAgo = new Date(now - 7 * 24 * 60 * 60 * 1000).toISOString();

    const [
      totalUsers, newUsers, suspendedUsers,
      pendingKyc, verifiedKyc,
      openReports,
      pendingPayments,
      totalBookings, activeBookings,
      totalProperties,
    ] = await Promise.all([
      db.from("profiles").select("*", { count: "exact", head: true }),
      db.from("profiles").select("*", { count: "exact", head: true }).gte("created_at", weekAgo),
      db.from("profiles").select("*", { count: "exact", head: true }).eq("is_suspended", true),
      db.from("kyc_verifications").select("*", { count: "exact", head: true }).eq("status", "pending"),
      db.from("kyc_verifications").select("*", { count: "exact", head: true }).eq("status", "approved"),
      db.from("user_reports").select("*", { count: "exact", head: true }),
      db.from("payments").select("*", { count: "exact", head: true }).eq("status", "pending"),
      db.from("bookings").select("*", { count: "exact", head: true }),
      db.from("bookings").select("*", { count: "exact", head: true }).eq("status", "active"),
      db.from("properties").select("*", { count: "exact", head: true }),
    ]);

    const summary = {
      users: {
        total: totalUsers.count ?? 0,
        newThisWeek: newUsers.count ?? 0,
        suspended: suspendedUsers.count ?? 0,
      },
      kyc: {
        pending: pendingKyc.count ?? 0,
        verified: verifiedKyc.count ?? 0,
      },
      safety: {
        openReports: openReports.count ?? 0,
      },
      payments: {
        pending: pendingPayments.count ?? 0,
      },
      bookings: {
        total: totalBookings.count ?? 0,
        active: activeBookings.count ?? 0,
      },
      properties: {
        total: totalProperties.count ?? 0,
      },
      generatedAt: now.toISOString(),
    };

    return {
      content: [{ type: "text", text: JSON.stringify(summary, null, 2) }],
    };
  }
);

// ════════════════════════════════════════════════════════════════════════════
// TOOL: list_users
// ════════════════════════════════════════════════════════════════════════════
server.tool(
  "list_users",
  "List users on the Khozna platform. Can filter by name, suspended status, or KYC status.",
  {
    search:    z.string().optional().describe("Search by name or phone"),
    suspended: z.boolean().optional().describe("Filter suspended users only"),
    kyc_status: z.enum(["verified", "pending", "rejected", "none"]).optional(),
    limit:     z.number().optional().default(20),
  },
  async ({ search, suspended, kyc_status, limit }) => {
    let query = db.from("profiles").select("id, full_name, email, phone_number, kyc_status, is_suspended, is_owner, created_at").order("created_at", { ascending: false }).limit(limit ?? 20);

    if (search)    query = query.or(`full_name.ilike.%${search}%,phone_number.ilike.%${search}%`);
    if (suspended !== undefined) query = query.eq("is_suspended", suspended);
    if (kyc_status) query = query.eq("kyc_status", kyc_status);

    const { data, error } = await query;
    if (error) throw new Error(error.message);

    return {
      content: [{ type: "text", text: JSON.stringify(data, null, 2) }],
    };
  }
);

// ════════════════════════════════════════════════════════════════════════════
// TOOL: suspend_user
// ════════════════════════════════════════════════════════════════════════════
server.tool(
  "suspend_user",
  "Suspend or unsuspend a user by their ID or full name.",
  {
    user_id:   z.string().optional().describe("User UUID"),
    full_name: z.string().optional().describe("User full name to look up"),
    suspend:   z.boolean().default(true).describe("true = suspend, false = unsuspend"),
  },
  async ({ user_id, full_name, suspend }) => {
    let id = user_id;

    if (!id && full_name) {
      const { data } = await db.from("profiles").select("id, full_name").ilike("full_name", `%${full_name}%`).limit(1).single();
      if (!data) throw new Error(`User "${full_name}" not found`);
      id = data.id;
    }

    if (!id) throw new Error("Provide user_id or full_name");

    const { error } = await db.from("profiles").update({ is_suspended: suspend }).eq("id", id);
    if (error) throw new Error(error.message);

    return {
      content: [{ type: "text", text: `✅ User ${id} has been ${suspend ? "suspended" : "unsuspended"} successfully.` }],
    };
  }
);

// ════════════════════════════════════════════════════════════════════════════
// TOOL: delete_user
// ════════════════════════════════════════════════════════════════════════════
server.tool(
  "delete_user",
  "Permanently delete a user account and all their data from Khozna.",
  {
    user_id:   z.string().optional().describe("User UUID"),
    full_name: z.string().optional().describe("User full name to look up"),
  },
  async ({ user_id, full_name }) => {
    let id = user_id;

    if (!id && full_name) {
      const { data } = await db.from("profiles").select("id, full_name").ilike("full_name", `%${full_name}%`).limit(1);
      if (!data || data.length === 0) throw new Error(`User "${full_name}" not found`);
      id = data[0].id;
    }

    if (!id) throw new Error("Provide user_id or full_name");

    // Delete in strict dependency order (FK constraints)
    try { await db.from("payments").delete().eq("payer_id", id); } catch (e) {}
    try { await db.from("payouts").delete().eq("owner_id", id); } catch (e) {}
    try { await db.from("user_reports").delete().or(`reporter_id.eq.${id},reported_user_id.eq.${id}`); } catch (e) {}
    try { await db.from("kyc_verifications").delete().eq("user_id", id); } catch (e) {}
    try { await db.from("notifications").delete().eq("user_id", id); } catch (e) {}
    try { await db.from("saved_properties").delete().eq("user_id", id); } catch (e) {}
    try { await db.from("bookings").delete().or(`guest_id.eq.${id},owner_id.eq.${id}`); } catch (e) {}
    try { await db.from("properties").delete().eq("owner_id", id); } catch (e) {}
    
    const { error: profileErr } = await db.from("profiles").delete().eq("id", id);
    if (profileErr) console.error("Profile delete error:", profileErr.message);

    // Delete auth user from Supabase Auth schema
    const { error: authErr } = await db.auth.admin.deleteUser(id);
    if (authErr) console.error("Auth delete error:", authErr.message);

    return {
      content: [{ type: "text", text: `🗑️ User ${id} (${full_name || 'id'}) and all associated records deleted.` }],
    };
  }
);

// ════════════════════════════════════════════════════════════════════════════
// TOOL: list_reports
// ════════════════════════════════════════════════════════════════════════════
server.tool(
  "list_reports",
  "List all open safety reports on the platform.",
  {},
  async () => {
    const { data, error } = await db
      .from("user_reports")
      .select(`*, reported:profiles!reported_user_id(full_name, email), reporter:profiles!reporter_id(full_name)`)
      .order("created_at", { ascending: false });

    if (error) throw new Error(error.message);

    return {
      content: [{ type: "text", text: JSON.stringify(data, null, 2) }],
    };
  }
);

// ════════════════════════════════════════════════════════════════════════════
// TOOL: resolve_report
// ════════════════════════════════════════════════════════════════════════════
server.tool(
  "resolve_report",
  "Resolve (dismiss) a safety report, optionally suspending the reported user.",
  {
    report_id:      z.string().describe("Report UUID"),
    suspend_user:   z.boolean().default(false).describe("Also suspend the reported user?"),
  },
  async ({ report_id, suspend_user }) => {
    const { data: report, error: fetchErr } = await db
      .from("user_reports")
      .select("*, reported_user_id")
      .eq("id", report_id)
      .single();

    if (fetchErr || !report) throw new Error("Report not found");

    if (suspend_user && report.reported_user_id) {
      await db.from("profiles").update({ is_suspended: true }).eq("id", report.reported_user_id);
    }

    const { error } = await db.from("user_reports").delete().eq("id", report_id);
    if (error) throw new Error(error.message);

    return {
      content: [{
        type: "text",
        text: `✅ Report resolved.${suspend_user ? " Reported user has been suspended." : ""}`,
      }],
    };
  }
);

// ════════════════════════════════════════════════════════════════════════════
// TOOL: list_properties
// ════════════════════════════════════════════════════════════════════════════
server.tool(
  "list_properties",
  "List all property listings on Khozna.",
  {
    search: z.string().optional().describe("Search by title or area"),
    limit:  z.number().optional().default(20),
  },
  async ({ search, limit }) => {
    let query = db
      .from("properties")
      .select("id, title, area_name, price, category, status, created_at, profiles:owner_id(full_name)")
      .order("created_at", { ascending: false })
      .limit(limit ?? 20);

    if (search) query = query.or(`title.ilike.%${search}%,area_name.ilike.%${search}%`);

    const { data, error } = await query;
    if (error) throw new Error(error.message);

    return {
      content: [{ type: "text", text: JSON.stringify(data, null, 2) }],
    };
  }
);

// ════════════════════════════════════════════════════════════════════════════
// FINANCIAL TOOLS
// ════════════════════════════════════════════════════════════════════════════

server.tool(
  "get_financial_summary",
  "Get financial breakdown of Khozna platform — total revenue volume, escrow balances, pending payments, completed payouts.",
  {},
  async () => {
    const [payments, payouts, bookings] = await Promise.all([
      db.from("payments").select("amount, status, payment_method"),
      db.from("payouts").select("amount, status").catch(() => ({ data: [] })),
      db.from("bookings").select("total_price, status"),
    ]);

    const verifiedPayments = (payments.data || []).filter(p => p.status === 'verified');
    const pendingPayments  = (payments.data || []).filter(p => p.status === 'pending');
    
    const totalVolume = verifiedPayments.reduce((acc, p) => acc + (p.amount || 0), 0);
    const pendingVolume = pendingPayments.reduce((acc, p) => acc + (p.amount || 0), 0);

    const summary = {
      totalVerifiedVolumeNPR: totalVolume,
      pendingPaymentVolumeNPR: pendingVolume,
      totalPaymentsCount: payments.data?.length ?? 0,
      verifiedCount: verifiedPayments.length,
      pendingCount: pendingPayments.length,
      totalBookingsCount: bookings.data?.length ?? 0,
    };

    return {
      content: [{ type: "text", text: JSON.stringify(summary, null, 2) }],
    };
  }
);

server.tool(
  "list_payments",
  "List payment transactions submitted by tenants/guests.",
  {
    status: z.enum(["pending", "verified", "rejected", "all"]).optional().default("all"),
    limit:  z.number().optional().default(20),
  },
  async ({ status, limit }) => {
    let query = db
      .from("payments")
      .select("*, bookings(total_price, status, properties(title), guest:profiles!bookings_guest_id_fkey(full_name))")
      .order("created_at", { ascending: false })
      .limit(limit ?? 20);

    if (status && status !== "all") {
      query = query.eq("status", status);
    }

    const { data, error } = await query;
    if (error) throw new Error(error.message);

    return {
      content: [{ type: "text", text: JSON.stringify(data, null, 2) }],
    };
  }
);

server.tool(
  "verify_payment",
  "Verify and confirm a guest payment transaction.",
  {
    payment_id: z.string().describe("Payment UUID or booking ID"),
  },
  async ({ payment_id }) => {
    if (!payment_id.startsWith('b_')) {
      await db.from("payments").update({ status: "verified" }).eq("id", payment_id);
    }
    const cleanBookingId = payment_id.replace('b_', '');
    const { error } = await db.from("bookings").update({ status: "confirmed" }).eq("id", cleanBookingId);
    if (error) throw new Error(error.message);

    return {
      content: [{ type: "text", text: `✅ Payment ${payment_id} verified and booking confirmed successfully.` }],
    };
  }
);

server.tool(
  "reject_payment",
  "Reject a guest payment transaction with a reason.",
  {
    payment_id: z.string().describe("Payment UUID or booking ID"),
    reason:     z.string().describe("Rejection reason for the tenant"),
  },
  async ({ payment_id, reason }) => {
    if (!payment_id.startsWith('b_')) {
      await db.from("payments").update({ status: "rejected" }).eq("id", payment_id);
    }
    const cleanBookingId = payment_id.replace('b_', '');
    const { error } = await db.from("bookings").update({
      status: "rejected",
      rejection_reason: reason,
    }).eq("id", cleanBookingId);

    if (error) throw new Error(error.message);

    return {
      content: [{ type: "text", text: `❌ Payment ${payment_id} rejected. Reason: ${reason}` }],
    };
  }
);

// ─── Start ───────────────────────────────────────────────────────────────────
const transport = new StdioServerTransport();
await server.connect(transport);
console.error("🏠 Khozna Admin MCP Server running...");
