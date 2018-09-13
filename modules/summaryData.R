

plotSummaryDataHC <- function(data,
                              x,
                              y,
                              series_name=y,
                              title = 'Title',
                              chart_zoom = '',
                              y_title = '',
                              y_format = '{value}',
                              x_label_rotation = 0) {
  
  
  # aggregate data
  data <- data %>% 
    group_by(!!rlang::sym(x)) %>% 
    summarise_at(vars(distance,moving_time),sum) %>% 
    arrange(!!rlang::sym(x))
  
  # plot with highchart
  highchart() %>% 
    
    # chart level options
    hc_title(text=title) %>% 
    hc_chart(
      zoomType=chart_zoom
    ) %>% 
    
    # column data
    hc_add_series(
      name = series_name,
      data = data,
      type = 'column',
      hcaes(x = !!rlang::sym(x), y = !!rlang::sym(y))
    ) %>%
    
    # y axis
    hc_yAxis(
      title=list(
        text=y_title
      ),
      labels=list(
        format = y_format
      )
    ) %>% 
    
    # x axis
    hc_xAxis(
      type='datetime',
      align='center',
      dateTimeLabelFormats = list(
        day='%d %b',
        week='%Y-%m-%d',
        month='%b \'%y'
      ),
      labels=list(
        rotation = x_label_rotation
      )
    ) 
  
}

plotSummaryData <- function(data,x,y,title='',date_fmt='%Y-%m-%d',y_fmt=scales::comma) {
  data <- data %>% 
    group_by(!!rlang::sym(x)) %>% 
    summarise_at(vars(distance,moving_time),sum) %>% 
    arrange(!!rlang::sym(x)) %>% 
    mutate(formatted = strftime(!!rlang::sym(x),date_fmt)) %>% 
    mutate(formatted = fct_reorder(formatted,!!rlang::sym(x)))
  
  saveRDS(data,'./temp.rds')
  data %>% 
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
      #box(width=6,plotOutput(ns('summary_chart'))),
      box(width=12,highchartOutput(ns('summary_chart2')))
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
  # output$summary_chart <- renderPlot({
  #   
  #   if (input$type=='moving_time') {
  #     FUN <- format_time
  #   } else {
  #     FUN <- scales::comma
  #   }
  #   
  #   if (input$period == 'monthly') {
  #     activities() %>% 
  #       plotSummaryData(x = 'month_end',
  #                       y = input$type,
  #                       title = 'Monthly Distance',
  #                       date_fmt = '%b \'%y',
  #                       y_fmt = FUN
  #       )  
  #   } else if (input$period == 'weekly') {
  #     activities() %>% 
  #       plotSummaryData(x = 'week_end',
  #                       y = input$type,
  #                       title = 'Weekly Distance',
  #                       date_fmt = '%Y/%m/%d',
  #                       y_fmt = FUN
  #       )
  #   }
  #   
  #   
  # })
  
  output$summary_chart2 <- renderHighchart({
    # shiny::validate(
    #   shiny::need(!is.null(activities(),message='No activities'))
    # )
    
    if (input$type=='moving_time') {
      FUN <- format_time
    } else {
      FUN <- scales::comma
    }
    
    if (input$period == 'monthly') {
      activities() %>% 
        plotSummaryDataHC(x = 'month_start',
                          y = input$type,
                          series_name = 'Monthly Distance',
                          title = 'Monthly Distance',
                          chart_zoom = 'x',
                          x_label_rotation = -45,
                          y_format = '{value} km'
        )  
    } else if (input$period == 'weekly') {
      activities() %>% 
        plotSummaryDataHC(x = 'week_start',
                          y = input$type,
                          series_name = 'Weekly Distance',
                          title = 'Weekly Distance',
                          chart_zoom = 'x',
                          x_label_rotation = -45,
                          y_format = '{value} km'
        )
    }
    
    
  })
  
}


