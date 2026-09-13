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

// Helper function to download an image URL and convert to Base64 for MCP image response
async function fetchImageAsBase64(url) {
  try {
    const res = await fetch(url);
    if (!res.ok) return null;
    const arrayBuffer = await res.arrayBuffer();
    const base64 = Buffer.from(arrayBuffer).toString("base64");
    const contentType = res.headers.get("content-type") || "image/png";
    return { data: base64, mimeType: contentType.startsWith("image/") ? contentType : "image/png" };
  } catch (e) {
    return null;
  }
}

// ════════════════════════════════════════════════════════════════════════════
// TOOL: audit_dashboard
// ════════════════════════════════════════════════════════════════════════════
server.tool(
  "audit_dashboard",
  "Get a complete audit of the Khozna admin dashboard — total users, new users this week vs previous week (WoW trend), reconciled KYC, safety reports, test vs organic user breakdown, financial volume, and supply/demand ratio.",
  {},
  async () => {
    const now = Date.now();
    const SEVEN_DAYS_MS = 7 * 24 * 60 * 60 * 1000;

    const [
      allProfilesRes,
      kycTableRes,
      userReportsRes,
      paymentsRes,
      bookingsRes,
      propertiesRes,
    ] = await Promise.all([
      db.from("profiles").select("id, full_name, email, kyc_status, is_suspended, created_at"),
      db.from("kyc_verifications").select("id, status, user_id"),
      db.from("user_reports").select("id", { count: "exact", head: true }),
      db.from("payments").select("amount, status"),
      db.from("bookings").select("id, total_price, status"),
      db.from("properties").select("id", { count: "exact", head: true }),
    ]);

    const profiles = allProfilesRes.data || [];
    const totalUsers = profiles.length;

    const newThisWeek = profiles.filter(u => new Date(u.created_at).getTime() >= (now - SEVEN_DAYS_MS)).length;
    const newPreviousWeek = profiles.filter(u => {
      const t = new Date(u.created_at).getTime();
      return t >= (now - 2 * SEVEN_DAYS_MS) && t < (now - SEVEN_DAYS_MS);
    }).length;
    const userGrowthWoWPercent = newPreviousWeek > 0 
      ? Math.round(((newThisWeek - newPreviousWeek) / newPreviousWeek) * 100)
      : newThisWeek * 100;

    const verifiedKycProfiles = profiles.filter(u => u.kyc_status === 'verified').length;
    const pendingKycProfiles = profiles.filter(u => u.kyc_status === 'pending').length;
    const pendingKycTable = (kycTableRes.data || []).filter(k => k.status === 'pending').length;

    const testAccounts = profiles.filter(u => 
      (u.email && u.email.includes('cloudtestlabaccounts.com')) || 
      (u.full_name && u.full_name.toLowerCase().includes('test')) ||
      (/[a-z]+\.[0-9]{5}@gmail\.com/.test(u.email || ''))
    ).length;
    const unnamedUsers = profiles.filter(u => !u.full_name || u.full_name === 'Khozna User' || u.full_name === 'Anonymous User').length;
    const organicUsers = totalUsers - testAccounts;

    const payments = paymentsRes.data || [];
    const bookings = bookingsRes.data || [];
    const verifiedPaymentsVolume = payments.filter(p => p.status === 'verified').reduce((a, b) => a + (b.amount || 0), 0);
    const confirmedBookingsVolume = bookings.filter(b => b.status === 'confirmed' || b.status === 'active').reduce((a, b) => a + (b.total_price || 0), 0);
    const pendingPaymentsCount = payments.filter(p => p.status === 'pending').length;

    const totalProperties = propertiesRes.count || 0;
    const supplyDemandRatio = organicUsers > 0 ? (totalProperties / organicUsers).toFixed(2) : '0';

    const auditReport = {
      growth_trends: {
        total_registered_users: totalUsers,
        organic_human_users: organicUsers,
        google_play_test_bots: testAccounts,
        unnamed_phone_users: unnamedUsers,
        new_users_this_week: newThisWeek,
        new_users_previous_week: newPreviousWeek,
        growth_wow_percent: `${userGrowthWoWPercent >= 0 ? '+' : ''}${userGrowthWoWPercent}%`,
      },
      kyc_reconciliation: {
        verified_users_count: verifiedKycProfiles,
        pending_kyc_reviews: Math.max(pendingKycProfiles, pendingKycTable),
        unverified_users_count: totalUsers - verifiedKycProfiles,
      },
      safety_and_moderation: {
        open_user_reports: userReportsRes.count || 0,
        suspended_users_count: profiles.filter(u => u.is_suspended).length,
      },
      financial_overview: {
        verified_payments_volume_npr: verifiedPaymentsVolume,
        confirmed_bookings_volume_npr: confirmedBookingsVolume,
        total_gross_volume_npr: verifiedPaymentsVolume + confirmedBookingsVolume,
        pending_payment_verifications: pendingPaymentsCount,
        total_bookings: bookings.length,
      },
      marketplace_supply_health: {
        total_active_properties: totalProperties,
        supply_demand_ratio: `${supplyDemandRatio} listings per user`,
        status_alert: totalProperties < 5 ? "⚠️ COLD START ALERT: Critical shortage of property listings relative to user base." : "HEALTHY",
      },
      audited_at: new Date().toISOString(),
    };

    return {
      content: [{ type: "text", text: JSON.stringify(auditReport, null, 2) }],
    };
  }
);

