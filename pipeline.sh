#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
WORKDIR="$ROOT_DIR/annotation"
DFAM="$WORKDIR/dfam"
PFAM_DIR="$WORKDIR/pfam_db"
ASSEMBLIES_DIR="$WORKDIR/assemblies"
RESULTS_DIR="$WORKDIR/results"

# Inputs (avec valeurs par défaut)
ASSEMBLY="${ASSEMBLY:-test_assembly.fasta}"
DBNAME="${DBNAME:-CODE}"
THREADS="${THREADS:-32}"

ASSEMBLY_PATH="$ASSEMBLIES_DIR/$ASSEMBLY"
TE_LIB="$RESULTS_DIR/$DBNAME/$DBNAME-families.fa"

DOCKER_USER="--user $(id -u):$(id -g)"

mkdir -p "$RESULTS_DIR/$DBNAME"
cd "$RESULTS_DIR/$DBNAME"

# Vérifications
[[ -f "$ASSEMBLY_PATH" ]] || { echo "Erreur: assembly introuvable: $ASSEMBLY_PATH"; exit 1; }
[[ -f "$DFAM/dfam39_full.0.h5" ]] || { echo "Erreur: Dfam introuvable: $DFAM/dfam39_full.0.h5"; exit 1; }
[[ -f "$PFAM_DIR/Pfam-A.hmm" ]] || { echo "Erreur: Pfam introuvable: $PFAM_DIR/Pfam-A.hmm"; exit 1; }
[[ -f "$PFAM_DIR/Pfam-A.hmm.dat" ]] || { echo "Erreur: Pfam dat introuvable: $PFAM_DIR/Pfam-A.hmm.dat"; exit 1; }

# BuildDatabase
docker run --rm \
  $DOCKER_USER \
  -v "$RESULTS_DIR/$DBNAME:/work" \
  -v "$ASSEMBLIES_DIR:/assemblies:ro" \
  -v "$DFAM:/dfam:ro" \
  -w /work \
  dfam/tetools:latest \
  BuildDatabase -name "${DBNAME}" "/assemblies/${ASSEMBLY}"

# RepeatModeler2
docker run --rm \
  $DOCKER_USER \
  -v "$RESULTS_DIR/$DBNAME:/work" \
  -v "$ASSEMBLIES_DIR:/assemblies:ro" \
  -v "$DFAM:/dfam:ro" \
  -w /work \
  dfam/tetools:latest \
  RepeatModeler -database "${DBNAME}" -threads "${THREADS}" \
  &> "repeatmodeler_${DBNAME}.log"

# TEtrimmer
OUTDIR="${DBNAME}-tetrimmer_out"
LOG="${DBNAME}-tetrimmer.log"
IMG="quay.io/biocontainers/tetrimmer:1.5.4--hdfd78af_0"

[[ -f "$TE_LIB" ]] || { echo "Erreur: TE lib introuvable (RepeatModeler n'a pas produit $TE_LIB)"; exit 1; }
mkdir -p "$OUTDIR"

docker run --rm \
  $DOCKER_USER \
  -e MPLCONFIGDIR=/tmp \
  -e XDG_CACHE_HOME=/tmp \
  -v "$RESULTS_DIR/$DBNAME:/data" \
  -v "$ASSEMBLIES_DIR:/assemblies:ro" \
  -v "$PFAM_DIR:/pfam:ro" \
  -w /data \
  "$IMG" \
  TEtrimmer \
    --input_file "/data/${DBNAME}-families.fa" \
    --genome_file "/assemblies/${ASSEMBLY}" \
    --output_dir "/data/${OUTDIR}" \
    --pfam_dir "/pfam" \
    --num_threads "${THREADS}" \
    --classify_all \
    --hmm \
    --genome_anno \
  &> "$LOG"

echo "✅ Pipeline terminé."
echo "Résultats: $RESULTS_DIR/$DBNAME"
echo "Bibliothèque finale: $RESULTS_DIR/$DBNAME/$OUTDIR/TEtrimmer_consensus_merged.fasta"
