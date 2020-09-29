readRenviron(".Renviron")

library(RPostgreSQL)
library(rgdal)
library(sf)

stopifnot(Sys.info()[["sysname"]] == "Windows") ## R can only work with .gdb files on Windows
subset(st_drivers(), grepl("GDB", name))

conn <- DBI::dbConnect(drv = RPostgreSQL::PostgreSQL(),
                       host = Sys.getenv("PGHOST"),
                       port = Sys.getenv("PGPORT"),
                       dbname = Sys.getenv("PGDATABASE"),
                       user = Sys.getenv("PGUSER"),
                       password = Sys.getenv("PGPASSWORD"))

dataDir <- ifelse(peutils::user("Alex Chubaty"), "Z:/MPB", "data")

## ---------------------------------------------------------------------------------------------- ##

f_mpb <- normalizePath(file.path(dataDir, "MPB_AERIAL_SURVEY_2018.gdb"))
stopifnot(file.exists(f_mpb))

fc_list <- ogrListLayers(f_mpb)
print(fc_list) ## points are 'x' features; polygons are 'p'

sort(unique(substr(fc_list, 10, 12)))

#years <- c(1975L:1987L, 1989L:1991L, 1994L, 1998L, 2001L:2018L)

mpb <- lapply(fc_list, function(lay) {
  yr_ <- substr(lay, 10, 11)
  yr_ <- ifelse(yr_ > 50, paste0(19, yr_), paste0(20, yr_))
  polypnts <- ifelse(substr(lay, 12, 12) == "x", "points", "polygons")

  tmp <- st_read(f_mpb, layer = lay)
  st_write(tmp, conn, layer = paste0("MPB_AB_", yr_, polypnts))
  rm(tmp)
})

## ---------------------------------------------------------------------------------------------- ##

f_mpb_2019 <- normalizePath(file.path(dataDir, "MPB_AERIAL_SURVEY_2019.gdb"))
stopifnot(file.exists(f_mpb_2019))

fc_list <- ogrListLayers(f_mpb_2019)
print(fc_list)

mpb <- lapply(fc_list, function(lay) {
  yr_ <- substr(lay, 10, 11)
  yr_ <- ifelse(yr_ > 50, paste0(19, yr_), paste0(20, yr_))
  polypnts <- ifelse(substr(lay, 12, 12) == "x", "pnts", "poly")

  tmp <- st_read(f_mpb, layer = lay)
  st_write(tmp, conn, layer = paste0("MPB_AB_", yr_, "_", polypnts))
  rm(tmp)
})
