# Knock-Onboarding

게시글과 댓글을 중심으로 동작하는 작은 커뮤니티 앱입니다.
Flutter 온보딩 과제로 개발했으며, 게시글과 댓글의 기본적인 흐름을 경험할 수 있도록 구성했습니다.

게시글 작성부터 댓글, 좋아요, 검색과 필터 기능까지 간단한 커뮤니티 서비스에서 자주 사용되는 기능들을 구현했습니다.

주요 기능

이 앱에서는 다음과 같은 기능을 사용할 수 있습니다.

게시글 작성, 조회, 수정, 삭제 기능을 제공합니다.

댓글 작성, 수정, 삭제가 가능합니다.

좋아요 기능은 서버 응답을 기다리지 않고 바로 반영되는 낙관적 업데이트 방식으로 구현했습니다.

게시글에 이미지를 base64 형태로 업로드할 수 있습니다.

검색 기능은 입력 후 약 300ms 동안 추가 입력이 없을 때 요청이 보내지는 디바운스 방식으로 처리했습니다.

필터 기능을 통해 유형(전체 / 게시글 / 질문), 작성자, 기간을 조합하여 게시글을 조회할 수 있습니다.

댓글 목록은 무한 스크롤 방식으로 동작하며 10개씩 추가 로드됩니다.

전체 흐름은 다음과 같습니다.

게시글 목록 → 게시글 상세 → 댓글 조회 및 작성

간단한 커뮤니티 서비스의 기본적인 사용자 흐름을 경험할 수 있도록 구성했습니다.

실행 방법
1. 의존성 설치
flutter pub get
2. 백엔드(json-server) 실행

게시글과 댓글 API는 로컬 json-server를 사용합니다.
프로젝트 루트의 db.json 파일을 데이터베이스로 사용합니다.

json-server --watch db.json

json-server가 실행되면 기본적으로 다음 주소에서 API를 사용할 수 있습니다.

http://localhost:3000
3. 앱 실행
flutter run
테스트 실행

전체 테스트 실행

flutter test

커버리지 포함 실행

flutter test --coverage

커버리지 결과는 다음 위치에 생성됩니다.

coverage/lcov.info
화면 구성
게시글 목록

게시글 목록 조회

검색 기능 (디바운스 300ms 적용)

필터 BottomSheet

게시글 상세

게시글 본문 조회

댓글 목록 조회

댓글 10개 단위 무한 스크롤

댓글 총 개수 표시

게시글 작성 / 수정

제목 입력

내용 입력

이미지 선택 및 미리보기

필터

BottomSheet 형태로 제공됩니다.

다음 세 가지 조건을 조합하여 게시글을 조회할 수 있습니다.

유형 (전체 / 게시글 / 질문)

작성자

기간

아키텍처

프로젝트는 Feature 기반 구조로 구성했습니다.

상태 관리는 BLoC 패턴을 사용합니다.

features/post
 ├ domain
 │   ├ entities
 │   └ repositories
 │
 ├ data
 │   ├ datasources (remote / local)
 │   ├ models
 │   └ repositories (implementation)
 │
 └ presentation
     ├ bloc
     ├ pages
     └ widgets
사용 기술

State Management
flutter_bloc

Network
dio

Mock Backend
json-server

Local Cache
shared_preferences

데이터 처리 방식

데이터는 다음 순서로 처리됩니다.

Remote → 실패 시 Local 캐시 fallback

서버 요청이 실패할 경우 로컬 캐시에 저장된 데이터를 사용하도록 구현했습니다.

개발 시 참고 사항

mocktail을 사용할 때 any()로 사용하는 타입은 registerFallbackValue를 등록해야 합니다.

json-server의 검색 쿼리 제한 때문에 검색 결과는 클라이언트에서 한 번 더 필터링하도록 처리했습니다.

리스트 처리 시 reversed.toList()를 반복 호출하지 않도록 구조를 정리했습니다.

가능한 부분에는 const를 사용하여 불필요한 객체 생성을 줄였습니다.

테스트

다음 영역을 중심으로 테스트를 작성했습니다.

Entity

Repository (Remote / Local mocking)

BLoC (bloc_test, mocktail 사용)

현재 테스트 상태

테스트 20개 이상

전체 통과율 100%

코드 커버리지 65% 이상

알림 기능은 아직 구현하지 않았습니다.

감사합니다