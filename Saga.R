#######################################################################################
#######################################################################################
#######First Steps with RSAGA
########################################################################################
########################################################################################

##Attention: This RSAGA version has been tested with SAGA GIS versions 2.3.1 - 6.3.0.

#Install RSAGA
install.packages("RSAGA")

setwd("C:/Users/Annika/Desktop/Saga/Uebung06/Uebung06_Daten")
library("RSAGA")

#Set up RSAGA Enviroment (Default)
work_env <- rsaga.env()

#set up RSAGA Enviroment with detailed environmental parameter
work_env <- rsaga.env(workspace='C:/Users/Annika/Desktop/Saga/Uebung06/Uebung06_Daten', ## workspace: path to your data
                      path = 'C:/SAGA-GIS',                                             ## path: path to SAGA 
                      modules = 'C:/SAGA-GIS/tools')                                    ## modules: path to SAGA modules

#Check RSAGA Enviroment
rsaga.env()

####################################################################
#Check out the Opportunities of RSAGA, example: morphometry, slope
####################################################################

# get a list of available libraries (modules)
rsaga.get.libraries() 

# get information about ta_morphometry
rsaga.get.modules('ta_morphometry')

# get usage information about the module ta_morphometry and  code= 0 (Slope, Aspect, Curvature)
rsaga.get.usage('ta_morphometry', 0) 


#calculate slope based on SRTM in sgrd-Format
rsaga.geoprocessor(lib = "ta_morphometry", module = "Slope, Aspect, Curvature",
                   param = list(ELEVATION = "./SRTM90_DHM_UTM32.sgrd", 
                                SLOPE = "./slope.sgrd"), env = work_env)
#or with the direct function for slope
rsaga.slope(in.dem = "./SRTM90_DHM_UTM32.sgrd", out.slope = "./slope2.sgrd", , method = "poly2zevenbergen", env = work_env)


