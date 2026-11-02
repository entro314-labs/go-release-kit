# __PROJECT_NAME__ Makefile
# Go project Makefile with PGO support and GoReleaser

# =============================================================================
# Variables
# =============================================================================
BINARY_NAME := __PROJECT_NAME__
MAIN_PACKAGE := __MAIN_PACKAGE__
VERSION := $(shell git describe --tags --always --dirty 2>/dev/null || echo "dev")
BUILD_TIME := $(shell date -u +"%Y-%m-%dT%H:%M:%SZ")
GIT_COMMIT := $(shell git rev-parse --short HEAD 2>/dev/null || echo "unknown")
GO_VERSION := $(shell go version | cut -d' ' -f3)

# Build configuration
CGO_ENABLED ?= 0
PGO_PROFILE := default.pgo

# Linker flags
LDFLAGS := -s -w \
	-X main.version=$(VERSION) \
	-X main.commit=$(GIT_COMMIT) \
	-X main.date=$(BUILD_TIME) \
	-X main.builtBy=make

# Output directories
DIST_DIR := dist

# =============================================================================
# Default target
# =============================================================================
.DEFAULT_GOAL := help

.PHONY: all
all: clean lint test build

# =============================================================================
# Build targets
# =============================================================================
.PHONY: build
build:
	@echo "Building $(BINARY_NAME)..."
	CGO_ENABLED=$(CGO_ENABLED) go build -trimpath -ldflags="$(LDFLAGS)" -o $(BINARY_NAME) $(MAIN_PACKAGE)
	@echo "Build complete"

.PHONY: build-dev
build-dev:
	@echo "Building $(BINARY_NAME) with race detection..."
	CGO_ENABLED=1 go build -race -ldflags="$(LDFLAGS)" -o $(BINARY_NAME)-dev $(MAIN_PACKAGE)

.PHONY: build-pgo
build-pgo:
	@if [ -f $(PGO_PROFILE) ]; then \
		echo "Building with Profile-Guided Optimization..."; \
		CGO_ENABLED=$(CGO_ENABLED) go build -trimpath -pgo=$(PGO_PROFILE) \
			-ldflags="$(LDFLAGS)" \
			-o $(BINARY_NAME) $(MAIN_PACKAGE); \
		echo "PGO build complete"; \
	else \
		echo "No $(PGO_PROFILE) found. Building without PGO..."; \
		$(MAKE) build; \
	fi

# =============================================================================
# Dependencies
# =============================================================================
.PHONY: deps
deps:
	@echo "Installing dependencies..."
	go mod download
	go mod tidy
	go mod verify

.PHONY: deps-update
deps-update:
	@echo "Updating dependencies..."
	go get -u ./...
	go mod tidy

# =============================================================================
# Testing
# =============================================================================
.PHONY: test
test:
	@echo "Running tests..."
	go test -v -race -coverprofile=coverage.out ./...

.PHONY: test-short
test-short:
	@echo "Running short tests..."
	go test -short -race ./...

.PHONY: test-coverage
test-coverage: test
	@echo "Generating coverage report..."
	go tool cover -html=coverage.out -o coverage.html
	@echo "Coverage report: coverage.html"

.PHONY: benchmark
benchmark:
	@echo "Running benchmarks..."
	go test -bench=. -benchmem ./...

# =============================================================================
# Linting and formatting
# =============================================================================
.PHONY: lint
lint:
	@echo "Running linters..."
	@if command -v golangci-lint >/dev/null 2>&1; then \
		golangci-lint run --timeout=5m; \
	else \
		echo "golangci-lint not found, running go vet..."; \
		go vet ./...; \
	fi

.PHONY: fmt
fmt:
	@echo "Formatting code..."
	go fmt ./...
	@if command -v goimports >/dev/null 2>&1; then \
		goimports -w .; \
	fi

.PHONY: check
check: fmt lint test

