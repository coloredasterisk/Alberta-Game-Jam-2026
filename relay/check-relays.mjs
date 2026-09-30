// Shows whether each relay is up and how much of today's free allowance it has used.
//   npm run status                 (the relays below)
//   npm run status -- HOST [HOST]  (others)
// "OVER DAILY LIMIT" = Cloudflare answers 429 / error 1027: that account's 100,000 free requests
// for today are used up (resets 00:00 UTC). Games then move to the other relay by themselves.
const RELAYS = process.argv.slice(2).length ? process.argv.slice(2) : [
  "alberta-game-jam-relay.pvp-phone-relay.workers.dev",   // RELAY_MAIN   (account 1)
  "alberta-game-jam-relay.gamejam-relay.workers.dev",     // RELAY_BACKUP (account 2)
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
      line = "not deployed on this account (404) - run npm run deploy there";
    } else if (!res.ok) {
      line = `problem: HTTP ${res.status} ${text.slice(0, 120)}`;
    } else {
      const s = JSON.parse(text);
      const resets = `resets in ${Math.floor(s.resetsInSec / 3600)}h${String(Math.floor((s.resetsInSec % 3600) / 60)).padStart(2, "0")}m`;
      line = !s.ok
        ? `REFUSING ROOMS (Durable Objects: ${s.error ?? "unavailable"})`
        : s.used == null
          ? `up; usage unknown (needs the CF_API_TOKEN secret, see README "status and usage"); ${resets}`
          : `up; Workers ${pct(s.workers, s.limit)}, Durable Objects ${pct(s.durableObjects, s.limit)} of ${s.limit.toLocaleString()}/day; ${resets}${s.used >= 0.9 ? "  <- games now prefer the other relay" : ""}`;
    }
  } catch (e) {
    line = `no answer (${e.cause?.code ?? e.name})`;
  }
  console.log(`${host}\n  ${line}`);
}
