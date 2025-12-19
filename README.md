# 🧬 Asellidae_TE_Annotation Pipeline

## Contenus

1. [Introduction](#introduction)
2. [Mode automatisé](#mode automatisé)
3. [Mode manuelle](#mode manuel)
    - [Installation et configuration](#Installation et configuration)
    - [Exécution de RepeatModeler2 + TEtrimmer (Docker)](#)
    - [Outputs](#outputs)
4. [Schéma du Pipeline](#schéma-du-pipeline)

## Introduction

Dans le cadre de mon stage de M2 intitulé **"Influence du régime alimentaire sur l'évolution du répertoire de gènes de dégradation de la lignocellulose"** et dont l'un des objectifs est de caractériser le répertoire de gènes des Asellidae, je suis amené à concevoir un pipeline d'annotation des éléments transposables (TE) dans les génomes de ces organismes.

Ce pipeline nommé **Asellidae_TE_Annotation** automatise la détection *de-novo*, la curation et le masquage des TE, produisant une bibliothèque de consensus de qualité avec une curation-manuelle pour chaque assembly des Asellidae. Il inclut **RepeatModeler2, TEtrimmer** et **RepeatMasker**.

## Mode automatisé

```bash
git clone http://pedago-service.univ-lyon1.fr:2325/tfoussenisalamicisse/asellidae_te_annotation.git
cd Asellidae_TE_Annotation
chmod +x config.sh Asellidea_TE_annot.sh run_pipeline.sh
./config.sh
```
Après exécution de ces lignes de commandes vous obtenez la structure suivante.

### Structure du dépôt (après clonage)
```bash
.
├── .gitignore
├── .gitlab-ci.yml
├── README.md
├── annotation
│   ├── assemblies -----→ déposer ici les génomes FASTA
│   │   
│   │   
│   ├── dfam -----→ la base de données dfam pour RM2
│   │   └── dfam39_full.0.h5
│   ├── pfam_db -----→ la base de données pfam pour TEtrimmer
│   │   ├── Pfam-A.hmm
│   │   ├── Pfam-A.hmm.dat
│   │   ├── Pfam-A.hmm.h3f
│   │   ├── Pfam-A.hmm.h3i
│   │   ├── Pfam-A.hmm.h3m
│   │   └── Pfam-A.hmm.h3p
│   └── results ----→ résultats générés automatiquement
│       
│       
├── config.sh
├── Asellidea_TE_annot.sh ----→ logique interne (ne pas modifier)
└── run_pipeline.sh
```
Pour vérifier la structure, exécutez la ligne de commande

```bash
tree -a -I '.git|__pycache__' -L 3
```
Ensuite copiez les assemblages dans le sous dossier **annotation/assemblies** et lancez run_pipeline.
```bash
./run_pipeline
```

## Mode manuel (niveau minimum en bash)

### Installation et configuration

Cette section décrit l’installation des bases de données nécessaires au pipeline.
L’exécution complète du pipeline est décrite dans la section suivante.


- Requirements

> S'assurer d'avoir le conteneur **docker** installé sur votre machine.

```bash
docker --version
```

> Créer un dossier  nommé annotation et télécharger le génome test
```bash
mkdir -p annotation
cd annotation
```

> Installation de **dfam** dans le dossier précédamment crée: annotation

La base Dfam est utilisée par RepeatModeler2 et RepeatMasker pour la classification des éléments transposables.
**La base Dfam doit se trouver dans annotation/dfam/**

```bash
mkdir -p dfam
cd dfam
wget https://www.dfam.org/releases/current/families/FamDB/dfam39_full.0.h5.gz
gunzip dfam39_full.0.h5.gz
cd ..
```
> Installation de pfam dans le dossier précédamment crée: annotation

La base Pfam est requise par TEtrimmer pour l’identification des domaines protéiques et la détermination de l’orientation des éléments transposables.
**La base pfam doit se trouver dans annotation/pfam_db/**


```bash
mkdir -p pfam_db
cd pfam_db
wget https://ftp.ebi.ac.uk/pub/databases/Pfam/current_release/Pfam-A.hmm.gz
wget https://ftp.ebi.ac.uk/pub/databases/Pfam/current_release/Pfam-A.hmm.dat.gz
gunzip Pfam-A.hmm.gz
gunzip Pfam-A.hmm.dat.gz
cd ..
```

### Exécution de RepeatModeler2 + TEtrimmer (Docker)

Cette étape exécute successivement :

1. la construction de la base génomique (BuildDatabase)

2. la détection de novo des TE avec RepeatModeler2

3. la curation automatisée des consensus TE avec TEtrimmer

L’ensemble est exécuté via des conteneurs Docker afin de garantir la reproductibilité et d’éviter les conflits de dépendances.

> Copier-coller le script suivant dans un fichier **Asellidea_TE_annot.sh**

**Remarque importante sur les chemins !** :

> - `WORKDIR` doit être un chemin absolu  
> - `DFAM` et `PFAM_DIR` sont définis relativement au dossier `annotation`  
> - le fichier `ASSEMBLY` doit être présent dans `WORKDIR`


```bash
#!/bin/bash
set -euo pipefail

#======================= VARIABLES =======================

WORKDIR="/chemin/absolu/de/annotation"
DFAM="${WORKDIR}/dfam/"
ASSEMBLY="assembly.fasta"     # doit être dans $WORKDIR
DBNAME="CODE"
TE_LIB="$DBNAME-families.fa"
PFAM_DIR="${WORKDIR}/pfam_db/"
THREADS=32

DOCKER_USER="--user $(id -u):$(id -g)"

mkdir -p "$WORKDIR"
cd "$WORKDIR"

#======================= VERIFICATIONS =======================

[[ -f "$ASSEMBLY" ]] || { echo "Erreur : assembly introuvable : $WORKDIR/$ASSEMBLY"; exit 1; }
[[ -f "$DFAM/dfam39_full.0.h5" ]] || { echo "Erreur : Dfam introuvable : $DFAM/dfam39_full.0.h5"; exit 1; }

#======================= BUILDDATABASE =======================

docker run --rm \
  $DOCKER_USER \
  -v "$WORKDIR:/work" \
  -v "$DFAM:/dfam" \
  -w /work \
  dfam/tetools:latest \
  BuildDatabase -name "${DBNAME}" "/work/${ASSEMBLY}"

#======================= Step2: REPEATMODELER2 =======================

docker run --rm \
  $DOCKER_USER \
  -v "$WORKDIR:/work" \
  -v "$DFAM:/dfam" \
  -w /work \
  dfam/tetools:latest \
  RepeatModeler -database "${DBNAME}" -threads "${THREADS}" \
  &> "repeatmodeler_${DBNAME}.log"

#======================= Step3: TETRIMMER =======================

OUTDIR="$DBNAME-tetrimmer_out"
LOG="$DBNAME-tetrimmer.log"
IMG="quay.io/biocontainers/tetrimmer:1.5.4--hdfd78af_0"

# Checks
[[ -f "$TE_LIB" ]] || { echo "Erreur: TE lib introuvable: $TE_LIB"; exit 1; }
[[ -d "$PFAM_DIR" ]] || { echo "Erreur: pfam_dir introuvable: $PFAM_DIR"; exit 1; }

mkdir -p "$OUTDIR"

docker run --rm \
  $DOCKER_USER \
  -e MPLCONFIGDIR=/tmp \
  -e XDG_CACHE_HOME=/tmp \
  -v "$PWD:/data" \
  -w /data \
  "$IMG" \
  TEtrimmer \
    --input_file "/data/${TE_LIB}" \
    --genome_file "/data/${ASSEMBLY}" \
    --output_dir "/data/${OUTDIR}" \
    --pfam_dir "/data/${PFAM_DIR}" \
    --num_threads "${THREADS}" \
    --classify_all \
    --hmm \
    --genome_anno \
  &> "$LOG"


# Optionnel mais pratique: rendre les sorties manipulables sans sudo
sudo chown -R "$(id -u):$(id -g)" "$OUTDIR" || true

echo "TEtrimmer terminé. Log: $LOG"
echo "Pipeline terminé pour ${DBNAME}."
echo "Bibliothèque TE finale : ${OUTDIR}/TEtrimmer_consensus_merged.fasta"

```


Rendre exécutable et lancer le script

```bash
chmod +x Asellidea_TE_annot.sh
./Asellidea_TE_annot.sh
```
### Outputs

Le pipeline génère les sorties principales suivantes :

#### RepeatModeler2
  - `${DBNAME}-families.fa` : bibliothèque de consensus TE *de novo*
  - `${DBNAME}-families.stk` : alignements multiples associés
  - `repeatmodeler_${DBNAME}.log` : log d’exécution

#### TEtrimmer
  - `${OUTDIR}/TEtrimmer_consensus.fasta` : consensus TE avant dé-duplication
    Le fichier principal à utiliser pour l’annotation du génome est
  - `${OUTDIR}/TEtrimmer_consensus_merged.fasta` : **bibliothèque finale curée**
  - `${OUTDIR}/summary.txt` : résumé de la curation
  - `${OUTDIR}/HMM_files/` : profils HMM (option `--hmm`)
  - `${OUTDIR}/RepeatMasker_result/` : annotation du génome par RepeatMasker via TEtrimmer (option `--genome_anno`)
  - `${OUTDIR}/TEtrimmer_for_proof_curation/` : figures PDF pour validation manuelle


## Schéma du Pipeline

      Assemblies (fasta)
                  │
                  ▼
      RepeatModeler2 (de novo TE discovery)
                  │
                  ▼
      TEtrimmer (curation + classification)
                  │
                  ▼
      RepeatMasker (annotation génomique)


