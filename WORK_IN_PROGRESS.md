# WORK_IN_PROGRESS — 계정 전환 핸드오프 메모

마지막 업데이트: 2026-05-07
마지막 커밋: `91dc592 chore: 엔터프라이즈 계정 전환 전 백업`

## 현재 상태

- 작업 트리 클린, `origin/main`과 동기화됨 (단, **로컬 백업 커밋은 아직 푸시 안 됨**).
- 최근 흐름: 자산 등록(개별 + 엑셀) → 자산 중복 방지 → QR 스캔 시 자산 전용 신고 화면 바로 진입.
- `qr.html`은 삭제됨. QR 진입은 `report.html?qr=1&...` 딥링크로 통합.

## 계정 전환 후 바로 해야 할 것

1. 새 계정으로 `git push origin main` — 백업 커밋 `91dc592` 원격 반영.
2. Vercel 재연결: `.vercel/project.json` (projectId `prj_n59FocYj4Ufrl59GA2ccJyyJCo1Y`)이 이전 계정 소유. 엔터프라이즈 계정에서 `vercel link` 다시 실행 → 기존 파일 덮어쓰기.
3. `chongmu-service` 프로젝트를 신규 계정/팀으로 이관(transfer)하거나, 새로 생성 후 도메인 다시 붙이기 결정.

## 미해결 / 다음 차례

### 우선순위 ↓

- **신고 ID 충돌**: `'RPT-' + (reports.length + 1)` 방식 — 삭제 기능 추가 시 ID 재사용 발생. UUID나 max+1 또는 단조 증가 카운터로 교체 검토.
- **디자인 토큰 중복**: `:root { --primary ... }` 와 `.bottom-nav`가 5개 HTML에 복붙. 공유 CSS로 빼면 유지보수 비용 절감.

### 해결됨 (2026-05-11 코드 리뷰)

- ~~자산 데이터 두 계보 통합~~ → admin 기준 단일 스키마(A001~A008 + `type`), `gs_assets_v='4'`로 통일. index/admin 모두 동일 시드 데이터 사용. 등록 후 리셋되던 `gs_assets_v` 불일치 버그(`!== '2'` vs `setItem '3'`)도 함께 수정 — `saveAssets()` 헬퍼로 일원화.
- ~~`admin.html`의 깨진 `qr.html` 링크~~ → QR관리 버튼 제거 (`.action-btn.qr` CSS도 함께 삭제). 향후 QR 관리 UI는 admin 내부 모달로 신규 구현 권장.

## 아키텍처 핵심 (CLAUDE.md 요약)

- 빌드/패키지 매니저/테스트 없음. 정적 HTML + 인라인 `<script>`.
- 페이지 간 통신은 **localStorage + URL 쿼리 파라미터**가 전부.
- localStorage 키: `gs_reports`, `gs_assets`, `gs_assets_v`.
- 로컬 확인 시 `python -m http.server` 같은 정적 서버 필수 (`file://`는 origin 분리되어 localStorage 공유 안 됨).

## 참고 파일

- `CLAUDE.md` — 프로젝트 컨텍스트 (새 Claude가 자동 로드).
- `index.html` / `report.html` / `status.html` / `admin.html` / `test.html` — 페이지 5개.
- `test.html` — 시나리오 허브(개발용, 사용자 네비에 없음).
