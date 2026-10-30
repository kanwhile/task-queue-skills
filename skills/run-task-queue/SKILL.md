---
name: run-task-queue
description: ตัวคุมคิวงานของ repo ปัจจุบัน อ่านบอร์ดตาม .claude/task-queue.md (Notion / GitHub Project / GitHub Issues) แล้วเปิด Claude session ใน herdr tab ใหม่ให้ทำ 1 การ์ดต่อ 1 session รวมรอบแก้ conflict และแก้ตามรีวิวของ PR ที่ค้าง และ merge PR ที่ผ่านทุกด่านเองเมื่อ config มีหัวข้อ merge รับ --dry-run ใช้กับ /loop
---

# Run task queue

ต้องรันอยู่ใน herdr: ถ้า `HERDR_ENV` ไม่ใช่ 1 ให้แจ้งว่าไม่ได้อยู่ใน herdr แล้วหยุด
ใช้สกิล herdr คู่กัน และดู syntax จริงจาก `herdr tab` กับ `herdr agent` ก่อนใช้ อย่าเดา flag เอง
session นี้แค่คุมคิว ไม่เขียนโค้ดเอง · เปิด session นี้ด้วย Sonnet (`claude --model claude-sonnet-5-5`) ก็พอ โมเดลของการ์ดแต่ละใบเลือกด้วย rubric `โมเดล` ใน config

ก่อนทุกรอบอ่าน `config.md` (วิธีอ่าน `.claude/task-queue.md`) และ `trackers.md` (คำสั่งต่อ kind) ในโฟลเดอร์สกิลนี้ · config ไม่ครบ = หยุดตามที่ `config.md` บอก
`<repo>` = basename ของ `<root>` · `<acct>` = จาก `บัญชี` หรือ `budget-check --pick` · ไม่มี `budget-check` → ข้ามทุกขั้นที่เรียกมัน ตาม `config.md` · `<ref>` และ **เลขของการ์ด** ตาม `trackers.md`
argument `--dry-run`: ทำข้อ 1–6 แล้วรายงานตามหัวข้อ "รายงาน dry-run" โดยไม่เปิด tab ไม่แตะบอร์ด ไม่ merge ไม่ส่ง notification

## ทุกรอบ
1. รันทุกรายการใน `ก่อนทุกรอบ` ของ config ก่อนข้ออื่น แม้รอบนั้นจะจบเร็ว
2. เก็บกวาด worktree ของงานที่ merge แล้ว ทำทุกรอบแม้รอบนั้นจะจบเร็ว
   - ดูเฉพาะ worktree ใน `git worktree list` ที่อยู่ใต้ `.claude/worktrees/task-*` (สร้างโดย `/pick-task`)
   - ข้ามใบที่ยังมี agent ใน `herdr agent list` ที่ `foreground_cwd` อยู่ใต้ path นั้น
     ห้ามเทียบจากชื่อ เพราะชื่อ agent กับชื่อ worktree อาจไม่ตรงกัน
   - อ่าน branch ด้วย `git -C <path> branch --show-current` แล้วเช็ก `gh pr list --head <branch> --state merged`
     ไม่มี PR ที่ merge แล้วให้ข้าม (PR ที่ยังเปิดหรือถูกปิดโดยไม่ merge ต้องเก็บ worktree ไว้)
   - `git -C <path> status --porcelain` ไม่ว่าง ให้ข้ามและส่ง `herdr notification` บอกเจ้าของว่า worktree ไหนมีของค้าง
   - worktree ที่ Claude สร้างจะถูก lock ด้วยเหตุผล `claude session <ชื่อ> (pid <N> ...)` ดูได้จาก `git worktree list --porcelain`
     `ps -p <N>` ยังเจอ process ให้ข้าม ไม่เจอให้ `git worktree unlock <path>` ก่อน
   - นอกนั้นลบด้วย `git worktree remove <path>` ห้ามใส่ `--force` และห้ามลบ branch
   - ลบ worktree แล้ว ถ้ามี `<root>/.tasks/<ชื่อ branch ตัด prefix/ ออก>/` ให้ย้ายไป `<root>/.tasks/_done/` เก็บเป็นประวัติ
