# Firebase 인덱스 설정 가이드

## 빠른 해결 방법

에러 메시지에 표시된 URL을 클릭하면 자동으로 인덱스가 생성됩니다:

```
https://console.firebase.google.com/v1/r/project/lh-notice-77077/firestore/indexes?create_composite=...
```

## 임시 해결책 (이미 적용됨)

앱 코드를 수정하여 클라이언트 측에서 필터링하도록 변경했습니다. 이제 인덱스 없이도 작동하지만, 데이터가 많을 경우 성능이 떨어질 수 있습니다.

## 권장 방법: Firebase Console에서 인덱스 생성

1. Firebase Console 접속: https://console.firebase.google.com
2. 프로젝트 선택: `lh-notice-77077`
3. Firestore Database로 이동
4. Indexes 탭 클릭
5. "Create Index" 버튼 클릭
6. 다음 설정 입력:
   - Collection ID: `notices`
   - Fields to index:
     - Field: `source`, Order: `Ascending`
     - Field: `date`, Order: `Descending`
   - Query scope: `Collection`
7. "Create" 클릭

## 인덱스 생성 후

인덱스가 생성되면 (몇 분 소요) 앱 코드를 다시 원래대로 변경하여 서버 측 필터링을 사용할 수 있습니다:

```dart
stream: FirebaseFirestore.instance
    .collection('notices')
    .where('source', isEqualTo: widget.source)
    .orderBy('date', descending: true)
    .snapshots(),
```

이렇게 하면 더 효율적으로 작동합니다.
