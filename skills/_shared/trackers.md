# tracker — 5 การกระทำต่อ kind

ทุกสกิลในชุดนี้คุยกับบอร์ดผ่าน 5 การกระทำ: **อ่านคิว · อ่านการ์ด · เปลี่ยนสถานะ · เขียนกลับ · หา PR** · ค่าเฉพาะมาจากหัวข้อ `tracker` และ `สถานะ` ใน `.claude/task-queue.md`

**ref ของการ์ด** = สิ่งที่ส่งต่อระหว่างสกิลและใช้ตั้งชื่อ: `notion` = URL ของหน้า · GitHub ทั้งสองแบบ = `#<เลข issue>` · **เลขของการ์ด** (ใช้ตั้งชื่อ worktree/agent/branch) = เลข issue ถ้ามี ไม่มีก็ 8 ตัวท้ายของ id หน้า Notion
`<repo>` = `owner/name` จาก `gh repo view --json nameWithOwner -q .nameWithOwner` ของ checkout ปัจจุบัน

## notion

ค่าใน `tracker`: `data source: collection://<id>` · `view: https://www.notion.so/<id ของ database ไม่มีขีด>?v=<id ของ view ไม่มีขีด>` (view คิว · ไม่บังคับ) · ช่อง `Status` · `GitHub Issue` (url) · `Issue #` (number) · `Priority` (ไม่บังคับ) · `repo: owner/name`

- **อ่านคิว**: มี `view` → `notion-query-data-sources` แบบ `{"data":{"mode":"view","view_url":"<view>","page_size":10}}` ได้แถวตามตัวกรอง/ลำดับของ view (`notion-fetch` บน view คืนแค่ config ไม่คืนแถว) · ไม่มี `view` → mode sql: `SELECT url, Name, "Issue #", Priority FROM "<data source>" WHERE Status = ? ORDER BY Priority, createdTime` params `["<queued>"]`
- **การ์ดสถานะใดสถานะหนึ่ง** (เช่น in-review): mode sql แบบเดียวกันเปลี่ยน params
- **อ่านการ์ด**: `notion-fetch` URL → property ทุกช่อง + เนื้อหา (AC · รายละเอียด) · ไฟล์แนบดาวน์โหลดด้วย `notion-get-file-download-urls`
- **เปลี่ยนสถานะ**: `notion-update-page` property `Status`
- **เขียนกลับ**: `notion-update-page` ต่อท้ายเนื้อหาด้วย `## <หัวข้อ>` + ข้อความ · หัวข้อที่สกิลใช้: `## รอเจ้าของตัดสิน` · `## หยุดเพราะโควตา` · `## คำถาม` · ลิงก์ PR แปะเป็นบรรทัดเปล่า ๆ ในเนื้อหา
- **หา PR**: ลิงก์ `github.com/<repo>/pull/<n>` ในเนื้อหาการ์ด และถ้ามี `Issue #` ให้ดู linked PR ของ issue (ด้านล่าง) ด้วย
- **issue**: การ์ดไม่มี `GitHub Issue` → pick-task ตัดสินเองว่าควรเปิด issue ไหม ถ้าเปิด `gh issue create -R <repo>` จากเนื้อการ์ด แล้วเขียน URL และเลขกลับ `GitHub Issue` / `Issue #`

## github-project

ค่าใน `tracker`: `owner: <login>` · `number: <เลข project>` · `repo: <owner/name>` (ไม่มี = repo ปัจจุบัน) · `priority field: <ชื่อช่อง>` (ไม่บังคับ)

