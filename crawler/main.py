import requests
from bs4 import BeautifulSoup
from urllib.parse import urljoin
import firebase_admin
from firebase_admin import credentials, firestore, messaging
import os
import hashlib
import re

# --- 설정값 ---
LH_BASE_URL = "https://www.lh.or.kr"
BOARD_MID = "a10601020000"
BOARD_BID = "0034"

def init_firebase():
    """Firebase 초기화"""
    if not firebase_admin._apps:
        # 현재 파일과 같은 폴더에 serviceAccountKey.json이 있어야 합니다.
        cred_path = os.path.join(os.path.dirname(__file__), 'serviceAccountKey.json')
        if not os.path.exists(cred_path):
            raise FileNotFoundError(f"키 파일 없음: {cred_path}")
        
        cred = credentials.Certificate(cred_path)
        firebase_admin.initialize_app(cred)
    return firestore.client()

def send_fcm_notification(title, link):
    """FCM 알림 발송 함수"""
    try:
        # 'lh_notice'라는 주제(Topic)를 구독한 앱들에게 알림을 쏩니다.
        message = messaging.Message(
            notification=messaging.Notification(
                title="[LH 새 공고 알림]",
                body=title,
            ),
            data={
                'link': link, # 앱에서 클릭 시 이동할 링크
                'click_action': 'FLUTTER_NOTIFICATION_CLICK'
            },
            topic='lh_notice',
        )
        response = messaging.send(message)
        print(f"  📢 [알림 발송 성공] Message ID: {response}")
    except Exception as e:
        print(f"  ⚠️ [알림 발송 실패] {e}")

def check_and_save(db, data):
    """저장 및 알림 트리거"""
    link = data.get('link', '').strip()
    if not link or link == '#': return False
    
    doc_id = hashlib.md5(link.encode('utf-8')).hexdigest()
    
    try:
        notices_ref = db.collection('notices')
        doc_ref = notices_ref.document(doc_id)
        
        # 1. 이미 저장된 글인지 확인
        if doc_ref.get().exists:
            # print(f"  [중복] {data['title']}") # 너무 시끄러우면 주석 처리
            return False 
        
        # 2. 신규 저장
        doc_ref.set({
            'number': data.get('number', ''),
            'title': data.get('title', ''),
            'date': data.get('date', ''),
            'link': link,
            'created_at': firestore.SERVER_TIMESTAMP
        })
        
        # 3. [중요] 저장 성공 시 알림 발송 함수 호출!
        print(f"  💾 [신규 저장 완료] {data['title']}")
        send_fcm_notification(data['title'], link)
        
        return True
    except Exception as e:
        print(f"  DB 에러: {e}")
        return False

def crawl_lh_notice():
    list_url = f"{LH_BASE_URL}/board.es?mid={BOARD_MID}&bid={BOARD_BID}"
    headers = {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
    }
    
    print(f"--- 크롤링 시작: {list_url} ---")
    
    try:
        response = requests.get(list_url, headers=headers, timeout=15)
        response.encoding = response.apparent_encoding
        
        soup = BeautifulSoup(response.text, 'html.parser')
        rows = soup.select('table tbody tr')
        
        if not rows:
            print("❌ 게시물을 찾을 수 없습니다.")
            return

        results = []
        for row in rows:
            # ... (데이터 추출 로직은 아까 검증된 코드와 동일) ...
            cells = row.find_all(['td', 'th'])
            if len(cells) < 3: continue
            
            number = cells[0].get_text(strip=True)
            link_tag = row.find('a')
            if not link_tag: continue

            title = link_tag.get_text(strip=True).replace('새글', '').strip()
            
            link_path = link_tag.get('href', '').strip()
            onclick = link_tag.get('onclick', '')
            final_link = ""

            if link_path and not link_path.startswith('java') and link_path != '#' and link_path != '#none':
                 final_link = urljoin(LH_BASE_URL, link_path)
            elif onclick:
                # onclick에서 실제 링크 경로 추출
                # 예: goView3('729895','/board.es?mid=a10601020000&bid=0034&act=view&list_no=729895&tag=&nPage=1');
                match = re.search(r"['\"](/board\.es\?[^'\"]+)['\"]", onclick)
                if match:
                    # onclick에서 전체 경로 추출
                    path = match.group(1)
                    final_link = urljoin(LH_BASE_URL, path)
                else:
                    # 폴백: list_no만 추출해서 링크 생성
                    match = re.search(r"['\"]?(\d{4,})['\"]?", onclick) 
                    if match:
                        list_no = match.group(1)
                        final_link = f"{LH_BASE_URL}/board.es?mid={BOARD_MID}&bid={BOARD_BID}&act=view&list_no={list_no}&tag=&nPage=1"
            
            if not final_link: continue

            # 날짜 추출
            date_text = cells[-2].get_text(strip=True)
            if not re.search(r'\d{4}[.-]\d{2}[.-]\d{2}', date_text):
                for cell in cells:
                    if re.search(r'\d{4}[.-]\d{2}[.-]\d{2}', cell.get_text(strip=True)):
                        date_text = cell.get_text(strip=True)
                        break

            # 모든 게시글 저장 (키워드 필터링 제거)
            results.append({
                'number': number,
                'title': title,
                'date': date_text,
                'link': final_link
            })

        # DB 저장 및 알림 시도
        if results:
            print(f"총 {len(results)}건의 게시물을 처리합니다...")
            db = init_firebase()
            new_count = 0
            for item in results:
                if check_and_save(db, item):
                    new_count += 1
            print(f"\n=== 실행 완료: {new_count}건 신규 저장 및 알림 전송 ===")
        else:
            print("\n게시물이 없습니다.")

    except Exception as e:
        print(f"에러 발생: {e}")

if __name__ == "__main__":
    crawl_lh_notice()
