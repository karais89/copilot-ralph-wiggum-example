# Examples

간단한 사용 예시와 출력 샘플입니다.

## Add

```bash
todo add "Buy groceries"
```

예상 출력:

```
✔ Added todo: "Buy groceries" (abc12345)
```

## List

```bash
todo list
```

예상 출력:

```
[ ] abc12345  Buy groceries
[✓] def67890  Finish project

Total: 2 todos
```

## Stats (text)

```bash
todo stats
```

예상 출력:

```
📊 Todo Statistics

Total:      2
Completed:  1 ✓
Pending:    1 ⏳
Progress:   50%
```

## Stats (JSON)

```bash
todo stats --json
# or
todo stats -j
```

예상 출력(JSON):

```json
{
  "total": 2,
  "completed": 1,
  "pending": 1,
  "overdue": 0,
  "completionRate": 50,
  "generated_at": "2026-02-07T12:00:00.000Z"
}
```
