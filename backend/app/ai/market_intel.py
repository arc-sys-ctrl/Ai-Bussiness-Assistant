"""
AURA Market Intelligence — Live news and competitor tracking.
Scrapes Google News RSS and public competitor pages.
No API keys required.
"""
import requests
from bs4 import BeautifulSoup
from datetime import datetime
from typing import List, Dict
import xml.etree.ElementTree as ET
import hashlib

HEADERS = {
    "User-Agent": (
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
        "AppleWebKit/537.36 (KHTML, like Gecko) "
        "Chrome/120.0.0.0 Safari/537.36"
    )
}
TIMEOUT = 8


def fetch_news(topic: str, max_results: int = 10) -> List[Dict]:
    """
    Fetch articles from Google News RSS for a given topic.
    Returns: list of {title, url, source, published_at}
    """
    query = topic.replace(" ", "+")
    url   = f"https://news.google.com/rss/search?q={query}&hl=en-US&gl=US&ceid=US:en"
    results = []
    try:
        resp = requests.get(url, headers=HEADERS, timeout=TIMEOUT)
        resp.raise_for_status()
        root = ET.fromstring(resp.content)
        channel = root.find("channel")
        if channel is None:
            return results
        for item in channel.findall("item")[:max_results]:
            title = item.findtext("title", "")
            link  = item.findtext("link",  "")
            pub   = item.findtext("pubDate", "")
            source_el = item.find("source")
            source = source_el.text if source_el is not None else "Google News"

            # Parse date
            try:
                from email.utils import parsedate_to_datetime
                pub_dt = parsedate_to_datetime(pub).isoformat() if pub else None
            except Exception:
                pub_dt = None

            results.append({
                "title":        title,
                "url":          link,
                "source":       source,
                "published_at": pub_dt,
            })
    except Exception as e:
        results.append({"title": f"Error fetching news: {e}", "url": "#", "source": "system", "published_at": None})
    return results


def scrape_page_hash(url: str) -> str:
    """
    Fetch a public web page and return a hash of its visible text content.
    Used to detect changes on competitor pages.
    """
    try:
        resp = requests.get(url, headers=HEADERS, timeout=TIMEOUT)
        resp.raise_for_status()
        soup = BeautifulSoup(resp.text, "html.parser")
        # Remove scripts and styles
        for tag in soup(["script", "style", "nav", "footer"]):
            tag.decompose()
        text = " ".join(soup.stripped_strings)
        return hashlib.sha256(text.encode()).hexdigest()
    except Exception:
        return ""


def generate_swot(context: Dict) -> Dict:
    """
    Generate a structured SWOT analysis from workspace context data.
    context keys: alerts (list), tasks_open (int), ideas (list), plan (str)
    """
    alerts     = context.get("alerts", [])
    tasks_open = context.get("tasks_open", 0)
    ideas      = context.get("ideas", [])
    plan       = context.get("plan", "free")

    warnings = [a for a in alerts if a.get("level") == "warning"]
    successes = [a for a in alerts if a.get("level") == "success"]

    strengths = [
        "Active AI-powered analytics infrastructure in place",
        f"{len(successes)} positive market signals detected recently",
    ]
    if plan in ("pro", "enterprise"):
        strengths.append("Advanced enterprise-tier capabilities enabled")

    weaknesses = [
        f"{tasks_open} open tasks with unresolved execution risk",
    ]
    if len(warnings) > 0:
        weaknesses.append(f"{len(warnings)} active warning-level alerts require attention")

    opportunities = [i[:100] if len(i) > 100 else i for i in ideas[:3]] or [
        "Expand into emerging high-growth markets",
        "Leverage data insights to upsell existing customers",
        "Automate reporting workflows to reduce overhead",
    ]

    threats = [
        "Competitive pressure from established SaaS platforms (ClickUp, Notion)",
        "Regulatory changes in financial data handling",
        "Dependency on third-party data sources for market intelligence",
    ]

    return {
        "strengths":     strengths,
        "weaknesses":    weaknesses,
        "opportunities": opportunities,
        "threats":       threats,
    }
