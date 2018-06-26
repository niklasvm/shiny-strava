message('server.R sourced')
source('global.R')

shinyServer(
  function(input, output,session) {
    

    # APPLICATION AUTHENTICATION --------------------------------------------------------------------
    
    get_shiny_url <- reactive({
      
      app_url <- paste0(session$clientData$url_protocol,
                        "//",
                        session$clientData$url_hostname, 
                        ifelse(
                          session$clientData$url_hostname %in% c("127.0.0.1",'192.168.99.100'), 
                          ":",
                          session$clientData$url_pathname
                        ),
                        session$clientData$url_port
      )
      
      return(app_url)
    })
    
    # generate authentication link as set out at https://developers.strava.com/docs/authentication/
    get_authorisation_url <- reactive({
      client_id <- Sys.getenv('strava_app_client_id')
      redirect_uri <- Sys.getenv('strava_app_url')
      glue('https://www.strava.com/oauth/authorize?client_id={client_id}&response_type=code&redirect_uri={redirect_uri}&approval_prompt=auto&state=')
     
    })
    
    # parse authentication code from current url if available
    get_authorisation_code <- reactive({
      pars <- parseQueryString(session$clientData$url_search)
      
      if (length(pars) > 0) {
        if (!is.null(pars$code)) {
          return(pars$code)
        } else {
          return(NULL)
        }  
      } else {
        return(NULL)
      }
    })
    
    # post auhtorisation code with client id and client secret to get user data
    post_authorisation_code <- reactive({
      authorisation_code <- get_authorisation_code()
      
      validate(
        shiny::need(!is.null(authorisation_code),message = 'You need to authenticate')  
      )
      
      message(glue('Using authorisation code: {authorisation_code}'))
      if (!is.null(authorisation_code)) {

        response <- POST(url = 'https://www.strava.com/oauth/token',
                         body = list(
                           client_id = Sys.getenv('strava_app_client_id'),
                           client_secret = Sys.getenv('strava_app_secret'),
                           code = authorisation_code
                         )
        )
        return(content(response))  
      }
      
    })
    
    # Get stoken using client id and secret
    get_stoken <- reactive({
      cache_file <- '.stoken'
      
      if (file.exists(cache_file)) {
        stoken <- readRDS(cache_file)
      } else {
        token_data <- post_authorisation_code()
        accesstoken <- token_data$access_token
        if (!is.null(accesstoken)) {
          stoken <- add_headers(Authorization = paste0("Bearer ",accesstoken))
          saveRDS(stoken,cache_file)
          return(stoken)
        } else {
          return(NULL)
        }
      }
    })
    
    output$authUI <- renderUI({
      if (is.null(get_authorisation_code())) {
        a('Click to authorise Strava Access',href=get_authorisation_url())
      }
    })
    
    
    
    output$activity_table <- renderDataTable({
      stoken <- get_stoken()
      
      message('Downloading activities...')
      my_acts <- get_activity_list(stoken)
      my_acts.df <- compile_activities(my_acts, acts = NULL, units = "metric")
      my_acts.df
    })
    
    # # Download data
    # output$downloadData <- downloadHandler(
    #   filename = function() {
    #     paste('StravaActivities-', Sys.Date(), '.csv', sep='')
    #   },
    #   content = function(con) {
    #     # get and save all activities
    #     my_acts <- get_activity_list(get_stoken())
    #     
    #     # Convert activities list to data frame
    #     my_acts.df <- compile_activities(my_acts, acts = NULL, units = "metric")
    #     
    #     write.csv(my_acts.df, con, row.names = FALSE)
    #   }
    # )
  }
)
