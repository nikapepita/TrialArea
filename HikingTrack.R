##Create Hiking Information and connect it with Remote Sensing
#source: https://rpubs.com/ials2un/gpx1

# check to see if packages are installed. Install them if they are not, then load them into the R session.
in_pak <- function(pkg){
  new.pkg <- pkg[!(pkg %in% installed.packages()[,"Package"])]
  if(length(new.pkg))
    install.packages(new.pkg, dependencies=TRUE)
  sapply(pkg, require, character.only=TRUE)
}

# install packages
packages <- c("XML", "OpenStreetMap", "lubridate", "ggmap", "ggplot2", "raster", "sp")
in_pak(packages)

#shifts vectors conveniently


shift.vec <- function (vec, shift) {
  if(length(vec) <= abs(shift)) {
    rep(NA ,length(vec))
  }else{
    if (shift >= 0) {
      c(rep(NA, shift), vec[1:(length(vec)-shift)]) }
    else {
      c(vec[(abs(shift)+1):length(vec)], rep(NA, abs(shift))) } } }

#check function shift.vec
col1 <- seq(0,100,5)

col2 <- seq(200, 100, -5)

my_df <- data.frame(c1= col1, c2= col2)

my_df

my_df$nc1 <- shift.vec(my_df$c1, -1)
my_df$nc2 <- shift.vec(my_df$c2, -1)
my_df

#load gpx data

options(digits=10)
# Parse the GPX file
pfile <- htmlTreeParse(file = "C:/Users/Annika/Documents/Downloads/2020-01-03_108250812_Wanderung 03.01.2020 16_46.gpx", error = function(...) {
}, useInternalNodes = T)
# Get all elevations, times and coordinates via the respective xpath
elevations <- as.numeric(xpathSApply(pfile, path = "//trkpt/ele", xmlValue))
times <- xpathSApply(pfile, path = "//trkpt/time", xmlValue)
coords <- xpathSApply(pfile, path = "//trkpt", xmlAttrs)

str(coords)


#Extract latitude and longitude from the coordinates
lats <- as.numeric(coords["lat",])
lons <- as.numeric(coords["lon",])

# Put everything in a dataframe and get rid of old variables
geodf <- data.frame(lat = lats, lon = lons, ele = elevations, time = times)
rm(list=c("elevations", "lats", "lons", "pfile", "times", "coords"))

head(geodf)

# Shift vectors for lat and lon so that each row also contains the next position.
geodf$lat.p1 <- shift.vec(geodf$lat, -1)
geodf$lon.p1 <- shift.vec(geodf$lon, -1)
head(geodf)

#Calculate distances (in metres) using the function pointDistance from the ‘raster’ package.
# Parameter ‘lonlat’ has to be TRUE!

geodf$dist.to.prev <- apply(geodf, 1, FUN = function (row) {
  pointDistance(c(as.numeric(row["lat.p1"]),
                  as.numeric(row["lon.p1"])),
                c(as.numeric(row["lat"]), as.numeric(row["lon"])),
                lonlat = T)
})

head(geodf$dist.to.prev)

td <- sum(geodf$dist.to.prev, na.rm=TRUE)
print(paste("The distance walk was ", td, " meters"))


# Transform the column ‘time’ so that R knows how to interpret it.
geodf$time <- strptime(geodf$time, format = "%Y-%m-%dT%H:%M:%OS")
# Shift the time vector, too.
geodf$time.p1 <- shift.vec(geodf$time, -1)
# Calculate the number of seconds between two positions.
geodf$time.diff.to.prev <- as.numeric(difftime(geodf$time.p1, geodf$time))

head(geodf$time.diff.to.prev, n=15) 

# Calculate metres per seconds, kilometres per hour and two LOWESS smoothers to get rid of some noise.
geodf$speed.m.per.sec <- geodf$dist.to.prev / geodf$time.diff.to.prev
geodf$speed.km.per.h <- geodf$speed.m.per.sec * 3.6
geodf$speed.km.per.h <- ifelse(is.na(geodf$speed.km.per.h), 0, geodf$speed.km.per.h)
geodf$lowess.speed <- lowess(geodf$speed.km.per.h, f = 0.2)$y
geodf$lowess.ele <- lowess(geodf$ele, f = 0.2)$y

# Plot elevations and smoother
plot(geodf$ele, type = "l", bty = "n", xaxt = "n", ylab = "Elevation", xlab = "", col = "grey40")
lines(geodf$lowess.ele, col = "red", lwd = 3)
legend(x="bottomright", legend = c("GPS elevation", "LOWESS elevation"),
       col = c("grey40", "red"), lwd = c(1,3), bty = "n")

# Plot speeds and smoother
plot(geodf$speed.km.per.h, type = "l", bty = "n", xaxt = "n", ylab = "Speed (km/h)", xlab = "",
     col = "grey40")
lines(geodf$lowess.speed, col = "blue", lwd = 3)
legend(x="bottom", legend = c("GPS speed", "LOWESS speed"),
       col = c("grey40", "blue"), lwd = c(1,3), bty = "n")
abline(h = mean(geodf$speed.km.per.h), lty = 2, col = "blue")

# Plot the track without any map, the shape of the track is already visible.
plot(rev(geodf$lon), rev(geodf$lat), type = "l", col = "red", lwd = 3, bty = "n", ylab = "Latitude", xlab = "Longitude")

library(ggmap)
lat <- c(min(geodf$lat), max(geodf$lat))
lat

lon <- c(min(geodf$lon), max(geodf$lon))
lon

bbox <- make_bbox(lon,lat)

b1 <- get_stamenmap(bbox, zoom=16, maptype="toner")

ggmap(b1) + geom_point(data = geodf, 
                       aes(lon,lat,col = ele), size=1, alpha=0.7) +
  labs(x = "Longitude", y = "Latitude",
       title="Track of hike through Bessenbach")

#Create  interaktiv Map

library(mapview)

class(geodf)
## [1] "data.frame"
spdf_geo <- geodf

coordinates(spdf_geo) <- ~ lon + lat
proj4string(spdf_geo) <- "+init=epsg:4326"

class(spdf_geo)
## [1] "SpatialPointsDataFrame"
## attr(,"package")
## [1] "sp"
mapview(spdf_geo)

#or
library(leaflet)

leaflet() %>% 
  addTiles() %>% 
  addFeatures(spdf_geo, weight = 1, fillColor = "grey", color = "black",
              opacity = 1, fillOpacity = 0.6)

#################################################
#3D Map - Rayshader

library(rayshader)

#Here, I load a map with the raster package.
loadzip = tempfile() 
download.file("https://tylermw.com/data/dem_01.tif.zip", loadzip)
localtif = raster::raster(unzip(loadzip, "dem_01.tif"))
unlink(loadzip)

#And convert it to a matrix:
elmat = raster_to_matrix(localtif)

#We use another one of rayshader's built-in textures:
elmat %>%
  sphere_shade(texture = "desert") %>%
  plot_map()