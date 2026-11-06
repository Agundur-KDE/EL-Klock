# EL-Klock

Parent rules in /home/alec/projects/AGENTS.md apply.

- Use the supplied KDE Plasma template. Collect reusable template findings in docs/template-improvements.md; upstream changes are a separate later task.
- For new behavior and bug fixes, write and observe a failing behavioral test before implementation, then verify green. Do not describe the initial implementation as TDD: its parser/alarm tests were added afterwards. The 61-second timing correction was developed red/green.
- Import production logic in tests; do not copy the implementation into test fixtures.
- EL time: one game minute takes 61 real seconds; one day has 6 game hours. Regular Mercator samples remain authoritative. See README for sources and failure behavior.
- Treat zero-filled payloads as invalid. Invasion reports have independent timestamps and can remain in the feed long after they are relevant.
- Special Day notifications must honor the user's per-day checkbox selection. Preserve original English game names, matching without case sensitivity.
- The first release uses public endpoints only. Personal-token messaging is a possible later feature, requiring secure token storage such as KWallet.
- Do not publish or push automatically. Keep the template remote named template.
