# global.R is sourced when the application is lauched
message('global.R sourced')

# Application options ----

# show application api inputs
ask_api_credentials <- F

# whether to load cached data (must have authenticated before)
cache <- F

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

# file dependencies ----

source('./utils.R')
source("./dplyr_verbs.R")
