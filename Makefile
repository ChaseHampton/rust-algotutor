.PHONY: fmt lint test run check

fmt:
	cargo fmt

lint:
	cargo clippy

test:
	cargo test

run:
	cargo run

check:
	cargo check
