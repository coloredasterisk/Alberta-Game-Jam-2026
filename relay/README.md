# Relay (Cloudflare Workers)

Pairs a game with the devices joining it, by room code. A browser game can't run a server, so both
sides connect *out* to this relay. It's used for:

- **Phone controllers** with the browser build (GitHub Pages, itch.io), and any time the game calls
  `PhoneControllers.start("relay")`: phones open the controller page from the relay and send their
  input through it.
- **Online matches** (phone vs phone, any build): the guest's game joins the host's room just like a
  phone controller would. In browsers the relay also carries the WebRTC offer/answer so the two phones
  can open a direct link; if that fails, input and game state keep flowing through the relay.

```
game / match host ──────► /ws/host/CODE ─┐
                                         ├─ Room CODE (Durable Object) forwards messages both ways
phone / match guest ────► /ws/phone/CODE ┘
phone opens               /?r=CODE        ── the controller page the game uploaded for room CODE
                                             (or the built-in copy in public/, see below)
```

Deployed twice, on two Cloudflare accounts (each has its own free daily allowance). Both addresses are
constants in `phone_controller/phone_control_server.gd`:

| Constant | Address |
|---|---|
| `RELAY_MAIN` | `https://alberta-game-jam-relay.pvp-phone-relay.workers.dev` |
| `RELAY_BACKUP` | `https://alberta-game-jam-relay.gamejam-relay.workers.dev` |

The game chooses between them by itself (`RELAYS` in that file, most preferred first), so one account
running out of its free allowance doesn't stop anyone playing. Deploy code changes to **both** (see
"Deploy / update").

## Automatic relay choice and failover

- **New session** (lobby opens): the game asks every relay's `/status` at once (a few seconds at most)
  and uses the first in `RELAYS` order that answers and is below `RELAY_SWITCH_AT` (90 %) of today's
  allowance. If all are above it, the one with the most left. A relay over its Workers limit answers 429
  (error 1027) without running any code, so it simply doesn't count as answering.
- **Mid-session**: if the game's relay connection fails twice in a row without opening the room, it moves
  to the next relay in `RELAYS` **with the same room code**. Phones get the other relays in the QR code
  (`&alt=…`) and try them in turn when theirs stops answering. An online guest does the same with
  `PhoneControllers.get_relay_candidates()`. Everyone finds the room again, usually within a few seconds,
  and keeps their player slot.
- **Joining by code**: a guest (or phone) told "no game with this code" asks the other relays before
  giving up, because the host may be on a different one.
- If every relay is down, retries keep backing off (up to 30 s), so a game left open doesn't burn
  requests.

Forcing one relay (next section) turns the automatic choice off; phones and guests still have the others
as fallbacks.

## Forcing a relay

Normally not needed (see above). To pin the game to one relay, set one of these (`_relay_override()` in
`phone_control_server.gd`); the first one set wins:

| Where | How | Needs a rebuild? |
|---|---|---|
| Web build | add `?relay=HOST` to the game's address, e.g. `https://coloredasterisk.github.io/Alberta-Game-Jam-2026/?relay=alberta-game-jam-relay.OTHER.workers.dev` | No; remove it to go back |
| Desktop / editor | environment variable `PHONE_RELAY_URL=HOST` before starting Godot or the game | No |
| Any build | Project Setting `phone_controllers/relay_url` (or an `override.cfg` next to the game) | Editor: no. Exports: re-export |
| Order of preference | the `RELAYS` list in `phone_control_server.gd` | Yes |

`HOST` can be a bare host name or a full `wss://…` URL. Phones follow automatically (the QR code points
at the relay in use), and invite links carry `&relay=…` when it isn't the default, so a friend's game
joins the same relay.

To run a relay on a **second Cloudflare account** without logging out of the first, give wrangler a
separate credentials folder (PowerShell):

```powershell
$env:XDG_CONFIG_HOME = "C:\path\to\wrangler-account2"   # any folder; keep it out of git
npx wrangler login        # sign in with the other account
npm run deploy            # prints https://pvp-phone-relay.<that account's subdomain>.workers.dev
```

Without `XDG_CONFIG_HOME` set, wrangler uses the original login again. Each Cloudflare account has its own
free daily allowance.

## Which controller page phones get

When the game opens a room it uploads its own `phone_controller/controller.html`
(`{"t":"_page","html":…}` over its WebSocket, see `upload_page_to_relay` in
`phone_control_server.gd`), and the relay serves that page at `/?r=CODE` with `Cache-Control: no-store`.
So:

- **Edit `controller.html`, restart the game (re-export builds), and phones get the new page.** No relay
  redeploy needed.
- One relay can serve many different games, each with its own controller page.
- `public/index.html` (copied from `../phone_controller/controller.html` by `npm run deploy`) is only a
  fallback for games that don't upload a page (older versions of `phone_control_server.gd`).

## Deploy / update

Needs Node.js and a (free) Cloudflare account. Only needed when `src/index.js` or `wrangler.jsonc`
change, or to set up your own relay.

```bash
cd relay
npm install
npx wrangler login     # once; approve in the browser
npm run deploy         # copies the fallback phone page into public/ and deploys
```

