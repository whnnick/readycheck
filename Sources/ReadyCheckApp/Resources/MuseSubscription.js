// Read muse.ai's settings subscription action in its own authenticated WebKit context.
// No conversation, generation, key creation, payment or settings-mutation requests are made.
// Settings-action discovery adapted from CodexBar (MIT); see CodexBar-MIT.txt in this resource bundle.
if (location.origin !== "https://muse.ai") return JSON.stringify({error: "loginRequired"});
const deadline = new AbortController();
const timer = setTimeout(() => deadline.abort(), 25000);
let stage = "home";
try {
    const pathsIn = text => [...new Set((text.match(/static\/chunks\/[\w~.-]+\.js/g) || [])
        .map(path => "/_next/" + path))];
    const readChunk = async path => {
        if (!/^\/_next\/static\/chunks\/[\w~.-]+\.js$/.test(path)) return "";
        const r = await fetch(path, {credentials: "omit", signal: deadline.signal, redirect: "error"});
        const text = r.ok ? await r.text() : "";
        if (text.length > 2000000) throw Error("responseChanged");
        return text;
    };
    const actionFrom = text => /"([0-9a-f]{40,64})",[^"\n]{0,200}"fetchSubscriptionAction"/.exec(text)?.[1];
    const discover = async () => {
        stage = "home";
        // Client-side sign-in can leave the signed-out page's scripts in the live DOM.
        // Discover from the current session's fresh HTML, without exporting that HTML.
        const home = await fetch("/", {method: "GET", credentials: "same-origin", cache: "no-store",
            headers: {Accept: "text/html"}, signal: deadline.signal, redirect: "manual"});
        if (home.type === "opaqueredirect" || home.status === 401 || home.status === 403) throw Error("loginRequired");
        if (!home.ok) throw Error("network");
        const html = await home.text();
        if (html.length > 8000000) throw Error("responseChanged");
        const paths = pathsIn(html).slice(0, 96);
        stage = "discovery";
        let source = "";
        for (let i = 0; i < paths.length; i += 8) {
            source += "\n" + (await Promise.all(paths.slice(i, i + 8).map(readChunk))).join("\n");
            if (source.length > 8000000) throw Error("responseChanged");
            const direct = actionFrom(source);
            if (direct) return direct;
            const module = /\.A\((\d+)\)\.then\(\(\{[^}]*Settings/.exec(source)?.[1];
            const loader = module && new RegExp("[,{\\[]" + module + ",\\w+=>\\{\\w+\\.v\\(\\w+=>Promise\\.all\\(\\[([^\\]]*)").exec(source);
            if (!loader) continue;
            const settings = pathsIn(loader[1]).slice(0, 32);
            for (let j = 0; j < settings.length; j += 8) {
                const bodies = await Promise.all(settings.slice(j, j + 8).map(readChunk));
                for (const body of bodies) { const id = actionFrom(body); if (id) return id; }
            }
            break;
        }
        throw Error("responseChanged");
    };
    const post = async action => {
        stage = "subscription";
        if (!/^[0-9a-f]{40,64}$/.test(action)) throw Error("responseChanged");
        return fetch("/", {method: "POST", credentials: "same-origin", redirect: "error", signal: deadline.signal,
            headers: {Accept: "text/x-component", "Content-Type": "text/plain;charset=UTF-8", "Next-Action": action},
            body: JSON.stringify([{includeAgreement: true}])});
    };
    const hasCachedAction = /^[0-9a-f]{40,64}$/.test(cachedActionID || "");
    let action = hasCachedAction ? cachedActionID : await discover();
    let response = await post(action);
    if (response.status === 404 || (hasCachedAction && response.status >= 500)) {
        action = await discover();
        response = await post(action);
    }
    if (response.status === 401 || response.status === 403) return JSON.stringify({error: "loginRequired", stage});
    if (!response.ok) return JSON.stringify({error: response.status === 404 ? "responseChanged" : "network", stage});
    const body = await response.text();
    stage = "response";
    if (body.length > 524288) throw Error("responseChanged");
    // Only return the subscription payload; no page contents, cookies or other account responses leave WebKit.
    const rows = body.split("\n").filter(line => /^[0-9a-f]+:\{/.test(line)).map(line => {
        try { return JSON.parse(line.slice(line.indexOf(":") + 1)); } catch { return null; }
    }).filter(row => row?.success === true && row.subscription?.usage);
    if (rows.length !== 1) throw Error("responseChanged");
    const sub = rows[0].subscription;
    const filtered = {success: true, subscription: {tier: sub.tier && {name: sub.tier.name},
        usage: {percentUsed: sub.usage.percentUsed, resetsAt: sub.usage.resetsAt},
        usageRowValueLabel: sub.usageRowValueLabel, topupRowValueLabel: sub.topupRowValueLabel,
        agreement: sub.agreement && {currentPeriodEndTime: sub.agreement.currentPeriodEndTime}}};
    return JSON.stringify({actionID: action, flight: "1:" + JSON.stringify(filtered)});
} catch (error) {
    return JSON.stringify({error: deadline.signal.aborted ? "timedOut" : ["responseChanged", "loginRequired"].includes(error.message) ? error.message : "network", stage});
} finally { clearTimeout(timer); }
