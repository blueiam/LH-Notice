import firebase_admin
from firebase_admin import credentials, messaging
import os

def send_test_notification_for_source(source, source_name):
    """각 소스별 테스트 알림 발송"""
    try:
        message = messaging.Message(
            notification=messaging.Notification(
                title=f"[{source_name}]",
                body=f"테스트 알림: {source_name} 알림이 정상적으로 발송됩니다.",
            ),
            data={
                'link': 'https://www.lh.or.kr',
                'source': source,
                'click_action': 'FLUTTER_NOTIFICATION_CLICK'
            },
            topic='lh_notice',
            android=messaging.AndroidConfig(
                priority='high',
                notification=messaging.AndroidNotification(
                    priority='high',
                    sound='default',
                    channel_id='lh_notice_channel'
                )
            ),
        )
        response = messaging.send(message)
        print(f"✅ [{source_name}] 알림 발송 성공! Message ID: {response}")
        return True
    except Exception as e:
        print(f"❌ [{source_name}] 알림 발송 실패: {e}")
        return False

def main():
    # Firebase 초기화
    if not firebase_admin._apps:
        cred_path = os.path.join(os.path.dirname(__file__), 'serviceAccountKey.json')
        if not os.path.exists(cred_path):
            print(f"❌ 키 파일 없음: {cred_path}")
            return
        
        cred = credentials.Certificate(cred_path)
        firebase_admin.initialize_app(cred)

    print("=" * 50)
    print("📢 각 소스별 FCM 알림 테스트 시작")
    print("=" * 50)
    
    # 각 소스별 테스트 알림 발송
    sources = [
        ('LH', 'LH 공모 알림'),
        ('KAMS', '예술경영지원센터 알림'),
        ('Seoul', '서울 공공디자인 알림'),
        ('SeoulPublicArt', '서울 공공미술 공모 알림'),
    ]
    
    success_count = 0
    for source, source_name in sources:
        print(f"\n📤 [{source}] 알림 발송 중...")
        if send_test_notification_for_source(source, source_name):
            success_count += 1
        import time
        time.sleep(1)  # 1초 간격으로 발송
    
    print("\n" + "=" * 50)
    print(f"✅ 테스트 완료: {success_count}/{len(sources)}개 알림 발송 성공")
    print("=" * 50)
    print("👉 이제 앱에서 알림을 확인해보세요!")

if __name__ == "__main__":
    main()

