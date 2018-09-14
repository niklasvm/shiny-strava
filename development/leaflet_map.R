# DRAW MAP WITH LEAFLET ----

library(tidyverse)
library(rStrava)
library(leaflet)


# 1. Import raw data ----

df <- readRDS('./cache/activities.rds')

# 2. Process data ----

# filter to activities with polyline
df <- df %>% 
  filter(!is.na(map.summary_polyline)) %>% 
  # sample a few
  head(10)

# convert polyline to coords

routes <- df %>% 
  select(id,map.summary_polyline) %>% 
  split(.$id) %>% 
  map(function(row) {
    row$map.summary_polyline[1] %>% 
      decode_Polyline() %>% 
      separate(latlon,into=c('lat','lon'),sep = ',') %>% 
      # add id
      mutate(id=row$id) %>% 
      # cast to numeric
      mutate(lat=as.numeric(lat)) %>% 
      mutate(lon=as.numeric(lon)) %>% 
      select(id,everything())
  })


# 3. Plot map ----

map <- leaflet() %>% 
  addTiles()

for (r in routes) {
  map <- map %>% addPolylines(
    lng = r$lon,
    lat = r$lat, 
    layerId = r$id,
    color='red',
    opacity = 0.1,
    weight = 1
  )
}
map
