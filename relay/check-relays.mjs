// Shows whether each relay is up and how much of today's free allowance it has used.
//   npm run status                 (the relays below)
//   npm run status -- HOST [HOST]  (others)
// "OVER DAILY LIMIT" = Cloudflare answers 429 / error 1027: that account's 100,000 free requests
// for today are used up (resets 00:00 UTC). Games then move to the other relay by themselves.
const RELAYS = process.argv.slice(2).length ? process.argv.slice(2) : [
  "pvp-phone-relay.pvp-phone-relay.workers.dev",   // RELAY_MAIN   (account 1)
  "pvp-phone-relay.gamejam-relay.workers.dev",     // RELAY_BACKUP (account 2)
];

const pct = (n, limit) => `${n.toLocaleString()} (${Math.round((100 * n) / limit)}%)`;

for (const host of RELAYS) {
  const base = `https://${host.replace(/^(wss?|https?):\/\//, "").replace(/\/$/, "")}`;
  let line;
  try {
    const res = await fetch(`${base}/status`, { signal: AbortSignal.timeout(8000) });
    const text = await res.text();
    if (res.status === 429 || text.includes("1027")) {
      line = "OVER DAILY LIMIT (429 / error 1027) - games use the other relay until 00:00 UTC";
    } else if (res.status === 404) {
      line = "up (old relay code without /status: run npm run deploy on this account)";
    } else if (!res.ok) {
      line = `problem: HTTP ${res.status} ${text.slice(0, 120)}`;
    } else {
      const s = JSON.parse(text);
      const resets = `resets in ${Math.floor(s.resetsInSec / 3600)}h${String(Math.floor((s.resetsInSec % 3600) / 60)).padStart(2, "0")}m`;
      line = !s.ok
        ? `REFUSING ROOMS (Durable Objects: ${s.error ?? "unavailable"})`
        : s.used == null
          ? `up; usage unknown (add CF_ACCOUNT_ID + CF_API_TOKEN secrets, see README); ${resets}`
          : `up; Workers ${pct(s.workers, s.limit)}, Durable Objects ${pct(s.durableObjects, s.limit)} of ${s.limit.toLocaleString()}/day; ${resets}${s.used >= 0.9 ? "  <- games now prefer the other relay" : ""}`;
    }
  } catch (e) {
    line = `no answer (${e.cause?.code ?? e.name})`;
  }
  console.log(`${host}\n  ${line}`);
}