- **id ที่ต้องใช้** (หาใหม่ทุกครั้ง ไม่จำ): project id `gh project view <number> --owner <owner> --format json -q .id` · ช่อง Status และ option: `gh project field-list <number> --owner <owner> --format json | jq '.fields[] | select(.name=="Status") | {id, options}'` แล้วจับคู่ชื่อจาก `สถานะ`
- **อ่านคิว**: `gh project item-list <number> --owner <owner> --format json --limit 500` → `.items[] | select(.content.type=="Issue" and .content.repository=="<repo>" and .status=="<queued>")` (ใช้ `.content.repository` ที่เป็น `owner/name` · คีย์ `.repository` ชั้นนอกเป็น URL เต็ม) · เรียงด้วย priority field (คีย์ใน JSON เป็นชื่อช่องตัวพิมพ์เล็ก) แล้วเลข issue น้อยก่อน · item ที่ `.content.type=="DraftIssue"` ข้าม (ไม่มี issue ให้ผูก PR)
- **อ่านการ์ด**: `gh issue view <n> -R <repo> --json title,body,labels,comments` · ไฟล์แนบ = ลิงก์ในเนื้อ issue
- **เปลี่ยนสถานะ**: `gh project item-edit --project-id <project id> --id <item id> --field-id <status field id> --single-select-option-id <option id>` · item id มาจาก `.items[].id` ของ item-list (หา item ของ issue ด้วย `.content.number`)
- **เขียนกลับ**: `gh issue comment <n> -R <repo> --body "## <หัวข้อ>…"` · ไม่แก้เนื้อ issue (เป็นสเปกของเจ้าของ) · ลิงก์ PR ไม่ต้องเขียน เพราะ `Closes #<n>` ใน PR ทำให้หาได้เอง
- **หา PR**: linked PR ของ issue (ด้านล่าง)

## github-issues

ค่าใน `tracker`: `repo: <owner/name>` (ไม่มี = repo ปัจจุบัน) · `priority label prefix: <เช่น P>` (ไม่บังคับ) · ชื่อใน `สถานะ` คือชื่อ label

- **อ่านคิว**: `gh issue list -R <repo> --label "<queued>" --state open --limit 200 --json number,title,labels,createdAt` · เรียง label priority (prefix น้อยก่อน เช่น P0 < P1) แล้วเลขน้อยก่อน · label ที่เพิ่งติดโผล่ในผล list ช้าราว 5 วินาที (index ของ GitHub) ถ้าเพิ่งติดเองให้รอก่อนอ่านซ้ำ
- **อ่านการ์ด**: เหมือน github-project
- **เปลี่ยนสถานะ**: `gh issue edit <n> -R <repo> --remove-label "<เดิม>" --add-label "<ใหม่>"` · ต้องถอดทุก label สถานะที่ติดอยู่ให้เหลือตัวเดียวเสมอ
- **เขียนกลับ**: เหมือน github-project
- **หา PR**: linked PR ของ issue (ด้านล่าง)

## ใช้ร่วมกันทุก kind ที่มี issue

**linked PR ของ issue** (PR ที่มี `Closes #n`):
```bash
gh api graphql -F o=<owner> -F r=<name> -F n=<เลข> -f query='query($o:String!,$r:String!,$n:Int!){ repository(owner:$o,name:$r){ issue(number:$n){ state body closedByPullRequestsReferences(first:10,includeClosedPrs:true){ nodes{ number state url isDraft } } } } }'
```
`state` ของ PR = `OPEN` · `MERGED` · `CLOSED`

**Blocked by**: บรรทัด `**Blocked by:** #n` (หรือ `Blocked by: #n`) ในเนื้อ issue · issue ที่อ้างยังเปิดอยู่ = การ์ดนี้ถูกบล็อก ข้ามไปใบถัดไป · Notion ใช้ `Issue #` ไปอ่านเนื้อ issue เดียวกัน ไม่มี issue = ไม่บล็อก

**สุขภาพ PR**:
```bash
gh pr view <n> -R <repo> --json state,url,headRefName,headRefOid,mergeStateStatus,reviewDecision,reviews,commits
```
- `mergeStateStatus` = `DIRTY` → ชน `main` ต้องแก้ conflict · ได้ `UNKNOWN` ให้รอ 3 วินาทีแล้วยิงซ้ำ (GitHub ยังคำนวณไม่เสร็จ)
- `reviewDecision` = `CHANGES_REQUESTED` → ดูว่าแก้แล้วหรือยัง: `submittedAt` ล่าสุดของ `.reviews[] | select(.state=="CHANGES_REQUESTED")` เทียบ `.commits[-1].committedDate` · commit ใหม่กว่า = แก้แล้ว รอเจ้าของรีวิวซ้ำ ไม่ต้องทำอะไร
- ข้อความรีวิวที่ต้องอ่านตอนแก้: `.reviews[].body` · inline: `gh api repos/<repo>/pulls/<n>/comments` · comment ธรรมดา: `gh api repos/<repo>/issues/<n>/comments`

