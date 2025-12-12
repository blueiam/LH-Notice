import requests
from bs4 import BeautifulSoup
import re

def debug_crawl():
    url = "https://www.lh.or.kr/board.es?mid=a10601020000&bid=0034"
    headers = {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
    }

    print(f"--- [1] 접속 시도: {url} ---")
    
    try:
        response = requests.get(url, headers=headers, timeout=10)
        print(f"응답 코드: {response.status_code}") 
        
        if response.status_code != 200:
            print("❌ 접속 실패!")
            return

        response.encoding = response.apparent_encoding
        soup = BeautifulSoup(response.text, 'html.parser')
        rows = soup.select('table tbody tr')
        print(f"--- [2] 찾은 게시물 수: {len(rows)}개 ---")

        if len(rows) == 0:
            print("❌ 게시물을 못 찾았습니다.")
            return

        print("\n--- [3] 데이터 추출 테스트 (상위 5개) ---")
        for i, row in enumerate(rows[:5]):
            link_tag = row.find('a')
            if not link_tag: continue
            
            full_title = link_tag.get_text(strip=True)
            
            cells = row.find_all('td')
            date_text = "날짜못찾음"
            for cell in cells:
                txt = cell.get_text(strip=True)
                if re.search(r'\d{4}[.-]\d{2}[.-]\d{2}', txt):
                    date_text = txt
                    break
            
            print(f"[{i+1}] {full_title} | {date_text}")

        print("\n✅ 테스트 완료")

    except Exception as e:
        print(f"❌ 에러 발생: {e}")

if __name__ == "__main__":
    debug_crawl()
