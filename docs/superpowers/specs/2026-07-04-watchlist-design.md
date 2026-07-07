# 관심종목(워치리스트) 설계

- **날짜**: 2026-07-04
- **상태**: 승인됨 (사용자 검토 대기)
- **대상**: 백엔드(`Tumo`, Spring Boot) 관심종목 CRUD API + iOS(`Tumo-iOS`) 종목 상세 ★ 토글·종목 탭 '관심' 세그먼트

## 배경 & 목표

사용자가 종목을 관심 목록에 담고, 종목 탭에서 관심종목만 모아 볼 수 있게 한다. 백엔드에 관심종목 저장소·API를 추가하고, iOS는 종목 상세의 ★ 토글과 종목 탭의 '관심' 세그먼트로 노출한다. 시세는 기존 합성 경로를 재사용하며, 관심종목 목록 응답은 기존 종목 목록과 동일한 형태(`StockPageResponse`)로 내려 iOS 통합을 최소화한다.

## 확정된 결정 (브레인스토밍)

1. **목록 위치**: 종목 탭의 정렬 세그먼트에 '관심' 추가 (기존 종목 리스트 화면 재사용)
2. **응답 형태**: 관심종목 목록 = 기존 `StockPageResponse`(시세 포함) 재사용 (접근법 A)
3. **추가/삭제**: 멱등 `POST`/`DELETE /watchlist/{stockCode}` (409 대신 멱등 설계)
4. **iOS 배치**: 새 모듈 없이 **StockFeature 안**에 구현 (포트폴리오 전례와 동일)

## 아키텍처

백엔드 먼저(API 계약 확정) → iOS. 두 저장소는 각각 별도 브랜치·PR.

### 백엔드 — WatchlistItem + 4개 엔드포인트

**엔티티** `watchlist/domain/WatchlistItem` (`Holding` 미러, 단 `@Version` 불필요 — 삽입/삭제만 있어 경합은 유니크 제약이 방어):
- `id`, `@ManyToOne(LAZY) user`, `@ManyToOne(LAZY) stock`, `createdAt`
- 유니크 제약 `uk_watchlist_user_stock (user_id, stock_id)`
- `public WatchlistItem(User user, Stock stock)` 생성자 (createdAt은 생성 시 `LocalDateTime.now()`)

**Repository** `WatchlistItemRepository extends JpaRepository<WatchlistItem, Long>`:
- `Optional<WatchlistItem> findByUserAndStock(User user, Stock stock)`
- `Page<WatchlistItem> findByUserOrderByCreatedAtDesc(User user, Pageable pageable)`
- `boolean existsByUserAndStock(User user, Stock stock)`
- `void deleteByUserAndStock(User user, Stock stock)`

**엔드포인트** (모두 JWT 인증, `Authentication principal → (Long) userId`), `WatchlistController` + `WatchlistService`:

| 메서드 | 경로 | 응답 | 동작 |
|--------|------|------|------|
| GET | `/api/v1/watchlist?page&size` | `StockPageResponse` (기존 DTO 재사용) | 추가 최신순, slice 페이지네이션. 각 종목 시세는 `StockService`의 현재가 갱신 경로 재사용 |
| POST | `/api/v1/watchlist/{stockCode}` | 201 (바디 없음) | **멱등**: 이미 있으면 그대로 성공. 종목 없으면 404 `STOCK_NOT_FOUND`. 동시 더블탭은 유니크 제약 위반(`DataIntegrityViolationException`)을 잡아 성공 처리 |
| DELETE | `/api/v1/watchlist/{stockCode}` | 204 | **멱등**: 없어도 204 |
| GET | `/api/v1/watchlist/{stockCode}` | `WatchedResponse { watched: boolean }` (신규 DTO) | 종목 상세 ★ 초기 상태 |

- **가격 합성 재사용**: 관심종목 목록은 `Stock`을 모아 `StockService`의 현재가 갱신·`StockResponse.from(stock, stockPrice)` 경로를 재사용한다. `WatchlistService`가 `StockService`(또는 공용 가격 갱신 헬퍼)를 협력자로 사용하도록 구성해 중복 매핑을 피한다.
- **신규 ErrorCode 없음**: 멱등 설계 + 기존 `STOCK_NOT_FOUND` 재사용 (YAGNI).
- **테스트**(Mockito+AssertJ, 기존 컨벤션): 추가 성공 / 중복 추가 멱등 / 삭제 / 없는 항목 삭제 멱등 / 목록 매핑·정렬·hasNext / 미존재 종목 추가 → `STOCK_NOT_FOUND` / `watched` 조회 true·false.

### iOS — StockFeature 확장 (신규 모듈 없음)

**데이터 계층** (기존 세로 슬라이스에 추가):
- `StockAPI` 신규 case (모두 authorizedProvider):
  - `.watchlist(page: Int, size: Int)` → `GET /api/v1/watchlist`
  - `.watched(stockCode: String)` → `GET /api/v1/watchlist/{stockCode}`
  - `.addWatchlist(stockCode: String)` → `POST /api/v1/watchlist/{stockCode}` (`.requestPlain`)
  - `.removeWatchlist(stockCode: String)` → `DELETE /api/v1/watchlist/{stockCode}` (`.requestPlain`)
- `StockClient` 신규 클로저 4개:
  - `fetchWatchlist: (_ page: Int, _ size: Int) async throws -> StockPage`
  - `fetchWatched: (_ stockCode: String) async throws -> Bool`
  - `addToWatchlist: (_ stockCode: String) async throws -> Void`
  - `removeFromWatchlist: (_ stockCode: String) async throws -> Void`
  - DataSource/Repository/Usecase + `StockAssembly` 배선 (기존 패턴). `WatchedResponseDTO { watched: Bool }` → Bool 매핑.

