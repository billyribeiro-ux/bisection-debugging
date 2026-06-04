python -m venv .venv-bisect
. .venv-bisect/bin/activate
pip install --no-deps -r requirements.txt >/dev/null 2>&1 || exit 125
pytest -x
