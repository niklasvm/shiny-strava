activityMapUI <- function(id) {
  ns <- NS(id)
  
  fluidPage(
    fluidRow(
      column(
        6,shiny::selectInput(ns('selected_anchor'),label='Location anchor',multiple=F,choices=c(''),width = '50%')
      ),
      column(
        6,shiny::numericInput(ns('selected_radius'),'Radius (m)',min=0,max=Inf,step=1000,value=100000,width = '50%')
      )
    ),
    fluidRow(
      leafletOutput(ns('leaflet_plot'))
    )
  )
}

activityMap <- function(input,output,session,activities) {
  
  # update select input
  observe({
    anchors <- activities() %>% arrange(desc(start_date)) %>% pull(title)
    
    updateSelectInput(
      session=session,
      inputId='selected_anchor',
      choices=anchors,
      selected=anchors[1]
    )
  })
  
  output$leaflet_plot <- renderLeaflet({
    # reference activities input
    activities <- activities()
    
    location_anchor <- activities %>% filter(title==input$selected_anchor)
    radius_filter <- input$selected_radius
    
    # remove activities with no polyline
    activities <- activities %>% 
      filter(!is.na(map.summary_polyline))
    
    # filter by radius
    activities <- activities %>% 
      filter_within_radius(
        lon=location_anchor$start_longitude[1],
        lat=location_anchor$start_latitude[1],
        radius=radius_filter
      )
    
    # plot
    activities %>% 
      get_leaflet_heat_map(
        colour='red',
        weight = 2,
        opacity=0.01,
        markers = T
      )
  })
  
}