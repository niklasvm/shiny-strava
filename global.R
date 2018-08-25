# global.R is sourced when the application is lauched

# dependencies
library(shiny)
library(rStrava)
library(tidyverse)
library(lubridate)
library(httr)
library(jsonlite)
library(glue)
library(DT)
library(leaflet)
library(shinydashboard)
library(shinythemes)
library(logging)

# initialise logging ----
basicConfig()
dir.create('./logs/',showWarnings = F)
addHandler(writeToFile,file=glue('./logs/{strftime(Sys.time(),\'%Y%m%d-%H%M%S\')}.log'))

# Load credentials if available ----

# the following environment variables must be set in credentials.R
# Sys.setenv(
#   strava_app_client_id  = 'xxxx',
#   strava_app_secret = 'xxxx'
# )

if (file.exists('./credentials.R')) source('./credentials.R')
  



# Application options ----

# check if api credentials need to be captured from the user
if (Sys.getenv('strava_app_client_id')=='' & Sys.getenv('strava_app_secret') == '') {
  
  loginfo('No credentials found in environment, displaying api credentials form',logger = 'authentication')
  ask_api_credentials <- T 

} else {
  loginfo('Credentials loaded',logger = 'authentication')
  ask_api_credentials <- F
}

# capture application url if not already set
if (Sys.getenv('strava_app_url') =='') {
  strava_app_url  <-  glue('http://127.0.0.1:1234')
  Sys.setenv(strava_app_url = strava_app_url) # set as environment variable
}
loginfo(glue('Set strava app url to {strava_app_url}'),logger = 'authentication')

cache <- F # whether to load cached data (must have authenticated before)

if (cache) {
  loginfo('Use cached credentials and data',logger='authentication')
}

# file dependencies ----

loginfo('Load file depencencies',logger='authentication')
source('./utils.R')
source("./dplyr_verbs.R")


# app misc ----
periods <- list(
  'This week' = c(floor_date(Sys.Date()-1,unit = 'week')+1,as.Date(strftime(Sys.Date(),'%Y-%m-%d'))),
  'Last 7 days' = c(Sys.Date()-6,Sys.Date()),
  'This month' = c(floor_date(Sys.Date(),unit = 'month'),as.Date(strftime(Sys.Date(),'%Y-%m-%d'))),
  'This year' = c(floor_date(Sys.Date(),unit = 'year'),Sys.Date()),
  'Last week' = c(floor_date(Sys.Date()-1-7,unit = 'week')+1,floor_date(Sys.Date()-1,unit = 'week')),
  'Last month' = c(floor_date(Sys.Date(),unit = 'month') - months(1),floor_date(Sys.Date(),'month')-1)
)