**ตรา** = บรรทัดที่ agent ประกาศว่า head ไหนพร้อมให้เจ้าของดู มีทั้ง ``(head `<sha>`)`` และ `รอเจ้าของตัดสิน <n> ข้อ` ในบรรทัดเดียวกัน เช่น ``ส่งเจ้าของ (head `a1b2c3d`) · รอเจ้าของตัดสิน 0 ข้อ``
- pick-task โพสต์เป็น comment ทุกครั้งที่ส่ง PR ให้เจ้าของ ทั้งตอนเปิด PR และรอบแก้ · run-task-queue ใช้ตัดสินว่า merge เองได้ไหม
- ต้องเป็น comment ไม่ใช่ PR body เพราะ body ไม่มีเวลาให้เทียบ · ต้องเป็นสิ่งสุดท้ายที่ agent โพสต์ลง PR ในรอบนั้น เพราะอะไรที่มาหลังตราแรกถูกนับว่าเป็นเรื่องที่ agent ยังไม่ได้อ่าน
- `<n>` = ข้อที่เขียนใต้ `## รอเจ้าของตัดสิน` ในรอบนั้น · PR ที่เคยมีตรา n > 0 จะไม่ถูก merge อัตโนมัติอีก เพราะคิวไม่รู้ว่าเจ้าของตอบครบหรือยัง

## เตรียม tracker (ใช้โดย /setup-task-queue)

- **github-project**: ผูก repo เข้า Project ถ้ายังไม่ผูก: `gh api graphql -f query='mutation($p:ID!,$r:ID!){ linkProjectV2ToRepository(input:{projectId:$p,repositoryId:$r}){ repository{ id } } }' -F p=<project id> -F r=$(gh repo view --json id -q .id)`
  option ของ Status ที่ขาด (`Ready` `In Review`) **ให้เจ้าของเพิ่มเองในหน้า Project settings → Status → Add option** แล้วบอกชื่อให้ตรง `สถานะ`
  issue ที่มีอยู่ก่อนผูก repo **ไม่เข้า Project เอง** (workflow "Auto-add" ของ Project กรองตาม repo ที่ตั้งไว้ใน UI): เพิ่มด้วย `gh project item-add <number> --owner <owner> --url <URL ของ issue>` ทุก issue ที่เปิดอยู่ แล้วบอกเจ้าของให้ตั้ง Auto-add ให้ครอบ repo นี้ด้วย · item ที่เพิ่มใหม่ Status เป็นค่าว่าง ให้ตั้ง `Todo` ด้วย item-edit
  ⛔ ห้ามใช้ `updateProjectV2Field` กับ `singleSelectOptions` — API สร้าง option id ใหม่ทั้งชุด และ**ค่า Status ของทุก item ในโปรเจกต์หายเป็นค่าว่าง** (เกิดจริง 28 ต.ค. 2026 กับ 147 item · กู้ได้แค่เดาจาก state ของ issue/PR) · การแก้ชื่อ/สี option ก็เช่นกัน
- **github-issues**: `gh label list --json name` แล้วสร้างเฉพาะที่ขาด `gh label create "<ชื่อ>" --color <hex> --description "<คำอธิบาย>"`
- **notion**: `notion-fetch` data source แล้วเช็กว่า `Status` มี option ครบ 4 ชื่อ และมีช่อง `GitHub Issue` / `Issue #` · ตรวจอย่างเดียว ไม่สร้าง (schema ของบอร์ดเป็นของเจ้าของ) · `view` เช็กด้วย `notion-fetch` ว่าเปิดได้
