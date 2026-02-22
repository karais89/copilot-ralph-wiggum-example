# TASK-23: export 명령 통합 테스트 및 문서 업데이트

## Title
export 명령 통합 검증 및 README 업데이트

## Dependencies
TASK-22

## Description
빌드 후 `todo export` 명령을 시나리오별로 실행해 결과를 검증하고, README에 export 명령 예시를 추가한다.

### 검증 시나리오
1. **빈 목록**: todo 없는 상태에서 `todo export` → 헤더만 있는 CSV + 경고 메시지
2. **데이터 있음**: todo 2~3개 추가 후 `todo export` → 헤더 + 데이터 행 포함 CSV
3. **지정 경로**: `todo export out/test.csv` 시 존재하지 않는 디렉터리 처리 (에러 메시지 확인)
4. **특수문자 제목**: 쉼표/큰따옴표가 포함된 title로 add 후 export → 올바른 CSV 이스케이프 확인
5. **도움말**: `todo export --help` 출력 확인

### README 업데이트
- 명령어 테이블에 `todo export [output]` 행 추가
- 사용 예시 한 줄 추가

## Acceptance Criteria
- 위 5개 시나리오 모두 통과
- README에 export 명령 기재
- `npm run build` 통과

## Files to Create/Modify
- **Modify**: `README.md`

## Verification
```bash
npm run build
node dist/index.js export --help
node dist/index.js export
cat todos.csv
node dist/index.js add "Buy milk"
node dist/index.js add "Read book, then sleep"
node dist/index.js export todos.csv
cat todos.csv
```