3. ด่านก่อนเริ่มงาน จบรอบนี้ถ้าข้อใดไม่ผ่าน:
   - มี agent ชื่อขึ้นต้นด้วย `task-` ใน `herdr agent list` เพราะทำได้ทีละงาน
   - (ข้ามถ้าไม่มี `budget-check`) `budget-check --unattended --acct <acct>` ไม่ได้ `OK` (ทั้ง `ROUTE-EXTERNAL` และ `STOP`) เพราะงานหนึ่งใบอาจกินโควตาจนตายกลางทาง
     ส่ง `herdr notification show` บอกตัวเลขกับเวลารีเซ็ตเฉพาะรอบแรกที่เจอใน session นี้ รอบถัดไปที่ยังไม่ `OK` ให้จบเงียบ ๆ
4. สำรวจ PR ที่ค้าง: การ์ดสถานะ `in-review` ทุกใบ → หา PR ของการ์ด → สุขภาพ PR (ทั้งสองอย่างตาม `trackers.md`) แล้วจัดกลุ่ม
   - `MERGED`: ไม่ทำอะไร (ข้อ 2 รอบถัดไปเก็บ worktree · เจ้าของย้ายการ์ดเอง)
   - `CLOSED` โดยไม่ merge: ข้าม และ notification ครั้งเดียวต่อ session
   - `OPEN` + `mergeStateStatus` `DIRTY` → กลุ่ม **แก้ conflict**
   - `OPEN` + `CHANGES_REQUESTED` ที่ยังไม่แก้ → กลุ่ม **แก้รีวิว**
   - `OPEN` อื่น ๆ → นับเป็น **PR เปิดค้าง** · config มีหัวข้อ `merge` ให้เช็กด่านตามหัวข้อ "merge อัตโนมัติ" ด้วย ผ่านครบ = กลุ่ม **พร้อม merge**
   - การ์ด `in-review` ที่หา PR ไม่เจอ: notification ครั้งเดียวต่อ session (pick-task ลืมแปะลิงก์ หรือเจ้าของย้ายเอง) แล้วข้าม
   มีกลุ่มพร้อม merge → merge ใบแรกตามหัวข้อ "merge อัตโนมัติ" แล้วนับใบนั้นออกจาก PR เปิดค้าง
   รอบละใบเดียว เพราะ merge แล้ว PR ใบอื่นอาจชน `main` ต้องให้ GitHub คำนวณ `mergeStateStatus` ใหม่ก่อนรอบหน้า
5. เลือกงานของรอบนี้ตามลำดับ หยุดที่ข้อแรกที่เจอ:
   1. การ์ดใบแรกในกลุ่มแก้ conflict
   2. การ์ดใบแรกในกลุ่มแก้รีวิว
   3. PR เปิดค้าง ≥ `ขีดจำกัด` → จบรอบ
   4. การ์ดบนสุดของคิว (อ่านคิวตาม `trackers.md`) ที่ไม่ถูก Blocked by · คิวว่างหรือถูกบล็อกหมด → จบรอบ
6. จดไว้: `<ref>` · เลขของการ์ด · โหมด (ใหม่ / แก้ conflict / แก้รีวิว) · **โมเดล** ตามหัวข้อ `โมเดล` ของ config:
   - ใหม่: รวบรวมข้อเท็จจริงสองชุด แล้วไล่กฎจากบนลงล่าง ข้อแรกที่ตรงชนะ ไม่ตรงเลยใช้ `default` · จดด้วยว่าตรงกฎข้อไหนและผล peek
     1. จากการ์ด: Type · Priority · AC · ชื่อ
     2. จากโค้ด: ผล 3 ค่าของหัวข้อ "peek โค้ด" ด้านล่าง (ไฟล์ที่แตะ · โซนหนัก · ไม่ชัด)
   - แก้ conflict: `conflict` ของ config (ไม่มี = `default`)
   - แก้รีวิว: บรรทัด `โมเดล:` ในหัว `task.md` ของการ์ด (`grep -l "<ref>" <root>/.tasks/*/task.md`) ไม่มีบรรทัดนั้นใช้ `default`

