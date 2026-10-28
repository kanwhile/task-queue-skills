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

## ก่อนทุกรอบ
- <สกิลหรือคำสั่ง · ลบหัวข้อนี้ถ้าไม่มี>

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
