"""
AURA Idea Generator
Synthesizes novel business ideas by combining database context, web search
results, and structured ideation templates. No external AI API required.
"""
import random
from typing import List, Dict, Optional
from . import web_search


# ─────────────────────── Ideation Templates ──────────────────────────────── #
IDEA_TEMPLATES = [
    "Leverage {keyword} to build a {product} that addresses {pain_point} in the {industry} space.",
    "Create a {product} platform that automates {process} for {audience} using {keyword}.",
    "Develop a data-driven {product} that predicts {metric} and provides actionable insights for {audience}.",
    "Launch a {keyword}-powered marketplace connecting {audience} with {resource} providers.",
    "Design a subscription service that uses {keyword} to continually optimize {process} for {industry} companies.",
    "Build an AI-enhanced {product} that reduces {pain_point} by analyzing real-time {metric} signals.",
    "Partner with {industry} firms to deploy {product} that turns {resource} data into strategic intelligence.",
    "Offer a freemium {product} targeting {audience} that solves {pain_point} through {keyword} automation.",
]

KEYWORDS    = ["machine learning", "data analytics", "automation", "blockchain", "IoT", "cloud computing", "edge AI", "NLP"]
PRODUCTS    = ["SaaS tool", "mobile app", "dashboard", "API service", "consulting platform", "marketplace", "analytics suite"]
PAIN_POINTS = ["inefficiency", "data silos", "manual reporting", "high operational cost", "slow decision-making", "talent gaps"]
PROCESSES   = ["risk assessment", "supply chain tracking", "customer onboarding", "financial forecasting", "compliance monitoring"]
AUDIENCES   = ["SMEs", "enterprise CFOs", "startup founders", "retail investors", "operations managers", "HR teams"]
METRICS     = ["revenue growth", "churn rate", "market volatility", "operational efficiency", "customer LTV", "fraud probability"]
RESOURCES   = ["talent", "capital", "infrastructure", "market data", "regulatory insight"]


class IdeaGenerator:
    def __init__(self, industry: str = "Financial Technology"):
        self.industry = industry

    def _fill_template(self, template: str, context_keywords: List[str]) -> str:
        kw = random.choice(context_keywords) if context_keywords else random.choice(KEYWORDS)
        return template.format(
            keyword    = kw,
            product    = random.choice(PRODUCTS),
            pain_point = random.choice(PAIN_POINTS),
            industry   = self.industry,
            process    = random.choice(PROCESSES),
            audience   = random.choice(AUDIENCES),
            metric     = random.choice(METRICS),
            resource   = random.choice(RESOURCES),
        )

    def _extract_keywords_from_search(self, results: List[Dict[str, str]]) -> List[str]:
        """Pull interesting nouns from search snippets for richer idea generation."""
        words = []
        for r in results:
            for token in r.get("snippet", "").split():
                clean = token.strip(".,!?;:()\"\\'").lower()
                if len(clean) > 5 and clean not in {"which", "their", "these", "those", "about", "after", "using"}:
                    words.append(clean)
        # Return unique top-frequency words
        from collections import Counter
        counts = Counter(words)
        return [w for w, _ in counts.most_common(10)]

    def generate(
        self,
        domain: str,
        db_context: Optional[str] = None,
        n_ideas: int = 4,
        use_web: bool = True,
    ) -> Dict:
        """
        Generate `n_ideas` business ideas for `domain`.
        Optionally enriches context with live web search results.
        """
        search_results = []
        search_text    = ""

        if use_web:
            search_results = web_search.search(f"business trends {domain} 2025", max_results=5)
            search_text    = web_search.format_results_as_text(search_results)

        # Extract keywords from search and DB context
        context_keywords = self._extract_keywords_from_search(search_results)
        if db_context:
            for token in db_context.split():
                clean = token.strip(".,!?;:").lower()
                if len(clean) > 4:
                    context_keywords.append(clean)

        # Generate ideas from templates
        templates = random.sample(IDEA_TEMPLATES, min(n_ideas, len(IDEA_TEMPLATES)))
        ideas = [self._fill_template(t, context_keywords) for t in templates]

        return {
            "domain": domain,
            "ideas": ideas,
            "web_context": search_results[:3],  # Return top-3 search refs
            "search_summary": search_text,
        }
