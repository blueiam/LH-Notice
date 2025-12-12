import firebase_admin
from firebase_admin import credentials, messaging
import os

def send_test_alert():
    # 1. Firebase 초기화
    if not firebase_admin._apps:
        cred_path = os.path.join(os.path.dirname(__file__), 'serviceAccountKey.json')
        cred = credentials.Certificate(cred_path)
        firebase_admin.initialize_app(cred)

    print("📢 알림 발송 준비 중...")

    # 2. 메시지 구성
    # 앱에서 'lh_notice' 주제를 구독하고 있어야 합니다.
    message = messaging.Message(
        notification=messaging.Notification(
            title="[테스트] 알림이 잘 오나요?",
            body="이 메시지가 보이면 앱 설정 성공입니다! 🎉",
        ),
        topic='lh_notice',
    )

    # 3. 발송
    try:
        response = messaging.send(message)
        print(f"✅ 성공! 서버에서 보낸 메시지 ID: {response}")
        print("👉 이제 핸드폰을 확인해보세요!")
    except Exception as e:
        print(f"❌ 실패: {e}")

if __name__ == "__main__":
    send_test_alert()