def stamp:
  [splits("\n") | select(test("\\(head `[0-9a-f]{7,40}`\\)") and test("รอเจ้าของตัดสิน [0-9]+ ข้อ"))][-1]
  | if . == null then null
    else {sha: capture("\\(head `(?<s>[0-9a-f]{7,40})`\\)").s, n: (capture("รอเจ้าของตัดสิน (?<n>[0-9]+) ข้อ").n | tonumber)}
    end;

.headRefOid as $head
| ($ARGS.named.inline // []) as $inline
| ($ARGS.named.deny // []) as $deny
| ($ARGS.named.skip // []) as $skip
| [.comments[] | (.body | stamp) as $s | select($s) | $s + {t: .createdAt}] as $stamps
| ([(.body | stamp | .n // 0)] + [$stamps[].n] | max) as $pending
| ($stamps[0].t // null) as $first
| [
    (if .state != "OPEN" then "1 state \(.state)" else empty end),
    (if .isDraft then "1 draft" else empty end),
    (if .mergeStateStatus != "CLEAN" then "2 mergeStateStatus \(.mergeStateStatus)" else empty end),
    (.reviews | group_by(.author.login)[]
      | map(select(.state == "APPROVED" or .state == "CHANGES_REQUESTED")) | last
      | select(. != null and .state == "CHANGES_REQUESTED")
      | "3 CHANGES_REQUESTED จาก \(.author.login)"),
    (if $first == null then "4 ไม่มีตราใน comment"
     elif ($head | startswith($stamps[-1].sha) | not) then "4 ตราล่าสุดชี้ \($stamps[-1].sha) ไม่ใช่ head \($head[0:7])"
     else empty end),
    (if $pending > 0 then "4 เคยมีเรื่องรอเจ้าของตัดสิน \($pending) ข้อ" else empty end),
    (if $first == null then empty else
      ((.comments[] | select(.createdAt > $first and (.body | stamp) == null) | {k: "comment", by: .author.login, t: .createdAt}),
       (.reviews[] | select(.submittedAt > $first) | {k: "review", by: .author.login, t: .submittedAt}),
       ($inline[] | select(.created_at > $first) | {k: "inline comment", by: .user.login, t: .created_at}))
      | select(.by as $b | $skip | index($b) | not)
      | "5 \(.k) จาก \(.by) หลังตราแรก (\(.t))"
     end),
    (if (.files | length) >= 100 then "6 ไฟล์ ≥ 100 ตรวจ path ไม่ครบ" else empty end),
    (.files[].path as $p | ([".claude/task-queue.md"] + $deny)[] as $d | select($p | startswith($d)) | "6 แตะ \($p)")
  ] as $fail
| {
    number,
    head: $head,
    ready: ($fail | length == 0),
    fail: $fail,
    checks: [.statusCheckRollup[] | {name: (.context // .name), state: (.state // .conclusion)}]
  }
