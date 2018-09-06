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
library(shinyjs)
library(shinydashboard)
library(shinythemes)
library(logging)
library(googlePolylines)
library(shinyjs)
library(tidyquant)

# initialise logging ----
basicConfig()
dir.create('./logs/',showWarnings = F)
addHandler(writeToFile,file=glue('./logs/{strftime(Sys.time(),\'%Y%m%d-%H%M%S\')}.log'))
#addHandler(writeToConsole)

# file dependencies ----

loginfo('Load file depencencies',logger='authentication')
source('./utils.R')
source("./dplyr_verbs.R")
list.files('./modules/',recursive = T,full.names = T) %>% 
  walk(source)

# Application options ----

dir.create('cache',showWarnings = F)
cache <- F # whether to load cached data (must have authenticated before)

if (cache) {
  loginfo('Use cached credentials and data',logger='authentication')
}




# app misc ----
periods <- list(
  'This week' = c(floor_date(Sys.Date()-1,unit = 'week')+1,as.Date(strftime(Sys.Date(),'%Y-%m-%d'))),
  'Last 7 days' = c(Sys.Date()-6,Sys.Date()),
  'This month' = c(floor_date(Sys.Date(),unit = 'month'),as.Date(strftime(Sys.Date(),'%Y-%m-%d'))),
  'Last 30 days' = c(Sys.Date()-29,Sys.Date()),
  'This year' = c(floor_date(Sys.Date(),unit = 'year'),Sys.Date()),
  'Last week' = c(floor_date(Sys.Date()-1-7,unit = 'week')+1,floor_date(Sys.Date()-1,unit = 'week')),
  'Last month' = c(floor_date(Sys.Date(),unit = 'month') - months(1),floor_date(Sys.Date(),'month')-1),
  'Custom' = c(floor_date(Sys.Date()-1,unit = 'week')+1,as.Date(strftime(Sys.Date(),'%Y-%m-%d')))
)
