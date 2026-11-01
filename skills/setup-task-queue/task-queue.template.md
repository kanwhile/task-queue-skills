# task-queue

อ่านโดยสกิล run-task-queue · pick-task · setup-task-queue · ความหมายแต่ละหัวข้ออยู่ใน config.md ของสกิล · หัวข้อที่ไม่ใช้ลบทิ้งได้ยกเว้น tracker และ สถานะ

## tracker
kind: github-project
owner: <login>
number: <เลข project>
repo: <owner/name>
priority field: Priority

<!-- kind: notion
data source: collection://<id>
view: <URL ของ view คิว>
repo: <owner/name>  (ใช้ตอนเปิด issue ให้การ์ด) -->

<!-- kind: github-issues
repo: <owner/name>
priority label prefix: P -->

## สถานะ
queued: Ready
in-progress: In Progress
in-review: In Review
unclear: Todo

## บัญชี
acct: <ชื่อบัญชีของ budget-check>

## ขีดจำกัด
PR เปิดค้าง: 3

## โมเดล
default: claude-opus-5-5
conflict: claude-sonnet-5-5
โซนหนัก: <path/glob ของ schema · migration · กฎโดเมน · auth คั่นด้วย ·>
- Priority P0 → claude-opus-5-5
- Type เป็น Feature หรือ AC มีคำว่า ออกแบบ · ตัดสิน · ADR · port → claude-opus-5-5
- peek แตะโซนหนัก หรือ peek ไม่ชัด → claude-opus-5-5
- Type เป็น Bug หรือ Task และ AC เป็นข้อ ๆ ชัดเจน และ peek แตะไม่เกิน 5 ไฟล์ → claude-sonnet-5-5

## ก่อนทุกรอบ
- <สกิลหรือคำสั่ง · ลบหัวข้อนี้ถ้าไม่มี>

## merge
- วิธี: <merge | squash | rebase ตามที่ repo ใช้ · ลบหัวข้อนี้ถ้าเจ้าของ merge เองทุกใบ>
- ด่าน: <check ที่ head ต้อง SUCCESS เช่น CI>
- ไม่ auto: <path prefix ของ migration · config deploy · .github/ · ไฟล์กฎของ repo คั่นด้วย ·>
- หลัง merge: <เช็กหลัง merge · ลบบรรทัดนี้ถ้าไม่มี>

## branch
task/<n>-<ชื่อ>

## setup
- <คำสั่งติดตั้งหลังสร้าง worktree>
- <ไฟล์ env ที่ต้องก๊อป และบรรทัดที่ต้องลบออกจากสำเนาใน worktree>

## verify
- <คำสั่งที่ต้องเขียวก่อนเปิด PR>
- <พอร์ต/วิธีปิดที่ไม่ชนกับ checkout หลัก>

## self-review
- <วิธีรีวิวตัวเอง เช่น เรียกสกิล /code-review เทียบไฟล์กฎของ repo>

## ci
- <CI ที่ต้องเขียวก่อนย้ายเป็น in-review · ลบหัวข้อนี้ถ้าไม่มี>

## กฎโค้ด
- <ไฟล์กฎของ repo และข้อที่ delegate ต้องรู้>

## delegate
- grok: <งานประเภทไหน>
- agy: <งานประเภทไหน>

## หลัง PR
- <สิ่งที่ต้องทำหลังเปิด PR เช่น sync wiki · ลบหัวข้อนี้ถ้าไม่มี>
