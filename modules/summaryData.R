plotSummaryData <- function(data,x,y,title='',date_fmt='%Y-%m-%d',y_fmt=scales::comma) {
  data %>% 
    group_by(!!rlang::sym(x)) %>% 
    summarise_at(vars(distance,moving_time),sum) %>% 
    arrange(!!rlang::sym(x)) %>% 
    mutate(formatted = strftime(!!rlang::sym(x),date_fmt)) %>% 
    mutate(formatted = fct_reorder(formatted,!!rlang::sym(x))) %>% 
    ggplot(aes_string(x='formatted',y=y))+
    geom_bar(stat='identity',fill=palette_dark()[1])+
    scale_y_continuous(labels = y_fmt)+
    labs(title=title,x='')+
    theme_minimal()+
    # font sizes
    theme(
      plot.title = element_text(size = 16, face = 'bold'),
      axis.text = element_text(size=14, face = 'bold'),
      axis.title = element_text(size = 14, face = 'bold')
    )+
    theme(
      axis.text.x=element_text(angle=90,vjust=0.5)
    )
}

summaryDataUI <- function(id) {
  ns <- NS(id)
  fluidPage(
    fluidRow(

      column(6,selectInput(ns('type'),label = 'Type',choices = c('distance','moving_time'),selected = 'distance')),
      
      column(6,selectInput(ns('period'),label='Period',choices=c('weekly','monthly'),selected = 'weekly'))
    ),
    
    fluidRow(
      plotOutput(ns('summary_chart'))  
    )
    
  )
  
}

x <- 86000
format_time <- function(x) {
  x %>% 
    seconds_to_period() %>% 
    as.period('hour') %>% 
    parse_time('%HH %MM %SS')
}

summaryData <- function(input, output, session, activities) {
  
  output$summary_chart <- renderPlot({
    
    if (input$type=='moving_time') {
      FUN <- format_time
    } else {
      FUN <- scales::comma
    }
    
    if (input$period == 'monthly') {
      activities() %>% 
        plotSummaryData(x = 'month_end',
                        y = input$type,
                        title = 'Monthly Distance',
                        date_fmt = '%b \'%y',
                        y_fmt = FUN
        )  
    } else if (input$period == 'weekly') {
      activities() %>% 
        plotSummaryData(x = 'week_end',
                        y = input$type,
                        title = 'Weekly Distance',
                        date_fmt = '%Y/%m/%d',
                        y_fmt = FUN
        )
    }
    
    
  })
  
}