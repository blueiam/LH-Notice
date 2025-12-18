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

def send_fcm_notification(title, link, source='LH'):
    """FCM 알림 발송 함수 - 신뢰성 개선"""
    try:
        # 소스별 알림 제목 설정
        source_names = {
            'LH': 'LH 공모 알림',
            'KAMS': '예술경영지원센터 알림',
            'Seoul': '서울특별시 알림',
            'SeoulPublicArt': '서울 공공미술 공모 알림'
        }
        source_name = source_names.get(source, '공모 알림')
        
        # 'lh_notice'라는 주제(Topic)를 구독한 앱들에게 알림을 쏩니다.
        message = messaging.Message(
            notification=messaging.Notification(
                title=f"[{source_name}]",
                body=title,
            ),
            data={
                'link': link, # 앱에서 클릭 시 이동할 링크
                'source': source, # 소스 정보 추가
                'click_action': 'FLUTTER_NOTIFICATION_CLICK'
            },
            topic='lh_notice',
            # 알림 우선순위 설정 (높은 우선순위로 즉시 전달)
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
        print(f"  📢 [알림 발송 성공] Message ID: {response} | Source: {source}")
        return True
    except Exception as e:
        print(f"  ⚠️ [알림 발송 실패] {e}")
        import traceback
        traceback.print_exc()
        return False

def check_and_save(db, data, source='LH'):
    """저장 및 알림 트리거 - source 필드 추가"""
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
        
        # 2. 신규 저장 (source 필드 추가)
        doc_ref.set({
            'number': data.get('number', ''),
            'title': data.get('title', ''),
            'date': data.get('date', ''),
            'link': link,
            'source': source,  # 소스 필드 추가
            'created_at': firestore.SERVER_TIMESTAMP
        })
        
        # 3. [중요] 저장 성공 시 알림 발송 함수 호출!
        print(f"  💾 [신규 저장 완료] {data['title']} | Source: {source}")
        notification_sent = send_fcm_notification(data['title'], link, source)
        
        if not notification_sent:
            print(f"  ⚠️ 알림 발송 실패했지만 데이터는 저장되었습니다.")
        
        return True
    except Exception as e:
        print(f"  DB 에러: {e}")
        import traceback
        traceback.print_exc()
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
                if check_and_save(db, item, source='LH'):
                    new_count += 1
            print(f"\n=== LH 실행 완료: {new_count}건 신규 저장 및 알림 전송 ===")
        else:
            print("\nLH 게시물이 없습니다.")

    except Exception as e:
        print(f"에러 발생: {e}")

def crawl_kams_notice():
    """KAMS 예술경영지원센터 크롤링"""
    list_url = "https://gokams.or.kr/01_news/event_list.aspx"
    headers = {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
    }
    
    print(f"--- KAMS 크롤링 시작: {list_url} ---")
    
    try:
        response = requests.get(list_url, headers=headers, timeout=15)
        response.encoding = response.apparent_encoding or 'utf-8'
        
        soup = BeautifulSoup(response.text, 'html.parser')
        
        # KAMS 사이트 구조: table tr 형태
        rows = soup.select('table tbody tr, table tr')
        
        if not rows:
            print("❌ KAMS 게시물을 찾을 수 없습니다.")
            return

        results = []
        base_url = "https://gokams.or.kr/01_news/"
        
        for row in rows:
            try:
                cells = row.find_all('td')
                if len(cells) < 4:  # 최소 4개 셀 필요
                    continue
                
                # 제목과 링크 추출
                link_tag = row.find('a')
                if not link_tag:
                    continue
                
                title = link_tag.get_text(strip=True)
                # "new" 이미지 텍스트 제거
                title = re.sub(r'\s*\[new\]\s*', '', title, flags=re.IGNORECASE)
                if not title:
                    continue
                
                # 링크 추출
                href = link_tag.get('href', '')
                if not href or href == '#':
                    continue
                
                # 절대 URL로 변환
                if href.startswith('/'):
                    final_link = urljoin('https://gokams.or.kr', href)
                elif href.startswith('http'):
                    final_link = href
                else:
                    final_link = urljoin(base_url, href)
                
                # 날짜 추출 (일반적으로 4번째 또는 5번째 셀)
                date_text = ''
                for cell in cells:
                    cell_text = cell.get_text(strip=True)
                    # 날짜 패턴 찾기 (YYYY-MM-DD 또는 YYYY-MM-DD ~ MM-DD)
                    date_match = re.search(r'(\d{4}[.-]\d{2}[.-]\d{2})', cell_text)
                    if date_match:
                        date_text = cell_text
                        break
                
                if not date_text:
                    date_text = '날짜 없음'
                
                # 번호 추출 (첫 번째 셀)
                number = cells[0].get_text(strip=True) if cells else ''
                
                results.append({
                    'number': number,
                    'title': title,
                    'date': date_text,
                    'link': final_link
                })
            except Exception as e:
                print(f"  ⚠️ 항목 파싱 오류: {e}")
                continue

        # DB 저장 및 알림 시도
        if results:
            print(f"총 {len(results)}건의 KAMS 게시물을 처리합니다...")
            db = init_firebase()
            new_count = 0
            for item in results:
                if check_and_save(db, item, source='KAMS'):
                    new_count += 1
            print(f"\n=== KAMS 실행 완료: {new_count}건 신규 저장 및 알림 전송 ===")
        else:
            print("\nKAMS 게시물이 없습니다.")

    except Exception as e:
        print(f"KAMS 크롤링 에러 발생: {e}")
        import traceback
        traceback.print_exc()

def crawl_seoul_notice():
    """서울특별시 크롤링 (디자인 뉴스)"""
    list_url = "https://news.seoul.go.kr/culture/archives/category/design-news_c1/business_design_c1/news_design-news-n1"
    headers = {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
    }
    
    print(f"--- Seoul 크롤링 시작: {list_url} ---")
    
    try:
        response = requests.get(list_url, headers=headers, timeout=15)
        response.encoding = response.apparent_encoding or 'utf-8'
        
        soup = BeautifulSoup(response.text, 'html.parser')
        
        # 서울시 사이트는 archives/숫자 형태의 링크를 직접 찾아야 함
        all_links = soup.find_all('a', href=True)
        archive_items = []
        
        for link in all_links:
            href = link.get('href', '')
            text = link.get_text(strip=True)
            
            # archives/숫자 형태의 링크 찾기
            if '/archives/' in href:
                # URL에서 숫자 ID 추출
                parts = href.split('/archives/')
                if len(parts) > 1:
                    id_part = parts[1].split('?')[0].split('/')[0]
                    if id_part.isdigit() and text and len(text) > 5:
                        # 의미있는 텍스트가 있는 링크만
                        archive_items.append({
                            'link': link,
                            'href': href,
                            'text': text
                        })
        
        if not archive_items:
            print("❌ Seoul 게시물을 찾을 수 없습니다.")
            return

        results = []
        for item_data in archive_items:
            try:
                link_tag = item_data['link']
                href = item_data['href']
                title = item_data['text']
                
                if not title or not href:
                    continue
                
                # 절대 URL로 변환
                if href.startswith('/'):
                    final_link = urljoin('https://news.seoul.go.kr', href)
                elif href.startswith('http'):
                    final_link = href
                else:
                    final_link = urljoin(list_url, href)
                
                # 날짜 추출 (부모 요소에서 찾기)
                date_text = '날짜 없음'
                parent = link_tag.parent
                if parent:
                    # 부모 요소에서 날짜 찾기
                    date_elements = parent.select('.date, .post-date, time, [class*="date"], [datetime]')
                    if date_elements:
                        date_text = date_elements[0].get_text(strip=True)
                        if not date_text and date_elements[0].get('datetime'):
                            date_text = date_elements[0].get('datetime')
                    else:
                        # 텍스트에서 날짜 패턴 찾기
                        text = parent.get_text()
                        date_match = re.search(r'(\d{4}[.-]\d{2}[.-]\d{2})', text)
                        if date_match:
                            date_text = date_match.group(1)
                
                results.append({
                    'number': '',
                    'title': title,
                    'date': date_text,
                    'link': final_link
                })
            except Exception as e:
                print(f"  ⚠️ 항목 파싱 오류: {e}")
                continue

        if results:
            print(f"총 {len(results)}건의 Seoul 게시물을 처리합니다...")
            db = init_firebase()
            new_count = 0
            for item in results:
                if check_and_save(db, item, source='Seoul'):
                    new_count += 1
            print(f"\n=== Seoul 실행 완료: {new_count}건 신규 저장 및 알림 전송 ===")
        else:
            print("\nSeoul 게시물이 없습니다.")

    except Exception as e:
        print(f"Seoul 크롤링 에러 발생: {e}")
        import traceback
        traceback.print_exc()

def crawl_seoul_public_art():
    """서울 공공미술 공모 크롤링 (디자인 뉴스에서 공공미술 공모 필터링)"""
    # 공공미술 공모는 디자인 뉴스 페이지에 포함되어 있음
    list_url = "https://news.seoul.go.kr/culture/archives/category/design-news_c1/business_design_c1/news_design-news-n1"
    headers = {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
    }
    
    print(f"--- Seoul 공공미술 공모 크롤링 시작 (디자인 뉴스에서 필터링) ---")
    
    try:
        response = requests.get(list_url, headers=headers, timeout=15)
        response.encoding = response.apparent_encoding or 'utf-8'
        
        soup = BeautifulSoup(response.text, 'html.parser')
        
        # ul li a[href*="archives"] 선택자 사용
        archive_links = soup.select('ul li a[href*="archives"]')
        
        if not archive_links:
            print("❌ Seoul 공공미술 공모 게시물을 찾을 수 없습니다.")
            return

        results = []
        for link_tag in archive_links:
            try:
                href = link_tag.get('href', '')
                title = link_tag.get_text(strip=True)
                
                if not title or not href or len(title) < 5:
                    continue
                
                # 공공미술 공모 관련 키워드 필터링
                public_art_keywords = ['공공미술', '미술작품', '조형물', '공모', '설치', '작가']
                if not any(keyword in title for keyword in public_art_keywords):
                    continue
                
                # archives/숫자 형태인지 확인
                if '/archives/' not in href:
                    continue
                
                # 절대 URL로 변환
                if href.startswith('/'):
                    final_link = urljoin('https://news.seoul.go.kr', href)
                elif href.startswith('http'):
                    final_link = href
                else:
                    final_link = urljoin(list_url, href)
                
                # 날짜 추출 (부모 요소에서 찾기)
                date_text = '날짜 없음'
                parent = link_tag.parent
                if parent:
                    # 부모 요소에서 날짜 찾기
                    date_elements = parent.select('.date, .post-date, time, [class*="date"], [datetime]')
                    if date_elements:
                        date_text = date_elements[0].get_text(strip=True)
                        if not date_text and date_elements[0].get('datetime'):
                            date_text = date_elements[0].get('datetime')
                    else:
                        # 텍스트에서 날짜 패턴 찾기
                        text = parent.get_text()
                        date_match = re.search(r'(\d{4}[.-]\d{2}[.-]\d{2})', text)
                        if date_match:
                            date_text = date_match.group(1)
                
                results.append({
                    'number': '',
                    'title': title,
                    'date': date_text,
                    'link': final_link
                })
            except Exception as e:
                print(f"  ⚠️ 항목 파싱 오류: {e}")
                continue

        if results:
            print(f"총 {len(results)}건의 Seoul 공공미술 공모 게시물을 처리합니다...")
            db = init_firebase()
            new_count = 0
            for item in results:
                if check_and_save(db, item, source='SeoulPublicArt'):
                    new_count += 1
            print(f"\n=== Seoul 공공미술 공모 실행 완료: {new_count}건 신규 저장 및 알림 전송 ===")
        else:
            print("\nSeoul 공공미술 공모 게시물이 없습니다.")

    except Exception as e:
        print(f"Seoul 공공미술 공모 크롤링 에러 발생: {e}")
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    # 모든 소스 크롤링 실행
    crawl_lh_notice()
    crawl_kams_notice()
    crawl_seoul_notice()
    crawl_seoul_public_art()
