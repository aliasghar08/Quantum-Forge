# Allowed elements in ANI-2x: H(1), C(6), N(7), O(8), F(9), S(16), Cl(17)
SUPPORTED_ELEMENTS = {1, 6, 7, 8, 9, 16, 17}

# Global model instance
model: Any | None = None
model_error: str | None = None


def load_ani_model() -> None:
    """Initializes the TorchANI ANI-2x ensemble potential."""
    global model, model_error
    try:
        import torchani  # type: ignore

        model = torchani.models.ANI2x().to(DEVICE)
        model_error = None
        weight_source = os.environ.get("ANI_CACHE_DIR", os.environ.get("TORCHANI_CACHE_DIR", "/opt/weights"))
        print(f"[MLIP] {type(model).__name__} loaded from {weight_source}")
        print(f"ANI-2x successfully initialized on {DEVICE}.")
    except Exception as exc:
        model = None
        model_error = f"{type(exc).__name__}: {exc}"
        print(f"ANI-2x initialization notice: {model_error}")


@asynccontextmanager
