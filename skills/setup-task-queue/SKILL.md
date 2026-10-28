---
name: setup-task-queue
description: ตั้ง repo ปัจจุบันให้ใช้ /run-task-queue และ /pick-task ได้ สร้าง .claude/task-queue.md โดยอนุมานจาก repo ก่อนแล้วถามเฉพาะที่เดาไม่ได้ เตรียม tracker (option ของ GitHub Project / label / ตรวจ Notion) และ gitignore รันซ้ำบน repo ที่มี config แล้วเพื่อตรวจ (doctor)
---

# Setup task queue

อ่าน `config.md` (ความหมายแต่ละหัวข้อ) และ `trackers.md` (ค่าที่แต่ละ kind ต้องมี + วิธีเตรียม) ในโฟลเดอร์สกิลนี้ก่อน
ทุกขั้น idempotent: ของที่มีแล้วรายงานว่า "มีแล้ว" ไม่สร้างซ้ำ ไม่เขียนทับไฟล์ที่เจ้าของแก้เอง

1. `<root>` ตาม `config.md` · มี `.claude/task-queue.md` อยู่แล้ว → โหมด doctor: ข้ามข้อ 2–4 เว้นแต่ขาดหัวข้อบังคับ (`tracker` `สถานะ`) ซึ่งต้องถามเฉพาะส่วนที่ขาดแล้วเติมใต้หัวข้อนั้น
2. อนุมานจาก repo ก่อนถาม เก็บเป็นค่าเสนอของแต่ละหัวข้อ:
   - `setup` / `verify` / `ci`: scripts ใน `package.json` (ชื่อที่มี setup · typecheck · build · test · verify · ci) · `.github/workflows/*` (มี CI ไหม และ `gh api repos/<repo>/actions/workflows` ว่า `active` ไหม) · ไฟล์ env ตัวอย่าง (`.dev.vars` `.env.example`)
   - `branch`: pattern จาก `gh pr list --state merged --limit 20 --json headRefName`
   - `กฎโค้ด` / `หลัง PR`: ไฟล์กฎของ repo (`AGENTS.md` `CLAUDE.md`) หาข้อที่ขึ้นต้นด้วยข้อห้าม/ต้องทำ และกฎแบบ "ทุกครั้งที่แก้ต้อง…" (เช่น sync wiki) ซึ่งเป็น `หลัง PR`
   - tracker ที่มีอยู่: `gh api graphql` ดู `projectsV2` ที่ผูกกับ repo · `gh project list --owner <owner>` · `gh label list` · Notion ถ้าเจ้าของเคยบอก
   - บัญชี: `budget-check --all`
3. ถาม `AskUserQuestion` รอบเดียว เฉพาะที่อนุมานไม่ได้: tracker (เสนอตัวเลือกจากข้อ 2) · บัญชี · การแบ่งงาน delegate · ขีดจำกัด PR เปิดค้าง (เสนอ 3)
   หัวข้อ `โมเดล` ไม่ต้องถาม: ใส่ rubric จาก template แล้วให้เจ้าของแก้ตอนดูไฟล์ในข้อ 4 · `budget-check --help` บอก tier ที่ `--tier` รับ
   ชื่อสถานะไม่ต้องถาม: Notion ใช้ชื่อที่มีในบอร์ด · GitHub Project ใช้ `Todo / Ready / In Progress / In Review` · label ใช้ `ready-for-agent / in-progress / in-review / needs-info`
4. ร่างไฟล์จาก `task-queue.template.md` ในโฟลเดอร์สกิลนี้ แล้วแสดงทั้งไฟล์ให้เจ้าของดูก่อนเขียน
   ค่าที่อนุมานได้แต่ไม่มั่นใจ ใส่ `⚠️ เดา:` นำหน้าบรรทัดนั้น ไม่ถามแยก · เจ้าของแก้แล้วค่อยเขียนลง `<root>/.claude/task-queue.md`
5. เตรียม tracker ตาม `trackers.md` §เตรียม: ผูก repo เข้า Project · option ของ Status ที่ขาดให้เจ้าของเพิ่มเองใน UI (บอกชื่อที่ต้องเพิ่มและรอจนเห็นใน `gh project field-list`) · สร้าง label ที่ขาด · Notion ตรวจอย่างเดียว
6. เตรียม repo: เพิ่ม `.tasks/` และ `.claude/worktrees/` ใน `.gitignore` ถ้ายังไม่ถูก ignore (`git check-ignore`) · ถ้าถูก ignore ผ่าน `.git/info/exclude` ให้ย้ายมา `.gitignore` เพราะ exclude ไม่ติดไปกับ clone/worktree อื่น
   เพิ่มบรรทัดเดียวในไฟล์กฎของ repo: "คิวงานของ agent: `/run-task-queue` อ่าน `.claude/task-queue.md`" ถ้ายังไม่มี
7. ตารางเครื่อง ✅/❌ รายงานอย่างเดียว ไม่แก้ให้: `gh auth status` มี scope `project` (ต้องมีเฉพาะ kind github-project) · `herdr` และ `budget-check` อยู่ใน `PATH` · symlink ของ `run-task-queue` `pick-task` `setup-task-queue` ครบใน `~/.claude/skills` และทุก `~/.claude-*/skills` (ขาด → บอกให้รัน `install.sh` ของ repo task-queue-skills) · `CLAUDE_CONFIG_DIR` ของบัญชีที่เลือกมีอยู่จริง
8. สรุป: ไฟล์ที่เขียน · สิ่งที่สร้างบน tracker · ❌ ในตารางที่เจ้าของต้องแก้เอง · คำสั่งถัดไป `/run-task-queue --dry-run`
