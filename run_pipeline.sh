#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
WORKDIR="$ROOT_DIR/annotation"
ASSEMBLIES_DIR="$WORKDIR/assemblies"

if [[ ! -d "$ASSEMBLIES_DIR" ]]; then
  echo "Erreur: dossier assemblies introuvable. Lance d'abord: ./setup.sh"
  exit 1
fi

echo "Assemblies disponibles dans $ASSEMBLIES_DIR :"
ls -1 "$ASSEMBLIES_DIR" || true
echo

read -rp "Nom du fichier FASTA à utiliser (défaut: test_assembly.fasta): " ASSEMBLY
ASSEMBLY="${ASSEMBLY:-test_assembly.fasta}"

read -rp "Nom du projet (DBNAME) (défaut: CODE): " DBNAME
DBNAME="${DBNAME:-CODE}"

read -rp "Threads (défaut: 32): " THREADS
THREADS="${THREADS:-32}"

export ASSEMBLY DBNAME THREADS
bash "$ROOT_DIR/pipeline.sh"

