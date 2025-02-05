# Le but de ce fichier est d'extraire les données paysagères autour de chaque transect

# On veut constituer 3 échelles de données paysagères:
# - un disque de rayon 1000 m autour du transect
# - un buffer de rayon compris entre 1000m et 5000m
# - un buffer de rayon compris entre 5000m et 10000m#

library(sf)
library(leaflet)
library(tidyverse)

setwd("/Users/sariakasalomon-ramialison/Desktop/PropageGH")

#--------TABLE -------------------------------------


# Table initialement prévue pour Maud avec les années
che_table <- "propage_pays/coord_propage.csv"
points_transects <- read.csv(che_table, header=TRUE, sep=",")
points_transects
# nrow(points_transects)
# 5374 : points 

# Retrait des années pour n'avoir que les transects
points_transects <- points_transects |>
  select(-annee) |>
  unique()
# 1814 points de transects, mais parfois les mêmes 

# Récupération des transects uniques 
points_transects <- points_transects |>
  filter(!duplicated(id_transect))
nrow(points_transects)

# 1754 points au total



# ------ TRANSFORMATION EN OBJET SF --------------

# Transformation des colonnes `long` et `lat` de la table 
points_transects <- points_transects |>
  st_as_sf(coords = c("long", "lat"), crs = 4326)


# ------ CREATION DU BUFFER 1000m --------------

coord_BF_1000 <- st_buffer(points_transects, dist = 1000)

# Plot des buffers
# ggplot() +
#   geom_sf(data = coord_BF_1000) +
#   theme_minimal()


#------ IMPORTATION DE LA COUCHE CLC  ------------

# On importe les données CLC :
che_corine_2180 <- "propage_pays/Corine/824_sdes_occupation_clc_metropole_2018.shp"
CLC_2018_France <- st_read(che_corine_2180)
st_crs(CLC_2018_France)

# on met le fichier dans le même crs que nos coord 

CLC_2018_France_wgs84 <- st_transform(CLC_2018_France, crs = st_crs(4326))

rm(CLC_2018_France)
st_crs(CLC_2018_France_wgs84)

CLC_2018_France_wgs84_sf <- st_as_sf(CLC_2018_France_wgs84, wkt = "the_geom")


#------ INTERSECTION DE CLC ET DES BUFFERS CREES AUTOURS DES TRANSECTS ------------



#on extrait ensuite du CLC les parcelles chevauchants les zones buffers de tous les points_transects :
#on garde seulement les parcelles qui chevauchent les points_transects

PARCELLES_chevauchantes <- st_intersects(coord_BF_1000, CLC_2018_France_wgs84_sf)



#------ CREATION DE LA TABLE LONGUE ID_TRANSECT, ID_PARCELLE CHEVAUCHANT, DONNEES CLC DE LA PARCELLE -------------------


# Créez un dataframe vide pour stocker les résultats
result_df_CLC <- data.frame(id_transect = character(),ID = character(), stringsAsFactors = FALSE)

# Parcourez chaque ligne de PARCELLES_chevauchantes

for (i in 1:length(PARCELLES_chevauchantes)) {
  # Obtenez l'id_transect du transect correspondant
  id_transect <- coord_BF_1000$id_transect[i]
  # Obtenez les indices des polygones intersectés dans PARCELLES_chevauchantes
  intersected_indices <- PARCELLES_chevauchantes[[i]]
  # Si la liste n'est pas vide, ajoutez les informations au dataframe résultant
  if (length(intersected_indices) > 0) {
    temp_df <- data.frame(id_transect = rep(id_transect, length(intersected_indices)),
                          ID = CLC_2018_France_wgs84_sf$ID[intersected_indices],
                          stringsAsFactors = FALSE)
    #result_df_CLC <- bind_rows(result_df_CLC, temp_df)
    result_df_CLC <- rbind(result_df_CLC, temp_df)
  }
}

# Affichez le dataframe résultant
View(result_df_CLC)

# result_df_CLC_FULL <- merge(result_df_CLC, CLC_2018_France_wgs84_sf, by = "ID", all.x = TRUE)
# str(result_df_CLC_FULL)

result_df_CLC_FULL <- result_df_CLC |>
  inner_join(CLC_2018_France_wgs84_sf, by = "ID")

