# `.claude/task-queue.md` — config ต่อ repo

ไฟล์อยู่ที่ `<root>/.claude/task-queue.md` · `<root>` = `$(dirname "$(git rev-parse --path-format=absolute --git-common-dir)")` ได้ path เดียวกันทั้งจาก checkout หลักและ worktree · สร้างหรือตรวจด้วย `/setup-task-queue`

อ่านทั้งไฟล์ก่อนเริ่มทุกครั้ง · ไม่มีไฟล์ หรือไม่มีหัวข้อ `tracker` / `สถานะ` → หยุด แล้วบอกเจ้าของให้รัน `/setup-task-queue` · หัวข้ออื่นที่ไม่มี = ขั้นที่ใช้หัวข้อนั้นข้ามไป

**ไม่มี `budget-check`** (`command -v budget-check` ว่าง) → ข้ามทุกขั้นที่เรียก `budget-check`: เช็กโควตาถือว่าได้ `OK` · จดโควตา (`--log` / `--cost`) ไม่ทำ · `<acct>` ที่ไม่มีหัวข้อ `บัญชี` = `default` · เช็กครั้งเดียวต่อ session

ใต้หัวข้อเป็น markdown อิสระที่ agent อ่านแล้วทำตาม ไม่ใช่ shell ล้วน (บางขั้นคือ "เรียกสกิล /x")

| หัวข้อ | ความหมาย | ใช้โดย |
|---|---|---|
| `tracker` | `kind:` หนึ่งใน `notion` · `github-project` · `github-issues` ตามด้วยค่าเฉพาะ kind (ดู `trackers.md`) | ทุกสกิล |
| `สถานะ` | ชื่อจริงบนบอร์ดของสถานะ canonical 4 ตัว: `queued` (พร้อมให้ agent หยิบ) · `in-progress` · `in-review` (เปิด PR แล้ว) · `unclear` (ถามเจ้าของแล้วถอยออกจากคิว) · สำหรับ `github-issues` ค่าคือชื่อ label | ทุกสกิล |
| `บัญชี` | `acct:` ชื่อบัญชีของ `budget-check` · `CLAUDE_CONFIG_DIR` = `~/.claude` เมื่อ acct เป็น `default` นอกนั้น `~/.claude-<acct>` · ไม่มีหัวข้อ → `budget-check --pick` เลือกให้ตอนเริ่มรอบ (ไม่มี `budget-check` = `default`) | run · pick |
| `โมเดล` | rubric เลือกโมเดลของ Claude ที่ถือการ์ด: `default: <model id>` · `conflict: <model id>` สำหรับโหมดแก้ conflict · `โซนหนัก: <path หรือ glob คั่นด้วย ·>` ส่วนของ repo ที่แตะแล้วงานหนักขึ้น (schema · migration · กฎโดเมน · auth) · แล้วตามด้วยกฎ `- <เงื่อนไข> → <model id>` ข้อแรกที่ตรงชนะ เงื่อนไขอ้างได้ทั้งข้อมูลบนการ์ด (Type · Priority · AC · ชื่อ) และผล peek โค้ดของ run-task-queue (ไฟล์ที่แตะ · โซนหนัก · ไม่ชัด) · โหมดแก้รีวิวใช้โมเดลเดิมของการ์ดจาก `task.md` · ไม่มีหัวข้อ = ไม่ส่ง `--model` (ค่าตั้งของบัญชี) | run · pick |
| `ขีดจำกัด` | `PR เปิดค้าง:` N · run-task-queue หยุดหยิบการ์ดใหม่เมื่อ PR ที่คิวเปิดไว้ยังเปิดอยู่ครบ N (ไม่มีหัวข้อ = 3) | run |
| `ก่อนทุกรอบ` | สกิล/คำสั่งที่ run-task-queue รันก่อนข้ออื่นทุกรอบ | run |
| `merge` | เปิด merge อัตโนมัติ: run-task-queue merge PR ของการ์ด `in-review` ที่ผ่านทุกด่านเอง · `วิธี:` `merge` / `squash` / `rebase` (ไม่มี = `merge`) · `ด่าน:` ด่านเพิ่มของ repo เช่น check ที่ head ต้อง `SUCCESS` · `ไม่ auto:` path prefix คั่นด้วย `·` ที่ PR แตะแล้วเจ้าของต้อง merge เอง (migration · config deploy · ไฟล์กฎ · CI) · `ข้าม comment ของ:` login ของบอทที่ comment แล้วไม่นับว่ามีคนพูด · `หลัง merge:` เช็กหลัง merge · ไม่มีหัวข้อ = เจ้าของ merge เองทุกใบ | run |
| `branch` | pattern ชื่อ branch เช่น `slice/<n>-<ชื่อ>` (ไม่มี = `task/<n>-<ชื่อ>`) | pick |
| `setup` | สิ่งที่ทำหลังสร้าง worktree (ติดตั้ง · ก๊อปไฟล์ env · ของที่ต้องลบออกจาก env ของ worktree) | pick |
| `verify` | คำสั่งที่ต้องเขียวก่อนเปิด PR และหลังแก้ PR + กฎกันชนกับ checkout หลัก (พอร์ต · state · วิธีปิดของตัวเอง) | pick |
| `self-review` | วิธีรีวิวตัวเองก่อนส่งเจ้าของ | pick |
| `ci` | CI ที่ต้องเขียวก่อนย้ายเป็น in-review และหลังแก้ PR | pick |
| `กฎโค้ด` | กฎที่ Claude และ delegate ต้องรู้ตอนแตะโค้ด (ชี้ไฟล์กฎของ repo ได้) | pick |
| `delegate` | งานประเภทไหนส่งให้ agent ตัวไหน + rules ที่ต้องใส่ตอน start | pick |
| `หลัง PR` | สิ่งที่ทำหลังเปิด PR ก่อนย้ายการ์ดเป็น in-review (เช่น sync wiki) | pick |
