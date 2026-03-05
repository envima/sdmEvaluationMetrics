# The accuracy of evaluation metrics in presence-only species distribution modelling.

## Abstract

Species distribution modeling is one of the most popular tools in ecology and nature conservation, promising researchers and stakeholders rapid solutions that facilitate remote decision-making with minimal field-based effort. While presence-only data are the most common data used in species distribution modelling, the evaluation metrics calculated from them are biased to an unknown extent. Consequently, decisions are based on evaluation metrics whose actual accuracy are unknown, which creates a significant risk of issuing wrong scientific guidelines or misallocating conservation resources. To quantify this uncertainty, we utilized virtual species to generate over 8,000 species distribution maps, enabling a direct comparison between commonly used evaluation metrics and the true probability of occurrence. We assessed metrics calculated from three data types: presence-only, presence-background (sampled randomly), and presence-artificial-absence (sampled from environmentally distant regions). Our findings provide two reference points for the field: (1) evaluation metrics calculated using presence-artificial-absence data provide the best estimate of performance currently available, with median absolute errors between 0.10-0.18, compared to 0.14-0.29 for presence-background and 0.25-0.44 for presence-only data. (2) Without true absence data, evaluation metrics typically deviate from actual model performance by 39% to 42%, depending on the specific context, this error range likely renders conclusion unreliable. Acknowledging these errors is essential when interpreting evaluation metrics calculated without true absence data; thus, our findings provide a critical baseline for the contextualization of evaluation metrics in both research and conservation.

---

## Repository Structure

This repository contains the full analytical pipeline, including virtual species generation, model training, and ploting of the study.


.
├── data/
│   ├── climate/           # Bioclimatic variables (Predictors)
│   ├── resultsMain/       # Benchmarking results using artificial maps
│   ├── resultsRealModels/ # Results using ML algorithms (RF, BRT, etc.)
│   └── virtualSpecies/    # Ground-truth suitability and occurrence data
├── R/
└── README.md


---

## Key Components

### 1. Data Generation
We utilize the `virtualspecies` R package to create 10 distinct virtual species (**VS01–VS10**) with known environmental preferences. This allows for the calculation of the "True Correlation" ($trueCor$), which serves as the ground-truth benchmark for all evaluation metrics.

### 2. Evaluated Metrics
The pipeline calculates 29 variables, including:
* **Traditional Metrics**: AUC, TSS, Kappa, PCC, COR.
* **Spatial Bias Indicators (SBI)**: Area displacement, patch size similarity, and centroid reach.
* **Precision-Recall**: PRG, SEDI, ORSS.

### 3. Spatial Cross-Validation
We test the influence of five different partitioning strategies:
* **KNNDM** (Nearest Neighbor Distance Matching)
* **Spatial Blocks** (Block1 & Block2)
* **Environmental Clusters**
* **Random Partitioning**

---

## Important Note on Data Size

The full study generates approximately **300GB** of data. To maintain repository functionality, **only a few example files are included in the repository**.

To reproduce the full dataset, please run the scripts in the `R/` folder sequentially.