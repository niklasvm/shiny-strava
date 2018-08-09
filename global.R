# global.R is sourced when the application is lauched
message('global.R sourced')

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
library(shinythemes)

# Application options ----

# application url
strava_app_url  <-  glue('http://127.0.0.1:1234')
#strava_app_url = '192.168.0.94:3838/shiny-strava'
# set as environment variable
Sys.setenv(
  strava_app_url = strava_app_url
)

# show application api inputs
ask_api_credentials <- F

# whether to load cached data (must have authenticated before)
cache <- T

# Load credentials if available ----

# the following environment variables must be set in credentials.R
# Sys.setenv(
#   strava_app_name='xxxxx',
#   strava_app_url = 'xxxxxx',
#   strava_app_client_id  = 'xxxx',
#   strava_app_secret = 'xxxx'
# )

try({
  source('./credentials.R')
})

# file dependencies ----

source('./utils.R')
source("./dplyr_verbs.R")
