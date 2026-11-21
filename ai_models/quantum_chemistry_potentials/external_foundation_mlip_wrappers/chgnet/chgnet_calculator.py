

# Global model instance
model: Any | None = None
model_error: str | None = None


def load_chgnet_model() -> None:
    """Loads pretrained CHGNet universal neural network potential."""
    global model, model_error
    try:
        from chgnet.model.model import CHGNet  # type: ignore

        model = CHGNet.load()
        model.to(DEVICE)
        model_error = None
        weight_source = os.environ.get("CHGNET_CACHE_DIR", "/opt/weights")
        print(f"[MLIP] {type(model).__name__} loaded from {weight_source}")
        print(f"CHGNet successfully initialized on {DEVICE}.")
    except Exception as exc:
        model = None
        model_error = f"{type(exc).__name__}: {exc}"
        print(f"CHGNet initialization notice: {model_error}")


@asynccontextmanager
