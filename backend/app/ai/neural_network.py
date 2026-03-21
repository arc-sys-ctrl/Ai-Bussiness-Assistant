"""
AURA Neural Network — Built from scratch using PyTorch tensors only.
Architecture: Input Layer → Hidden Layer 1 → Hidden Layer 2 → Output Layer
Training: Manual backpropagation with gradient descent.
"""
import torch
import torch.nn.functional as F
import os


VOCAB_SIZE = 2048       # Max unique word IDs
EMBED_DIM  = 64         # Embedding dimension (Input Layer output size)
HIDDEN_1   = 128        # Hidden Layer 1 size
HIDDEN_2   = 64         # Hidden Layer 2 size
OUTPUT_DIM = 16         # Output: intent class scores (0–15)


# ─────────────────────────── 1. Simple Tokenizer ──────────────────────────── #
class AuraTokenizer:
    """Minimal word-level tokenizer with a learnable vocabulary."""
    def __init__(self):
        self.word2id = {"<PAD>": 0, "<UNK>": 1}
        self.next_id = 2

    def tokenize(self, text: str, max_len: int = 32) -> torch.Tensor:
        tokens = []
        for word in text.lower().split():
            word = word.strip(".,!?;:")
            if word not in self.word2id:
                if self.next_id < VOCAB_SIZE:
                    self.word2id[word] = self.next_id
                    self.next_id += 1
            tokens.append(self.word2id.get(word, 1))   # 1 = <UNK>
        # Pad / truncate
        tokens = tokens[:max_len]
        tokens += [0] * (max_len - len(tokens))
        return torch.tensor(tokens, dtype=torch.long)


# ─────────────────────────── 2. Input Layer ───────────────────────────────── #
class InputLayer:
    """
    Embeds token IDs into dense vectors (Embedding + mean-pooling).
    Parameters: W_embed  [VOCAB_SIZE × EMBED_DIM]
    """
    def __init__(self):
        # Create as leaf tensor
        self.W_embed = torch.randn(VOCAB_SIZE, EMBED_DIM) * 0.01
        self.W_embed.requires_grad_(True)

    def forward(self, token_ids: torch.Tensor) -> torch.Tensor:
        """token_ids: [seq_len] → output: [EMBED_DIM]"""
        embedded = self.W_embed[token_ids]      # [seq_len, EMBED_DIM]
        pooled   = embedded.mean(dim=0)         # [EMBED_DIM]
        return pooled

    def parameters(self):
        return [self.W_embed]


# ─────────────────────────── 3. Hidden Layers ─────────────────────────────── #
class HiddenLayer:
    """
    Two dense hidden layers with ReLU activation and dropout.
    Parameters: W1 [EMBED_DIM × HIDDEN_1], b1 [HIDDEN_1]
                W2 [HIDDEN_1  × HIDDEN_2], b2 [HIDDEN_2]
    """
    def __init__(self):
        with torch.no_grad():
            self.W1 = torch.randn(EMBED_DIM, HIDDEN_1) * 0.01
            self.b1 = torch.zeros(HIDDEN_1)
            self.W2 = torch.randn(HIDDEN_1, HIDDEN_2) * 0.01
            self.b2 = torch.zeros(HIDDEN_2)
        
        self.W1.requires_grad_(True)
        self.b1.requires_grad_(True)
        self.W2.requires_grad_(True)
        self.b2.requires_grad_(True)

    def forward(self, x: torch.Tensor, training: bool = False) -> torch.Tensor:
        # Layer 1
        h1 = F.relu(x @ self.W1 + self.b1)
        if training:
            h1 = F.dropout(h1, p=0.2, training=True)
        # Layer 2
        h2 = F.relu(h1 @ self.W2 + self.b2)
        return h2

    def parameters(self):
        return [self.W1, self.b1, self.W2, self.b2]