# =============================================================================
# Installation
# =============================================================================
.PHONY: install
install: build
	@echo "Installing $(BINARY_NAME) to /usr/local/bin..."
	sudo install -m 755 $(BINARY_NAME) /usr/local/bin/$(BINARY_NAME)
	@echo "Installed $(BINARY_NAME)"

.PHONY: uninstall
uninstall:
	@echo "Removing $(BINARY_NAME) from /usr/local/bin..."
	sudo rm -f /usr/local/bin/$(BINARY_NAME)
	@echo "Uninstalled $(BINARY_NAME)"

# =============================================================================
# Development
# =============================================================================
.PHONY: dev
dev: deps fmt lint test build
	@echo "Development workflow complete"

.PHONY: run
run: build
	./$(BINARY_NAME) --help

# =============================================================================
# Release (GoReleaser)
# =============================================================================
.PHONY: release-check
release-check:
	goreleaser check

# --skip=sign: signing is keyless cosign, which needs the OIDC identity only the
# release workflow has.
.PHONY: release-snapshot
release-snapshot:
	goreleaser release --snapshot --clean --skip=sign

# Cut the next version: infer the bump from the conventional commits since the last tag,
# update CHANGELOG.md, commit, tag and push. Pushing the tag is what triggers
# .github/workflows/release.yml (copied from templates/.github/), which runs goreleaser.
#   npm i -g @entro314labs/release-kit
.PHONY: tag
tag:
	release-kit auto

# =============================================================================
# Cleanup
# =============================================================================
# $(PGO_PROFILE) stays: it is a committed input to build-pgo (Go's convention), not an
# artifact, and `all` runs clean first.
.PHONY: clean
clean:
	@echo "Cleaning build artifacts..."
	go clean
	rm -f $(BINARY_NAME) $(BINARY_NAME)-*
	rm -rf $(DIST_DIR)
	rm -f coverage.out coverage.html
	rm -f *.prof

# =============================================================================
# Tools installation
# =============================================================================
.PHONY: install-tools
install-tools:
	@echo "Installing development tools..."
	go install github.com/golangci/golangci-lint/v2/cmd/golangci-lint@v2.15.0
	go install golang.org/x/tools/cmd/goimports@latest
	go install github.com/goreleaser/goreleaser/v2@latest
	@echo "Development tools installed"

.PHONY: setup
setup: install-tools deps
	@echo "Development environment ready"

# =============================================================================
# Information
# =============================================================================
.PHONY: info
info:
	@echo "Build Information:"
	@echo "  Binary:     $(BINARY_NAME)"
	@echo "  Version:    $(VERSION)"
	@echo "  Commit:     $(GIT_COMMIT)"
	@echo "  Go:         $(GO_VERSION)"
	@echo "  CGO:        $(CGO_ENABLED)"

.PHONY: help
help:
	@echo "$(BINARY_NAME) Makefile"
	@echo ""
	@echo "Build targets:"
	@echo "  build            Build binary"
	@echo "  build-dev        Build with race detection"
	@echo "  build-pgo        Build with Profile-Guided Optimization"
	@echo ""
	@echo "Development:"
	@echo "  deps             Download dependencies"
	@echo "  deps-update      Update dependencies"
	@echo "  test             Run tests with coverage"
	@echo "  lint             Run linters"
	@echo "  fmt              Format code"
	@echo "  check            Run fmt, lint, and test"
	@echo "  dev              Full dev workflow"
	@echo ""
	@echo "Installation:"
	@echo "  install          Install to /usr/local/bin"
	@echo "  uninstall        Remove from /usr/local/bin"
	@echo ""
	@echo "Release:"
	@echo "  release-check    Validate GoReleaser config"
	@echo "  release-snapshot Build snapshot release"
	@echo ""
	@echo "Other:"
	@echo "  clean            Clean artifacts"
	@echo "  setup            Setup dev environment"
	@echo "  info             Show build info"
	@echo "  help             Show this help"