## peek โค้ด
ใช้ตอนเลือกโมเดลของโหมดใหม่เท่านั้น และทำเฉพาะการ์ดใบที่จะเปิดรอบนี้ (dry-run ก็ใบเดียว) เพราะทุกคำสั่งกิน token ของ session คุมคิว
อ่านจาก checkout หลัก `<root>` แบบ read-only · งบไม่เกิน 6 คำสั่ง · ห้ามเปิดอ่านเนื้อไฟล์ (ไม่ `cat` ไม่ Read) ดูได้แค่รายชื่อไฟล์
1. ดึงคำค้นจากการ์ดไม่เกิน 5 คำ: path ไฟล์ · ชื่อ component / function / route / table · ข้อความ error ที่การ์ดยกมา · ชื่อฟีเจอร์ที่น่าจะเป็นชื่อไฟล์
   การ์ดไม่มีอะไรจับได้เลย (เช่น "ปรับให้ลื่นขึ้น") → ผล **ไม่ชัด** ข้ามข้อ 2–3
2. `git -C <root> grep -l -i -F -e <คำ1> -e <คำ2> … | head -40` · คำที่เป็น path ใช้ `git -C <root> ls-files '<path>*'` แทน
3. สรุปเป็น 3 ค่า แล้วจดไว้ใช้กับกฎ:
   - **ไฟล์ที่แตะ** = จำนวนไฟล์จากข้อ 2 หลังตัด test · doc · lockfile · ไฟล์ที่ generate ออก
   - **โซนหนัก** = ไฟล์ในรายชื่อที่ match บรรทัด `โซนหนัก:` ของ config · config ไม่มีบรรทัดนั้นให้ถือว่า path ที่มี `migration` `schema` `prisma` `drizzle` `auth` เป็นโซนหนัก
   - **ไม่ชัด** = ข้อ 2 ได้ 0 ไฟล์ หรือเต็ม 40 (คำค้นกว้างเกินจะเชื่อ)
peek เป็นข้อเท็จจริงให้กฎของ config ใช้ ไม่ใช่ตัวเลือกโมเดลเอง · ไม่รู้ค่าไหน = ไม่ตรงกฎที่อ้างค่านั้น

## merge อัตโนมัติ
ทำเมื่อ config มีหัวข้อ `merge` เท่านั้น ไม่มี = เจ้าของ merge เองทุกใบ · แตะได้แค่ PR ที่หาเจอจากการ์ด `in-review` ในข้อ 4 ไม่แตะ PR ที่เจ้าของเปิดเองนอกบอร์ด
merge แล้ว `main` ขยับทันทีและอาจ deploy ต่อเอง ด่านจึงเลือกฝั่งปลอดภัย: ไม่แน่ใจข้อไหน = ไม่ผ่าน ปล่อยให้เจ้าของ merge เองเหมือนเดิม

เช็กด่านด้วย `merge-check.jq` ในโฟลเดอร์สกิลนี้ (`deny` = ค่าใน `ไม่ auto:` · `skip` = ค่าใน `ข้าม comment ของ:` ไม่มีบรรทัดนั้นตัด `--argjson` ตัวนั้นทิ้ง):
```bash
inline=$(gh api repos/<repo>/pulls/<n>/comments --paginate | jq -s 'add // []')
gh pr view <n> -R <repo> --json number,state,isDraft,headRefOid,mergeStateStatus,reviews,body,comments,files,statusCheckRollup \
  | jq -f <โฟลเดอร์สกิลนี้>/merge-check.jq --argjson inline "$inline" --argjson deny '["<prefix>", …]' --argjson skip '["<login>", …]'
```
ได้ `ready` · `fail` (เหตุที่ตก ขึ้นต้นด้วยเลขด่าน) · `head` · `checks` · `fail` มีแค่ `2 mergeStateStatus UNKNOWN` ให้รอ 3 วินาทีแล้วยิงซ้ำ
ด่านที่ `merge-check.jq` ตรวจ:
1. `OPEN` และไม่ใช่ draft · เจ้าของกันใบไหนไว้ได้ด้วยการกด Convert to draft
2. `mergeStateStatus` `CLEAN` (ไม่ชน และ check/status ที่ head ไม่แดงหรือค้าง)
3. ไม่มีใครที่รีวิวล่าสุดเป็น `CHANGES_REQUESTED` แม้จะ push แก้แล้ว เพราะแก้แล้วแปลว่ารอคนนั้นรีวิวซ้ำ
4. **ตรา** (`trackers.md`) ล่าสุดชี้ head ปัจจุบัน และทุกตราใน PR รอเจ้าของตัดสิน 0 ข้อ
5. ไม่มี comment · review · inline comment หลังตราแรก นอกจากตราเอง (ยกเว้น login ใน `ข้าม comment ของ:`)
6. ไม่แตะ `.claude/task-queue.md` (PR ที่แก้กติกาของคิวเองต้องให้เจ้าของ merge) และ path ที่ขึ้นต้นด้วยค่าใน `ไม่ auto:`

