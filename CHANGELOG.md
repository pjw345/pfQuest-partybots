# Changelog

## 1.0.4 - 2026-10-22 (preview)

- Show localized quest objective instructions above bot progress in party quest
  popups, both under the tracker and in the full comparison.
- Use the exact quest ID for the current chain stage, preserving per-bot counts
  and ready/stale states even when local instruction text is unavailable.
- Client-only change; no server rebuild required.

## 1.0.3 - 2026-10-22 (preview)

- Include every party journal quest missing from pfQuest's visible tracker rows,
  including bot-only quests and personal quests filtered by the native tracker.
- Replace the four-quest cutoff with six-row pages and a visible total.
- Keep click-expanded progress per quest across paging and snapshot refreshes.
- Include the extra rows in tracker bounds without accumulating height.
- Preserve distinct quest IDs and fix overlapping final comparison pages.
- Client-only UI change; no server rebuild required.

## 1.0.2 - 2026-10-22 (preview)

- Show compact bot rows inside each clicked/expanded quest instead of permanently.
- Preserve pfQuest's initial expansion setting and native quest click shortcuts.
- Collapse bot-only footer progress until its quest title is clicked.
- Keep hover details and the Party comparison available.
- Client-only UI change; no server rebuild required.

## 1.0.1 - 2026-10-22 (preview)

- Send colon-delimited requests so the 1.12 chat escape validator accepts them.
- Add a send-validator regression and cover request size, ID limits and party/raid sends.
- Requires matching server parser support; build 2151c15b does not accept the new request envelope.
- Reply format, snapshot cache and quest UI remain unchanged.

## 1.0.0 - 2026-10-21 (preview)

- Publish the companion AddOn independently from the server repository.
- Show per-bot pfQuest progress, objective tooltips and a party comparison.
- Require owner-authorized `PFQBOT` version-1 server snapshots.
- Include standalone client tests, native packet fixture and packaged download.
- Live client transport, graphics and gameplay acceptance remain pending.
