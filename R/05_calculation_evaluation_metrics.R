#' @name 05_calculaton_evaluation_metrics.R
#' @date 29.08.2025
#' @author Lisa Bald
#' @contact bald@staff.uni-marburg.de
#' 
#' @description
#' This script evaluates artificial species distribution maps. 
#' For each species, several sampling strategies, 
#' test datasets, and replicates are evaluated. Evaluation metrics 
#' are calculated and saved.


# ================================================================ #
# 1. Set up ----
# ================================================================ #

library(dplyr)            # data manipulation
library(sf)               # spatial vector data
library(parallel)         # parallel processing
library(terra)            # raster handling
library(climateStability) # rescaling to [0,1]
#devtools::install_github("envima/poEvaluationMetrics")
library(poEvaluationMetrics)

if (Sys.info()[[4]]=="PC19674") {
  nCores=1
} else if (Sys.info()[[4]]=="pc19543") {
  nCores=60
}

# create a unique name for different runs
all_runs <- c("resultsMain", "resultsImbalanced", "resultsRealModels")



for (nameRun in all_runs) {
  
  message(paste("--- Processing Run:", nameRun, "---"))
  
  
  # ================================================================ #
  # 2. Define experimental evaluation setup ----
  # ================================================================ #
  
  df=expand.grid(size=as.character(c("KNNDM","random","block1","block2","clusters")) , # data separation strategies
                 species=c("VS01", "VS02", "VS03", "VS04", "VS05", "VS06", "VS07", "VS08", "VS09", "VS10"), # virtual species IDs
                 points=unique(sapply(strsplit(gsub(".gpkg", "", 
                                                    list.files("data/virtualSpeciesTrain", 
                                                               full.names = FALSE,pattern=".gpkg")), "_"), `[`, 2)), # number of originally sampled points points
                 replicates=1:5, # replicate runs
                 model=if(nameRun == "resultsRealModels") as.character(c("Lasso", "RF","Maxent", "BRT", "GAM")) else "NA", # placeholder (no models trained here)
                 testData = 1:6            ) # test dataset identifiers
  
  
  # ================================================================ #
  # 3. Calculation of evaluation metrics ----
  # ================================================================ #
  
  vars_path=normalizePath("data/variables.tif")

  mclapply(1:nrow(df), function(i){
    
    print(i)
    # Skip evaluation if result already exists
    if(!file.exists(paste0("data/",nameRun,"/results/",as.character(df$species[i]),"_",as.character(df$size[i]),"_",as.character(df$model[i]),"_testData",df$testData[i],"_points",as.character(df$points[i]),"_replicates",df$replicates[i],".RDS"))){
      
      vars=terra::rast(vars_path)
      vs=sf::read_sf(paste0("data/virtualSpeciesTrain/",as.character(df$species[i]),"_",as.character(df$points[i]),"_",df$replicates[i],".gpkg"))
      # Select test data according to sampling strategy
      test <- vs %>%
        dplyr::filter(.data[[as.character(df$size[i])]] == df$testData[i])
      
      # Abort if fewer than 5 presence points available
      if(nrow(test%>%dplyr::filter(Real==1))<2) return(NULL)
      
      # Load true species distribution raster
      realDistribution=terra::rast(paste0("data/virtualSpecies/",as.character(df$species[i]),".tif"))
      # ================================================================ #
      # set parameters for different runs: ----
      # ================================================================ #
      
      
      if(nameRun == "resultsImabalanced"){
        pathPred = "resultsMain"
        # Imbalanced test dataset
        noPointsTesting = nrow(test%>%dplyr::filter(Real==1))*10
      } else if(nameRun %in%  c("resultsMain", "resultsRealModels")) {
        pathPred = nameRun
        noPointsTesting= NA
      } 
      
      pred=terra::rast(paste0("data/",pathPred,"/maps/",as.character(df$species[i]),"_",df$size[i],"_",df$model[i],"_testData",df$testData[i],"_points",as.character(df$points[i]),"_replicates",df$replicates[i],".tif"))
      # Skip if prediction map contains only NA values
      if(isTRUE(terra::global(pred, fun = function(x) all(is.na(x)))[[1]])) return(NULL)
      pred=terra::mask(pred,realDistribution)
      pred=terra::project(pred, "EPSG:3577")
      # ================================================================ #
      # 5a. Calculate evaluation metrics ----
      # ================================================================ #
      
      
      
      # calculate metrics for the map
      result = performanceEstimation( prediction             = pred,
                                      presence               = test %>% dplyr::filter(Real == 1),
                                      absence                = test %>% dplyr::filter(Real == 0),
                                      background             = TRUE,
                                      aa                     = TRUE,
                                      environmentalVariables = vars,
                                      noPointsTesting        = noPointsTesting,
                                      replicates             = 20)
      
      # Calculate direct spatial correlation between the artificial map and the true distribution
      result$trueCor <- terra::layerCor(terra::rast(list(pred,realDistribution)),fun="cor")$correlation[[1,2]]
      
      # Attach metadata
      result$model        <- as.character(df$model[i])
      result$size         <- as.character(df$size[i])
      result$testData     <- df$testData[i]
      result$method       <- gsub("index","",rownames(result))
      result$replicate    <- as.character(df$replicates[i])
      result$points       <- as.character(df$points[i])
      result$species      <- as.character(df$species[i])
      
      # Clean up memory 
      rm(pred,realDistribution,test,vs, autocorrRange, randomEffects, pathPred);gc()
      
      # save result
      if(!dir.exists(paste0("data/",nameRun,"/results"))) dir.create(paste0("data/",nameRun,"/results"), recursive=T)
      saveRDS(result, paste0("data/",nameRun,"/results/",as.character(df$species[i]),"_",as.character(df$size[i]),"_",as.character(df$model[i]),"_testData",df$testData[i],"_points",as.character(df$points[i]),"_replicates",df$replicates[i],".RDS"))
    }
  },mc.cores=nCores)
  
  
  # ================================================================ #
  # 6. Combine all results ----
  # ================================================================ #
  
  gc()
  
  # combine all result files
  if(!file.exists(paste0("data/",nameRun,"/results.RDS"))){
    data=list.files(paste0("data/",nameRun,"/results"),full.names = T)
    data=mclapply(data, function(x){
      df=readRDS(x)
      df$species <- strsplit(strsplit(x, split="/")[[1]][4],split="_")[[1]][1]
      return(df)
    },mc.cores=nCores)
    
    #data2=do.call(rbind,data)
    data2=dplyr::bind_rows(data)
    saveRDS(data2, paste0("data/",nameRun,"/results.RDS"))
  } else data=readRDS(paste0("data/",nameRun,"/results.RDS"))
  
}