result_df_CLC_FULL_sf <- st_as_sf(result_df_CLC_FULL, crs = st_crs(4326))
st_crs(result_df_CLC_FULL_sf)
View(result_df_CLC_FULL_sf)


#------ CALCUL DES SURFACES DE PARCELLE INTERSECTANT CHAQUE BUFFER -----------------------------------


# Fonction pour effectuer l'intersection (calcul des surfaces) pour un Id point donné !!
# Argument : id_transect
# Retour : une mini-dataframe avec id_transect, donnees CLC & surface parcelle correspondantes
intersect_code_point <- function(id_transect) {
  # Selection des lignes de `result_df_CLC_FULL_sf` pour le transect sélectionné (parcelles)
  subset_df <- result_df_CLC_FULL_sf[result_df_CLC_FULL_sf$id_transect == id_transect, ]
  # Selection de la ligne de `coord_BF_1000` pour le transect sélectionné (buffer)
  subset_buffer <- coord_BF_1000[coord_BF_1000$id_transect == id_transect, ]
  intersection <- st_intersection(subset_df, subset_buffer)
  intersection$overlap_area <- st_area(intersection)
  return(intersection)
}

# Test pour un transect
View(intersect_code_point("1121_Parc de l'abbaye"))
test <- intersect_code_point("1121_Parc de l'abbaye")

ggplot() +
  geom_sf(data = test,
          col = 'blue') +
  theme_minimal()

# Appliquer la fonction pour chaque id_transect unique
unique_code_points <- unique(result_df_CLC_FULL_sf$id_transect)

# # J'ajoute une fonction  pour afficher un message pour chaque point dont le buffer est caractérisé
# # afficher_message_point <- function(id_transect) {
# #   message(paste("Traitement du point", id_transect))
# # }

# Utiliser lapply pour caractériser les buffers point par point par seulement les parcelles qui chevauchent ce point
intersection_list_CLC_allFRANCE <- lapply(unique_code_points, function(id_transect, vec = unique_code_points) {
  # afficher_message_point(id_transect)
  print(paste0(which(id_transect == vec), "/", length(vec)))
  intersect_code_point(id_transect)
})


library(future)
library(future.apply)
library(progress)
library(sf)
library(tidyr)
#library(plyr)

# Fonction pour convertir chaque élément de la liste en dataframe
convert_to_dataframe <- function(x) {
  as.data.frame(x)
}

# Appliquer la conversion en parallèle
buffercaractCLC_df_temporaire <- future_lapply(intersection_list_CLC_allFRANCE, convert_to_dataframe)
# Concaténer les résultats avec ldply
buffercaractCLC_df_temporaire2 <- ldply(buffercaractCLC_df_temporaire)

# Assurez-vous que le résultat est un dataframe
buffercaractCLC_df <- as.data.frame(buffercaractCLC_df_temporaire2) |>
  unique()
# on enlève les colonnes doublon
buffercaractCLC_df <- buffercaractCLC_df %>%
  select(-ends_with(".1"))
View(buffercaractCLC_df)

# On supprime les df temporaires
rm(buffercaractCLC_df_temporaire)
rm(buffercaractCLC_df_temporaire2)

# On a ainsi `buffercaractCLC_df` qui est une table longue des id_transects 
# avec les données CLC des parcelles intersectant chaque transect
# avec la surface de chaque transect


# ------ AGREGATION DES SURFACES DE PARCELLES IDENTIQUES SUR UN BUFFER ----------------------

result <- aggregate(overlap_area ~ id_transect + CODE_18, buffercaractCLC_df, sum, na.rm = TRUE)
#View(result)

buffercaract_CLC_allFRANCE <- result %>%
  pivot_wider(names_from = CODE_18, values_from = overlap_area)
#View(buffercaract_CLC_allFRANCE)

buffercaract_CLC_allFRANCE2 <- buffercaract_CLC_allFRANCE

buffercaract_CLC_allFRANCE2 <- mutate_all(buffercaract_CLC_allFRANCE2, ~replace(., is.na(.), 0))
View(buffercaract_CLC_allFRANCE2 %>%
       mutate(total = rowSums(buffercaract_CLC_allFRANCE2[,-1])))



