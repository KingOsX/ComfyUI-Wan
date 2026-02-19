#!/bin/bash

# ============================================================================
#  ComfyUI + WAN 2.2 NSFW Enhanced SVI (CF) - RunPod One-Click Installer
#  Modele : wan22EnhancedNSFWSVICamera (nolightning SVI CF Q8 H+L)
#  LoRA   : DR34ML4Y I2V 14B v2
#
#  Usage: CIVITAI_TOKEN=xxx bash install.sh [OPTIONS]
#
#  OPTIONS:
#    --svi              Telecharge les SVI LoRAs High + Low (Kijai v2 PRO)
#    --lightning 1|2|3  Lightning LoRA combo (1=Motion, 2=Quality, 3=Balanced)
#    --nsfw-clip        Text encoder NSFW UMT5-XXL (fp8) au lieu du standard
#    --no-lora          Ne telecharge pas le LoRA DR34ML4Y
#    --light            Installation minimale (sans KJNodes)
#
#  DISK SPACE REQUIRED:
#    Defaut (High+Low GGUF + LoRA + encodeurs) : ~38 GB -> Volume 50 GB
#    + SVI LoRAs                               : ~41 GB -> Volume 55 GB
#    + Lightning LoRAs                         : ~43 GB -> Volume 60 GB
#
#  CIVITAI TOKEN:
#    Obligatoire pour telecharger les modeles CivitAI.
#    Obtenir sur : civitai.com -> Settings -> API Keys
#    Usage: CIVITAI_TOKEN=votre_token bash install.sh
# ============================================================================

CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

LOG_FILE="/workspace/install.log"

log()  { echo -e "${CYAN}[INSTALL]${NC} $1" | tee -a "$LOG_FILE"; }
ok()   { echo -e "${GREEN}[  OK  ]${NC} $1" | tee -a "$LOG_FILE"; }
warn() { echo -e "${YELLOW}[ WARN ]${NC} $1" | tee -a "$LOG_FILE"; }
err()  { echo -e "${RED}[ERROR ]${NC} $1" | tee -a "$LOG_FILE"; }

# --- Config par defaut ---
WORKSPACE="/workspace"
DOWNLOAD_SVI=false
LIGHTNING_COMBO=0
NSFW_CLIP=false
DOWNLOAD_LORA=true
LIGHT_MODE=false
LISTEN_PORT=8188

# --- Init log ---
echo "" >> "$LOG_FILE"
echo "========== $(date) ==========" >> "$LOG_FILE"

# --- Parse arguments ---
while [[ $# -gt 0 ]]; do
  case $1 in
    --svi)
      DOWNLOAD_SVI=true
      shift ;;
    --lightning)
      LIGHTNING_COMBO="$2"
      shift 2 ;;
    --nsfw-clip)
      NSFW_CLIP=true
      shift ;;
    --no-lora)
      DOWNLOAD_LORA=false
      shift ;;
    --light)
      LIGHT_MODE=true
      shift ;;
    *)
      warn "Argument inconnu: $1"
      shift ;;
  esac
done

# --- Verification token CivitAI ---
if [ -z "$CIVITAI_TOKEN" ]; then
  err "CIVITAI_TOKEN non defini !"
  err "Usage : CIVITAI_TOKEN=votre_token bash install.sh"
  err "Obtenir votre token : civitai.com -> Settings -> API Keys"
  exit 1
fi

COMFY_DIR="$WORKSPACE/ComfyUI"

# --- URLs base models (HuggingFace) ---
HF_WAN_BASE="https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files"

if [ "$NSFW_CLIP" = true ]; then
  TEXT_ENCODER_FILE="nsfw_wan_umt5-xxl_fp8_scaled.safetensors"
  TEXT_ENCODER_URL="https://huggingface.co/NSFW-API/NSFW-Wan-UMT5-XXL/resolve/main/$TEXT_ENCODER_FILE"
else
  TEXT_ENCODER_FILE="umt5_xxl_fp8_e4m3fn_scaled.safetensors"
  TEXT_ENCODER_URL="$HF_WAN_BASE/text_encoders/$TEXT_ENCODER_FILE"
fi

VAE_FILE="wan_2.1_vae.safetensors"
VAE_URL="$HF_WAN_BASE/vae/$VAE_FILE"

CLIP_VISION_FILE="clip_vision_h.safetensors"
CLIP_VISION_URL="$HF_WAN_BASE/clip_vision/$CLIP_VISION_FILE"

