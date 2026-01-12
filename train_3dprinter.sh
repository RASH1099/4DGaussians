#!/bin/bash
# 无管理员权限也能运行的 NeRF 训练/渲染/评估脚本

# 配置（根据你自己的路径修改）
GPU=0
PORT_BASE=6000
SCENE_NAME="3dprinter"
DATA_ROOT="data/hypernerf"
CONFIG_ROOT="arguments/hypernerf"
OUTPUT_ROOT="output"
PORT_NUM="6017"

# 自动推导路径
DATA_PATH="${DATA_ROOT}/${SCENE_NAME}"
CONFIG_FILE="${CONFIG_ROOT}/${SCENE_NAME}.py"
MODEL_PATH="${OUTPUT_ROOT}/${SCENE_NAME}"

# 步骤1：训练
echo "开始训练..."
python train.py \
  -s "${DATA_PATH}" \
  --port "${PORT_NUM}" \
  --expname "${SCENE_NAME}" \
  --configs "${CONFIG_FILE}"

# 步骤2：渲染
echo "开始渲染..."
python render.py \
  --model_path "${MODEL_PATH}" \
  --skip_train \
  --configs "${CONFIG_FILE}"

# 步骤3：评估
echo "开始评估..."
python metrics.py \
  --model_path "${MODEL_PATH}"

echo "全部完成！结果在 ${MODEL_PATH}"