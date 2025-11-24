.PHONY: build test fmt clippy check python-install python-test clean

build:
	cargo build --workspace

fmt:
	cargo fmt --all

clippy:
	cargo clippy --workspace --all-targets -- -D warnings

test:
	cargo test --workspace --all-features

python-install:
	python -m pip install -r deai/requirements.txt

python-test:
	PYTHONPATH=$$PYTHONPATH:$$(pwd)/deai/lib pytest tests/integration_simple.py --maxfail=1 --disable-warnings -q

check: fmt clippy test python-test

clean:
	cargo clean
