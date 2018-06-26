message('ui.R sourced')
source('global.R')


shinyUI(
  fluidPage(
    uiOutput('authUI'),
    br(),
    dataTableOutput('activity_table')
  )
)