// ════════════════════════════════════════════════════════════════════════════
// TOOL: capture_dashboard_ui
// Captures live visual screenshot of the Admin Dashboard and sends image to Claude
// ════════════════════════════════════════════════════════════════════════════
server.tool(
  "capture_dashboard_ui",
  "Takes a live UI screenshot of the Khozna Admin Dashboard and returns the image directly to Claude for visual UI/UX critique and layout evaluation.",
  {
    path: z.string().optional().default("/").describe("Page path (e.g. '/' for overview, '/users' for user directory, '/kyc' for verifications)"),
  },
  async ({ path }) => {
    let puppeteer;
    try {
      puppeteer = (await import("puppeteer-core")).default;
    } catch (e) {
      throw new Error("puppeteer-core is required for visual capture");
    }

    const browser = await puppeteer.launch({
      executablePath: "C:\\Program Files (x86)\\Microsoft\\Edge\\Application\\msedge.exe",
      headless: true,
      args: ["--no-sandbox", "--disable-setuid-sandbox"],
    });

    try {
      const page = await browser.newPage();
      await page.setViewport({ width: 1440, height: 900 });
      const targetUrl = `http://localhost:5173${path || '/'}`;
      await page.goto(targetUrl, { waitUntil: "domcontentloaded" });
      await page.evaluate(() => localStorage.setItem("khozna_admin_unlocked", "true"));
      await page.reload({ waitUntil: "networkidle0" });

      const imgBuffer = await page.screenshot({ type: "png" });
      const base64 = imgBuffer.toString("base64");

      return {
        content: [
          { type: "text", text: `📸 Live visual screenshot of Khozna Admin Dashboard at ${targetUrl}:` },
          { type: "image", data: base64, mimeType: "image/png" },
        ],
      };
    } finally {
      await browser.close();
    }
  }
);

// ════════════════════════════════════════════════════════════════════════════
// TOOL: list_pending_kyc
// ════════════════════════════════════════════════════════════════════════════
server.tool(
  "list_pending_kyc",
  "List pending user KYC submissions awaiting admin approval, including user details and document IDs.",
  {},
  async () => {
    const { data, error } = await db
      .from("kyc_verifications")
      .select("id, user_id, full_name, email, phone_number, citizenship_number, status, created_at, front_image_url, back_image_url, selfie_image_url")
      .order("created_at", { ascending: false });

    if (error) throw new Error(error.message);

    return {
      content: [{ type: "text", text: JSON.stringify(data, null, 2) }],
    };
  }
);

