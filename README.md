# ComfyUI + WAN 2.2 NSFW Enhanced SVI | RunPod Installer

Installation automatique de **ComfyUI** avec le modele **WAN 2.2 NSFW Enhanced SVI (CF)** sur **RunPod** en une seule commande.

Modele Dual High+Low en GGUF fp8, compatible SVI (Stable Video Infinity), I2V et T2V, avec LoRA DR34ML4Y integre.

## Installation rapide

### Methode 1 : Clone + Run

```bash
git clone https://github.com/KingOsX/ComfyUI-Wan.git && CIVITAI_TOKEN=votre_token bash ComfyUI-Wan/install.sh
```

### Methode 2 : Directe (sans clone)

```bash
CIVITAI_TOKEN=votre_token bash <(wget -qO- https://raw.githubusercontent.com/KingOsX/ComfyUI-Wan/main/install.sh)
```

> Obtenir votre token CivitAI : **civitai.com → Settings → API Keys**

## Options du script

| Flag | Description |
|------|-------------|
| *(defaut)* | High+Low GGUF + LoRA DR34ML4Y + Text Encoder + VAE + CLIP Vision (~38 GB) |
| `--svi` | Ajoute les **SVI LoRAs** High + Low (Kijai v2 PRO, +2.5 GB) |
| `--lightning 1` | **Combo 1** : More Motion (High w=4, Low w=1.4) |
| `--lightning 2` | **Combo 2** : Less Degradation / qualite (High w=1, Low w=1) |
| `--lightning 3` | **Combo 3** : Balanced (High w=3, Low w=1.5) |
| `--nsfw-clip` | Text encoder **NSFW UMT5-XXL fp8** (meilleure comprehension NSFW) |
| `--no-lora` | Ne telecharge pas le LoRA DR34ML4Y |
| `--light` | Installation minimale (sans KJNodes) |

Les flags sont combinables :

```bash
# Defaut (High+Low + LoRA, ~38 GB)
CIVITAI_TOKEN=xxx bash install.sh

# + SVI LoRAs pour videos longues
CIVITAI_TOKEN=xxx bash install.sh --svi

# + Lightning Combo 2 (moins de degradation) + Text encoder NSFW
CIVITAI_TOKEN=xxx bash install.sh --lightning 2 --nsfw-clip

# Configuration complete (tout)
CIVITAI_TOKEN=xxx bash install.sh --svi --lightning 2 --nsfw-clip
```

## Ce qui est installe

### Logiciels

