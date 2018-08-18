# DRAW MAP WITH LEAFLET ----

library(tidyverse)
library(rStrava)
library(httr)
library(leaflet)

source("./utils.R")
source("./dplyr_verbs.R")

# 1. Import raw data ----

# raw data
stoken <- readRDS('./cache/stoken.rds')
# accesstoken <- '056727d371b4ea24d3f458c186d19c857ba6c21b'
# stoken <- add_headers(Authorization = paste0("Bearer ",accesstoken))

# 
# df_raw <- get_activity_list(stoken,club = T)
# 
df_raw <- readRDS('./cache/raw_activities.rds')

# tidy
df <- df_raw %>%
  compile_activities() %>%
  tidy_activities()

df <- df %>%
  mutate(week_start=lubridate::floor_date(as.Date(start_date_local)-1,unit = 'week')+1)
# 
df %>%
  filter(start_date_local > '2018-01-01') %>%
  select(start_date_local,week_start) %>%
  arrange(start_date_local) %>%
  tail

df %>% 
  filter(start_date_local > '2017-07-01') %>% 
  group_by(week_start) %>% 
  summarise(dist=sum(distance)) %>% 
  ggplot(aes(x=week_start,y=dist))+
  #geom_line()+
  geom_point()+
  geom_segment(aes(xend=week_start,yend=0))

df$start_date_local %>% lubridate::floor_date(.,unit = 'week') %>% (. + 1) %>% strftime('%A')


# filter values
date_range_filter <- c('2018-08-01',as.character(Sys.Date()))
type_filter <- c('Run')
radius_filter <- 10
radius_center <- df$title[1]


# filter activities
data <- df %>% 
  filter(!is.na(map.summary_polyline)) %>% 
  arrange(desc(start_date_local)) %>% 
  filter(type=='Run') %>% 
  
  filter(start_date_local>='2018-08-01')

lon=data$start_longitude[1]
lat=data$start_latitude[1]
radius=5000

data %>% 
  filter_within_radius(
    lon=.$start_longitude[1],
    lat=.$start_latitude[1],
    radius=5000
  ) %>%
  get_leaflet_heat_map(
    colour='red',
    weight = 3,
    opacity=0.01
  )
  
