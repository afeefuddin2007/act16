# ICA16 Class A: Test Log

Record one row per test. Do not write passwords or tokens here.

Columns: ID | Precondition | Action | Expected | Observed | Pass/Fail | Evidence ref (screenshot/log name) | Timestamp | Commit | Round ID suffix (last 6)

## Required for everyone (Class A)

| ID  | Action | Required observation |
|-----|--------|----------------------|
| T01 | Valid and invalid sign-in | Correct UID or visible auth error; no secret logging. |
| T02 | Load the exact Class A URL | 10 valid easy category-9 multiple-choice questions. |
| T03 | Inject bad JSON, nonzero API code, and nine results (temporarily edit the parser input or use a test stub) | Each case blocks play and offers retry. |
| T04 | Answer correctly, incorrectly, and double-tap an answer | Readable decoded text; stable choices; one score change. |
| T05 | Finish and replay | 10 review entries; accurate total; new round ID; state reset. |
| T06 | Submit online; double-tap Submit | One cloud document; server timestamp; matching server-only read. |
| T07 | Restart app while online; sign in as same user | Original attempt is retrieved; quiz is not replayed. |
| T08 | Go offline before submit; reconnect | No false success; reconcile and recover with same ID. |
| T09 | Set fault to `lostAck` (DEV ONLY) and submit | Shows saveUnknown; "Check server" resolves via server read; still one document. |
| T10 | As user B, read/write user A's path (Firestore console or a dev-only test) | Both denied by deployed rules. |
| T11 | Try score 11, an extra field, and an update | All three rejected; original attempt unchanged. |
| T12 | Set fault to `unavailable`, then `exhausted` | Distinct visible errors; bounded retry; no fake success. Label injections. |

## Graduate only (also run T01-T12)

| ID  | Action | Required observation |
|-----|--------|----------------------|
| G01 | Two signed-in clients submit the same round ID and payload at once (two devices or two runs) | Exactly one document in the deployed console. |
| G02 | Reuse an ID with a different score | Collision reported; original preserved. |
| G03 | Inject a stale response after switching users | Old response cannot update the new user's UI. |

## Log template

| ID | Precondition | Action | Expected | Observed | Pass/Fail | Evidence ref | Timestamp | Commit | Round suffix |
|----|--------------|--------|----------|----------|-----------|--------------|-----------|--------|--------------|
| T01 |  |  |  |  |  |  |  |  |  |
| T02 |  |  |  |  |  |  |  |  |  |
| T03 |  |  |  |  |  |  |  |  |  |
| T04 |  |  |  |  |  |  |  |  |  |
| T05 |  |  |  |  |  |  |  |  |  |
| T06 |  |  |  |  |  |  |  |  |  |
| T07 |  |  |  |  |  |  |  |  |  |
| T08 |  |  |  |  |  |  |  |  |  |
| T09 |  |  |  |  |  |  |  |  |  |
| T10 |  |  |  |  |  |  |  |  |  |
| T11 |  |  |  |  |  |  |  |  |  |
| T12 |  |  |  |  |  |  |  |  |  |
