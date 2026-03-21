"""
AURA Analytics Engine — Revenue forecasting and anomaly detection.
Uses NumPy only: no external AI APIs.
"""
import numpy as np
from typing import List, Dict


def predict_revenue(historical: List[float], periods_ahead: int = 4) -> Dict:
    """
    Linear regression on historical revenue figures.
    Returns forecast values and trend metadata.
    historical: list of revenue values (oldest first)
    """
    if len(historical) < 2:
        raise ValueError("Need at least 2 data points for forecasting")

    n   = len(historical)
    x   = np.arange(n, dtype=float)
    y   = np.array(historical, dtype=float)

    # Normal equations: β = (XᵀX)⁻¹ Xᵀy
    x_mean = x.mean()
    y_mean = y.mean()
    slope  = np.sum((x - x_mean) * (y - y_mean)) / np.sum((x - x_mean) ** 2)
    intercept = y_mean - slope * x_mean

    # Forecast
    forecast_x = np.arange(n, n + periods_ahead, dtype=float)
    forecast_y = slope * forecast_x + intercept

    # R² for confidence
    y_pred = slope * x + intercept
    ss_res = np.sum((y - y_pred) ** 2)
    ss_tot = np.sum((y - y_mean) ** 2)
    r2     = 1 - (ss_res / ss_tot) if ss_tot > 0 else 0.0

    trend = "growing" if slope > 0 else "declining" if slope < 0 else "flat"

    return {
        "forecast":      [round(float(v), 2) for v in forecast_y],
        "slope":         round(float(slope), 4),
        "trend":         trend,
        "r2":            round(float(r2), 4),
        "periods_ahead": periods_ahead,
    }


def detect_anomaly(series: List[float], threshold: float = 2.5) -> List[Dict]:
    """
    Z-score based anomaly detection.
    Returns list of anomalous points with index, value, and z-score.
    """
    if len(series) < 3:
        return []

    arr    = np.array(series, dtype=float)
    mean   = arr.mean()
    std    = arr.std()

    if std == 0:
        return []

    z_scores  = np.abs((arr - mean) / std)
    anomalies = []
    for i, (val, z) in enumerate(zip(series, z_scores)):
        if z >= threshold:
            anomalies.append({
                "index":   i,
                "value":   round(float(val), 2),
                "z_score": round(float(z), 3),
                "type":    "spike" if val > mean else "dip",
            })
    return anomalies


def compute_growth_rate(old: float, new: float) -> float:
    """Percentage growth rate."""
    if old == 0:
        return 0.0
    return round(((new - old) / abs(old)) * 100, 2)
