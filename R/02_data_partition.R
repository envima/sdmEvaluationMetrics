#'@name 02_data_partition.R
#'@date 25.06.2025
#'@author Lisa Bald [bald@staff.uni-marburg.de]
#' 
#' @description 
#' Splits species presence-absence data into training, validation, and testing 
#' sets using various (spatial) cross-validation (CV) techniques.
#' 
#' Methods:
#' 1. K-nearest neighbor distance matching (KNNDM)
#' 2. Random partitioning
#' 3. Spatial blocking (Hexagonal & Square)
#' 4. Environmental Clustering
#' 
#' @references 
#' Valavi et al. (2019). blockCV: an r package for generating spatially or environmentally 
#' separated folds for k ‐fold cross‐validation of species distribution models. 
#' Methods in Ecology and Evolution. https://doi.org/10.1111/2041-210X.13107
#' 
#' Meyer et al. (2023). CAST: “caret” applications for spatial-temporal models. 
#' R package version 0.8.1. https://CRAN.R-project.org/package=CAST 
#' 
#' Tutorial: https://hannameyer.github.io/CAST/articles/cast02-AOA-tutorial.html

# ================================================================ #
# 1. Set up ----
# ================================================================ #

library(blockCV)
library(predicts)
library(sf)
library(parallel)
library(terra)
library(CAST)

if (Sys.info()[[4]]=="PC19674") {
  nCores=1
} else if (Sys.info()[[4]]=="pc19543") {
  nCores=50
}

# Load environmental predictors
vars <- terra::rast("data/variables.tif")

# ================================================================ #
# 2. Load species ----
# ================================================================ #

species=list.files("data/PA/",pattern=".gpkg",full.names=F)

# ================================================================ #
# 3. Create a background dataset ----
# ================================================================ #

if(! file.exists("data/bg.gpkg")){
  bg=as.data.frame(predicts::backgroundSample(terra::rast("data/variables.tif"), n=10000))
  bg=sf::st_as_sf(bg, coords=c("x","y"), crs="epsg:3577", remove=F)
  
  extr=terra::extract(vars,background,ID=F)
  background$Real<- 0
  background$Observed<-0
  background=cbind(background,extr)
  background$random <-  sample(1:6, size=nrow(background), replace = T)
  background$KNNDM <-  sample(1:6, size=nrow(background), replace = T)
  background$clusters <-  sample(1:6, size=nrow(background), replace = T)
  background$block1 <-  sample(1:6, size=nrow(background), replace = T)
  background$block2 <-  sample(1:6, size=nrow(background), replace = T)
  background$x<-NULL
  background$y<-NULL
  
  
  sf::write_sf(bg, "data/bg.gpkg")
} else {
  bg=sf::read_sf("data/bg.gpkg")}

# ================================================================ #
# 4. Split species data ----
# ================================================================ #

mclapply(1:length(species), function(i){
  print(i)
  if(!file.exists(paste0("data/virtualSpeciesTrain/",species[i]))){
    vs=sf::read_sf(paste0("data/PA/",species[i]))
    
    # K-nearest neighor distance matching
    KNNDM=CAST::knndm(tpoints=vs,modeldomain = vars,k=6)
    vs$KNNDM <- KNNDM$clusters
    
    # random
    vs$random <- sample(1:6, size=nrow(vs), replace = T)
    
    
    # block cv 1
    block1 = blockCV::cv_spatial(x = vs,
                                 column = "Real",
                                 r = vars, # optionally add a raster layer
                                 k = 6, 
                                 size = 300000, #in m
                                 hexagon = T, 
                                 selection = "random",
                                 offset = c(0, 0),
                                 progress = T, # turn off progress bar for vignette
                                 iteration = 50, 
                                 biomod2 = F,
                                 extend = 5,
                                 plot=F)
    vs$block1 <- block1$folds_ids
    
    
    block2 = blockCV::cv_spatial(x = vs,
                                 column = "Real",
                                 r = vars, # optionally add a raster layer
                                 k = 6, 
                                 size = 100000, #in m
                                 hexagon = F, 
                                 selection = "random",
                                 offset = c(0, 0),
                                 progress = T, # turn off progress bar for vignette
                                 iteration = 50, 
                                 biomod2 = F,
                                 extend = 5,
                                 plot=F)
    vs$block2 <- block2$folds_ids
    
    
    clusters = blockCV::cv_cluster(x=vs,r=vars,k=6)
    vs$clusters <- clusters$folds_ids
    
    # save folding technique
    if(!dir.exists("data/run2/folds")) dir.create("data/run2/folds", recursive=T)
    saveRDS(block1, sprintf("data/folds/%s_block1.RDS",gsub(".gpkg","",species[i])))
    saveRDS(block2, sprintf("data/folds/%s_block2.RDS",gsub(".gpkg","",species[i])))
    saveRDS(clusters, sprintf("data/folds/%s_clusters.RDS",gsub(".gpkg","",species[i])))
    saveRDS(KNNDM, sprintf("data/folds/%s_KNNDM.RDS",gsub(".gpkg","",species[i])))
    
    
    # extract environmental information
    extr=terra::extract(vars,vs,ID=F)
    vs=cbind(vs,extr)
    
    if(!dir.exists("data/virtualSpeciesTrain")) dir.create("data/virtualSpeciesTrain", recursive=T)
    sf::write_sf(vs,paste0("data/virtualSpeciesTrain/",species[i]))
  }
},mc.cores=nCores)

