"""
AURA Self-Learning Engine
Implements online gradient descent: after each interaction the network
updates its own weights and persists them to disk.
"""
import os
import torch
import torch.nn.functional as F
from .neural_network import AuraNeuralNet, OutputLayer

WEIGHTS_DIR  = os.path.join(os.path.dirname(__file__), "weights")
WEIGHTS_FILE = os.path.join(WEIGHTS_DIR, "aura_weights.pt")
LEARNING_RATE = 0.005


class SelfLearner:
    """
    Wraps AuraNeuralNet with:
      - Weight loading/saving to disk
      - Online backpropagation (SGD update after each interaction)
      - Intent keyword seeding so the network starts with reasonable behavior
    """

    # Keyword seeds map patterns → intent index for initial supervised warm-up
    KEYWORD_SEEDS = {
        "search":   3,  "find":     3,  "look up":   3,  "google":   3,
        "revenue":  4,  "profit":   4,  "sales":     4,  "income":   4,
        "sentiment":5,  "feeling":  5,  "mood":      5,
        "strategy": 6,  "plan":     6,  "roadmap":   6,
        "idea":     7,  "ideas":    7,  "generate":  7,  "suggest":  7,
        "risk":     8,  "danger":   8,  "threat":    8,
        "market":   9,  "stock":    9,  "price":     9,  "trend":    9,
        "forecast": 10, "predict":  10, "future":    10,
        "alert":    11, "warning":  11, "notify":    11,
        "hello":    1,  "hi":       1,  "hey":       1,
        "bye":      2,  "goodbye":  2,  "exit":      2,
        "help":     14, "assist":   14, "support":   14,
    }

    def __init__(self):
        os.makedirs(WEIGHTS_DIR, exist_ok=True)
        self.net = AuraNeuralNet()
        self._load_weights()

    # ──────────────────── Persistence ────────────────────────────────────── #
    def _load_weights(self):
        if os.path.exists(WEIGHTS_FILE):
            state = torch.load(WEIGHTS_FILE, weights_only=False)
            self.net.load_state_dict(state)
            print("[AURA] Weights loaded from disk.")
        else:
            print("[AURA] No weights file found — starting with fresh weights.")

    def _save_weights(self):
        torch.save(self.net.get_state_dict(), WEIGHTS_FILE)

    # ──────────────────── Intent Detection ───────────────────────────────── #
    def detect_intent(self, text: str) -> dict:
        """Combine keyword-heuristic with neural network for robust intent classification."""
        text_lower = text.lower()

        # Fast keyword check (strongest signal first)
        keyword_intent = None
        for kw, intent_idx in self.KEYWORD_SEEDS.items():
            if kw in text_lower:
                keyword_intent = intent_idx
                break

        # Neural network prediction
        nn_result = self.net.predict(text)

        # Trust keyword seedif confidence is low
        if keyword_intent is not None and nn_result["confidence"] < 0.5:
            intent_idx = keyword_intent
            intent_name = OutputLayer.INTENTS[intent_idx]
            # Self-train on this observation
            self._backprop(text, intent_idx)
        else:
            intent_name = nn_result["intent"]
            intent_idx  = OutputLayer.INTENTS.index(intent_name)

        return {"intent": intent_name, "intent_idx": intent_idx, "confidence": nn_result["confidence"]}

    # ──────────────────── Online Learning ────────────────────────────────── #
    def _backprop(self, text: str, target_intent: int):
        """Perform one SGD step against the given target label."""
        params = self.net.all_parameters()
        # Zero gradients
        for p in params:
            if p.grad is not None:
                p.grad.zero_()

        # Forward pass (with gradient tracking)
        logits = self.net.forward(text, training=True)
        loss   = self.net.compute_loss(logits, target_intent)

        # Backward pass (PyTorch autograd)
        loss.backward()

        # SGD weight update (no optimizer object — manual update)
        with torch.no_grad():
            for p in params:
                if p.grad is not None:
                    p.data -= LEARNING_RATE * p.grad

        self._save_weights()
        return loss.item()

    def learn_from_feedback(self, text: str, correct_intent: str):
        """
        Called when feedback is provided for a response.
        Updates weights toward the correct intent and persists.
        """
        if correct_intent in OutputLayer.INTENTS:
            idx  = OutputLayer.INTENTS.index(correct_intent)
            loss = self._backprop(text, idx)
            return {"status": "learned", "loss": round(loss, 6)}
        return {"status": "unknown_intent"}

    def process(self, text: str) -> dict:
        """Main entry point — returns intent plus triggers training if confident enough."""
        intent_data = self.detect_intent(text)
        return intent_data
