# ReadyCheck 0.5.0 — Reminders you control. Records you can inspect.

[中文](RELEASE_NOTES.zh-CN.md) · [Black-box checks](QA.md) · [65-feature retention](RELEASE_AUDIT.md)

- **Choose when expiry reminders arrive.** Select72/48/24/12 hours in Settings → Reminders. Existing handled milestones, independent switches and account authorization stay intact; missed nodes coalesce instead of generating a burst.
- **See what happened to a card.** Overview and Settings share card-use and check records. Inspect prepared requests, known server outcomes and separate notification status. A card missing from the available list stays unconfirmed; it is not labeled successfully used.
- **Keep confirmed receipts.** A failed follow-up quota refresh no longer discards a confirmed redemption outcome. Protected open-file access and persistent check diagnostics improve continuity without weakening file protection. Repeated check warnings are coalesced.
- **Understand the current reading.** Data status and usage pace explain continuous observation time, valid records and interruptions. An unreadable authorization shows Unconfirmed, not a misleading Off switch.

Both quotas, account benefits/reset counts, expiry dates, Token statistics, reminder history, the Widget’s last-hour chart, pinning/dragging, click-only notch and About remain. New automatic use stays opt-in; existing consent is retained. Earliest qualifying expiry, exact-card final-hour checks, stable retries and confirmed-success notices remain in place.

## Verification and limits

Development validation:398 full Swift tests plus final scoped/native checks, real reading, same-binary cold start and measured lock/unlock checks. Release-source tests, packages and downloads are recorded separately in [QA](QA.md); development evidence does not prove publication.

No real reset card was consumed for acceptance. A historical overnight card outcome remains unresolved; the new records do not retroactively establish who used it or whether it expired. Request preparation is not proof that bytes were sent. Notification submission is distinct from a visible banner. The app must run with usable account access and network; sleep, quitting or restrictions can still prevent timely use.

Mac additions only; Windows retains its existing interface. Apple-silicon macOS14+ self-signed preview, **not Developer ID signed or notarized**. A new binary can still require system Keychain approval; no prompt-free upgrade claim. Existing second-account, external-display/Spaces, full accessibility and Windows-device limits remain documented.