# ─────────────────────────── 4. Output Layer ──────────────────────────────── #
class OutputLayer:
    """
    Maps hidden representation to intent logits.
    Parameters: W_out [HIDDEN_2 × OUTPUT_DIM], b_out [OUTPUT_DIM]
    Intent classes (0-15):
        0 = general      1 = greeting     2 = farewell     3 = search
        4 = revenue      5 = sentiment    6 = strategy     7 = ideas
        8 = risk         9 = market      10 = forecast     11 = alert
       12 = profile     13 = setting     14 = help         15 = unknown
    """
    INTENTS = [
        "general", "greeting", "farewell", "search",
        "revenue", "sentiment", "strategy", "ideas",
        "risk", "market", "forecast", "alert",
        "profile", "setting", "help", "unknown",
    ]

    def __init__(self):
        with torch.no_grad():
            self.W_out = torch.randn(HIDDEN_2, OUTPUT_DIM) * 0.01
            self.b_out = torch.zeros(OUTPUT_DIM)
        
        self.W_out.requires_grad_(True)
        self.b_out.requires_grad_(True)

    def forward(self, h: torch.Tensor) -> torch.Tensor:
        logits = h @ self.W_out + self.b_out    # [OUTPUT_DIM]
        return logits

    def predict_intent(self, logits: torch.Tensor) -> str:
        idx = logits.argmax().item()
        return self.INTENTS[idx]

    def parameters(self):
        return [self.W_out, self.b_out]


# ─────────────────────────── 5. AuraNeuralNet ─────────────────────────────── #
class AuraNeuralNet:
    """
    Full forward + manual backward pass.
    Architecture:
        text → tokenize → InputLayer → HiddenLayer → OutputLayer → intent logits
    """
    def __init__(self):
        self.tokenizer    = AuraTokenizer()
        self.input_layer  = InputLayer()
        self.hidden_layer = HiddenLayer()
        self.output_layer = OutputLayer()

    def forward(self, text: str, training: bool = False):
        tokens  = self.tokenizer.tokenize(text)
        x       = self.input_layer.forward(tokens)
        h       = self.hidden_layer.forward(x, training=training)
        logits  = self.output_layer.forward(h)
        return logits

    def predict(self, text: str) -> dict:
        with torch.no_grad():
            logits  = self.forward(text, training=False)
            probs   = F.softmax(logits, dim=0)
            intent  = self.output_layer.predict_intent(logits)
            confidence = probs.max().item()
        return {"intent": intent, "confidence": round(confidence, 4), "logits": logits}

    def compute_loss(self, logits: torch.Tensor, target_intent: int) -> torch.Tensor:
        target = torch.tensor([target_intent], dtype=torch.long)
        return F.cross_entropy(logits.unsqueeze(0), target)

    def all_parameters(self):
        params = []
        params += self.input_layer.parameters()
        params += self.hidden_layer.parameters()
        params += self.output_layer.parameters()
        return params

    def get_state_dict(self) -> dict:
        return {
            "W_embed": self.input_layer.W_embed.data,
            "W1":      self.hidden_layer.W1.data,
            "b1":      self.hidden_layer.b1.data,
            "W2":      self.hidden_layer.W2.data,
            "b2":      self.hidden_layer.b2.data,
            "W_out":   self.output_layer.W_out.data,
            "b_out":   self.output_layer.b_out.data,
            "word2id": self.tokenizer.word2id,
            "next_id": self.tokenizer.next_id,
        }

    def load_state_dict(self, state: dict):
        self.input_layer.W_embed.data.copy_(state["W_embed"])
        self.hidden_layer.W1.data.copy_(state["W1"])
        self.hidden_layer.b1.data.copy_(state["b1"])
        self.hidden_layer.W2.data.copy_(state["W2"])
        self.hidden_layer.b2.data.copy_(state["b2"])
        self.output_layer.W_out.data.copy_(state["W_out"])
        self.output_layer.b_out.data.copy_(state["b_out"])
        self.tokenizer.word2id = state["word2id"]
        self.tokenizer.next_id = state["next_id"]