# --- GGUF Models (CivitAI) ---
MODEL_HIGH_FILE="wan22EnhancedNSFWSVICamera_nolightningSVICfQ8H.gguf"
MODEL_HIGH_URL="https://civitai.com/api/download/models/2668710?type=Model&format=GGUF&size=full&fp=fp8&token=${CIVITAI_TOKEN}"

MODEL_LOW_FILE="wan22EnhancedNSFWSVICamera_nolightningSVICfQ8L.gguf"
MODEL_LOW_URL="https://civitai.com/api/download/models/2668712?type=Model&format=GGUF&size=full&fp=fp8&token=${CIVITAI_TOKEN}"

# --- LoRA principal (CivitAI) ---
LORA_DR34_FILE="DR34ML4Y_I2V_14B_LOW_V2.safetensors"
LORA_DR34_URL="https://civitai.com/api/download/models/2553271?type=Model&format=SafeTensor&token=${CIVITAI_TOKEN}"

# --- SVI LoRAs (HuggingFace - Kijai v2 PRO) ---
HF_KIJAI="https://huggingface.co/Kijai/WanVideo_comfy/resolve/main"
SVI_HIGH_FILE="SVI_v2_PRO_Wan2.2-I2V-A14B_HIGH_lora_rank_128_fp16.safetensors"
SVI_HIGH_URL="$HF_KIJAI/LoRAs/Stable-Video-Infinity/v2.0/$SVI_HIGH_FILE"
SVI_LOW_FILE="SVI_v2_PRO_Wan2.2-I2V-A14B_LOW_lora_rank_128_fp16.safetensors"
SVI_LOW_URL="$HF_KIJAI/LoRAs/Stable-Video-Infinity/v2.0/$SVI_LOW_FILE"

# --- Lightning LoRAs (HuggingFace) ---
HF_KIJAI_COMMIT="https://huggingface.co/Kijai/WanVideo_comfy/resolve/709844db75d2e15582cf204e9a0b5e12b23a35dd"
HF_LIGHTX2V="https://huggingface.co/lightx2v/Wan2.2-Distill-Loras/resolve/main"

LIGHT_14B_FILE="lightx2v_I2V_14B_480p_cfg_step_distill_rank128_bf16.safetensors"
LIGHT_14B_URL="$HF_KIJAI_COMMIT/Lightx2v/$LIGHT_14B_FILE"

LIGHT_HIGH_NOISE_FILE="wan2.2_i2v_A14b_high_noise_lora_rank64_lightx2v_4step_1022.safetensors"
LIGHT_HIGH_NOISE_URL="$HF_LIGHTX2V/$LIGHT_HIGH_NOISE_FILE"

LIGHT_LOW_NOISE_FILE="wan2.2_i2v_A14b_low_noise_lora_rank64_lightx2v_4step_1022.safetensors"
LIGHT_LOW_NOISE_URL="$HF_LIGHTX2V/$LIGHT_LOW_NOISE_FILE"

echo ""
echo "=============================================="
echo "  ComfyUI + WAN 2.2 NSFW SVI (CF) Installer"
echo "  for RunPod"
echo "=============================================="
echo ""
log "Text Encoder       : $([ "$NSFW_CLIP" = true ] && echo "NSFW UMT5-XXL fp8" || echo "Standard UMT5-XXL fp8")"
log "Modele High        : $MODEL_HIGH_FILE"
log "Modele Low         : $MODEL_LOW_FILE"
log "LoRA DR34ML4Y      : $([ "$DOWNLOAD_LORA" = true ] && echo "oui" || echo "non")"
log "SVI LoRAs          : $DOWNLOAD_SVI"
log "Lightning Combo    : $([ "$LIGHTNING_COMBO" -gt 0 ] && echo "Combo $LIGHTNING_COMBO" || echo "non")"
log "Workspace          : $WORKSPACE"
echo ""

# --- Verification espace disque ---
AVAILABLE_GB=$(df -BG "$WORKSPACE" 2>/dev/null | awk 'NR==2 {print $4}' | tr -d 'G')
if [ -n "$AVAILABLE_GB" ] && [ "$AVAILABLE_GB" -lt 45 ]; then
  warn "Seulement ${AVAILABLE_GB} GB disponibles !"
  warn "Recommande: 50 GB minimum (Volume Disk sur RunPod)"
  warn "Continuation..."
  echo ""
fi

# ============================================================================
# 1. Dependances systeme
# ============================================================================
log "Installation des dependances systeme..."
if apt-get update -qq && apt-get install -y -qq git wget ffmpeg libgl1 > /dev/null 2>&1; then
  ok "Dependances systeme installees"
else
  warn "apt-get a echoue (peut-etre deja installe, continuation...)"
