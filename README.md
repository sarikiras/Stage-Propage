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

