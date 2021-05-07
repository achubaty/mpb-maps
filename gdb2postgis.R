readRenviron(".Renviron")

library(Require)
Require(c("RPostgres", "rgdal", "sf", "ggplot2", "ggspatial"))

stopifnot(Sys.info()[["sysname"]] == "Windows") ## R can only work with .gdb files on Windows
subset(st_drivers(), grepl("GDB", name))

conn <- DBI::dbConnect(drv = RPostgres::Postgres(),
                       host = Sys.getenv("PGHOST"),
                       port = Sys.getenv("PGPORT"),
                       dbname = Sys.getenv("PGDATABASE"),
                       user = Sys.getenv("PGUSER"),
                       password = Sys.getenv("PGPASSWORD"))

dataDir <- ifelse(peutils::user("Alex Chubaty"), "Z:/MPB", "data")

write2db <- function(x, f, conn) {
  yr_ <- substr(x, 10, 11)
  yr_ <- ifelse(yr_ > 50, paste0(19, yr_), paste0(20, yr_))
  polypnts <- ifelse(substr(x, 12, 12) == "x", "pnts", "poly")

  tmp <- st_read(f, layer = x)
  st_crs(tmp) <- 3400
  st_write(tmp, conn, layer = paste0("MPB_AB_", yr_, "_", polypnts))
  rm(tmp)
}

## ---------------------------------------------------------------------------------------------- ##

f_mpb_2018 <- normalizePath(file.path(dataDir, "MPB_AERIAL_SURVEY_2018.gdb"))
stopifnot(file.exists(f_mpb_2018))

fc_list_2018 <- ogrListLayers(f_mpb_2018)
print(fc_list_2018) ## points are 'x' features; polygons are 'p'

sort(unique(substr(fc_list_2018, 10, 12)))
#years <- c(1975L:1987L, 1989L:1991L, 1994L, 1998L, 2001L:2018L)

mpb <- lapply(fc_list_2018, write2db, f = f_mpb_2018, conn = conn)

f_mpb_2019 <- normalizePath(file.path(dataDir, "MPB_AERIAL_SURVEY_2019.gdb"))
stopifnot(file.exists(f_mpb_2019))

fc_list_2019 <- ogrListLayers(f_mpb_2019)
print(fc_list_2019)

mpb_2019 <- lapply(fc_list_2019, write2db, f = f_mpb_2019, conn = conn)

mpb <- append(mpb, mpb_2019)

## ---------------------------------------------------------------------------------------------- ##

f <- normalizePath(file.path(dataDir, "Mountain_Pine_Beetle_SSI.gdb"))

## List all feature classes in a file geodatabase
fc_list <- ogrListLayers(f)
print(fc_list)

ssi <- st_read(dsn = f, layer = "STAND_SUSC_INDEX_MPB")

st_write(ssi, conn, layer = "MPB_AB_SSI")

## save to shapefiles
dout <- file.path(dataDir, "ab_mpb_ssi") %>% checkPath(create = TRUE)
fout <- file.path(dout, "ab_mpb_ssi.shp")
write_sf(ssi, dsn = fout)
