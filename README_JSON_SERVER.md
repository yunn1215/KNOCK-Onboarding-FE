## json-server 실행 가이드 (Knock App)

### 1) 사전 준비
- **Node.js** 설치
- 프로젝트 루트에 `db.json` 존재 (이미 포함)

### 2) json-server 설치/실행

전역 설치(권장):

```bash
npm i -g json-server
```

실행:

```bash
json-server --watch db.json --port 3000
```

정상 확인:
- `GET /posts`: `http://localhost:3000/posts`
- `GET /replies`: `http://localhost:3000/replies`

### 3) 앱에서 접속 주소(중요)

앱의 기본 Base URL은 `lib/core/network/api_client.dart`의 규칙을 따릅니다.

- **iOS 시뮬레이터 / macOS 데스크탑(해당 시)**: `http://localhost:3000`
- **Android 에뮬레이터**: `http://10.0.2.2:3000`

> 실기기에서 테스트하면 PC의 로컬 IP로 바꿔야 합니다.  
> 필요하면 `ApiClient.create(baseUrl: 'http://<내PC IP>:3000')` 형태로 주입하세요.

### 4) 과제 요구 엔드포인트(8개)

- **Post**
  - `GET /posts` (목록)
  - `GET /posts/:id` (상세)
  - `POST /posts` (작성)
  - `PATCH /posts/:id` (수정)
  - `DELETE /posts/:id` (삭제)
- **Reply**
  - `GET /replies?postId=:postId&_page=:page&_limit=10` (댓글 조회/페이지네이션)
  - `POST /replies` (댓글 작성)
  - `DELETE /replies/:id` (댓글 삭제)

### 5) 오프라인(Fallback) 동작

- Repository가 **Remote 우선**으로 호출합니다.
- Remote 실패 시 **SharedPreferences 캐시**를 읽어 화면에 표시합니다.
- 댓글은 스크롤 하단 근처 도달 시 **10개씩 추가 로딩**합니다.

