uv sync --frozen >/dev/null 2>&1 || exit 125
uv run pytest -x
