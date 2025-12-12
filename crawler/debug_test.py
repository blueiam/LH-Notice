import requests
from bs4 import BeautifulSoup
import re

def debug_crawl():
    # LH 공지사항 URL
    url = "https://www.lh.or.kr/board.es?mid=a10601020000&bid=0034"
    
    headers = {
        # 봇 차단을 피하기 위한 헤더 설정
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
    }

    print(f"--- [1] 접속 시도: {url} ---")
    
    try:
        response = requests.get(url, headers=headers, timeout=10)
        print(f"응답 코드: {response.status_code}") # 200이 나와야 정상
        
        if response.status_code != 200:
            print("❌ 접속 실패! 사이트에서 차단했거나 URL이 잘못되었습니다.")
            return

        # 인코딩 자동 보정
        response.encoding = response.apparent_encoding
        
        soup = BeautifulSoup(response.text, 'html.parser')
        
        # 게시물 행 찾기
        rows = soup.select('table tbody tr')
        print(f"--- [2] 찾은 게시물 수: {len(rows)}개 ---")

        if len(rows) == 0:
            print("❌ 게시물을 하나도 못 찾았습니다. HTML 구조(table tbody tr)가 바뀌었을 수 있습니다.")
            # 디버깅을 위해 HTML 일부 출력
            print("HTML 앞부분 500자 확인:\n", soup.prettify()[:500])
            return

        print("\n--- [3] 데이터 추출 테스트 (상위 5개만) ---")
        for i, row in enumerate(rows[:5]):
            # 제목 찾기
            link_tag = row.find('a')
            if not link_tag:
                print(f"{i+1}번: ❌ <a> 태그 없음")
                continue
                
            full_title = link_tag.get_text(strip=True)
            
            # 날짜 찾기 (모든 칸 뒤져서 날짜 형식 찾기)
            cells = row.find_all('td')
            date_text = "날짜못찾음"
            for cell in cells:
                txt = cell.get_text(strip=True)
                if re.search(r'\d{4}[.-]\d{2}[.-]\d{2}', txt):
                    date_text = txt
                    break
            
            print(f"[{i+1}번 게시물]")
            print(f"  - 제목: {full_title}")
            print(f"  - 날짜: {date_text}")
            print("-" * 30)

        print("\n✅ 테스트 완료. 위 제목들이 정상적으로 보이나요?")

    except Exception as e:
        print(f"❌ 치명적인 에러 발생: {e}")

if __name__ == "__main__":
    debug_crawl()