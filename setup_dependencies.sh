#!/bin/bash
# Setup script for MMFN project dependencies
# This script downloads external model files and sets up the environment

set -e  # Exit on error

echo "=========================================="
echo "MMFN Project Dependency Setup"
echo "=========================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if Python is installed
if ! command -v python3 &> /dev/null && ! command -v python &> /dev/null; then
    echo -e "${RED}Error: Python is not installed. Please install Python 3.8 or higher.${NC}"
    exit 1
fi

PYTHON_CMD=$(command -v python3 || command -v python)
echo -e "${GREEN}✓ Python found: $PYTHON_CMD${NC}"

# Check Python version
PYTHON_VERSION=$($PYTHON_CMD --version 2>&1 | awk '{print $2}')
echo "Python version: $PYTHON_VERSION"
echo ""

# Step 1: Create virtual environment if it doesn't exist
if [ ! -d "venv" ]; then
    echo -e "${YELLOW}Creating virtual environment...${NC}"
    $PYTHON_CMD -m venv venv
    echo -e "${GREEN}✓ Virtual environment created${NC}"
else
    echo -e "${GREEN}✓ Virtual environment already exists${NC}"
fi
echo ""

# Step 2: Activate virtual environment
echo -e "${YELLOW}Activating virtual environment...${NC}"
source venv/bin/activate
echo -e "${GREEN}✓ Virtual environment activated${NC}"
echo ""

# Step 3: Upgrade pip
echo -e "${YELLOW}Upgrading pip...${NC}"
python -m pip install --upgrade pip
echo -e "${GREEN}✓ pip upgraded${NC}"
echo ""

# Step 4: Install Python packages
echo -e "${YELLOW}Installing Python packages from requirements.txt...${NC}"
if [ -f "requirements.txt" ]; then
    pip install -r requirements.txt
    echo -e "${GREEN}✓ Python packages installed${NC}"
else
    echo -e "${RED}Warning: requirements.txt not found. Installing essential packages...${NC}"
    pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118
    pip install transformers scikit-learn tqdm numpy pillow opencv-python pandas langdetect packaging
    pip install git+https://github.com/openai/CLIP.git
    echo -e "${GREEN}✓ Essential packages installed${NC}"
fi
echo ""

# Step 5: Download CLIP BPE vocabulary file
echo -e "${YELLOW}Downloading CLIP BPE vocabulary file...${NC}"
if [ ! -f "bpe_simple_vocab_16e6.txt.gz" ]; then
    curl -L -o bpe_simple_vocab_16e6.txt.gz https://github.com/openai/CLIP/raw/main/clip/bpe_simple_vocab_16e6.txt.gz
    echo -e "${GREEN}✓ BPE vocabulary file downloaded${NC}"
else
    echo -e "${GREEN}✓ BPE vocabulary file already exists${NC}"
fi
echo ""

# Step 6: Verify model files will be downloaded on first run
echo -e "${YELLOW}Note: Pre-trained models will be downloaded automatically on first run:${NC}"
echo "  - bert-base-chinese (~400MB)"
echo "  - microsoft/swin-base-patch4-window7-224 (~350MB)"
echo "  - OpenAI CLIP ViT-B/32 (~350MB)"
echo "These will be cached in your home directory under .cache/huggingface"
echo ""

# Step 7: Check dataset structure
echo -e "${YELLOW}Checking dataset structure...${NC}"
if [ -d "dataset/twitter" ]; then
    echo -e "${GREEN}✓ Twitter dataset directory found${NC}"
    
    # Check for required files
    if [ -f "dataset/twitter/train_posts.txt" ] && [ -f "dataset/twitter/test_posts.txt" ]; then
        echo -e "${GREEN}✓ Raw data files found${NC}"
        
        # Check if preprocessing is needed
        if [ ! -f "dataset/twitter/train_tweets_preprocess.csv" ] || [ ! -f "dataset/twitter/test_tweets_preprocess.csv" ]; then
            echo -e "${YELLOW}Preprocessing files not found. Running preprocessing...${NC}"
            cd data
            python twitter_preprocess.py
            cd ..
            echo -e "${GREEN}✓ Dataset preprocessing complete${NC}"
        else
            echo -e "${GREEN}✓ Preprocessed data files already exist${NC}"
        fi
    else
        echo -e "${RED}Warning: Raw data files (train_posts.txt, test_posts.txt) not found in dataset/twitter/${NC}"
        echo "Please ensure your dataset is properly placed in the dataset/twitter directory"
    fi
else
    echo -e "${RED}Warning: dataset/twitter directory not found${NC}"
    echo "Please create the directory and add your dataset files"
fi
echo ""

# Step 8: Summary
echo "=========================================="
echo -e "${GREEN}Setup Complete!${NC}"
echo "=========================================="
echo ""
echo "Next steps:"
echo "1. Activate the virtual environment:"
echo "   source venv/bin/activate"
echo ""
echo "2. Run the training script:"
echo "   python trainMMFN.py"
echo ""
echo "3. Or run preprocessing separately if needed:"
echo "   cd data && python twitter_preprocess.py"
echo ""
echo -e "${YELLOW}Note: First run will download pre-trained models (~1GB total)${NC}"
echo "=========================================="
