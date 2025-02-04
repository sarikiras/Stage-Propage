# Stage-Propage

La plupart des codes du Stage. En bazar...

Les donnnées se trouvent dans `all_data_propage20240201.xlsx` (fichier all_data_propage20240201.xlsx.zip à dézipper).

## I. Fichiers à exécuter en premier

#### 1. data_clean.Rmd

+ Création d'une table `data` qui sert de base pour tout le stage : simplification des noms des habitats, ajouts de colonnes (id_transect, jour_julien...)
+ Fonctions de filtration des dates
+ Fonctions de géographie
+ Tables et listes pouvant être utiles

#### 2. EDA.Rmd

**Fichier liés** : data_clean.Rmd

Premières exporations sur les sessions, le habitats, les transects ...

#### 3. EDA_ind_taxo.Rmd

**Fichier liés** : data_clean.Rmd

Premières explorations des données biologiques. 
Premiers calculs des indices de diversité taxonomique (sur la base des abondances).


#### 4. indic_taxo_env.Rmd

**Fichier liés** : data_clean.Rmd

Premières explorations des données environnementales, répérage de quelques anomalies.
Création de tables environnementales : ajout des durées d'observation, mois ...

## II. PRAIRIES

On utilise systématiquement des fichiers de la partie I.

#### 1. Prairies_corrigees.Rmd

[FICHIER SUPER RICHE]

**Fichier liés** : data_clean.Rmd, EDA_ind_taxo.Rmd, indic_taxo_env.Rmd

C'est ici que j'effectue toutes les transformation utiles pour le Stage:
+ Filtre des données à ± 15 jours, des transects pour lesquels on a 3 relevés complets, des bonnes durées etc.
+ Transformations en tables spatiales : ajout de la longueur de transect pour calculer les densités
+ Tables des densités, calculs des indices de diversité taxonomique à partir de cette table.
  *Remarque : les indices sont calculés en prenant en compte tous les taxons de la liste dans un premier temps, puis en  ne prenant en compte que les espèces dans un deuxième temps.*

#### 2. Prairies_15ans_corr_sans0.Rmd

**Fichier liés** : data_clean.Rmd, EDA_ind_taxo.Rmd, indic_taxo_env.Rmd

Tests statistiques : influence des variables des gestion sur les données de 15 ans.
On a enlevé tous les relevés sans observation.
Premiers modèles (mais il y aura d'autres fichiers plus complets avec tous les modèles)

