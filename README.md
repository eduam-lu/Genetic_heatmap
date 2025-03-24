Heatmapp is an interactive tool for visualizing genetic distance between populations through time and space. Leveraging data from the AADR database, and an individual selected by the user, Heatmapp is able to visualise the genetic distance among all the other individuals in the database
### Data processing into a formated file

1. Download the database AADR in EIGENSTRAT format (https://reich.hms.harvard.edu/allen-ancient-dna-resource-aadr-downloadable-genotypes-present-day-and-ancient-dna-data)
2. Convert into PACKED PED format using convertf from ADMMIXTOOLS (Eigensoft 3.0)
    
    Confertf requires a config file called convertf.par described below
    
    ```bash
    genotypename:    v54.1.p1_1240K_public.geno
    snpname:         v54.1.p1_1240K_public.snp
    indivname:       v54.1.p1_1240K_public.ind
    outputformat:    PACKEDPED
    genotypeoutname: aadr_data.bed
    snpoutname:      aadr_data.bim
    indivoutname:    aadr_data.fam
    ```
    
    ```bash
    convertf -p convertf.par
    ```
    
3. Filter bed file by missingness (using PLINK 1.9)
    
    ```bash
     
    plink --bfile aadr_data --geno 0.1 --make-bed --out filtered_aadr
    ```
    
4. Compute IBS distances (using PLINK 1.9)
    
    ```bash
     plink --bfile filtered_aadr --distance 1-ibs flat-missing --out ibs_matrix
    ```
    
5. Select an individual. First we initiate the formated file echoing the tittles and then we find the apropiate ID
    
    ```bash
    echo "IID2 DST" > new_distances.txt
    awk '$2 == "VK127_noUDG.SG" {print $4, $12}' ibs_distances.genome >> new_distances.txt
    ```
    
6. Assign year, latitude and longitude to the distances using the .anno file
    
    For this the python script “distance_merger.py“ was developed, which uses pandas 2.2.3 to merge those two files with an inner join
    

### How does Heatmapp work

Heatmapp takes the formated input (”Years BP”, “Genetic ID”, “Lat.”, “Long.”, “DST”) and lets the user select a number of time bins. With this input:

1. The data is cleaned from missing and infinite values
2. Individuals are splitted in two groups: ancient and modern
3. Ancient individuals are grouped in the number of bins indicated by the user containing the same number of individuals each. Each of these bins is plotted sepparately
4. Modern individuals are sampled ensuring proper representation of all kinds of genetic distances. This subsample generates then a single plot
5. The result is a list of plots that can be parsed with the slider 

Heatmapp is an R shiny app developed under R 4.4.3 using the package shiny (1.10.0).

Heatmapp’s plotting function relies on the following R packages for visualization: ggplot2 (3.5.1) for data management and aesthetics; sf (1.0-19)  and rnaturalearth (1.0.1) for geographical display; and akima (0.6-3.4) and raster (3.6-31) for rendering discrete distance values into a continuous geographical function that generates the heatmap. 

### How to use Heatmapp
Run the Heatmapp_v1.R script in the same directory than heatmappp_functions.R
Heatmapp takes a file (with the same format as the example provided in the all_indivs_mapped example file. Let's the user select the number of bins and then plots it
The user can select which plot to visualise with a slidebar
