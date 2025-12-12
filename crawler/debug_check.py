import firebase_admin
from firebase_admin import credentials, firestore
import os
import json

# 1. 키 파일 로드 및 프로젝트 ID 확인
key_path = os.path.join(os.path.dirname(__file__), 'serviceAccountKey.json')

if not os.path.exists(key_path):
    print(f"❌ 오류: 파일이 없습니다 -> {key_path}")
    exit()

# JSON 파일 직접 읽어서 ID 확인
with open(key_path, 'r') as f:
    key_data = json.load(f)
    project_id_in_file = key_data.get('project_id')

print(f"🔑 내 컴퓨터(JSON)가 보고 있는 프로젝트 ID: [ {project_id_in_file} ]")

# 2. Firebase 연결
if not firebase_admin._apps:
    cred = credentials.Certificate(key_path)
    firebase_admin.initialize_app(cred)

db = firestore.client()

# 3. 강제 쓰기 테스트
print("\n🧪 강제 쓰기 테스트 중...")
try:
    # 'debug_test'라는 컬렉션에 데이터를 억지로 넣어봅니다.
    db.collection('debug_test').document('test_doc').set({
        'message': 'Hello Firebase!',
        'timestamp': firestore.SERVER_TIMESTAMP
    })
    print("✅ 쓰기 성공! (데이터를 보냈습니다)")
except Exception as e:
    print(f"❌ 쓰기 실패: {e}")

# 4. 방금 쓴 거 읽어오기
print("\n👀 방금 쓴 데이터 확인 중...")
doc = db.collection('debug_test').document('test_doc').get()
if doc.exists:
    print(f"✅ 읽기 성공! 내용: {doc.to_dict()}")
    print("🎉 결론: 연결은 완벽합니다. 웹사이트에서 프로젝트 ID를 다시 확인하세요.")
else:
    print("❌ 읽기 실패: 썼는데 없네요..?")