fi

# ============================================================================
# 2. Clone ComfyUI
# ============================================================================
if [ -d "$COMFY_DIR" ]; then
  log "ComfyUI existe deja, mise a jour..."
  cd "$COMFY_DIR" && git pull --quiet || warn "git pull echoue (offline ?), version existante utilisee"
else
  log "Clonage de ComfyUI..."
  git clone --quiet https://github.com/comfyanonymous/ComfyUI.git "$COMFY_DIR" || {
    err "Echec du clonage de ComfyUI - verifier la connexion"
    exit 1
  }
fi
cd "$COMFY_DIR"
ok "ComfyUI pret"

# ============================================================================
# 3. Dependances Python
# ============================================================================
log "Mise a jour de pip..."
python -m pip install --upgrade pip 2>&1 | tee -a "$LOG_FILE" || true

log "Installation des dependances ComfyUI..."
pip install -r requirements.txt 2>&1 | tee -a "$LOG_FILE" || warn "Certaines dependances pip ont echoue"

log "Installation des dependances supplementaires..."
pip install sqlalchemy alembic aiohttp aiosqlite 2>&1 | tee -a "$LOG_FILE" || warn "Echec partiel"

CRITICAL_MODULES="torch sqlalchemy alembic aiohttp tqdm yaml PIL numpy"
for mod in $CRITICAL_MODULES; do
  python -c "import $mod" 2>/dev/null || {
    warn "Module '$mod' manquant, tentative d'installation..."
    pip install "$mod" 2>&1 | tee -a "$LOG_FILE" || true
  }
done
ok "Dependances Python installees"

# ============================================================================
# 4. Custom nodes
# ============================================================================
log "Installation des custom nodes..."
cd "$COMFY_DIR/custom_nodes"

install_node() {
  local name="$1"
  local url="$2"
  if [ -d "$name" ]; then
    log "  Mise a jour de $name..."
    (cd "$name" && git pull --quiet) || warn "  Echec de la mise a jour de $name"
  else
    log "  Clonage de $name..."
    git clone "$url" "$name" 2>&1 | tee -a "$LOG_FILE"
    if [ ! -d "$name" ]; then
      err "  ECHEC du clonage de $name - nouvelle tentative..."
      git clone "$url" "$name" 2>&1 | tee -a "$LOG_FILE" || err "  $name - echec apres retry"
    fi
  fi
  if [ -f "$name/requirements.txt" ]; then
    pip install -r "$name/requirements.txt" 2>&1 | tee -a "$LOG_FILE" || warn "  Certaines deps de $name ont echoue"
  fi
}

# ComfyUI-Manager (essentiel)
install_node "ComfyUI-Manager" "https://github.com/ltdrdata/ComfyUI-Manager.git"

# VideoHelperSuite (output video)
install_node "ComfyUI-VideoHelperSuite" "https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite.git"

# ComfyUI-GGUF (pour charger les modeles .gguf)
install_node "ComfyUI-GGUF" "https://github.com/city96/ComfyUI-GGUF.git"

# KJNodes (WAN NAG node pour negative prompts)
if [ "$LIGHT_MODE" != true ]; then
  install_node "ComfyUI-KJNodes" "https://github.com/kijai/ComfyUI-KJNodes.git"
fi

if [ -d "ComfyUI-Manager" ] && [ -d "ComfyUI-GGUF" ]; then
  ok "Custom nodes installes (Manager + GGUF verifies)"
else
  err "Un ou plusieurs custom nodes manquants ! Verifier la connexion."
fi

# ============================================================================
# 5. Creation des repertoires modeles
# ============================================================================
cd "$COMFY_DIR"
mkdir -p models/diffusion_models
mkdir -p models/text_encoders
mkdir -p models/vae
mkdir -p models/clip_vision
mkdir -p models/loras

# ============================================================================
# 6. Fonctions de telechargement
# ============================================================================
download_hf() {
  local url="$1"
  local dest="$2"
  local filename=$(basename "$dest")
  if [ -f "$dest" ] && [ -s "$dest" ]; then
    ok "Deja telecharge: $filename"
    return 0
  fi
  [ -f "$dest" ] && rm -f "$dest"
  log "Telechargement $filename..."
  wget -q --show-progress -O "$dest" "$url" || {
    warn "Echec du telechargement de $filename - suppression"
    rm -f "$dest"
    return 1
  }
  ok "Telecharge: $filename"
}

