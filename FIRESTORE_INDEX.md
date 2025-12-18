# Firestore 인덱스 설정 가이드

## 필수 복합 인덱스 생성

앱에서 `source` 필드로 필터링하고 `date` 필드로 정렬하는 쿼리를 사용하므로, Firestore에 복합 인덱스를 생성해야 합니다.

## 자동 인덱스 생성 (권장)

1. Firebase Console에 접속: https://console.firebase.google.com
2. 프로젝트 선택: `lh-notice-77077`
3. Firestore Database로 이동
4. 앱을 실행하고 쿼리를 실행하면 자동으로 인덱스 생성 링크가 표시됩니다
5. 링크를 클릭하여 인덱스 생성

## 수동 인덱스 생성

Firebase Console > Firestore Database > Indexes 탭에서 다음 인덱스를 생성하세요:

### 인덱스 1: notices 컬렉션
- Collection ID: `notices`
- Fields:
  - `source` (Ascending)
  - `date` (Descending)
- Query scope: Collection

### 인덱스 생성 명령어 (Firebase CLI 사용 시)

```bash
firebase deploy --only firestore:indexes
```

또는 `firestore.indexes.json` 파일 생성:

```json
{
  "indexes": [
    {
      "collectionGroup": "notices",
      "queryScope": "COLLECTION",
      "fields": [
        {
          "fieldPath": "source",
          "order": "ASCENDING"
        },
        {
          "fieldPath": "date",
          "order": "DESCENDING"
        }
      ]
    }
  ],
  "fieldOverrides": []
}
```

## 확인 방법

인덱스가 생성되면 앱에서 다음 쿼리가 정상 작동합니다:

```dart
FirebaseFirestore.instance
    .collection('notices')
    .where('source', isEqualTo: 'LH')
    .orderBy('date', descending: true)
    .snapshots()
```

## 참고

- 인덱스 생성에는 몇 분이 소요될 수 있습니다
- 인덱스가 생성되기 전까지는 쿼리가 실패할 수 있습니다
- 각 소스(LH, KAMS, Seoul)별로 동일한 인덱스를 사용합니다
