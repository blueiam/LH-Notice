import firebase_admin
from firebase_admin import credentials, firestore
import os

# 1. Firebase 초기화
cred_path = os.path.join(os.path.dirname(__file__), 'serviceAccountKey.json')
cred = credentials.Certificate(cred_path)
firebase_admin.initialize_app(cred)
db = firestore.client()

def delete_collection(coll_ref, batch_size):
    docs = coll_ref.limit(batch_size).stream()
    deleted = 0

    for doc in docs:
        print(f'삭제 중: {doc.id}')
        doc.reference.delete()
        deleted += 1

    if deleted >= batch_size:
        return delete_collection(coll_ref, batch_size)

# 2. 'notices' 컬렉션 싹 비우기
print("DB 초기화를 시작합니다...")
delete_collection(db.collection('notices'), 10)
print("✅ DB 초기화 완료! 이제 main.py를 다시 실행하세요.")