That deploys to the account wrangler is logged in to (`RELAY_MAIN`). For `RELAY_BACKUP`, which is on the
second account, point wrangler at that account's login folder first (PowerShell; the folder is the one
used when logging in to that account, see "Switching to another relay"):

```powershell
$env:XDG_CONFIG_HOME = "C:\path\to\wrangler-account2"; npm run deploy
Remove-Item Env:XDG_CONFIG_HOME      # back to the main account
```

**Your own relay for another game:** change `"name"` in `wrangler.jsonc` first (e.g. `"my-game-relay"`),
deploy, and set `DEFAULT_RELAY_URL` to the `wss://…workers.dev` address it prints. Deploying with an
existing name to the same Cloudflare account **replaces** that relay.

Local testing: `npm run dev` serves the relay on http://127.0.0.1:8787. Point the game at it with an
`override.cfg` in the project root (don't commit it):

```ini
[phone_controllers]
mode="relay"
relay_url="ws://127.0.0.1:8787"
```

## Is a relay over its limit? (status and usage)

From the `relay` folder:

```bash
npm run status
```

```
alberta-game-jam-relay.pvp-phone-relay.workers.dev
  up; Workers 12,408 (12%), Durable Objects 71,230 (71%) of 100,000/day; resets in 5h12m
alberta-game-jam-relay.gamejam-relay.workers.dev
  OVER DAILY LIMIT (429 / error 1027) - games use the other relay until 00:00 UTC
```

It reads each relay's `GET /status`, which the games use too:

```json
{"ok": true, "used": 0.71, "workers": 12408, "durableObjects": 71230, "limit": 100000, "resetsInSec": 18720}
```

- `ok: false` means the relay runs but can't open rooms (usually its Durable Object allowance is used up).
- No answer, or 429, means the Workers allowance is used up (or the relay is down).
- **`used` needs a read-only analytics token** on each account, otherwise it's `null` and a relay only
  counts as full once it stops answering. Per account (both, once):
  1. Cloudflare dashboard → My Profile → API Tokens → Create Token → Custom token, permission
     **Account · Account Analytics · Read**, that account only.
  2. From `relay/` (for the backup account, with `XDG_CONFIG_HOME` set as in "Deploy / update"):
     ```bash
     npx wrangler secret put CF_API_TOKEN     # paste the token
     npx wrangler secret put CF_ACCOUNT_ID    # the account ID from `npx wrangler whoami`
     ```
  The numbers come from Cloudflare's analytics, which lag a few minutes; the relay caches them for 2.

## Costs and the free plan's daily limit

The free plan allows, per Cloudflare account, **100,000 Worker requests a day** and **100,000 Durable
Object requests a day** (both reset at 00:00 UTC). Every page load and every WebSocket connect is a
Worker request. Messages over an open connection aren't Worker requests, but every room is a Durable
Object and **messages arriving at it count as Durable Object requests (20 messages = 1 request)**, so
the relay's traffic, not only connects, uses up that allowance. Phones only send when the input changes;
an online match over the relay (no direct WebRTC link) sends the guest's input and the host's 30 Hz
snapshots through it, a few requests a second. When the Workers limit is hit, *everything* on the relay
answers **429 / Cloudflare error 1027** ("temporarily rate limited") until the reset; when the Durable
Object limit is hit, rooms stop working. Either way the games move to the other relay (see above).

To stay well under it, every client backs off when the other side is gone:

| Client | Retries | Gives up |
|---|---|---|
| Phone controller page | 0.5 s growing to 4 s, then to 30 s after a minute; paused while the page is hidden | after 10 minutes (shows the Join button) |
| Online guest (`OnlineGuest`) | 1 s growing to 15 s | after 2 minutes (the menu shows why) |
| Game / match host (`PhoneControllers`) | 2 s growing to 30 s | never (the lobby shows the status) |

Still, close controller pages and game tabs you're not using. For heavy use, the Workers Paid plan
(10 million requests a month) removes the problem. Each room is also a Durable Object, which has its own
free allowance; see Cloudflare's current pricing page for exact limits.

## Notes

- Rooms are 4-character codes chosen by the game; if one is taken the game picks another. The match code
  players type is this room code.
- If the game disconnects, phones see "Waiting for the game…" (an online guest shows *reconnecting*) and
  rejoin automatically, in the same player slot, when it reconnects with the same code. The room keeps its
  uploaded page meanwhile.
- Up to 8 devices per room. Forwarded messages over 4096 characters are dropped (game messages and WebRTC
  offers are well under that); an uploaded page can be up to 512 KB.
- Latency is roughly your network's ping to Cloudflare; unstable Wi-Fi shows up as stutter.

## This repo's relay folder

`wrangler.jsonc` here is named `alberta-game-jam-relay`, so `npm run deploy` from this folder creates or
updates this game's own relay on whichever Cloudflare account wrangler is logged in to. It doesn't touch
`pvp-phone-relay` (the PvP game's relay on the same accounts). Deploy it to **both** accounts; the
addresses become `alberta-game-jam-relay.<account subdomain>.workers.dev`, which is what `RELAY_MAIN`
and `RELAY_BACKUP` in `phone_controller/phone_control_server.gd` point at. Both games still share each
account's daily allowance.
