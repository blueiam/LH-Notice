import firebase_admin
from firebase_admin import credentials, messaging
import os

# 1. Firebase 설정 (기존 키 파일 사용)
cred_path = os.path.join(os.path.dirname(__file__), 'serviceAccountKey.json')
cred = credentials.Certificate(cred_path)
firebase_admin.initialize_app(cred)

# 2. 테스트 메시지 구성
print("🔔 테스트 알림을 전송합니다...")

message = messaging.Message(
    notification=messaging.Notification(
        title="[테스트] 알림 시스템 점검",
        body="이 알림이 보이면 앱 연결 성공입니다! 🎉",
    ),
    data={
        'link': 'https://www.lh.or.kr',
        'type': 'test'
    },
    topic='lh_notice',  # 앱에서 구독 중인 주제
)

# 3. 전송
try:
    response = messaging.send(message)
    print('✅ 성공! 메시지 ID:', response)
except Exception as e:
    print('❌ 실패:', e)