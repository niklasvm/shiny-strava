daytimeHeatmapUI <- function(id) {
  ns <- NS(id)
  fluidPage(
    fluidRow(
      column(12,plotOutput(ns('plot')))
    )
  )
}

daytimeHeatmap <- function(input, output, session, activities) {
  
  output$plot <- renderPlot({
    activities <- activities()
    
    activities <- activities %>% 
      mutate(day=factor(weekdays(start_date_local),levels=c('Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday'),ordered=T)) %>% 
      mutate(hour=hour(start_date_local)) %>% 
      mutate(year=year(start_date_local))
    
    activities %>% 
      group_by(
        day,
        hour
      ) %>% 
      mutate(distance=mean(distance)) %>% 
      ungroup() %>% 
      mutate(day=fct_rev(day)) %>% 
      ggplot(aes(x=hour,y=day,fill=distance))+
      geom_tile()+
      scale_fill_viridis_c()+
      scale_x_continuous(breaks=1:24)+
      theme_minimal()+
      # font sizes
      theme(
        plot.title = element_text(size = 16, face = 'bold'),
        axis.text = element_text(size=14, face = 'bold'),
        axis.title = element_text(size = 14, face = 'bold'),
        panel.grid = element_blank()
      )+
      labs(x='Hour',y='Day of week')
    
  })  
}
