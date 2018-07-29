# this file is sourced when the application is lauched


# the following environment variables must be set. Uncomment the lines below and set explicitly:
# TIP: to get the strava_app_url you can just click `Run App` in RStudio and it will be the URL in the address bar.


# Sys.setenv(
#   strava_app_name='xxxxx',
#   strava_app_url = 'xxxxxx',
#   strava_app_client_id  = 'xxxx',
#   strava_app_secret = 'xxxx'
# )

# dependencies
library(shiny)
library(rStrava)
library(tidyverse)
library(httr)
library(jsonlite)
library(glue)
library(DT)
library(leaflet)
library(shinydashboard)

# # validate environment variables are set
# missing <- c('strava_app_url','strava_app_client_id','strava_app_secret') %>% 
#   map_lgl(~ Sys.getenv(.x) == "") %>% 
#   any
# if (missing) stop('Please set all require environment variables')
# 
# # generate authentication link as set out at https://developers.strava.com/docs/authentication/
# authorisation_url <-   glue('https://www.strava.com/oauth/authorize?client_id={Sys.getenv(\'strava_app_client_id\')}&response_type=code&redirect_uri={Sys.getenv(\'strava_app_url\')}&approval_prompt=auto&state=')
  

# Application options ----

# show application api inputs
ask_api_credentials <- F

# whether to load cached data (must have authenticated before)
cache <- T

source('./utils.R')
source("./dplyr_verbs.R")
