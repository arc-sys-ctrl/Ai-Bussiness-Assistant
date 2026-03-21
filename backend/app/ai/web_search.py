"""
AURA Web Search Module
Scrapes DuckDuckGo HTML search results using requests + BeautifulSoup.
No API key required.
"""
import requests
from bs4 import BeautifulSoup
from typing import List, Dict
import urllib.parse

HEADERS = {
    "User-Agent": (
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
        "AppleWebKit/537.36 (KHTML, like Gecko) "
        "Chrome/120.0.0.0 Safari/537.36"
    )
}
DDG_URL = "https://html.duckduckgo.com/html/"
TIMEOUT = 8


def search(query: str, max_results: int = 5) -> List[Dict[str, str]]:
    """
    Search DuckDuckGo for `query` and return up to `max_results` results.
    Each result: {"title": str, "snippet": str, "url": str}
    """
    results = []
    try:
        params = {"q": query, "kl": "wt-wt"}
        resp = requests.post(DDG_URL, data=params, headers=HEADERS, timeout=TIMEOUT)
        resp.raise_for_status()

        soup = BeautifulSoup(resp.text, "html.parser")
        for r in soup.select(".result__body")[:max_results]:
            title_tag   = r.select_one(".result__title a")
            snippet_tag = r.select_one(".result__snippet")

            title   = title_tag.get_text(strip=True)   if title_tag   else "No title"
            snippet = snippet_tag.get_text(strip=True)  if snippet_tag else "No snippet"
            raw_url = title_tag["href"]                  if title_tag   else "#"

            # DuckDuckGo wraps URLs — decode if needed
            if "uddg=" in raw_url:
                parsed = urllib.parse.urlparse(raw_url)
                qs     = urllib.parse.parse_qs(parsed.query)
                url    = qs.get("uddg", [raw_url])[0]
            else:
                url = raw_url

            results.append({"title": title, "snippet": snippet, "url": url})

    except requests.exceptions.Timeout:
        results.append({"title": "Search Timeout", "snippet": f"Request for '{query}' timed out.", "url": "#"})
    except Exception as e:
        results.append({"title": "Search Error", "snippet": str(e), "url": "#"})

    return results


def format_results_as_text(results: List[Dict[str, str]]) -> str:
    """Returns search results as a readable string for embedding in responses."""
    if not results:
        return "No results found."
    parts = []
    for i, r in enumerate(results, 1):
        parts.append(f"{i}. **{r['title']}**\n   {r['snippet']}\n   🔗 {r['url']}")
    return "\n\n".join(parts)
