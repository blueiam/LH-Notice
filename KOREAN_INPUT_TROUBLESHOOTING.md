# 한글 입력 문제 해결 가이드

## 시뮬레이터에서 한글 입력이 안 되는 경우

### 1. 시뮬레이터 키보드 설정 확인

Android 시뮬레이터에서 한글 입력을 사용하려면:

1. **시뮬레이터 설정 열기**
   - 시뮬레이터에서 Settings 앱 열기
   - System → Languages & input → Virtual keyboard

2. **한글 키보드 활성화**
   - Gboard 또는 다른 키보드에서 한국어 추가
   - 또는 시뮬레이터의 키보드 아이콘을 길게 눌러 키보드 전환

3. **키보드 전환**
   - 텍스트 입력 필드를 탭하면 키보드가 나타남
   - 키보드의 공백 키 옆에 있는 언어 전환 버튼 클릭
   - 또는 시뮬레이터 메뉴에서 키보드 언어 변경

### 2. 시뮬레이터 확장 컨트롤 사용

시뮬레이터의 확장 컨트롤(Extended Controls)에서:
- Settings → Language → 한국어 추가
- 또는 키보드 단축키로 언어 전환

### 3. 실제 기기에서 테스트

시뮬레이터에서 계속 문제가 발생하면:
- 실제 Android 기기에서 테스트 권장
- 실제 기기에서는 한글 입력이 정상적으로 작동합니다

### 4. 코드 측 확인 사항

현재 코드는 한글 입력을 허용하도록 설정되어 있습니다:
- `keyboardType` 제한 없음
- `inputFormatters` 없음 (모든 문자 허용)
- `enableSuggestions: true`
- `autocorrect: true`

## 해결 방법

1. **시뮬레이터 재시작**
   ```bash
   # 시뮬레이터 종료 후 재시작
   ```

2. **앱 재설치**
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

3. **실제 기기에서 테스트**
   - USB 디버깅 활성화
   - `flutter devices`로 기기 확인
   - `flutter run -d <device-id>`로 실행

## 참고

- Flutter 앱 자체는 한글 입력을 완전히 지원합니다
- 문제는 대부분 시뮬레이터의 키보드 설정 문제입니다
- 실제 Android 기기에서는 한글 입력이 정상 작동합니다