| Composant | Source |
|-----------|--------|
| ComfyUI | [comfyanonymous/ComfyUI](https://github.com/comfyanonymous/ComfyUI) |
| ComfyUI-GGUF | [city96/ComfyUI-GGUF](https://github.com/city96/ComfyUI-GGUF) |
| ComfyUI-VideoHelperSuite | [Kosinkadink/ComfyUI-VideoHelperSuite](https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite) |
| ComfyUI-KJNodes | [kijai/ComfyUI-KJNodes](https://github.com/kijai/ComfyUI-KJNodes) |
| ComfyUI-Manager | [ltdrdata/ComfyUI-Manager](https://github.com/ltdrdata/ComfyUI-Manager) |

> **ComfyUI-GGUF** est indispensable pour charger les fichiers `.gguf`.
> **ComfyUI-KJNodes** est requis pour le node **WAN NAG** (negative prompts).

### Modeles (config par defaut)

| Modele | Taille | Emplacement |
|--------|--------|-------------|
| `wan22EnhancedNSFWSVICamera_nolightningSVICfQ8H.gguf` | ~15 GB | `models/diffusion_models/` |
| `wan22EnhancedNSFWSVICamera_nolightningSVICfQ8L.gguf` | ~15 GB | `models/diffusion_models/` |
| `umt5_xxl_fp8_e4m3fn_scaled.safetensors` | ~5 GB | `models/text_encoders/` |
| `wan_2.1_vae.safetensors` | ~1 GB | `models/vae/` |
| `clip_vision_h.safetensors` | ~0.8 GB | `models/clip_vision/` |
| `DR34ML4Y_I2V_14B_LOW_V2.safetensors` | ~292 MB | `models/loras/` |

**Espace modeles (defaut) : ~38 GB**

### Modeles optionnels

| Modele | Flag | Taille |
|--------|------|--------|
| SVI High LoRA (Kijai v2 PRO) | `--svi` | 1.23 GB |
| SVI Low LoRA (Kijai v2 PRO) | `--svi` | 1.23 GB |
| lightx2v_I2V_14B_480p (Combo 1 & 3) | `--lightning 1` ou `3` | ~1.5 GB |
| wan2.2_high_noise_lora (Combo 2) | `--lightning 2` | ~0.5 GB |
| wan2.2_low_noise_lora (Combo 1 & 2) | `--lightning 1` ou `2` | ~0.5 GB |
| nsfw_wan_umt5-xxl_fp8_scaled | `--nsfw-clip` | ~5 GB |

## Structure des fichiers

```
/workspace/ComfyUI/
  |- main.py
  |- models/
  |   |- diffusion_models/     # Modeles High + Low GGUF
  |   |- text_encoders/        # UMT5-XXL (standard ou NSFW)
  |   |- vae/                  # Wan 2.1 VAE
  |   |- clip_vision/          # CLIP Vision H (pour I2V)
  |   |- loras/                # DR34ML4Y + SVI + Lightning LoRAs
  |- custom_nodes/
  |   |- ComfyUI-GGUF/
  |   |- ComfyUI-Manager/
  |   |- ComfyUI-VideoHelperSuite/
  |   |- ComfyUI-KJNodes/
  |- output/                   # Videos generees ici
```

## Settings recommandes

| Parametre | Valeur |
|-----------|--------|
| **Sampler** | Euler simple |
| **Steps** | 2+2 (High kSampler + Low kSampler) |
| **CFG** | 1 |
| **Lightning LoRAs** | NE PAS en ajouter (modele SVI "nolightning") |

> Pour de meilleurs resultats, Jellai recommande **2+3** steps (2 sur High, 3 sur Low).

## Workflow

Ce modele utilise un **Double kSampler** :

```
[Image/Prompt]
      |
[CLIPTextEncode] -> [WAN NAG (optionnel)]
      |
[kSampler HIGH] (steps=2, model=Q8H)
      |
[kSampler LOW]  (steps=2, model=Q8L)
      |
[VAEDecode] -> [VHS_VideoCombine]
```

### Workflows disponibles

| Workflow | Lien |
|----------|------|
| 2 kSampler SVI (recommande) | [civitai.com/models/2079192](https://civitai.com/models/2079192?modelVersionId=2668801) |
| v2.1 NSFW V2 | [civitai.com/models/2079192](https://civitai.com/models/2079192?modelVersionId=2562360) |
| Triple kSampler (plus de motion) | [civitai.com/models/1866565](https://civitai.com/models/1866565) |
| SVI native loop (Kijai) | [Wan.2.2.SVI.Pro.Loop.native.json](https://github.com/user-attachments/files/24364598/Wan.-.2.2.SVI.Pro.-.Loop.native.json) |

## Trigger words LoRA DR34ML4Y

| Mot-cle | Pose |
|---------|------|
| `m15510n4ry` | Missionary |
| `bl0wj0b` | Blowjob |
| `d0gg1e` | Doggy |
| `c0wg1rl` | Cowgirl |
| `d0ubl3_bj` | Double BJ |

> Ajuster le poids du LoRA selon les previews (0.3 a 1.0 selon la pose).

## SVI LoRAs (--svi)

SVI (Stable Video Infinity) permet de generer des **videos longues** avec de meilleures transitions.

**Avantages :** transitions fluides, coherence du personnage, moins de degradation
**Inconvenients :** moins de dynamisme, comprehension du prompt plus faible, risque de slow-motion

> Utiliser `--lightning 2` ou `--lightning 3` avec `--svi` pour corriger le slow-motion.

## Lightning LoRA Combos (optionnel)

| Combo | High LoRA | Poids | Low LoRA | Poids | Effet |
|-------|-----------|-------|----------|-------|-------|
| **1** | lightx2v_14B | 4 | low_noise | 1.4 | More Motion (degradation rapide) |
| **2** | high_noise | 1 | low_noise | 1 | Less Degradation (qualite) |
| **3** | lightx2v_14B | 3 | lightx2v_14B | 1.5 | Balanced (recommande) |

## Negative prompts

Activer les negative prompts (double le temps de generation) :

1. Ouvrir ComfyUI-Manager
2. Installer `kjnode`
3. Ajouter le node **WAN NAG** apres le LoRA Loader
4. Connecter au premier kSampler (High)

**Negative prompt recommande (anti-mouvement excessif) :**
```
motion artifacts, animation artifacts, movement blur, exaggerated butt movement,
jiggle, overanimated hips, unnatural butt motion, hyper bounce, extreme curves,
distorted hips, unnatural pose, unrealistic anatomy, deformed body, floating limbs,
blurry textures, clipping, stretching, artifacts, butt bounce, wobbling hips
```

## GPU recommande sur RunPod

| GPU | VRAM | Compatibilite |
|-----|------|---------------|
| **A100 80GB** | 80 GB | Optimale |
| **A100 40GB** | 40 GB | Tres bonne |
| **A6000** | 48 GB | Tres bonne |
| **RTX 4090** | 24 GB | Bonne |
| **RTX 3090** | 24 GB | Correcte |

## Relancer ComfyUI

```bash
cd /workspace/ComfyUI && python main.py --listen 0.0.0.0 --port 8188
```

## Depannage

| Probleme | Solution |
|----------|----------|
| `CIVITAI_TOKEN non defini` | Ajouter `CIVITAI_TOKEN=xxx` avant `bash install.sh` |
| Modele .gguf non detecte | Verifier que ComfyUI-GGUF est installe, utiliser `UnetLoaderGGUF` |
| Out of memory | Reduire les frames ou la resolution |
| Slow-motion | Ajouter `--lightning 2` ou `--lightning 3` |
| Negative prompts inactifs | CFG=1 par defaut, activer le node WAN NAG (KJNodes) |
| Download CivitAI echoue | Verifier le token : `echo $CIVITAI_TOKEN` |
| Port deja utilise | Changer le port dans le script (`LISTEN_PORT=8189`) |

## Licence

Ce script d'installation est fourni tel quel (Apache 2.0).
Les modeles WAN 2.2 sont soumis a leur licence respective sur CivitAI et HuggingFace.
