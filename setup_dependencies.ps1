# PowerShell Setup Script for MMFN Project
# This script downloads external model files and sets up the environment

# Enable strict mode
$ErrorActionPreference = "Stop"

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "MMFN Project Dependency Setup" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# Check if Python is installed
try {
    $pythonVersion = python --version 2>&1
    Write-Host "✓ Python found: $pythonVersion" -ForegroundColor Green
} catch {
    Write-Host "Error: Python is not installed. Please install Python 3.8 or higher." -ForegroundColor Red
    exit 1
}
Write-Host ""

# Step 1: Create virtual environment if it doesn't exist
if (-not (Test-Path "venv")) {
    Write-Host "Creating virtual environment..." -ForegroundColor Yellow
    python -m venv venv
    Write-Host "✓ Virtual environment created" -ForegroundColor Green
} else {
    Write-Host "✓ Virtual environment already exists" -ForegroundColor Green
}
Write-Host ""

# Step 2: Activate virtual environment
Write-Host "Activating virtual environment..." -ForegroundColor Yellow
& .\venv\Scripts\Activate.ps1
Write-Host "✓ Virtual environment activated" -ForegroundColor Green
Write-Host ""

# Step 3: Upgrade pip
Write-Host "Upgrading pip..." -ForegroundColor Yellow
python -m pip install --upgrade pip | Out-Null
Write-Host "✓ pip upgraded" -ForegroundColor Green
Write-Host ""

# Step 4: Install Python packages
Write-Host "Installing Python packages..." -ForegroundColor Yellow
if (Test-Path "requirements.txt") {
    Write-Host "Installing from requirements.txt..." -ForegroundColor Yellow
    pip install -r requirements.txt
    Write-Host "✓ Python packages installed" -ForegroundColor Green
} else {
    Write-Host "Warning: requirements.txt not found. Installing essential packages..." -ForegroundColor Red
    Write-Host "Installing PyTorch with CUDA support..." -ForegroundColor Yellow
    pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118
    
    Write-Host "Installing other dependencies..." -ForegroundColor Yellow
    pip install transformers scikit-learn tqdm numpy pillow opencv-python pandas langdetect packaging
    
    Write-Host "Installing CLIP from GitHub..." -ForegroundColor Yellow
    pip install git+https://github.com/openai/CLIP.git
    
    Write-Host "✓ Essential packages installed" -ForegroundColor Green
}
Write-Host ""

# Step 5: Download CLIP BPE vocabulary file
Write-Host "Downloading CLIP BPE vocabulary file..." -ForegroundColor Yellow
if (-not (Test-Path "bpe_simple_vocab_16e6.txt.gz")) {
    try {
        $url = "https://github.com/openai/CLIP/raw/main/clip/bpe_simple_vocab_16e6.txt.gz"
        $output = "bpe_simple_vocab_16e6.txt.gz"
        
        # Use Invoke-WebRequest or curl
        if (Get-Command curl -ErrorAction SilentlyContinue) {
            curl -L -o $output $url
        } else {
            Invoke-WebRequest -Uri $url -OutFile $output
        }
        Write-Host "✓ BPE vocabulary file downloaded" -ForegroundColor Green
    } catch {
        Write-Host "Error downloading BPE vocabulary file: $_" -ForegroundColor Red
        Write-Host "Please download manually from: $url" -ForegroundColor Yellow
    }
} else {
    Write-Host "✓ BPE vocabulary file already exists" -ForegroundColor Green
}
Write-Host ""

# Step 6: Verify model files will be downloaded on first run
Write-Host "Note: Pre-trained models will be downloaded automatically on first run:" -ForegroundColor Yellow
Write-Host "  - bert-base-chinese (~400MB)"
Write-Host "  - microsoft/swin-base-patch4-window7-224 (~350MB)"
Write-Host "  - OpenAI CLIP ViT-B/32 (~350MB)"
Write-Host "These will be cached in: $env:USERPROFILE\.cache\huggingface"
Write-Host ""

# Step 7: Check dataset structure
Write-Host "Checking dataset structure..." -ForegroundColor Yellow
if (Test-Path "dataset\twitter") {
    Write-Host "✓ Twitter dataset directory found" -ForegroundColor Green
    
    # Check for required files
    $trainExists = Test-Path "dataset\twitter\train_posts.txt"
    $testExists = Test-Path "dataset\twitter\test_posts.txt"
    
    if ($trainExists -and $testExists) {
        Write-Host "✓ Raw data files found" -ForegroundColor Green
        
        # Check if preprocessing is needed
        $trainPreprocessed = Test-Path "dataset\twitter\train_tweets_preprocess.csv"
        $testPreprocessed = Test-Path "dataset\twitter\test_tweets_preprocess.csv"
        
        if (-not ($trainPreprocessed -and $testPreprocessed)) {
            Write-Host "Preprocessing files not found. Running preprocessing..." -ForegroundColor Yellow
            Push-Location data
            python twitter_preprocess.py
            Pop-Location
            Write-Host "✓ Dataset preprocessing complete" -ForegroundColor Green
        } else {
            Write-Host "✓ Preprocessed data files already exist" -ForegroundColor Green
        }
    } else {
        Write-Host "Warning: Raw data files (train_posts.txt, test_posts.txt) not found in dataset\twitter\" -ForegroundColor Red
        Write-Host "Please ensure your dataset is properly placed in the dataset\twitter directory"
    }
} else {
    Write-Host "Warning: dataset\twitter directory not found" -ForegroundColor Red
    Write-Host "Please create the directory and add your dataset files"
}
Write-Host ""

# Step 8: Create a requirements.txt if it doesn't exist
if (-not (Test-Path "requirements.txt")) {
    Write-Host "Creating requirements.txt..." -ForegroundColor Yellow
    pip freeze > requirements.txt
    Write-Host "✓ requirements.txt created" -ForegroundColor Green
    Write-Host ""
}

# Step 9: Summary
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Setup Complete!" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next steps:"
Write-Host "1. Activate the virtual environment (if not already active):"
Write-Host "   .\venv\Scripts\Activate.ps1" -ForegroundColor Yellow
Write-Host ""
Write-Host "2. Run the training script:"
Write-Host "   python trainMMFN.py" -ForegroundColor Yellow
Write-Host ""
Write-Host "3. Or run preprocessing separately if needed:"
Write-Host "   cd data; python twitter_preprocess.py" -ForegroundColor Yellow
Write-Host ""
Write-Host "Note: First run will download pre-trained models (~1GB total)" -ForegroundColor Yellow
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
