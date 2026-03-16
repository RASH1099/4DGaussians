#!/usr/bin/env bash
set -euo pipefail

ENV_NAME="${1:-Gaussians4D_cu116}"
PYTHON_VERSION="${PYTHON_VERSION:-3.7}"
CUDA_HOME="${CUDA_HOME:-/usr/local/cuda-11.6}"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if ! command -v conda >/dev/null 2>&1; then
    echo "conda not found in PATH"
    exit 1
fi

CONDA_BIN="$(command -v conda)"
CONDA_BASE="$(cd "$(dirname "$CONDA_BIN")/.." && pwd)"

if [ ! -f "$CONDA_BASE/etc/profile.d/conda.sh" ]; then
    echo "conda.sh not found under $CONDA_BASE"
    exit 1
fi

source "$CONDA_BASE/etc/profile.d/conda.sh"

export CUDA_HOME
export PATH="$CUDA_HOME/bin:$PATH"
export LD_LIBRARY_PATH="$CUDA_HOME/lib64:${LD_LIBRARY_PATH:-}"
export CONDA_SOLVER=classic
export PIP_DEFAULT_TIMEOUT="${PIP_DEFAULT_TIMEOUT:-1000}"

echo "repo root: $REPO_ROOT"
echo "target env: $ENV_NAME"
echo "python: $PYTHON_VERSION"
echo "cuda home: $CUDA_HOME"

if [ ! -d "$CUDA_HOME" ]; then
    echo "CUDA_HOME does not exist: $CUDA_HOME"
    exit 1
fi

if ! CONDA_NO_PLUGINS=true conda env list | awk '{print $1}' | grep -qx "$ENV_NAME"; then
    CONDA_NO_PLUGINS=true conda create -y --solver classic -n "$ENV_NAME" "python=$PYTHON_VERSION"
fi

conda activate "$ENV_NAME"

python -m pip install --upgrade pip setuptools wheel
python -m pip uninstall -y diff-gaussian-rasterization simple-knn || true

python -m pip install --retries 5 \
    --extra-index-url https://download.pytorch.org/whl/cu116 \
    torch==1.13.1+cu116 \
    torchvision==0.14.1+cu116 \
    torchaudio==0.13.1

python -m pip install -r "$REPO_ROOT/requirements.txt"

rm -rf "$REPO_ROOT/submodules/depth-diff-gaussian-rasterization/build"
rm -rf "$REPO_ROOT/submodules/simple-knn/build"
rm -f "$REPO_ROOT"/submodules/depth-diff-gaussian-rasterization/diff_gaussian_rasterization/_C*.so
rm -f "$REPO_ROOT"/submodules/simple-knn/simple_knn/_C*.so

python -m pip install -e "$REPO_ROOT/submodules/depth-diff-gaussian-rasterization"
python -m pip install -e "$REPO_ROOT/submodules/simple-knn"

python - <<'PY'
import torch
print("torch", torch.__version__)
print("torch cuda", torch.version.cuda)
print("cuda available", torch.cuda.is_available())
import diff_gaussian_rasterization
from simple_knn import _C as simple_knn_C
print("diff_gaussian_rasterization", diff_gaussian_rasterization.__file__)
print("simple_knn._C", simple_knn_C.__file__)
PY

echo
echo "Environment is ready."
echo "Activate with: conda activate $ENV_NAME"