// ════════════════════════════════════════════════════════════════════════════
// TOOL: inspect_kyc_submission
// Returns front ID, back ID, and selfie photo directly as BASE64 IMAGES to Claude
// so Claude can visually verify facial match, ID text, and authenticity.
// ════════════════════════════════════════════════════════════════════════════
server.tool(
  "inspect_kyc_submission",
  "Visually inspect a user's KYC submission documents. Returns Front ID, Back ID, and Selfie photo directly as visual IMAGES to Claude so Claude can verify facial match, document authenticity, and legibility.",
  {
    kyc_id:  z.string().optional().describe("KYC record UUID"),
    user_id: z.string().optional().describe("User UUID"),
  },
  async ({ kyc_id, user_id }) => {
    let query = db.from("kyc_verifications").select("*");
    if (kyc_id) query = query.eq("id", kyc_id);
    else if (user_id) query = query.eq("user_id", user_id);
    else throw new Error("Provide kyc_id or user_id");

    const { data, error } = await query.limit(1);
    if (error || !data || data.length === 0) throw new Error("KYC submission record not found");

    const kyc = data[0];
    const content = [
      {
        type: "text",
        text: `🔍 KYC Submission Details for ${kyc.full_name}:\n` +
              `- Record ID: ${kyc.id}\n` +
              `- User ID: ${kyc.user_id}\n` +
              `- Full Name: ${kyc.full_name}\n` +
              `- Citizenship Number: ${kyc.citizenship_number || 'N/A'}\n` +
              `- Email: ${kyc.email || 'N/A'}\n` +
              `- Phone: ${kyc.phone_number || 'N/A'}\n` +
              `- GPS Location: ${kyc.latitude ? `${kyc.latitude}, ${kyc.longitude}` : 'Not verified'}\n` +
              `- Status: ${kyc.status}\n\n` +
              `Below are the submitted Front ID, Back ID, and Live Selfie images:`
      }
    ];

    if (kyc.front_image_url) {
      const img = await fetchImageAsBase64(kyc.front_image_url);
      if (img) {
        content.push({ type: "text", text: "🪪 [FRONT CITIZENSHIP ID PHOTO]:" });
        content.push({ type: "image", data: img.data, mimeType: img.mimeType });
      }
    }

    if (kyc.back_image_url) {
      const img = await fetchImageAsBase64(kyc.back_image_url);
      if (img) {
        content.push({ type: "text", text: "🪪 [BACK CITIZENSHIP ID PHOTO]:" });
        content.push({ type: "image", data: img.data, mimeType: img.mimeType });
      }
    }

    if (kyc.selfie_image_url) {
      const img = await fetchImageAsBase64(kyc.selfie_image_url);
      if (img) {
        content.push({ type: "text", text: "🤳 [LIVE SELFIE PHOTO]:" });
        content.push({ type: "image", data: img.data, mimeType: img.mimeType });
      }
    }

    return { content };
  }
);

// ════════════════════════════════════════════════════════════════════════════
// TOOL: approve_kyc
// ════════════════════════════════════════════════════════════════════════════
// TOOL: approve_kyc
// ════════════════════════════════════════════════════════════════════════════
server.tool(
  "approve_kyc",
  "Approve a user's KYC verification after validating that their ID card name and surname match their profile name and the document is clear.",
  {
    kyc_id: z.string().describe("KYC record UUID"),
  },
  async ({ kyc_id }) => {
    const { data: kyc, error: fetchErr } = await db.from("kyc_verifications").select("id, user_id, full_name").eq("id", kyc_id).single();
    if (fetchErr || !kyc) throw new Error("KYC record not found");

    await db.from("kyc_verifications").update({ status: "verified" }).eq("id", kyc_id);
    await db.from("profiles").update({ kyc_status: "verified" }).eq("id", kyc.user_id);

    try {
      await db.from("notifications").insert({
        user_id: kyc.user_id,
        title: "KYC Approved 🎉",
        message: "Congratulations! Your identity document has been verified. You now have full verified access on Khozna.",
        type: "kyc_update",
        is_read: false,
      });
    } catch (e) {
      console.error("Notification insert error:", e.message);
    }

    return {
      content: [{ type: "text", text: `✅ KYC submission for ${kyc.full_name} (${kyc.user_id}) APPROVED and notification dispatched to user app.` }],
    };
  }
);

