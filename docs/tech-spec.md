# Tumo iOS Tech Spec

Tumo iOS 앱의 기술 방향, 아키텍처, 모듈 전략 정의.

## 1. Overview

Tumo iOS는 Tumo Backend Phase 1 API와 연동해 다음 핵심 흐름을 제공.

```text
회원가입/로그인
→ 종목 조회
→ 매수 주문
→ 포트폴리오 조회
```

초기 목표는 백엔드 Phase 1 API를 안정적으로 연결하고, 이후 기능 확장에 견딜 수 있는 iOS 구조를 만드는 것.

## 2. Goals

```text
SwiftUI 기반 화면 구현
TCA 기반 상태 관리
Feature 단위 모듈화
Feature 내부 Clean Architecture 계층 분리
Swift Modern Concurrency 기반 비동기 처리
Tuist 기반 프로젝트/모듈 관리
Keychain 기반 토큰 저장
백엔드 Phase 1 API end-to-end 연동
```

## 3. Non-Goals

초기 단계에서 제외.

```text
과도한 Micro Module 분리
FeatureInterface / FeatureTesting 모듈 분리
RxSwift / Combine 중심 비동기 구조
오프라인 캐싱
실시간 시세 WebSocket
복잡한 앱 라우팅 프레임워크
```

## 4. Tech Stack

| 구분 | 기술 |
|------|------|
| UI | SwiftUI |
| Architecture | TCA, Clean Architecture |
| Concurrency | Swift Modern Concurrency |
| Project Generation | Tuist |
| Networking | URLSession 기반 async/await |
| Token Storage | Keychain |
| State Management | TCA Store / Reducer |
| Test | XCTest, TCA TestStore |

## 5. Module Strategy

모듈은 Feature 단위로 분리.

초기에는 Domain/Data/Interface를 별도 모듈로 쪼개지 않고, 하나의 Feature 모듈 안에서 폴더로 계층을 나눔.

```text
Feature 단위 모듈
→ AuthFeature
→ StockFeature
→ OrderFeature
→ PortfolioFeature
```

Core는 여러 Feature가 공유하는 기반 기능만 분리.

```text
CoreNetwork
CoreStorage
CoreDesignSystem
CoreModels
CoreDependencies
```

## 6. Target Project Structure

Tuist 적용 이후 목표 구조.

```text
Projects/
├── App/
│   └── Tumo
├── Core/
│   ├── CoreNetwork
│   ├── CoreStorage
│   ├── CoreDesignSystem
│   ├── CoreModels
│   └── CoreDependencies
└── Features/
    ├── AuthFeature
    ├── StockFeature
    ├── OrderFeature
    └── PortfolioFeature
```

현재 Xcode 기본 프로젝트에서 시작한 뒤, Tuist 도입 시 위 구조로 전환.

## 7. Feature Internal Structure

Feature 모듈 내부는 Clean Architecture 계층을 폴더로 표현.

예시: `AuthFeature`

```text
AuthFeature/
├── Presentation/
│   ├── LoginView.swift
│   ├── SignupView.swift
│   └── AuthFeature.swift
├── Domain/
│   ├── AuthUseCase.swift
│   ├── AuthRepository.swift
│   └── Entity/
└── Data/
    ├── AuthRepositoryImpl.swift
    ├── AuthAPI.swift
    └── DTO/
```

계층 역할:

| 계층 | 역할 |
|------|------|
| Presentation | SwiftUI View, TCA Reducer, View State |
| Domain | UseCase, Repository protocol, 도메인 모델 |
| Data | Repository 구현체, API 호출, DTO 변환 |

## 8. Dependency Direction

의존 방향:

```text
Presentation
→ Domain
← Data
```

Feature 내부 규칙:

```text
View는 Repository 구현체를 직접 알지 않음
Reducer는 UseCase를 통해 비즈니스 흐름 실행
UseCase는 Repository protocol에 의존
Repository 구현체는 Data 계층에 위치
DTO는 Data 계층에 위치
Domain 모델은 API 응답 DTO에 의존하지 않음
```

## 9. TCA Policy

TCA는 화면 상태와 사용자 액션 처리에 사용.

기본 흐름:

```text
View
→ Store
→ Reducer
→ UseCase
→ Repository
→ APIClient
```

Reducer 규칙:

```text
Reducer에서 URLSession 직접 호출 금지
Reducer에서 Keychain 직접 접근 금지
비동기 작업은 Effect.run 사용
UseCase는 Dependency로 주입
상태 변경은 Reducer에서 명확하게 처리
```

예시:

```swift
case .loginButtonTapped:
    return .run { [email = state.email, password = state.password] send in
        do {
            let token = try await authUseCase.login(email: email, password: password)
            await send(.loginResponse(.success(token)))
        } catch {
            await send(.loginResponse(.failure(error)))
        }
    }
```

## 10. Swift Modern Concurrency Policy

비동기 처리는 `async/await`를 기본으로 사용.

```text
URLSession async API 사용
Repository method는 async throws 기본
UseCase method는 async throws 기본
UI 상태 변경은 MainActor 경계 준수
Task cancellation 고려
Sendable 경고 대응
```

