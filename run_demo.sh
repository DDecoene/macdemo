#!/bin/bash

# A simple script to compile and run the C + Metal demo on macOS.

# Define some colors for output
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

DEMO_NAME="mydemo"
METAL_SHADER_FILE="shaders.metal"
INTERMEDIATE_AIR_FILE="shaders.air"
METAL_LIBRARY_FILE="default.metallib"

echo -e "${GREEN}Starting C + Metal demo compilation and execution...${NC}"
echo ""

# --- Command 1: Compile Metal Shaders ---
echo -e "${CYAN}1. Compiling Metal shaders...${NC}"
xcrun metal -c "$METAL_SHADER_FILE" -o "$INTERMEDIATE_AIR_FILE"
if [ $? -ne 0 ]; then
    echo -e "${RED}Error: Failed to compile Metal shaders.${NC}"
    exit 1
fi
echo -e "${GREEN}   Metal shaders compiled successfully.${NC}"
echo ""

# --- Command 2: Create Metal Library ---
echo -e "${CYAN}2. Creating Metal library...${NC}"
xcrun metallib "$INTERMEDIATE_AIR_FILE" -o "$METAL_LIBRARY_FILE"
if [ $? -ne 0 ]; then
    echo -e "${RED}Error: Failed to create Metal library.${NC}"
    exit 1
fi
echo -e "${GREEN}   Metal library created successfully.${NC}"
echo ""

# --- Command 3: Compile C/Objective-C Code ---
echo -e "${CYAN}3. Compiling C/Objective-C code...${NC}"
clang -x objective-c main.c renderer.m -o "$DEMO_NAME" -fobjc-arc -framework Metal -framework MetalKit -framework Cocoa -framework QuartzCore
if [ $? -ne 0 ]; then
    echo -e "${RED}Error: Failed to compile C/Objective-C code.${NC}"
    echo -e "${YELLOW}Please ensure you have Xcode Command Line Tools installed.${NC}"
    exit 1
fi
echo -e "${GREEN}   C/Objective-C code compiled successfully.${NC}"
echo ""

# --- Command 4: Run the Demo ---
echo -e "${YELLOW}4. Running the demo. Press Ctrl+C in the terminal to quit.${NC}"
"./$DEMO_NAME"

echo ""
echo -e "${GREEN}Demo execution finished.${NC}"

# Optional: Clean up intermediate files if you wish
# echo -e "${CYAN}Cleaning up intermediate files...${NC}"
# rm "$INTERMEDIATE_AIR_FILE" "$METAL_LIBRARY_FILE"

exit 0