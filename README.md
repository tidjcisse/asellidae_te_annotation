# 🧬 Asellidae_TE_Annotation Pipeline

## Contenus

1. [Introduction](README.md#Introduction)
2. [Installation](README.md#Installation)
3. [Usage](README.md#Usage)    
    - [Inputs](README.md#Inputs)  
    - [Outputs](README.md#Outputs)  
4.  [Pipeline Overview](README.md#Pipeline-Overview) 
5.  [All Commands](README.md#All-Commands)  
6. [Update History](README.md#Update-History)


## Introduction

Dans le cadre de mon stage de M2 intitulé **"Influence du régime alimentaire sur l'évolution du répertoire de gènes de dégradation de la lignocellulose"** et dont l'un des objectifs est de caractériser le répertoire de gènes des Asellidae, je suis amené à concevoir un pipeline d'annotation des éléments transposables (TE) dans les génomes de ces organismes.

Ce pipeline nommé **Asellidae_TE_Annotation** automatise la détection *de-novo*, la curation et le masquage des TE, produisant une bibliothèque de consensus de qualité avec une curation-manuelle pour chaque assembly des Asellidae. Il inclut **RepeatModeler2, TEtrimmer** et **RepeatMasker**.

## exécution de RepeatModeler2 (Docker)

- Requirements

> S'assurer d'avoir le conteneur **docker** installé sur votre machine.

```bash
docker --version
```

> Télécharger dfam

```bash
mkdir -p dfam
wget https://www.dfam.org/releases/current/families/FamDB/dfam39_full.0.h5.gz
cd dfam
gunzip dfam39_full.0.h5.gz
cd ..
```

> Préparer l’environnement RepeatModeler2 (Docker)

Le pipeline utilise l’image Docker dfam/tetools, qui inclut RepeatModeler2, RepeatMasker et toutes leurs dépendances.

Copier-coller le script suivant dans un fichier **script_repeatModeler2.sh**

```bash
#!/bin/bash
set -euo pipefail

DFAM="/chemin/absolu/de/dfam"
WORKDIR="/chemin/absolu/de/RepeatModeler2"
ASSEMBLY="assembly.fasta"     # doit être dans $WORKDIR
DBNAME="CODE"
THREADS=32

DOCKER_USER="--user $(id -u):$(id -g)"

mkdir -p "$WORKDIR"
cd "$WORKDIR"

# Vérifications
[[ -f "$ASSEMBLY" ]] || { echo "Erreur : assembly introuvable : $WORKDIR/$ASSEMBLY"; exit 1; }
[[ -f "$DFAM/dfam39_full.0.h5" ]] || { echo "Erreur : Dfam introuvable : $DFAM/dfam39_full.0.h5"; exit 1; }

# BuildDatabase
docker run --rm \
  $DOCKER_USER \
  -v "$WORKDIR:/work" \
  -v "$DFAM:/dfam" \
  -w /work \
  dfam/tetools:latest \
  BuildDatabase -name "${DBNAME}" "/work/${ASSEMBLY}"

# RepeatModeler
docker run --rm \
  $DOCKER_USER \
  -v "$WORKDIR:/work" \
  -v "$DFAM:/dfam" \
  -w /work \
  dfam/tetools:latest \
  RepeatModeler -database "${DBNAME}" -threads "${THREADS}" \
  &> "repeatmodeler_${DBNAME}.log"

```
Pensez à bien utiliser les chemins absolus correspondants

> DFAM="/chemin/absolu/de/dfam"
WORKDIR="/chemin/absolu/de/RepeatModeler2"
ASSEMBLY="assembly.fasta"

Rendre exécutable et lancer le script

```bash
chmod +x script_repeatModeler2.sh
./script_repeatModeler2.sh
```

## Utilisation

## Schéma du Pipeline

## Commandes