Repository protocol 예시:

```swift
protocol AuthRepository {
    func login(email: String, password: String) async throws -> LoginToken
    func signup(email: String, password: String, nickname: String) async throws -> User
    func refreshToken(_ refreshToken: String) async throws -> LoginToken
    func logout() async throws
}
```

## 11. Networking Policy

CoreNetwork에서 공통 네트워크 기능 제공.

역할:

```text
Base URL 관리
URLRequest 생성
JSON Encoding/Decoding
HTTP status 검증
공통 ErrorResponse 파싱
Authorization 헤더 추가
401 응답 처리
```

기본 API 주소:

```text
http://localhost:8080
```

인증 헤더:

```http
Authorization: Bearer {accessToken}
```

공통 에러 응답:

```json
{
  "code": "ERROR_CODE",
  "message": "에러 메시지",
  "fieldErrors": []
}
```

## 12. Token Storage Policy

토큰 저장은 CoreStorage에서 담당.

```text
accessToken
→ Keychain 저장

refreshToken
→ Keychain 저장

로그아웃
→ accessToken 삭제
→ refreshToken 삭제
→ 서버 logout API 호출
```

`UserDefaults`에 토큰 저장 금지.

## 13. Token Refresh Policy

인증이 필요한 API 요청 흐름:

```text
1. accessToken으로 API 요청
2. 401 INVALID_TOKEN 응답 수신
3. refreshToken으로 재발급 요청
4. 재발급 성공 시 토큰 저장
5. 원래 요청 1회 재시도
6. 재발급 실패 시 로컬 토큰 삭제 및 로그인 화면 이동
```

무한 재시도 방지:

```text
원래 요청 재시도는 최대 1회
refresh API 자체는 refresh 재시도 대상에서 제외
logout API 실패 시 로컬 토큰 삭제 우선
```

## 14. Feature Plan

### AuthFeature

```text
회원가입
로그인
로그아웃
토큰 재발급
내 정보 조회
```

### StockFeature

```text
종목 목록 조회
종목 상세 조회
```

### OrderFeature

```text
매수 주문
잔고 부족 에러 표시
주문 성공 결과 표시
```

### PortfolioFeature

```text
현금 잔고 표시
보유 종목 목록 표시
평가 금액 표시
평가손익 표시
수익률 표시
```

## 15. Initial Implementation Order

추천 구현 순서:

```text
1. Tuist 기본 구조 생성
2. CoreNetwork 생성
3. CoreStorage 생성
4. CoreModels 생성
5. AuthFeature 로그인 연동
6. TokenStore 저장/삭제 구현
7. 내 정보 조회 연동
8. StockFeature 종목 목록 연동
9. OrderFeature 매수 주문 연동
10. PortfolioFeature 포트폴리오 조회 연동
```

첫 번째 end-to-end 목표:

```text
로그인 성공
→ accessToken / refreshToken 저장
→ 내 정보 조회 성공
```

두 번째 end-to-end 목표:

```text
종목 목록 조회
→ 매수 주문
→ 포트폴리오 조회
```

## 16. Testing Strategy

### Unit Test

```text
UseCase 테스트
Repository mock 테스트
TokenStore 테스트
APIError 매핑 테스트
DTO decoding 테스트
```

### TCA Test

```text
로그인 성공/실패 상태 변화
회원가입 검증 에러 상태 변화
종목 목록 로딩 상태
매수 주문 성공/실패 상태
포트폴리오 조회 상태
```

### Integration Test

```text
APIClient request 생성 검증
ErrorResponse decoding 검증
Token refresh 흐름 검증
```

## 17. Refactoring Policy

초기에는 Feature 단위 모듈만 분리.

다음 상황이 생기면 더 엄격한 모듈 분리 검토.

```text
Feature 간 의존성이 복잡해지는 경우
Domain 로직 재사용이 많아지는 경우
Data 구현 교체 필요성이 커지는 경우
테스트 전용 모듈 필요성이 생기는 경우
빌드 시간이 크게 증가하는 경우
```

추후 분리 후보:

```text
AuthFeatureInterface
AuthFeatureTesting
CoreNetworkingTesting
Feature별 Domain/Data 모듈 분리
```

## 18. Backend API References

Backend 문서 기준:

```text
Phase 1 API 명세
Phase 1 API 테스트 가이드
에러 응답 형식
JWT 인증
Refresh Token 정책
```

Backend 주요 API:

| Method | Endpoint | 설명 |
|--------|----------|------|
| POST | `/api/v1/auth/signup` | 회원가입 |
| POST | `/api/v1/auth/login` | 로그인 |
| POST | `/api/v1/auth/token/refresh` | Access Token 재발급 |
| POST | `/api/v1/auth/logout` | 로그아웃 |
| GET | `/api/v1/users/me` | 내 정보 조회 |
| GET | `/api/v1/stocks` | 종목 목록 조회 |
| GET | `/api/v1/stocks/{stockCode}` | 종목 상세 조회 |
| POST | `/api/v1/orders` | 매수 주문 |
| GET | `/api/v1/portfolio` | 내 포트폴리오 조회 |
