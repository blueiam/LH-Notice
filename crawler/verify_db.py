import firebase_admin
from firebase_admin import credentials, firestore
import os

# Firebase 초기화
if not firebase_admin._apps:
    cred_path = os.path.join(os.path.dirname(__file__), 'serviceAccountKey.json')
    cred = credentials.Certificate(cred_path)
    firebase_admin.initialize_app(cred)

db = firestore.client()

# 데이터 가져오기
print("=== Firestore 데이터 확인 시작 ===")
docs = db.collection('notices').stream()

count = 0
for doc in docs:
    data = doc.to_dict()
    print(f"[{count+1}] {data.get('title', '제목 없음')}")
    print(f"    링크: {data.get('link', '링크 없음')}")
    print("-" * 30)
    count += 1

if count == 0:
    print("데이터가 없습니다. (정말 비어있음)")
else:
    print(f"총 {count}개의 데이터가 확인되었습니다!")