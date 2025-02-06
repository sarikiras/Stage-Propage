# Stage-Propage

La plupart des codes du Stage. 

**_Avertissement_** : Ces codes n'étaient pas destinés à être publiés. Les fichers *.Rmd sont plus ou moins structurés (cf l'outline),
mais il arrive qu'à l'intérieur d'une partie, ça parte dans tous les sens, car il s'agit de mon travail de réflexion.

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

**Fichier liés** : Prairies_corrigees.Rmd

Tests statistiques : influence des variables des gestion sur les données de 15 ans.
On a enlevé tous les relevés sans observation.
Premiers modèles (mais il y aura d'autres fichiers plus complets avec tous les modèles)

#### 3. Prairies_modeles.Rmd

**Fichier liés** : Prairies_corrigees.Rmd

Plein de tests de modèles sur la densité avec et sans effets aléatoires.

#### 4. Prairies_modeles_effaleasp.Rmd

**Fichier liés** : Prairies_modèles.Rmd

Modèles sur la log-densité en rajoutant l'effet aléatoire espèce.

**Attention** : on ne travaille pas sur la même table que dans le fichier précédent! Il faut une table longue.

#### 5. Prairies_modeles_richesse.Rmd

Fichier autonome car télécharge des dataframes qui sont enregistrées dans le fichier table :)

Plein d'essais de modèles sur la richesse : utilisation de lois discrètes (Poisson, negative binomial)

#### 5. Prairies_modeles_Shannon.Rmd

Fichier autonome car télécharge des dataframes qui sont enregistrées dans le fichier table :)

Plein d'essais de modèles sur l'indice de Shannon : utilisation de lois continues (et bizarre comme Hurdle) 

## III. Dossier propage_pays

[Indépendant de **TOUT** ce qui a été fait précédemment !]

Ici les codes et fichiers qui traitent des données paysagères. 

#### 1. Tables utiles
+ `coord_propage.csv` : Table contenant les coordonnées moyennes de chaque transect.
+ Dossier **Corine** : Fichiers de la base de donnée Corine land cover de 2018 (à compléter car il manque les plus gros -et accessoirement les plus importants ah ah - que je n'ai pas pu mettre sur le gitHub car trop volumineux ie `824_sdes_occupation_clc_metropole_2018.dbf`et `
824_sdes_occupation_clc_metropole_2018.shp`)
+ `RE_classement_CLC.xlsx` : Table de redéfinition des niveaux CLC en milieux plus "cohérents" pour une étude de communautés de papillons. 
  
#### 2. Code `extractclc_propage.R`
THE code qui permet d'extraire l'occupation du sol autour de chaque transect (de son point moyen).
  - Dans les tables nommées `buffer_XXXX_complete.csv`, on a les *surfaces* représentées par chaque type de paysage du *niveau 3* de la nomenclature CLC.
  - Dans les tables nommées `buffer_XXX_CLC_grossier.csv`, on a les *surfaces* représentées par les 5 types de paysage du *niveau 1* de la nomenclature CLC.
  - Dans les tables nommées `paysage_XXXX.csv`, on a les *pourcentage d'occupation* représentées par chaque type de paysage du *niveau 3* de la nomenclature CLC.

**Rem** : Ce magnique code n'est pas de moi, il m'a été tranmis par Maud Weber, qui elle-même l'a hérité de Victor Quilichini. Certaines lignes du codes peuvent être assez longues à exécuter donc pas de panique.

#### 3. Fichier 'ACP_paysage.Rmd'

THE fichier qui permet de récupérer les variables paysagères que l'on va intégrer dans les modèles.
+ On construit des nouvelles tables de pourcentage d'occupation du sol selon les 8 milieux définis dans `RE_classement_CLC.xlsx`
+ On fait ensuite des ACP pour retenir les 2 axes principaux, variables qui représentant au mieux le paysage. 

Les deux fichiers suivants :
- 'ACP_paysage_prai.Rmd'
- 'ACP_paysage_pel.Rmd'
sont des clones du précédent. Mais en ne sélectionnant que les données du milieu concerné (prairie ou pelouse).