write.table(x = buffercaract_CLC_allFRANCE2, file = 'propage_pays/buffer_1000_complete.csv', sep = ';', row.names = FALSE)


# ------ AGREGATION DES SURFACES PAR "GRAND TYPE DE PAYSAGE" -----------------------------

# Sélectionner uniquement les colonnes X1 à X5
#voici les préfixes des colonnes à agréger
IdCLCout <- buffercaract_CLC_allFRANCE2%>%
  mutate(
    X1 = rowSums(select(., starts_with("1"))),
    X2 = rowSums(select(., starts_with("2"))),
    X3 = rowSums(select(., starts_with("3"))),
    X4 = rowSums(select(., starts_with("4"))),
    X5 = rowSums(select(., starts_with("5")))
  )

IdCLCout <- IdCLCout[,c(1,36:40)] 


# Renommer les colonnes en numero habitat directement
# Renommer les colonnes X1 à X5 en utilisant les chiffres correspondants
IdCLCout <- IdCLCout %>%
  rename_with(~ gsub("X", "", .), starts_with("X"))
View(IdCLCout %>%
       mutate(total = rowSums(IdCLCout[,2:6])))


write.table(x = IdCLCout, file = 'propage_pays/buffer_1000_CLC_grossier.csv', sep = ';', row.names = FALSE)


# ----- TABLE DE POURCENTAGE DE PAYSAGES

paysage_1000 <- IdCLCout |>
  mutate(total = rowSums(IdCLCout[,2:6])) |>
  mutate_at(vars(2:6), ~./total*100) |>
  select(-total)
write.table(x = IdCLCout, file = 'propage_pays/paysage_1000.csv', sep = ';', row.names = FALSE)



##############################################################
#------ ETUDE SIMILAIRE POUR 2ND BUFFER - DISQUE 1-5 --------#
##############################################################


# ------ CREATION DU BUFFER 1000m - 5000m --------------


# Rappel `coord_BF_1000` couche du buffer à 1000 m
# On va créer `coord_BF_1000` qui est l'anneau entre 100Om et 5000m

disc_BF_5000 <- st_buffer(points_transects, dist = 5000)


### BOUCLE 

coord_BF_5000 <- data.frame()

for (i in 1:nrow(coord_BF_1000)) {
  a <- coord_BF_1000[i,]
  b <- disc_BF_5000[i,]
  coord_BF_5000 <- rbind(coord_BF_5000, st_difference(b, a))
  print(paste0(i, "/", nrow(coord_BF_1000)))
}

# Plot des [5 premiers ]buffers
ggplot() +
  geom_sf(data = coord_BF_5000[1:2,],
          col = 'blue') +
  theme_minimal()


#------ INTERSECTION DE CLC ET DES BUFFERS CREES AUTOURS DES TRANSECTS ------------


#on extrait ensuite du CLC les parcelles chevauchants les zones buffers de tous les points_transects :
#on garde seulement les parcelles qui chevauchent les points_transects

PARCELLES_chevauchantes_5000 <- st_intersects(coord_BF_5000, CLC_2018_France_wgs84_sf)



#------ CREATION DE LA TABLE LONGUE ID_TRANSECT, ID_PARCELLE CHEVAUCHANT, DONNEES CLC DE LA PARCELLE -------------------


# Créez un dataframe vide pour stocker les résultats
result_df_CLC_5000 <- data.frame(id_transect = character(),ID = character(), stringsAsFactors = FALSE)

# Parcourez chaque ligne de PARCELLES_chevauchantes_5000

for (i in 1:length(PARCELLES_chevauchantes_5000)) {
  # Obtenez l'id_transect du transect correspondant
  id_transect <- coord_BF_1000$id_transect[i]
  # Obtenez les indices des polygones intersectés dans PARCELLES_chevauchantes_5000
  intersected_indices <- PARCELLES_chevauchantes_5000[[i]]
  # Si la liste n'est pas vide, ajoutez les informations au dataframe résultant
  if (length(intersected_indices) > 0) {
    temp_df <- data.frame(id_transect = rep(id_transect, length(intersected_indices)),
                          ID = CLC_2018_France_wgs84_sf$ID[intersected_indices],
                          stringsAsFactors = FALSE)
    #result_df_CLC_5000 <- bind_rows(result_df_CLC_5000, temp_df)
    result_df_CLC_5000 <- rbind(result_df_CLC_5000, temp_df)
  }
}

