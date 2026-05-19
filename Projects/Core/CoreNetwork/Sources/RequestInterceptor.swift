/// 요청 전 수정과 실패 후 재시도 판단을 함께 수행하는 네트워크 인터셉터.
public protocol RequestInterceptor: RequestAdapter, RequestRetrier {}
