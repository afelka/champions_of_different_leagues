import requests
import pandas as pd
from bs4 import BeautifulSoup
from io import StringIO

url = 'https://en.wikipedia.org/wiki/List_of_Turkish_football_champions'

HEADERS = {
    "User-Agent": (
        "UCLPotScraper/1.0 "
        "(contact: your.email@example.com) "
        "Educational / non-commercial use"
    )
}
response = requests.get(url, headers=HEADERS)
soup = BeautifulSoup(response.content, "html.parser")

# Robustly find the 'Süper Lig (1959–present)' section by id and get the next table
target_table = None

section_h3 = soup.find('h3', id="Süper_Lig_(1959–present)")
target_table = None
if section_h3:
    parent_div = section_h3.find_parent('div', class_='mw-heading')
    sib = parent_div if parent_div else section_h3
    while sib is not None:
        sib = sib.find_next_sibling()
        if sib is None:
            break
        if sib.name == 'span':
            continue
        if sib.name == 'table' and 'wikitable' in sib.get('class', []):
            target_table = sib
            break
        if sib.name == 'div':
            table_in_div = sib.find('table', class_='wikitable')
            if table_in_div:
                target_table = table_in_div
                break

if target_table is None:
    raise Exception("Could not find the Süper Lig (1959–present) table. Check debug output above for clues.")

turkish_df = pd.read_html(StringIO(str(target_table)))[0]

# 1. Identify the 'Season' and 'Winner' columns dynamically
# We use 'Season' and 'Winner' keywords to find the right headers
season_col = [col for col in turkish_df.columns if 'Season' in str(col)]
winner_col = [col for col in turkish_df.columns if 'Winner' in str(col)]

if not season_col or not winner_col:
    raise Exception("Could not find the Season or Winner columns in the table.")

# Extract only the season and winners columns and clean up the club name
turkish_winners = turkish_df[[season_col[0], winner_col[0]]].copy()
turkish_winners[winner_col[0]] = turkish_winners[winner_col[0]].astype(str).str.replace(r"\s*\([^)]*\)", "", regex=True).str.strip()
turkish_winners.columns = ['Season', 'Winner']

turkish_winners.to_csv("turkish_league_champions.csv", index=False)
print(f"Scraped and saved league winners to turkish_league_champions.csv")