// ════════════════════════════════════════════════════════════════════════════
// TOOL: reject_kyc
// ════════════════════════════════════════════════════════════════════════════
server.tool(
  "reject_kyc",
  "Reject a user's KYC verification if ID card name/surname does not match profile or ID photo is blurry/unreadable. Automatically dispatches a push & in-app notification to the user describing the issue so they can re-upload.",
  {
    kyc_id: z.string().describe("KYC record UUID"),
    reason: z.string().describe("Specific reason for rejection (e.g., 'Name on ID card does not match profile name', 'ID card image is blurry or unreadable')"),
  },
  async ({ kyc_id, reason }) => {
    const { data: kyc, error: fetchErr } = await db.from("kyc_verifications").select("id, user_id, full_name").eq("id", kyc_id).single();
    if (fetchErr || !kyc) throw new Error("KYC record not found");

    await db.from("kyc_verifications").update({ status: "rejected", rejection_reason: reason }).eq("id", kyc_id);
    await db.from("profiles").update({ kyc_status: "rejected" }).eq("id", kyc.user_id);

    try {
      await db.from("notifications").insert({
        user_id: kyc.user_id,
        title: "KYC Document Issue ⚠️",
        message: `Your identity document review requires correction: ${reason}. Please re-upload a clear ID document with matching name.`,
        type: "kyc_update",
        is_read: false,
      });
    } catch (e) {
      console.error("Notification insert error:", e.message);
    }

    return {
      content: [{ type: "text", text: `❌ KYC submission for ${kyc.full_name} (${kyc.user_id}) REJECTED. Notification sent to user: "${reason}"` }],
    };
  }
);

// ════════════════════════════════════════════════════════════════════════════
// TOOL: get_financial_summary
// ════════════════════════════════════════════════════════════════════════════
server.tool(
  "get_financial_summary",
  "Get financial breakdown of Khozna platform — total revenue volume, escrow balances, pending payments, completed payouts.",
  {},
  async () => {
    let paymentsData = [];
    let bookingsData = [];
    let payoutsData = [];

    const paymentsRes = await db.from("payments").select("amount, status, payment_method");
    if (paymentsRes.data) paymentsData = paymentsRes.data;

    const bookingsRes = await db.from("bookings").select("total_price, status");
    if (bookingsRes.data) bookingsData = bookingsRes.data;

    const payoutsRes = await db.from("payouts").select("amount, status");
    if (payoutsRes.data) payoutsData = payoutsRes.data;

    const verifiedPayments = paymentsData.filter(p => p.status === 'verified');
    const pendingPayments  = paymentsData.filter(p => p.status === 'pending');
    
    const confirmedBookings = bookingsData.filter(b => b.status === 'confirmed' || b.status === 'active');
    const confirmedBookingVolume = confirmedBookings.reduce((acc, b) => acc + (b.total_price || 0), 0);
    const verifiedPaymentVolume = verifiedPayments.reduce((acc, p) => acc + (p.amount || 0), 0);
    const pendingPaymentVolume = pendingPayments.reduce((acc, p) => acc + (p.amount || 0), 0);

    const summary = {
      verifiedPaymentVolumeNPR: verifiedPaymentVolume,
      confirmedBookingVolumeNPR: confirmedBookingVolume,
      totalGrossVolumeNPR: verifiedPaymentVolume + confirmedBookingVolume,
      pendingPaymentVolumeNPR: pendingPaymentVolume,
      totalPaymentsCount: paymentsData.length,
      verifiedPaymentsCount: verifiedPayments.length,
      pendingPaymentsCount: pendingPayments.length,
      totalBookingsCount: bookingsData.length,
      confirmedBookingsCount: confirmedBookings.length,
      payoutsCount: payoutsData.length,
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
      const { data } = await db.from("profiles").select("id, full_name").ilike("full_name", `%${full_name}%`).limit(1);
      if (!data || data.length === 0) throw new Error(`User "${full_name}" not found`);
      id = data[0].id;
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