download_civitai() {
  local url="$1"
  local dest="$2"
  local filename=$(basename "$dest")
  if [ -f "$dest" ] && [ -s "$dest" ]; then
    ok "Deja telecharge: $filename"
    return 0
  fi
  [ -f "$dest" ] && rm -f "$dest"
  log "Telechargement CivitAI: $filename (~15 GB, patience)..."
  wget -q --show-progress \
    --content-disposition \
    -O "$dest" \
    "$url" || {
    warn "Echec du telechargement de $filename - suppression"
    rm -f "$dest"
    return 1
  }
  ok "Telecharge: $filename"
}

# ============================================================================
# 7. Telechargement des modeles de base (HuggingFace)
# ============================================================================

# --- Text Encoder ---
download_hf "$TEXT_ENCODER_URL" "models/text_encoders/$TEXT_ENCODER_FILE"

# --- VAE ---
download_hf "$VAE_URL" "models/vae/$VAE_FILE"

# --- CLIP Vision (I2V) ---
download_hf "$CLIP_VISION_URL" "models/clip_vision/$CLIP_VISION_FILE"

# ============================================================================
# 8. Telechargement des modeles GGUF (CivitAI)
# ============================================================================

# --- Modele High (~15 GB) ---
download_civitai "$MODEL_HIGH_URL" "models/diffusion_models/$MODEL_HIGH_FILE"

# --- Modele Low (~15 GB) ---
download_civitai "$MODEL_LOW_URL" "models/diffusion_models/$MODEL_LOW_FILE"

# ============================================================================
# 9. LoRA DR34ML4Y
# ============================================================================
if [ "$DOWNLOAD_LORA" = true ]; then
  download_civitai "$LORA_DR34_URL" "models/loras/$LORA_DR34_FILE"
fi

# ============================================================================
# 10. SVI LoRAs (optionnel)
# ============================================================================
if [ "$DOWNLOAD_SVI" = true ]; then
  log "Telechargement des SVI LoRAs (Kijai v2 PRO)..."
  download_hf "$SVI_HIGH_URL" "models/loras/$SVI_HIGH_FILE"
  download_hf "$SVI_LOW_URL"  "models/loras/$SVI_LOW_FILE"
fi

# ============================================================================
# 11. Lightning LoRAs (optionnel)
# ============================================================================
if [ "$LIGHTNING_COMBO" -gt 0 ]; then
  log "Telechargement Lightning LoRA Combo $LIGHTNING_COMBO..."

  case "$LIGHTNING_COMBO" in
    1)
      # Combo 1 : More Motion (High weight=4, Low weight=1.4)
      download_hf "$LIGHT_14B_URL"        "models/loras/$LIGHT_14B_FILE"
      download_hf "$LIGHT_LOW_NOISE_URL"  "models/loras/$LIGHT_LOW_NOISE_FILE"
      log "  -> Combo 1 : High=$LIGHT_14B_FILE (w=4) | Low=$LIGHT_LOW_NOISE_FILE (w=1.4)"
      ;;
    2)
      # Combo 2 : Less Degradation (High weight=1, Low weight=1)
      download_hf "$LIGHT_HIGH_NOISE_URL" "models/loras/$LIGHT_HIGH_NOISE_FILE"
      download_hf "$LIGHT_LOW_NOISE_URL"  "models/loras/$LIGHT_LOW_NOISE_FILE"
      log "  -> Combo 2 : High=$LIGHT_HIGH_NOISE_FILE (w=1) | Low=$LIGHT_LOW_NOISE_FILE (w=1)"
      ;;
    3)
      # Combo 3 : Balanced (meme fichier High+Low, weights 3/1.5)
      download_hf "$LIGHT_14B_URL"        "models/loras/$LIGHT_14B_FILE"
      log "  -> Combo 3 : High+Low=$LIGHT_14B_FILE (w=3 / w=1.5)"
      ;;
    *)
      warn "Combo Lightning invalide: $LIGHTNING_COMBO (valeurs: 1, 2 ou 3)"
      ;;
  esac
fi

# ============================================================================
# 12. Correction des dependances connues
# ============================================================================
log "Correction des conflits de dependances..."
pip install -q --force-reinstall protobuf sentencepiece 2>&1 | tee -a "$LOG_FILE" || true
ok "Dependances corrigees"

# ============================================================================
# 13. Verification des telechargements
# ============================================================================
log "Verification des telechargements..."
MISSING=0
for f in \
  "models/text_encoders/$TEXT_ENCODER_FILE" \
  "models/vae/$VAE_FILE" \
  "models/clip_vision/$CLIP_VISION_FILE" \
  "models/diffusion_models/$MODEL_HIGH_FILE" \
  "models/diffusion_models/$MODEL_LOW_FILE" \
