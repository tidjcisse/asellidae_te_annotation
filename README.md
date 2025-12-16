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

Ce pipeline nommé **Asellidae_TE_Annotation** automatise la détection *de-novo*, la curation et le masquage des TE, produisant une bibliothèque de consensus de qualité avec une curation-manuelle pour chaque assembly des Asellidae.

## Installation

- Requirements

> S'assurer d'avoir le conteneur **docker** installé.

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

> Installer RepeatModeler2

D'abord il faut créer un repertoir RepeatModeler2 et y rentrer avec les commandes.
```bash
mkdir -p RepeatModeler2
cd RepeatModeler2
```
## Utilisation

## Schéma du Pipeline

## Commandes
