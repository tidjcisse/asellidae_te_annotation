#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
WORKDIR="$ROOT_DIR/annotation"

mkdir -p $WORKDIR/assemblies "$WORKDIR/dfam" "$WORKDIR/pfam_db" "$WORKDIR/results"

# Check Docker
docker --version >/dev/null

# Dfam
if [[ ! -f "$WORKDIR/dfam/dfam39_full.0.h5" ]]; then
  echo "==> Téléchargement Dfam..."
  wget -O "$WORKDIR/dfam/dfam39_full.0.h5.gz" \
    https://www.dfam.org/releases/current/families/FamDB/dfam39_full.0.h5.gz
  gunzip "$WORKDIR/dfam/dfam39_full.0.h5.gz"
else
  echo "==> Dfam déjà présent."
fi

# Pfam
if [[ ! -f "$WORKDIR/pfam_db/Pfam-A.hmm" ]]; then
  echo "==> Téléchargement Pfam..."
  wget -O "$WORKDIR/pfam_db/Pfam-A.hmm.gz" \
    https://ftp.ebi.ac.uk/pub/databases/Pfam/current_release/Pfam-A.hmm.gz
  wget -O "$WORKDIR/pfam_db/Pfam-A.hmm.dat.gz" \
    https://ftp.ebi.ac.uk/pub/databases/Pfam/current_release/Pfam-A.hmm.dat.gz
  gunzip "$WORKDIR/pfam_db/Pfam-A.hmm.gz"
  gunzip "$WORKDIR/pfam_db/Pfam-A.hmm.dat.gz"
else
  echo "==> Pfam déjà présent."
fi

echo "✅ Setup terminé."
echo "➡️ Place ton génome FASTA dans: $WORKDIR/assemblies/"
echo "➡️ Puis lance: ./run_pipeline.sh"