ด่านที่ session นี้ตรวจเอง:

7. ทุกข้อใน `ด่าน:` ของ config (ส่วนใหญ่เป็นชื่อใน `checks` ที่ต้อง `SUCCESS`)

ผ่านครบ 7 ข้อ → merge:
1. `gh pr merge <n> -R <repo> --<วิธี> --match-head-commit <head>` · ห้าม `--admin` และ `--delete-branch` (worktree ยังใช้ branch อยู่ ข้อ 2 เก็บกวาดเอง)
   error ว่า head ไม่ตรง = มี push ใหม่ระหว่างเช็ก ปล่อยไว้รอบหน้า · error อื่นส่ง notification แล้วข้าม ไม่ลองซ้ำ
2. ทำ `หลัง merge:` ของ config · ไม่ผ่าน → notification ทันทีว่า PR ไหนตกข้อไหน ห้ามแก้หรือ revert เอง
3. comment ใน PR ``merge อัตโนมัติโดย /run-task-queue (head `<sha 7 ตัว>`) · ผ่านด่าน 1–7`` แล้วส่ง notification `merge #<n> แล้ว · <ชื่อการ์ด>`
   การ์ดไม่ต้องย้าย ข้อ 4 รอบหน้าเห็นเป็น `MERGED` เหมือนที่เจ้าของ merge เอง

ตกด่าน 4–7 → notification ครั้งเดียวต่อ PR ต่อ session ว่า `#<n> รอเจ้าของ merge: <fail ตัวแรก>` · ตกด่าน 1–3 ไม่ต้องแจ้ง เพราะเป็นสถานะปกติระหว่างรอ CI หรือรอรีวิว

