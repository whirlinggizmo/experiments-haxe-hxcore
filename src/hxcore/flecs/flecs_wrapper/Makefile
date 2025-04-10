# Makefile

# helper to fix the issue with wildcard for subdirectories not including ./
rwildcard = $(wildcard $1$2) $(foreach d,$(wildcard $1*/),$(call rwildcard,$d,$2))

# Paths
WRAPPER_SRC_DIR     = ./src/
WRAPPER_INC_DIR     = ./include/
FLECS_DIR   = ../vendor/flecs/distr
FLECS_SRC_DIR = ../vendor/flecs/distr
FLECS_INC_DIR = ../vendor/flecs/distr
BUILD_DIR   = ./build
FLECS_BUILD_DIR = $(BUILD_DIR)/flecs
WRAPPER_BUILD_DIR = $(BUILD_DIR)/wrapper
BIN_DIR     = ./lib

# Output
TARGET_DYNAMIC      = $(BIN_DIR)/libflecs_wrapper.so
TARGET_STATIC       = $(BIN_DIR)/libflecs_wrapper.a

# Files
WRAPPER_SRC = $(call rwildcard,$(WRAPPER_SRC_DIR),*.c)
FLECS_SRC = $(call rwildcard,$(FLECS_SRC_DIR),*.c)
FLECS_OBJ   = $(patsubst $(FLECS_SRC_DIR)/%.c,$(FLECS_BUILD_DIR)/%.o,$(FLECS_SRC))
FLECS_LIB   = $(BIN_DIR)/libflecs.a

# Compiler
CC          = gcc
CFLAGS      = -fPIC -Wall -O2 -fvisibility=default 
LDFLAGS     = -shared

# Default target
all: $(TARGET_DYNAMIC) $(TARGET_STATIC)

static: $(TARGET_STATIC)

dynamic: $(TARGET_DYNAMIC)

# Rule to build all Flecs .o files into build/flecs/
$(FLECS_BUILD_DIR)/%.o: $(FLECS_SRC_DIR)/%.c
	mkdir -p $(dir $@)
	$(CC) $(CFLAGS) -I$(FLECS_INC_DIR) -c $< -o $@

# Archive all .o into libflecs.a
$(FLECS_LIB): $(FLECS_OBJ)
	mkdir -p $(BIN_DIR)
	cp -r $(FLECS_INC_DIR)/*.h $(WRAPPER_INC_DIR)
	ar rcs $(FLECS_LIB) $(FLECS_OBJ)
	@echo "Flecs library built: $(FLECS_LIB)"

# Link wrapper .so against static Flecs lib
# Note: Weuse the flecs.c source directly instead of first building the flecs library 
#$(TARGET_DYNAMIC): $(FLECS_LIB) $(WRAPPER_SRC)
#	$(CC) $(CFLAGS) -I$(WRAPPER_INC_DIR) $(WRAPPER_SRC) -o $(TARGET_DYNAMIC) $(LDFLAGS) $(FLECS_LIB)
$(TARGET_DYNAMIC): $(WRAPPER_SRC)
	mkdir -p $(BIN_DIR)
	$(CC) $(CFLAGS) -I$(WRAPPER_INC_DIR) $(WRAPPER_SRC) -o $(TARGET_DYNAMIC) $(LDFLAGS) 

# Create static wrapper library
# Note: We use include flecs.c source directly instead of pre-generating flecs object files 
#$(TARGET_STATIC): $(FLECS_OBJ) $(WRAPPER_SRC)
#	mkdir -p $(WRAPPER_BUILD_DIR)
#	$(foreach src,$(WRAPPER_SRC),$(CC) $(CFLAGS) -I$(WRAPPER_INC_DIR) -c $(src) -o $(WRAPPER_BUILD_DIR)/$(notdir $(basename $(src))).o;)
#	# Combine both flecs and wrapper object files into one static library
#	ar rcs $(TARGET_STATIC) $(WRAPPER_BUILD_DIR)/*.o $(FLECS_OBJ)

$(TARGET_STATIC): $(WRAPPER_SRC)
	mkdir -p $(BIN_DIR)
	mkdir -p $(WRAPPER_BUILD_DIR)
	$(foreach src,$(WRAPPER_SRC),$(CC) $(CFLAGS) -I$(WRAPPER_INC_DIR) -c $(src) -o $(WRAPPER_BUILD_DIR)/$(notdir $(basename $(src))).o;)
	ar rcs $(TARGET_STATIC) $(WRAPPER_BUILD_DIR)/*.o 


# Cleanup
clean:
	rm -f $(TARGET_DYNAMIC) $(TARGET_STATIC) $(FLECS_LIB)
	rm -rf $(BUILD_DIR)

print-srcs:
	@echo "TARGET_DYNAMIC: $(TARGET_DYNAMIC)"
	@echo "TARGET_STATIC: $(TARGET_STATIC)"
#	@echo "FLECS_DIR: $(FLECS_DIR)"
	@echo "BUILD_DIR: $(BUILD_DIR)"
	@echo "BIN_DIR: $(BIN_DIR)"
	@echo "WRAPPER_SRC_DIR: $(WRAPPER_SRC_DIR)"
	@echo "WRAPPER_INC_DIR: $(WRAPPER_INC_DIR)"
	@echo "WRAPPER_SRC: $(WRAPPER_SRC)"
#	@echo "FLECS_SRC_DIR: $(FLECS_SRC_DIR)"
#	@echo "FLECS_INC_DIR: $(FLECS_INC_DIR)"
#	@echo "FLECS_SRC: $(FLECS_SRC)"
#	@echo "FLECS_OBJ: $(FLECS_OBJ)"
