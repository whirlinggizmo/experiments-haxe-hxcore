# Compiler and linker settings
CXX      = g++
CXXFLAGS = -std=c++11 -I../test/dist/lib
LDFLAGS  = -L../test/dist/lib -lhxcore

# Target executable and source files
TARGET = main
SRC    = main.cpp

# Default target: build the executable
all: $(TARGET)

$(TARGET): $(SRC)
	$(CXX) $(CXXFLAGS) $(SRC) $(LDFLAGS) -o $(TARGET)

# Clean up generated files
clean:
	rm -f $(TARGET)
