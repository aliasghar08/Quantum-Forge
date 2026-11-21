    """Checks if xtb binary or xtb-python is available in environment."""
    if shutil.which("xtb"):
        return True
    try:
        import xtb  # type: ignore
        return True
    except ImportError:
        return False


@asynccontextmanager
async def lifespan(_: FastAPI):
    weight_source = os.environ.get("XTB_PARAM_PATH", os.environ.get("XTBPATH", "/opt/weights"))
    print(f"[MLIP] GFN2-xTB loaded from {weight_source}")
    yield


app = FastAPI(
    title="Quantum Forge — GFN2-xTB Microservice",
    description="Semi-empirical Extended Tight-Binding Quantum Mechanics API for Quantum Forge",
    version="1.0.0",
    lifespan=lifespan,
)


app.add_middleware(