; do
  if [ ! -s "$f" ]; then
    warn "MANQUANT ou VIDE: $f"
    MISSING=$((MISSING + 1))
  fi
done

if [ "$DOWNLOAD_LORA" = true ] && [ ! -s "models/loras/$LORA_DR34_FILE" ]; then
  warn "MANQUANT: models/loras/$LORA_DR34_FILE"
  MISSING=$((MISSING + 1))
fi

if [ "$MISSING" -gt 0 ]; then
  warn "$MISSING fichier(s) manquant(s) ! Verifier l'espace disque (df -h) et relancer."
else
  ok "Tous les fichiers requis sont presents"
fi

# ============================================================================
# 14. Resume
# ============================================================================
echo ""
echo "=============================================="
echo -e "${GREEN}  Installation complete !${NC}"
echo "=============================================="
echo ""
echo "  Modeles telecharges:"
echo "    - Text Encoder : $TEXT_ENCODER_FILE"
echo "    - VAE          : $VAE_FILE"
echo "    - CLIP Vision  : $CLIP_VISION_FILE"
echo "    - Model High   : $MODEL_HIGH_FILE"
echo "    - Model Low    : $MODEL_LOW_FILE"
[ "$DOWNLOAD_LORA" = true ]    && echo "    - LoRA         : $LORA_DR34_FILE"
[ "$DOWNLOAD_SVI" = true ]     && echo "    - SVI High     : $SVI_HIGH_FILE"
[ "$DOWNLOAD_SVI" = true ]     && echo "    - SVI Low      : $SVI_LOW_FILE"
[ "$LIGHTNING_COMBO" -eq 1 ]   && echo "    - Lightning    : Combo 1 (More Motion)"
[ "$LIGHTNING_COMBO" -eq 2 ]   && echo "    - Lightning    : Combo 2 (Less Degradation)"
[ "$LIGHTNING_COMBO" -eq 3 ]   && echo "    - Lightning    : Combo 3 (Balanced)"
echo ""
USED=$(du -sh "$COMFY_DIR/models" 2>/dev/null | awk '{print $1}')
echo "  Espace total modeles: $USED"
echo ""
echo "  Custom nodes installes:"
echo "    - ComfyUI-Manager"
echo "    - ComfyUI-GGUF       (charge les .gguf)"
echo "    - ComfyUI-VideoHelperSuite"
[ "$LIGHT_MODE" != true ] && echo "    - ComfyUI-KJNodes    (WAN NAG - negative prompts)"
echo ""
echo "  Trigger words LoRA DR34ML4Y:"
echo "    m15510n4ry | bl0wj0b | d0gg1e | c0wg1rl | d0ubl3_bj"
echo ""
echo "  Settings recommandes:"
echo "    Sampler : Euler simple"
echo "    Steps   : 2+2 (High kSampler + Low kSampler)"
echo "    CFG     : 1"
echo "    NE PAS ajouter Lightning LoRAs manuels (non integres dans SVI CF)"
echo ""
echo "  Pour demarrer ComfyUI:"
echo "    cd $COMFY_DIR && python main.py --listen 0.0.0.0 --port $LISTEN_PORT"
echo ""
echo "=============================================="

# ============================================================================
# 15. Demarrage automatique ComfyUI
# ============================================================================
log "Demarrage de ComfyUI sur le port $LISTEN_PORT..."
cd "$COMFY_DIR"

MAX_RETRIES=5
RETRY_COUNT=0
while [ "$RETRY_COUNT" -lt "$MAX_RETRIES" ]; do
  log "Lancement de ComfyUI (tentative $((RETRY_COUNT + 1))/$MAX_RETRIES)..."
  python main.py --listen 0.0.0.0 --port "$LISTEN_PORT" 2>&1 | tee -a "$LOG_FILE"
  EXIT_CODE=$?
  RETRY_COUNT=$((RETRY_COUNT + 1))
  if [ "$EXIT_CODE" -eq 0 ]; then
    break
  fi
  warn "ComfyUI a quitte avec code $EXIT_CODE, redemarrage dans 5s..."
  sleep 5
done

if [ "$RETRY_COUNT" -ge "$MAX_RETRIES" ]; then
  err "ComfyUI a echoue apres $MAX_RETRIES tentatives. Verifier $LOG_FILE"
fi

log "ComfyUI arrete. Maintien du container pour debug..."
log "Logs : cat $LOG_FILE"
log "Relancer : cd $COMFY_DIR && python main.py --listen 0.0.0.0 --port $LISTEN_PORT"
sleep infinity
