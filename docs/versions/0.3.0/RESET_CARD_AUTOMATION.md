# Expiring reset cards: automatic use

[中文](RESET_CARD_AUTOMATION.zh-CN.md) · [Plan](PLAN.md) · [Checks](QA.md) · [Version index](../../VERSIONS.md)

2026-10-20, local0.3.0-dev.4. Requirement R7: use an earned reset card in its final hour without losing the existing expiry reminders. This is independent from quota-pace estimates and low/recovery notifications.

## User flow

Settings → Reminders → “Use reset cards one hour before expiry”. Off by default. Enabling shows an explicit confirmation that authorizes only the current account, regardless of remaining quota. Redemption cannot be undone; the service decides which eligible windows the card resets. Disabling prevents later requests but cannot recall one already sent. No purchased credits are used or bought.

While the app is running, its own60-second task checks even with every product window closed; wake also triggers a check. Execution happens at the first successful check within `(expiry−1h, expiry)`, including exactly1h remaining. It is not a cloud scheduler and cannot guarantee timing during quit, sleep, offline/auth failures or unsupported-client periods. Expired cards are never submitted. The Settings card displays the latest result and its time; existing expiry notifications remain unchanged.

## Execution and persistence

Use the documented [Codex app-server earned-reset RPC](https://learn.chatgpt.com/docs/app-server#8-earned-rate-limit-resets-chatgpt). Local CLI0.162.1's generated schema includes explicit `creditId`, caller `idempotencyKey` and four outcomes. No speculative HTTP mutation endpoint or UI auto-clicking is used.

Preflight reads fresh account/card data, requires an exact account match and available `codexRateLimits` card with a unique nonempty ID and verified future expiry within1 hour. Only the earliest eligible card is selected. Save its ID, expiry and UUID before sending; storage failure blocks redemption. Retry the same card/key after an unknown transport outcome, including across restart; never fall back to unspecified-card selection. If that pending card disappears/expires, record verification required and pause other cards until its original expiry. Duplicate checks are serialized; disabling while preflight is in flight revokes a permit synchronized with writing the irreversible RPC. Confirmation captures the account identity; a later account change invalidates it.

`reset` and `alreadyRedeemed` are confirmed success; `nothingToReset` and `noCredit` are distinct non-success states. A no-eligible-window response keeps the same logical request for a later check. Fetch rate limits after the consume response and refresh the product; do not invent new windows locally.

Standalone sign-in uses the existing Keychain/token refresh lifecycle and experimental external-token login in a private temporary Codex home. ReadyCheck sends token material only through stdin, never argv, and does not write a token file itself. The private Codex home is removed after the child exits. The native Codex login/configuration is not replaced. Local mode uses the currently signed-in Codex account, verified again before dispatch. No new Hook/notify integration or task-stop/resume behavior is introduced.

## Acceptance boundary

Deterministic policy, process-protocol and model/UI tests use fake accounts/cards only. No real card is consumed during development acceptance. A real redemption/result remains unverified until a user-authorized eligible event; schema presence and simulated success do not prove that account's server will accept it. Unsupported/auth failures remain visible and fail closed. Windows receives version metadata only.


## Independent expiry reminder switch (0.3.0-dev.3)

Settings → Reminders groups two controls in one reset-card section, in this order:

1. **Reset-card expiry reminders**: On by default, preserving old behavior for files without the new preference. Shows72/48/24/12-hour rules. Turning it off suppresses future expiry notifications, while retaining known expirations, notification history and deduplication. Delivered notifications are not withdrawn. Re-enabling considers the nearest currently eligible unhandled threshold on a later valid refresh; it does not burst missed thresholds or repeat delivered ones.
2. **Use reset cards one hour before expiry**: Remains independently Off by default, with account-specific irreversible-use confirmation. Disabling expiry reminders does not disable or authorize automatic redemption.

Low-quota/recovery/Credits reminders are unaffected. The preference lives in the existing reminder store, with a revision so an older delivery batch cannot restore its old value. Delivery checks again after awaiting notification permissions; an unsent event skipped because the user disabled it is not recorded as a failed delivery. Requires the app running and system notification permission, as before.

## Confirmed-use notification (0.3.0-dev.4)

After a new automatic-use request receives `reset` or `alreadyRedeemed`, save an account-owned pending success notice with the same durable request identity. Send “Reset card used automatically”, including the card’s original expiry time, without exposing account or request identifiers. No success notice is generated for pending/unknown, expired, `nothingToReset` or `noCredit` outcomes. Older development receipts without pending-notice state are not replayed.

Success notices are independent of the expiry/recovery switches and have no additional toggle. Enabling automatic use checks notification permission. If delivery fails or permission is denied, preserve the pending notice and record the failed notification attempt; retry at the next running-app check without redeeming a card again. Turning automatic use off stops future redemption requests but does not suppress an already-confirmed spend receipt. Account ownership still applies.

Notification Center verification and a saved history record acknowledge the notice. A stable notification identifier and delivered-history lookup prevent repeat delivery across checks/restarts; the durable acknowledgement remains after history pruning. As with other notifications, a crash between OS delivery and acknowledgement cannot provide a transactional exactly-once guarantee. Notification Center presence does not prove a visible banner; system settings and Focus apply. The native status and notification-history entry remain available.