# Affichez le dataframe résultant
View(result_df_CLC_5000)

# result_df_CLC_5000_FULL <- merge(result_df_CLC_5000, CLC_2018_France_wgs84_sf, by = "ID", all.x = TRUE)
# str(result_df_CLC_5000_FULL)

result_df_CLC_5000_FULL <- result_df_CLC_5000 |>
  inner_join(CLC_2018_France_wgs84_sf, by = "ID")

result_df_CLC_5000_FULL_sf <- st_as_sf(result_df_CLC_5000_FULL, crs = st_crs(4326))
st_crs(result_df_CLC_5000_FULL_sf)



#------ CALCUL DES SURFACES DE PARCELLE INTERSECTANT CHAQUE BUFFER -----------------------------------


# Fonction pour effectuer l'intersection (calcul des surfaces) pour un Id point donné !!
# Argument : id_transect
# Retour : une mini-dataframe avec id_transect, donnees CLC & surface parcelle correspondantes
intersect_code_point_5K <- function(id_transect) {
  # Selection des lignes de `result_df_CLC_5000_FULL_sf` pour le transect sélectionné (parcelles)
  subset_df <- result_df_CLC_5000_FULL_sf[result_df_CLC_5000_FULL_sf$id_transect == id_transect, ]
  # Selection de la ligne de `coord_BF_5000` pour le transect sélectionné (buffer)
  subset_buffer <- coord_BF_5000[coord_BF_5000$id_transect == id_transect, ]
  intersection <- st_intersection(subset_df, subset_buffer)
  intersection$overlap_area <- st_area(intersection)
  return(intersection)
}


# Test de l'intersection sur un transect
test2 <- intersect_code_point_5K("1121_Parc de l'abbaye")
View(test2)


plot1 <- ggplot() +
  geom_sf(data = test2,
          col = 'blue') +
  theme_minimal()
plot1

sum(st_area(test2))

# Vérification car somme bizarre
# On fait l'intersection sur le disque de 5000 
# Y a t il une différence avec l'anneau?

intersect_code_point_5K_d <- function(id_transect) {
  # Selection des lignes de `result_df_CLC_5000_FULL_sf` pour le transect sélectionné (parcelles)
  subset_df <- result_df_CLC_5000_FULL_sf[result_df_CLC_5000_FULL_sf$id_transect == id_transect, ]
  # Selection de la ligne de `coord_BF_5000` pour le transect sélectionné (buffer)
  subset_buffer <- disc_BF_5000[disc_BF_5000$id_transect == id_transect, ]
  intersection <- st_intersection(subset_df, subset_buffer)
  intersection$overlap_area <- st_area(intersection)
  return(intersection)
}


test2d <- intersect_code_point_5K_d("1121_Parc de l'abbaye")
View(test2d)

plot2 <- ggplot() +
  geom_sf(data = test2d,
          col = 'blue') +
  theme_minimal()
plot2
sum(st_area(test2d))

library(gridExtra)
grid.arrange(plot1, plot2, ncol=2)

# Comparaison des 2 sommes

sum(st_area(test2d)) - sum(st_area(test2))
# Tout est ok!!


# Appliquer la fonction pour chaque id_transect unique
unique_code_points <- unique(result_df_CLC_5000_FULL_sf$id_transect)

# # J'ajoute une fonction  pour afficher un message pour chaque point dont le buffer est caractérisé
# # afficher_message_point <- function(id_transect) {
# #   message(paste("Traitement du point", id_transect))
# # }

# Utiliser lapply pour caractériser les buffers point par point par seulement les parcelles qui chevauchent ce point
intersection_list_CLC_5000_allFRANCE <- lapply(unique_code_points, function(id_transect, vec = unique_code_points) {
  # afficher_message_point(id_transect)
  print(paste0(which(id_transect == vec), "/", length(vec)))
  intersect_code_point_5K(id_transect)
})

#----- CALCUL DES SURFACES CORRESPONDANTES


# Appliquer la conversion en parallèle
buffercaractCLC_df_temporaire <- future_lapply(intersection_list_CLC_5000_allFRANCE, convert_to_dataframe)
# Concaténer les résultats avec ldply
buffercaractCLC_df_temporaire2 <- ldply(buffercaractCLC_df_temporaire)