## รายงาน dry-run
พิมพ์ตารางแล้วจบ: PR ค้างแต่ละใบกับกลุ่มที่จัด (config มี `merge` ให้ใส่ `fail` ตัวแรกของใบที่ไม่พร้อม merge ด้วย) · PR เปิดค้าง n/ขีดจำกัด (นับเหมือนใบแรกของกลุ่มพร้อม merge ถูก merge แล้ว) · คิว 5 ใบแรกพร้อมเหตุที่ข้าม (ถูกบล็อกโดย #n · draft) · ใบที่จะเปิดแสดงผล peek (ไฟล์ที่แตะ n · โซนหนัก <ไฟล์> · ไม่ชัด) กับโมเดลและกฎข้อที่ตรง ใบอื่นไม่ peek จึงไม่ต้องแสดงโมเดล · มีใบพร้อม merge ให้ขึ้นบรรทัด "รอบนี้จะ merge #<n>" ก่อนบรรทัดสุดท้าย · บรรทัดสุดท้าย "รอบนี้จะเปิด tab ให้ `<ref>` โหมด <…> โมเดล <…> (กฎข้อ <…> · peek <สรุป>)" หรือ "รอบนี้ไม่เปิดอะไร เพราะ <ข้อที่หยุด>"

## เปิด session ใหม่
7. สร้าง tab ใหม่ใน workspace ปัจจุบัน แล้วอ่าน `.result.tab.tab_id` กับ `.result.root_pane.pane_id` จาก JSON ที่ตอบกลับ
   `herdr tab create --workspace "$HERDR_WORKSPACE_ID" --cwd <root> --label task-<เลข> --env CLAUDE_CONFIG_DIR=<dir ของ acct> --no-focus`
   ต้องใส่ `--env` เสมอ เพราะ `herdr agent start --kind claude` รัน `claude` เปล่า ซึ่งได้ config `~/.claude` ที่อาจเป็นบัญชีผิด
   ไม่ต้องสร้าง worktree เอง เพราะ `/pick-task` ย้ายตัวเองเข้า worktree ก่อนเริ่มทำงาน
8. เริ่ม Claude ใน pane นั้น: `herdr agent start task-<เลข> --kind claude --pane <root_pane> --timeout 120000 -- --model <โมเดล>` (ตัด `-- --model …` ถ้า config ไม่มีหัวข้อ `โมเดล`)
   ได้ `agent_not_ready … blocked during startup` ให้ `herdr agent read task-<เลข> --source visible` ก่อน: ถ้าเป็นหน้าถาม trust folder ของ Claude (เจอครั้งแรกของแต่ละบัญชีต่อ repo) ให้ `herdr agent send-keys task-<เลข> down enter` แล้ว `herdr agent wait task-<เลข> --until idle --timeout 90000` เพราะ repo นี้เป็นของเจ้าของเอง · หน้าอื่นที่ไม่ใช่ trust ให้ notification แล้วจบรอบ ไม่ตอบแทน
9. จดโควตาก่อนเริ่ม (ข้ามถ้าไม่มี `budget-check`): `budget-check --log <repo>/task-<เลข> before --acct <acct> --tier <sonnet|opus|haiku ตามโมเดล>`
   แล้วส่งงาน: `herdr agent prompt task-<เลข> "/pick-task <ref> --model <โมเดล>" --wait --timeout 7200000` (ไม่มีโมเดลก็ไม่ต้องใส่ `--model`)
   ทุกโหมดใช้คำสั่งเดียวกัน `/pick-task` รู้โหมดจากสถานะใน `task.md` ของการ์ด
   รันเป็น background command เพราะ Bash ที่รอผลรอได้นานสุด 10 นาที แต่งานหนึ่งใบใช้ 15–60 นาที บวก self-review กับ ci ตาม config

## หลังงานจบ
จดโควตาหลังจบ (ข้ามถ้าไม่มี `budget-check`): `budget-check --log <repo>/task-<เลข> after --acct <acct>` แล้วเอาบรรทัดจาก `budget-check --cost <repo>/task-<เลข>` ใส่ใน notification หรือรายงานรอบนี้
ตัวเลขนี้ใช้ปรับเกณฑ์ในข้อ 3 ว่างานหนึ่งใบกินโควตากี่ %

10. ปิด tab ที่สร้างในข้อ 7 ด้วย `herdr tab close` ได้เมื่อการ์ดเป็น `in-review` และหา PR เจอ (ทั้งโหมดใหม่และโหมดแก้)
    worktree ของงานยังต้องอยู่ เผื่อรอบแก้ conflict/รีวิวในรอบหลัง ข้อ 2 จะลบเองเมื่อ PR merge
11. การ์ดมีหัวข้อ `## หยุดเพราะโควตา` ที่ `/pick-task` เขียนไว้ ให้ปิด tab ได้เหมือนข้อ 10
    แล้วส่ง notification บอกว่าการ์ดไหนหยุดค้างที่ branch ไหน worktree ยังเก็บไว้ให้ทำต่อ
    นอกจากสองกรณีนี้ ถ้า agent อยู่ในสถานะ blocked, หมดเวลา หรือการ์ดยังไม่ถึง `in-review` อย่าปิด tab และอย่าตอบคำถามแทน
    ส่ง `herdr notification` บอกเจ้าของว่า task ไหนติดอยู่ที่ tab ไหน
12. ปิดได้แค่ tab ที่ session นี้สร้าง และลบได้แค่ worktree `task-*` ตามเงื่อนไขในข้อ 2 เท่านั้น
