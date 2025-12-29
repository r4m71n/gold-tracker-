import requests
from bs4 import BeautifulSoup


def fetch_tgju_data():
    """
    دریافت قیمت‌های لحظه‌ای از TGJU
    ارزهای تضمینی که توی تست موفق بودن
    """

    targets = {
        'usd': 'price_dollar_rl',  # دلار آمریکا
        'gold_18': 'geram18',  # طلای ۱۸ عیار
        'gold_24': 'geram24',  # طلای ۲۴ عیار
        'coin_half': 'retail_nim',  # نیم سکه
        'coin_quarter': 'retail_rob',  # ربع سکه
        'coin_gerami': 'retail_gerami',  # سکه گرمی
    }

    url = "https://www.tgju.org/"
    headers = {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
    }

    try:
        response = requests.get(url, headers=headers, timeout=15)
        if response.status_code == 200:
            soup = BeautifulSoup(response.content, 'html.parser')
            results = {}

            for db_code, tgju_slug in targets.items():
                row = soup.find('tr', {'data-market-row': tgju_slug})
                if row:
                    price_tag = row.find('td', class_='nf')
                    if price_tag:
                        clean_price = price_tag.text.replace(',', '').strip()
                        if clean_price.isdigit():
                            results[db_code] = int(clean_price)

            return results
        return None

    except Exception as e:
        print(f"Scraping Error: {e}")
        return None