# Assurez-vous que le résultat est un dataframe
buffercaractCLC_df_5000 <- as.data.frame(buffercaractCLC_df_temporaire2) |>
  unique()
head(buffercaractCLC_df_5000, 20)
# on enlève les colonnes doublon
buffercaractCLC_df_5000 <- buffercaractCLC_df_5000 %>%
  select(-ends_with(".1"))
View(head(buffercaractCLC_df_5000))

# On supprime les df temporaires
rm(buffercaractCLC_df_temporaire)
rm(buffercaractCLC_df_temporaire2)

# On a ainsi `buffercaractCLC_df_5000` qui est une table longue des id_transects 
# avec les données CLC des parcelles intersectant chaque transect
# avec la surface de chaque transect


# ------ AGREGATION DES SURFACES DE PARCELLES IDENTIQUES SUR UN BUFFER ----------------------

result_5K <- aggregate(overlap_area ~ id_transect + CODE_18, buffercaractCLC_df_5000, sum, na.rm = TRUE)
#View(result)

buffercaract_CLC_allFRANCE_5000 <- result_5K %>%
  pivot_wider(names_from = CODE_18, values_from = overlap_area)
#View(buffercaract_CLC_allFRANCE)

buffercaract_CLC_allFRANCE_5000_2 <- buffercaract_CLC_allFRANCE_5000

buffercaract_CLC_allFRANCE_5000_2 <- mutate_all(buffercaract_CLC_allFRANCE_5000_2, ~replace(., is.na(.), 0))
View(buffercaract_CLC_allFRANCE_5000_2)

write.table(x = buffercaract_CLC_allFRANCE_5000_2, file = 'propage_pays/buffer_5000_complete.csv', sep = ';', row.names = FALSE)


# ------ AGREGATION DES SURFACES PAR "GRAND TYPE DE PAYSAGE" -----------------------------

# Sélectionner uniquement les colonnes X1 à X5
#voici les préfixes des colonnes à agréger
IdCLCout_5000 <- buffercaract_CLC_allFRANCE_5000_2%>%
  mutate(
    X1 = rowSums(select(., starts_with("1"))),
    X2 = rowSums(select(., starts_with("2"))),
    X3 = rowSums(select(., starts_with("3"))),
    X4 = rowSums(select(., starts_with("4"))),
    X5 = rowSums(select(., starts_with("5")))
  )


IdCLCout_5000 <- IdCLCout_5000[,c(1,39:43)] 


# Renommer les colonnes en numero habitat directement
# Renommer les colonnes X1 à X5 en utilisant les chiffres correspondants
IdCLCout_5000 <- IdCLCout_5000 %>%
  rename_with(~ gsub("X", "", .), starts_with("X"))



View(IdCLCout_5000 %>%
       mutate(total = rowSums(IdCLCout_5000[,2:6])))

write.table(x = IdCLCout_5000, file = 'propage_pays/buffer_5000_CLC_grossier.csv', sep = ';', row.names = FALSE)

# ----- TABLE DE POURCENTAGE DE PAYSAGES

paysage_5000 <- IdCLCout_5000 |>
  mutate(total = rowSums(IdCLCout_5000[,2:6])) |>
  mutate_at(vars(2:6), ~./total*100) |>
  select(-total)
write.table(x = IdCLCout_5000, file = 'propage_pays/paysage_5000.csv', sep = ';', row.names = FALSE)

#write.table(x = paysage_5000, file = '/Users/sariakasalomon-ramialison/Desktop/Propage/paysage_5000.csv', sep = ';', row.names = FALSE)


##############################################################
#------ ETUDE SIMILAIRE POUR 3RD BUFFER - DISQUE 5-10 --------#
##############################################################


# ------ CREATION DU BUFFER 5000m - 10000m --------------


# Rappel `coord_BF_1000` couche du buffer à 1000 m
# Rappel `coord_BF_5000` couche du buffer entre 1000 m et 5000m
# On va créer `coord_BF_10000` qui est l'anneau entre 5000m et 10000m

disc_BF_10000 <- st_buffer(points_transects, dist = 10000)


### BOUCLE 

coord_BF_10000 <- data.frame()