**종목 상세 ★ 토글** (`StockDetailFeature` / `StockDetailView`):
- State: `isWatched: Bool?` (nil = 로딩 전)
- `onAppear` → `loadWatched` 효과 추가(기존 `loadHolding`과 `.merge`로 병렬)
- Action: `loadWatched`, `watchedLoaded(Bool)`, `watchedLoadFailed`, `starTapped`, `watchlistToggleFailed(Bool)`(원복용)
- `starTapped` → **낙관적 토글**: `isWatched.toggle()` 즉시 반영 후 add/remove 호출, 실패 시 이전 값으로 원복
- View: 헤더 `HStack(종목명, MarketBadge)` 뒤 `Spacer()` + ★ 버튼. 채워진 별(`star.fill`, `tumoBlue`)/빈 별(`star`, `tumoMuted`). `isWatched == nil`이면 비활성/숨김.

**종목 탭 '관심' 세그먼트** (`StockFeature` / `StockView`):
- `StockSortOption`에 `case watchlist`("관심") 추가. `id`/`title`은 기존 패턴. `rankingType`은 관심 케이스에서 사용하지 않음(옵셔널/무시).
- 리듀서: 선택이 `.watchlist`면 랭킹/목록 대신 `stockClient.fetchWatchlist(page,size)` 호출. 나머지 케이스는 기존 로직 유지.
- 빈 상태 문구: "관심종목이 없어요. 종목 상세에서 ★을 눌러 추가해 보세요."
- 행 UI·페이지네이션·당겨서 새로고침·행 탭→상세는 기존 그대로 재사용.
- **동기화 한계(범위 밖)**: 상세에서 ★ 해제 후 목록 복귀 시 즉시 반영은 세그먼트 재진입/새로고침 때 이뤄짐. 실시간 상호 동기화는 하지 않음.

## 데이터 흐름

```
[추가] StockDetailView ★ 탭
  → StockDetailFeature.starTapped (isWatched=true 즉시)
  → stockClient.addToWatchlist(code)  // POST /watchlist/{code} (멱등)
  → 실패 시 watchlistToggleFailed(false)로 원복

[목록] StockView '관심' 세그먼트 선택
  → StockFeature: fetchWatchlist(page,size)  // GET /watchlist → StockPage
  → 기존 종목 행/페이지네이션 렌더
```

## 테스트

- **백엔드**: `WatchlistService` 단위(위 8케이스), 필요 시 `WatchlistController` 슬라이스.
- **iOS `StockDetailFeature`**: `watched` 로드(true/false), 낙관적 토글 성공(add 호출), 실패 시 원복(`watchlistToggleFailed`).
- **iOS `StockFeature`**: '관심' 세그먼트 선택 → `fetchWatchlist` 호출·목록 반영, 빈 상태.
- `TestStore` + `withDependencies`(기존 StockFeature 패턴). `stockClient`에 신규 클로저 testValue(fatalError) 추가 필요 시 반영.

## 신규/수정 파일 (요약)

**백엔드 (신규)**
- `watchlist/domain/WatchlistItem.java`
- `watchlist/repository/WatchlistItemRepository.java`
- `watchlist/service/WatchlistService.java`
- `watchlist/controller/WatchlistController.java`
- `watchlist/dto/WatchedResponse.java`
- (재사용) `stock/dto/StockPageResponse.java`, `StockResponse.java`, 현재가 갱신 경로
- 테스트: `WatchlistServiceTest.java`

**iOS (수정, StockFeature 내)**
- `Data/API/StockAPI.swift` (+4 case)
- `Data/DTO/WatchedResponseDTO.swift` (신규)
- DataSource/Repository/Usecase(+4) + `StockClient.swift`/`StockAssembly.swift`
- `Presentation/StockDetail/Feature/StockDetailFeature.swift` + `View/StockDetailView.swift` (★)
- `Presentation/Stock/Feature/StockFeature.swift` + `View/StockView.swift` (관심 세그먼트)
- `Tests/Sources/StockFeatureTests.swift` (신규 테스트)

## 엣지 케이스

- **동시 더블탭 추가**: 유니크 제약 위반 → 서버가 멱등 성공 처리. iOS 낙관적 토글은 최종 상태로 수렴.
- **미존재 종목 추가**: 404 `STOCK_NOT_FOUND` → iOS는 토글 원복 + (선택) 토스트.
- **시세 조회 실패**: 목록의 해당 종목은 시세 필드 nil로 내려감(기존 `StockResponse.from(stock)` 폴백).
- **비로그인**: 모든 관심 API는 인증 필요 → 기존 인터셉터 토큰 갱신에 위임.

## 범위 밖 (YAGNI)

- 관심 목록 직접 편집(순서 변경, 스와이프 삭제)
- 홈 화면 관심 섹션
- 관심종목 실시간 시세 스트리밍
- 관심 개수 상한, 폴더/그룹
- 상세↔목록 실시간 상호 동기화

## 오픈 리스크

- `WatchlistService`의 가격 합성 재사용 방식: `StockService`의 현재가 갱신 로직이 `private`이면, 공용 헬퍼로 추출하거나 `StockService`의 공개 메서드(예: 종목 목록 매핑)를 협력자로 사용. 구현 첫 단계에서 실제 가시성을 확인해 중복 없이 재사용.
