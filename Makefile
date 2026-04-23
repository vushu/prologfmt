# --- OS Detection ---
ifeq ($(OS),Windows_NT)
    # Windows Settings
    EXE = .exe
    RM = del /Q
    CLEAN_CMD = if exist $(TARGET)$(EXE) $(RM) $(TARGET)$(EXE)
    # Ensure swipl is in the path
    PROLOG = swipl
else
    # macOS and Linux Settings
    EXE =
    RM = rm -f
    CLEAN_CMD = $(RM) $(TARGET)
    PROLOG = swipl
endif

# --- Configuration ---
SOURCE = prologfmt.pl
TARGET = prologfmt
FLAGS  = -O -q

# --- Targets ---

# Default: Build the binary
all: $(TARGET)$(EXE)

# Compile the standalone binary
# The saved state is fast because it's a pre-compiled memory image
$(TARGET)$(EXE): $(SOURCE)
	@echo "Compiling for $(OS)..."
	$(PROLOG) $(FLAGS) -o $(TARGET)$(EXE) -g main -c $(SOURCE)
	@# Only chmod if we are not on Windows
	@if [ "$(OS)" != "Windows_NT" ]; then chmod +x $(TARGET)$(EXE); fi
	@echo "Build complete: $(TARGET)$(EXE)"

# Run tests from source (Fastest feedback loop)
# We use halt(0) on success and halt(1) on failure for CI/CD compatibility
test:
	@echo "Running tests from source..."
	@$(PROLOG) $(FLAGS) -g "run_formatter_tests, halt(0)." -t "halt(1)." $(SOURCE) && echo "Tests Passed"

# Clean up build artifacts
clean:
	@echo "Cleaning up..."
	@$(CLEAN_CMD)

# Check SWI-Prolog version
version:
	$(PROLOG) --version

.PHONY: all test clean version