for (i in 1:nrow(disc_BF_5000)) {
  a <- disc_BF_5000[i,]
  b <- disc_BF_10000[i,]
  coord_BF_10000 <- rbind(coord_BF_10000, st_difference(b, a))
  print(paste0(i, "/", nrow(disc_BF_5000)))
}

# Plot des [2 premiers] buffers
ggplot() +
  geom_sf(data = coord_BF_10000[1:2,],
          col = 'blue') +
  theme_minimal()


#------ INTERSECTION DE CLC ET DES BUFFERS CREES AUTOURS DES TRANSECTS ------------



#on extrait ensuite du CLC les parcelles chevauchants les zones buffers de tous les points_transects :
#on garde seulement les parcelles qui chevauchent les points_transects

PARCELLES_chevauchantes_10000 <- st_intersects(coord_BF_10000, CLC_2018_France_wgs84_sf)



#------ CREATION DE LA TABLE LONGUE ID_TRANSECT, ID_PARCELLE CHEVAUCHANT, DONNEES CLC DE LA PARCELLE -------------------


# Créez un dataframe vide pour stocker les résultats
result_df_CLC_10000 <- data.frame(id_transect = character(),ID = character(), stringsAsFactors = FALSE)

# Parcourez chaque ligne de PARCELLES_chevauchantes_10000

for (i in 1:length(PARCELLES_chevauchantes_10000)) {
  # Obtenez l'id_transect du transect correspondant
  id_transect <- coord_BF_10000$id_transect[i]
  # Obtenez les indices des polygones intersectés dans PARCELLES_chevauchantes_10000
  intersected_indices <- PARCELLES_chevauchantes_10000[[i]]
  # Si la liste n'est pas vide, ajoutez les informations au dataframe résultant
  if (length(intersected_indices) > 0) {
    temp_df <- data.frame(id_transect = rep(id_transect, length(intersected_indices)),
                          ID = CLC_2018_France_wgs84_sf$ID[intersected_indices],
                          stringsAsFactors = FALSE)
    #result_df_CLC_10000 <- bind_rows(result_df_CLC_10000, temp_df)
    result_df_CLC_10000 <- rbind(result_df_CLC_10000, temp_df)
  }
}

# Affichez le dataframe résultant
View(result_df_CLC_10000)

# result_df_CLC_10000_FULL <- merge(result_df_CLC_10000, CLC_2018_France_wgs84_sf, by = "ID", all.x = TRUE)
# str(result_df_CLC_10000_FULL)

result_df_CLC_10000_FULL <- result_df_CLC_10000 |>
  inner_join(CLC_2018_France_wgs84_sf, by = "ID")

result_df_CLC_10000_FULL_sf <- st_as_sf(result_df_CLC_10000_FULL, crs = st_crs(4326))
st_crs(result_df_CLC_10000_FULL_sf)



#------ CALCUL DES SURFACES DE PARCELLE INTERSECTANT CHAQUE BUFFER -----------------------------------


# Fonction pour effectuer l'intersection (calcul des surfaces) pour un Id point donné !!
# Argument : id_transect
# Retour : une mini-dataframe avec id_transect, donnees CLC & surface parcelle correspondantes
intersect_code_point_10K <- function(id_transect) {
  # Selection des lignes de `result_df_CLC_10000_FULL_sf` pour le transect sélectionné (parcelles)
  subset_df <- result_df_CLC_10000_FULL_sf[result_df_CLC_10000_FULL_sf$id_transect == id_transect, ]
  # Selection de la ligne de `coord_BF_5000` pour le transect sélectionné (buffer)
  subset_buffer <- coord_BF_10000[coord_BF_10000$id_transect == id_transect, ]
  intersection <- st_intersection(subset_df, subset_buffer)
  intersection$overlap_area <- st_area(intersection)
  return(intersection)
}

# test sur un transect
test3 <- intersect_code_point_10K("1121_Parc de l'abbaye")

ggplot() +
  geom_sf(data = test3,
          col = 'blue') +
  theme_minimal()

sum(st_area(test3)) 

# Appliquer la fonction pour chaque id_transect unique
unique_code_points <- unique(result_df_CLC_10000_FULL_sf$id_transect)

