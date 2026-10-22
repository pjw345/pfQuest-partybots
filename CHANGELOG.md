# Changelog

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
