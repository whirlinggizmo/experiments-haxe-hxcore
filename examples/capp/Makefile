# Compiler and linker settings
CXX      = g++
CXXFLAGS = -std=c++11 -I./dist/lib -Os
LDFLAGS  = -L./dist/lib -lhxcore

# Target executable and source files
SRC    = src/cpp/main.cpp
OUTDIR = dist/app
TARGET = $(OUTDIR)/main

# Default target: build the executable
all: $(TARGET)

$(OUTDIR):
	mkdir -p $(OUTDIR)

$(TARGET): $(OUTDIR) $(SRC)
	$(CXX) $(CXXFLAGS) $(SRC) $(LDFLAGS) -o $(TARGET)

# Clean up generated files
clean:
	rm -f $(TARGET)