# # J'ajoute une fonction  pour afficher un message pour chaque point dont le buffer est caractérisé
# # afficher_message_point <- function(id_transect) {
# #   message(paste("Traitement du point", id_transect))
# # }

# Utiliser lapply pour caractériser les buffers point par point par seulement les parcelles qui chevauchent ce point
intersection_list_CLC_10000_allFRANCE <- lapply(unique_code_points, function(id_transect, vec = unique_code_points) {
  # afficher_message_point(id_transect)
  print(paste0(which(id_transect == vec), "/", length(vec)))
  intersect_code_point_10K(id_transect)
})

#----- CALCUL DES SURFACES CORRESPONDANTES


# Appliquer la conversion en parallèle
buffercaractCLC_df_temporaire <- future_lapply(intersection_list_CLC_10000_allFRANCE, convert_to_dataframe)
# Concaténer les résultats avec ldply
buffercaractCLC_df_temporaire2 <- ldply(buffercaractCLC_df_temporaire)

# Assurez-vous que le résultat est un dataframe
buffercaractCLC_df_10000 <- as.data.frame(buffercaractCLC_df_temporaire2)
head(buffercaractCLC_df_10000, 20)
# on enlève les colonnes doublon
buffercaractCLC_df_10000 <- buffercaractCLC_df_10000 %>%
  select(-ends_with(".1"))
View(head(buffercaractCLC_df_10000))

# On supprime les df temporaires
rm(buffercaractCLC_df_temporaire)
rm(buffercaractCLC_df_temporaire2)

# On a ainsi `buffercaractCLC_df_10000` qui est une table longue des id_transects 
# avec les données CLC des parcelles intersectant chaque transect
# avec la surface de chaque transect


# ------ AGREGATION DES SURFACES DE PARCELLES IDENTIQUES SUR UN BUFFER ----------------------

result_10K <- aggregate(overlap_area ~ id_transect + CODE_18, buffercaractCLC_df_10000, sum, na.rm = TRUE)
#View(result)

buffercaract_CLC_allFRANCE_10000 <- result_10K %>%
  pivot_wider(names_from = CODE_18, values_from = overlap_area)
#View(buffercaract_CLC_allFRANCE)

buffercaract_CLC_allFRANCE_10000_2 <- buffercaract_CLC_allFRANCE_10000

buffercaract_CLC_allFRANCE_10000_2 <- mutate_all(buffercaract_CLC_allFRANCE_10000_2, ~replace(., is.na(.), 0))
View(buffercaract_CLC_allFRANCE_10000_2)

write.table(x = buffercaract_CLC_allFRANCE_10000_2, file = 'propage_pays/buffer_10000_complete.csv', sep = ';', row.names = FALSE)


# ------ AGREGATION DES SURFACES PAR "GRAND TYPE DE PAYSAGE" -----------------------------

# Sélectionner uniquement les colonnes X1 à X5
#voici les préfixes des colonnes à agréger
IdCLCout_10000 <- buffercaract_CLC_allFRANCE_10000_2%>%
  mutate(
    X1 = rowSums(select(., starts_with("1"))),
    X2 = rowSums(select(., starts_with("2"))),
    X3 = rowSums(select(., starts_with("3"))),
    X4 = rowSums(select(., starts_with("4"))),
    X5 = rowSums(select(., starts_with("5")))
  )


IdCLCout_10000 <- IdCLCout_10000[,c(1,42:46)] 


# Renommer les colonnes en numero habitat directement
# Renommer les colonnes X1 à X5 en utilisant les chiffres correspondants
IdCLCout_10000 <- IdCLCout_10000 %>%
  rename_with(~ gsub("X", "", .), starts_with("X"))
View(IdCLCout_10000 %>%
  mutate(total = rowSums(IdCLCout_10000[,2:6])))





write.table(x = IdCLCout_10000, file = 'propage_pays/buffer_10000_CLC_grossier.csv', sep = ';', row.names = FALSE)


# ----- TABLE DE POURCENTAGE DE PAYSAGES

paysage_10000 <- IdCLCout_10000 |>
  mutate(total = rowSums(IdCLCout_10000[,2:6])) |>
  mutate_at(vars(2:6), ~./total*100) |>
  select(-total)
write.table(x = IdCLCout_10000, file = 'propage_pays/paysage_10000.csv', sep = ';', row.names = FALSE)
