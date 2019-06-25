library( shiny )
library( data.table )

RawData <- readRDS( "RawDataLongWPop.dat" )
RawData$None <- "None"
RawData$SexNum <- ifelse( RawData$Sex=="Férfi", 1, 2 )
RawData$SexAge <- interaction( RawData$Sex, RawData$Age, sep = " - " )
ICDs <- readRDS( "ICDs.dat" )
StdPops <- readRDS( "StdPops.dat" )
MapHunNUTS3 <- readRDS( "MapHunNUTS3.dat" )

binomCI <- function( x, n, conf.level, groups, mult = 100000 ) {
  list( IncCIlwr = ifelse( x == 0, 0, qbeta( (1 - conf.level)/2, x, n - x + 1 ) )*mult,
        IncCIupr = ifelse( x == n, 1, qbeta( 1 - (1 - conf.level)/2, x + 1, n - x ) )*mult,
        Inc = x/n*mult, groups = groups )
}

ui <- fluidPage(
  theme = "owntheme.css",
  
  tags$head( 
    tags$meta( name = "description", content = paste0( "A magyar Rákregiszter adatait feldolgozó, azokat kényelmesen ",
                                                       "használhatóvá tevő, vizualizáló alkalmazás. ",
                                                       "Írta: Ferenci Tamás." ) ),
    tags$meta( property = "og:title", content = "Rákregiszter vizualizátor" ),
    tags$meta( property = "og:type", content = "website" ),
    tags$meta( property = "og:locale", content = "hu_HU" ),
    tags$meta( property = "og:url",
               content = "http://research.physcon.uni-obuda.hu/RakregiszterVizualizator/" ),
    tags$meta( property = "og:image",
               content = "http://research.physcon.uni-obuda.hu/RakregiszterVizualizator_Pelda.png" ),
    tags$meta( property = "og:description", content = paste0( "A magyar Rákregiszter adatait feldolgozó, azokat kényelmesen ",
                                                              "használhatóvá tevő, vizualizáló alkalmazás. ",
                                                              "Írta: Ferenci Tamás." ) ),
    tags$meta( name = "DC.Title", content = "Rákregiszter vizualizátor" ),
    tags$meta( name = "DC.Creator", content = "Ferenci Tamás" ),
    tags$meta( name = "DC.Subject", content = "rákepidemiológia" ),
    tags$meta( name = "DC.Description", content = paste0( "A magyar Rákregiszter adatait feldolgozó, azokat kényelmesen ",
                                                          "használhatóvá tevő, vizualizáló alkalmazás. " ) ),
    tags$meta( name = "DC.Publisher",
               content = "http://research.physcon.uni-obuda.hu/RakregiszterVizualizator/" ),
    tags$meta( name = "DC.Contributor", content = "Ferenci Tamás" ),
    tags$meta( name = "DC.Language", content = "hu_HU" )
  ),
  
  tags$div( id="fb-root" ),
  tags$script( HTML( "(function(d, s, id) {
                     var js, fjs = d.getElementsByTagName(s)[0];
                     if (d.getElementById(id)) return;
                     js = d.createElement(s); js.id = id;
                     js.src = 'https://connect.facebook.net/hu_HU/sdk.js#xfbml=1&version=v2.12';
                     fjs.parentNode.insertBefore(js, fjs);
                     }(document, 'script', 'facebook-jssdk'));" ) ),
  
  tags$style( ".shiny-file-input-progress {display: none}" ),
  
  titlePanel( "Rákregiszter vizualizátor" ),
  
  p( "A program használatát részletesen bemutató súgó, valamint a technikai részletek",
     a( "itt", href = "https://github.com/tamas-ferenci/RakregiszterVizualizator",
        target = "_blank" ), "olvashatóak el." ),
  div( class="fb-like",
       "data-href"="http://research.physcon.uni-obuda.hu/RakregiszterVizualizator/",
       "data-layout"="standard", "data-action"="like", "data-size"="small",
       "data-show-faces"="true", "data-share"="true"), p(),
  
  sidebarLayout(
    
    sidebarPanel(
      
      tags$head( tags$style( "#myplot{height:100vh !important;}" ) ),
      
      radioButtons( "Mod", "Üzemmód", c( "Vizualizáció", "Modellezés" ) ),
      
      conditionalPanel( "input.Mod=='Vizualizáció'",
                        
                        h3( "Vizualizáció" ),
                        selectInput( "Feladat", "Feladat", c( "Kor- és/vagy nemspecifikus incidencia",
                                                              "Kor- és/vagy nemspecifikus incidencia alakulása időben",
                                                              "Nyers incidencia alakulása időben",
                                                              "Standardizált incidencia alakulása időben",
                                                              "Megyénkénti nyers incidenciák",
                                                              "Megyénkénti standardizált incidenciák" ) ),
                        uiOutput( "SubtaskUI" ),
                        uiOutput( "StratificationUI" ),
                        uiOutput( "StandardUI" ),
                        selectInput( "Diagnozis", "Diagnózis", paste0( ICDs$ICDCode, " - ", ICDs$ICDName ) ),
                        uiOutput( "YearSelect" ),
                        uiOutput( "CountySelect" ),
                        downloadButton( "AbraLetoltesPDF", "Az ábra letöltése (PDF)" ),
                        downloadButton( "AbraLetoltesPNG", "Az ábra letöltése (PNG)" ),
                        checkboxInput( "Advanced", "Haladó beállítások megjelenítése" ),
                        conditionalPanel( "input.Advanced",
                                          uiOutput( "CIout" ),
                                          fluidRow( column( 6, uiOutput( "CIconfout" ) ), column( 6, uiOutput( "CIstylout" ) ) ),
                                          uiOutput( "VerticalAxisLogarithmic" ),
                                          checkboxInput( "ManualVerticalAxisScale",  "Függőleges tengely kézi skálázása"  ),
                                          fluidRow( column( 6, uiOutput( "VerticalAxisScaleMinOut" ) ),
                                                    column( 6, uiOutput( "VerticalAxisScaleMaxOut" ) ) ),
                                          fluidRow( column( 6, numericInput( "PngWidth", "PNG fájl szélessége (pixelben):",
                                                                             3600, 1, 4800, 1 ) ),
                                                    column( 6, numericInput( "PngHeight", "PNG fájl magassága (pixelben):",
                                                                             2400, 1, 4800, 1 ) ) ) )
      ),
      
      conditionalPanel( "input.Mod=='Modellezés'",
                        
                        h3( "Modellezés" ),
                        selectInput( "ICDModel", "Diagnózis", paste0( ICDs$ICDCode, " - ", ICDs$ICDName ) ),
                        selectInput( "YearModel", "Év függvényformája", c( "Lineáris", "Spline", "Nem-paraméteres" ) ),
                        selectInput( "AgeModel", "Kor függvényformája", c( "Lineáris", "Spline", "Nem-paraméteres" ) ),
                        selectInput( "CountyModel", "Megye függvényformája", c( "Maradjon ki", "Nem-paraméteres" ) )
                        
      )
      
    ),
    
    mainPanel(
      plotOutput( "EredmenyPlot" )
    )
  ),
  
  h4( "Írta: Ferenci Tamás (Óbudai Egyetem, Élettani Szabályozások Kutatóközpont), v2.11" ),
  
  tags$script( HTML( "var sc_project=11601191; 
                     var sc_invisible=1; 
                     var sc_security=\"5a06c22d\";
                     var scJsHost = ((\"https:\" == document.location.protocol) ?
                     \"https://secure.\" : \"http://www.\");
                     document.write(\"<sc\"+\"ript type='text/javascript' src='\" +
                     scJsHost+
                     \"statcounter.com/counter/counter.js'></\"+\"script>\");" ),
               type = "text/javascript" )
  
)

server <- function( input, output, session ) {
  
  MapTask <- c( "Megyénkénti nyers incidenciák", "Megyénkénti standardizált incidenciák" )
  
  observe({
    if( !input$Feladat%in%MapTask ) {
      updateCheckboxInput( session, "ManualVerticalAxisScale", "Függőleges tengely kézi skálázása" )
    } else {
      updateCheckboxInput( session, "ManualVerticalAxisScale", "Színtengely kézi skálázása" )
    }
  })
  
  plotInput <- function() {
    
    if( !is.null( input$Year )&!is.null( input$County )&!is.null( input$Subtask )&
        ( !is.null( input$Standard )|input$Feladat!="Standardizált incidencia alakulása időben" ) ) {
      if( input$Mod=="Vizualizáció" ) {
        
        ev <- if( input$Year=="Összes"|input$Stratification=="Évente" ) unique( RawData$Year ) else input$Year
        megye <- if( input$County=="Összes"|input$Stratification=="Megyénként" ) unique( RawData$County ) else input$County
        dg <- substring( input$Diagnozis, 1, 3 )
        
        PlotFormula <- if( !is.null( input$CI )&&input$CI ) {
          if( input$VerticalAxisLogarithmic ) "Hmisc::Cbind( Inc, log10(IncCIlwr), log10(IncCIupr) ) ~ " else
            "Hmisc::Cbind( Inc, IncCIlwr, IncCIupr ) ~ "
        } else "Inc ~ "
        
        if( input$Feladat%in%c( "Kor- és/vagy nemspecifikus incidencia",
                                "Kor- és/vagy nemspecifikus incidencia alakulása időben") ) {
          MainLab <- input$Subtask
        } else {
          MainLab <- input$Feladat
        }
        MainLab <- paste0( MainLab,"\n(Diagnózis: ", dg, ", Megye: ",
                           if( input$County=="Összes"|input$Stratification=="Megyénként" )
                             "összes megye" else input$County, ", Év: ",
                           if( input$Year=="Összes"|input$Stratification=="Évente" )
                             paste( range( ev ), collapse = "-" ) else input$Year )
        
        if( input$Feladat=="Kor- és/vagy nemspecifikus incidencia" ) {
          
          PlotFormula <- paste0( PlotFormula, if( input$Subtask=="Nemspecifikus incidencia") "SexNum" else "Age" )
          
          if( input$Subtask=="Kor- és nemspecifikus incidencia" ) {
            groupvar <- "Sex"
            byvars <- c( "None", "Sex", "SexNum", "Age" )
          } else if( input$Subtask== "Korspecifikus incidencia" ) {
            groupvar <- "None"
            byvars <- c( "None", "Age" )
          } else {
            groupvar <- "None"
            byvars <- c( "None", "Sex", "SexNum" )
          }
          
          if( input$Stratification=="Évente" ) {
            PlotFormula <- paste0( PlotFormula, " | as.factor( Year ) " )
            byvars <- c( byvars, "Year" )
          } else if( input$Stratification=="Megyénként" ) {
            PlotFormula <- paste0( PlotFormula, " | County " )
            byvars <- c( byvars, "County" )
          }
          
          MainLab <- paste0( MainLab, ")" )
          
          pars <- list( formula = as.formula( PlotFormula ), groups = as.name( "groups" ),
                        ylab = "Incidencia [/év/100 ezer fő]",
                        xlab = if( input$Subtask!="Nemspecifikus incidencia" ) "Életkor [év]" else "Nem",
                        data = RawData[ ICDCode==dg&Year%in%ev&County%in%megye,
                                        binomCI( sum( N ), sum( Population ), input$CIconf/100,
                                                 eval( parse( text = groupvar ) ) ), by = byvars ],
                        label.curves = FALSE,
                        method = if( is.null( input$CIstyle )||input$CIstyle=="Sávok" ) "bars" else "filled bands",
                        col.fill = scales::alpha( lattice::trellis.par.get()$superpose.line$col, 0.5 ),
                        main = MainLab, type = if( input$Subtask!="Nemspecifikus incidencia" ) "l" else "p" )
          
          if( input$Subtask=="Kor- és nemspecifikus incidencia" ) {
            pars <- c( pars, auto.key = list( list( points = FALSE, lines = TRUE, columns = 2 ) ) )
          }
          
        } else if( input$Feladat=="Kor- és/vagy nemspecifikus incidencia alakulása időben" ) {
          
          PlotFormula <- paste0( PlotFormula, "Year" )
          
          if( input$Subtask=="Kor- és nemspecifikus incidencia" ) {
            groupvar <- "SexAge"
            byvars <- c( "None", "Year", "SexAge" )
          } else if( input$Subtask== "Korspecifikus incidencia" ) {
            groupvar <- "Age"
            byvars <- c( "None", "Year", "Age" )
          } else {
            groupvar <- "Sex"
            byvars <- c( "None", "Year", "Sex" )
          }
          
          MainLab <- paste0( MainLab, ")" )
          
          pars <- list( formula = as.formula( PlotFormula ), groups = as.name( "groups" ),
                        ylab = "Incidencia [/év/100 ezer fő]", xlab = "Év",
                        data = RawData[ ICDCode==dg,
                                        binomCI( sum( N ), sum( Population ), input$CIconf/100,
                                                 eval( parse( text = groupvar ) ) ), by = byvars ],
                        label.curves = TRUE,
                        method = if( is.null( input$CIstyle )||input$CIstyle=="Sávok" ) "bars" else "filled bands",
                        col.fill = scales::alpha( lattice::trellis.par.get()$superpose.line$col, 0.5 ),
                        main = MainLab, type = "l" )
          ### TODO: megyénkénti bontás
          
        } else if( input$Feladat=="Nyers incidencia alakulása időben" ) {
          PlotFormula <- paste0( PlotFormula, "Year" )
          MainLab <- paste0( MainLab, ")" )
          pars <- list( formula = as.formula( PlotFormula ), ylab = "Incidencia [/év/100 ezer fő]", xlab = "Év", type = "b",
                        data = RawData[ ICDCode==dg, binomCI( sum( N ), sum( Population ), input$CIconf/100, "None" ),
                                        .( Year ) ],
                        method = if( is.null( input$CIstyle )||input$CIstyle=="Sávok" ) "bars" else "filled bands",
                        col.fill = scales::alpha( lattice::trellis.par.get()$superpose.line$col, 0.5 ),
                        main = MainLab )
          ### TODO: megyénkénti bontás (többféleképp)
        } else if( input$Feladat=="Standardizált incidencia alakulása időben" ) {
          PlotFormula <- paste0( PlotFormula, "Year" )
          MainLab <- paste0( MainLab, ", Standard: ", input$Standard, ")" )
          pars <- list( formula = as.formula( PlotFormula ), ylab = "Incidencia [/év/100 ezer fő]", xlab = "Év", type = "b",
                        data = merge( StdPops,
                                      RawData[ ICDCode==dg, .( N = sum( N ), Population = sum( Population ) ),
                                               .( Age, Sex, Year ) ], by = c( "Age", "Sex" ) )[
                                                 , as.list( epitools::ageadjust.direct(
                                                   N, Population, stdpop = eval( parse( text = input$Standard ) ) ) *100000 ),
                                                 .( Year ) ][ , .( Year = Year, Inc = adj.rate, IncCIlwr = lci,
                                                                   IncCIupr = uci ) ],
                        method = if( is.null( input$CIstyle )||input$CIstyle=="Sávok" ) "bars" else "filled bands",
                        col.fill = scales::alpha( lattice::trellis.par.get()$superpose.line$col, 0.5 ),
                        main = MainLab )
          ### TODO: A standard nevét is kiírni a címben
        } else if( input$Feladat=="Megyénkénti nyers incidenciák"  ) {
          MainLab <- paste0( MainLab, ")" )
          pars <- list( obj = sp::merge( MapHunNUTS3, RawData[ ICDCode==dg&Year%in%ev, .(
            Incidence = sum( N )/sum( Population )*100000 ), .( NAME = County ) ] ), zcol = "Incidence",
            cuts = 999, col.regions = colorRampPalette( c( "green", "red" ) )( 1000 ),
            main = MainLab )
        } else if( input$Feladat=="Megyénkénti standardizált incidenciák"&&!is.null( input$Standard ) ) {
          MainLab <- paste0( MainLab, ")" )
          pars <- list( obj = sp::merge( MapHunNUTS3,
                                         merge( StdPops, RawData[ ICDCode==dg&Year%in%ev,
                                                                  .( N = sum( N ), Population = sum( Population ) ),
                                                                  .( Age, Sex, County ) ],
                                                by = c( "Age", "Sex" ) )[
                                                  , .( Incidence = epitools::ageadjust.direct(
                                                    N, Population, stdpop = eval( parse( text = input$Standard ) ) )[
                                                      "adj.rate" ]*100000 ), .( NAME = County ) ] ),
                        zcol = "Incidence", cuts = 999, col.regions = colorRampPalette( c( "green", "red" ) )( 1000 ),
                        main = MainLab )
        }
        
        if( !input$Feladat%in%MapTask ) {
          if( input$ManualVerticalAxisScale ) {
            ran <- c( input$VerticalAxisScaleMin, input$VerticalAxisScaleMax )
          } else {
            ran <- extendrange( r = range( if( !is.null( input$CI )&&input$CI )
              c( pars$data$IncCIlwr, pars$data$IncCIupr ) else pars$data$Inc ) )
          }
          if( input$VerticalAxisLogarithmic ) {
            if( ran[1]<1 ) ran[1] <- 1
            if( input$Feladat=="Kor- és/vagy nemspecifikus incidencia"&&input$Subtask=="Nemspecifikus incidencia" ) {
              pars <- c( pars, list( xlim = c( 0.5, 2.5 ), pch = 19, cex = 1.5,
                                     scales = list( x = list( at = 1:2, labels = c( "Férfi", "Nő" ) ),
                                                    y = list( log = 10, at = axisTicks( log10( ran ), log = TRUE ) ) ) ) )
            } else {
              pars <- c( pars, list( scales = list( y = list( log = 10, at = axisTicks( log10( ran ), log = TRUE ) ) ) ) )
            }
          } else {
            if( input$Feladat=="Kor- és/vagy nemspecifikus incidencia"&&input$Subtask=="Nemspecifikus incidencia" ) {
              pars <- c( pars, list( xlim = c( 0.5, 2.5 ), pch = 19, cex = 1.5,
                                     scales = list( x = list( at = 1:2, labels = c( "Férfi", "Nő" ) ) ) ) )
            }
          }
          pars <- c( pars, ylim = list( ran ) )
        } else {
          if( input$ManualVerticalAxisScale&!is.null( input$VerticalAxisScaleMin )&!is.null( input$VerticalAxisScaleMax ) ) {
            pars <- c( pars, list( colorkey = list( at = input$VerticalAxisScaleMin:input$VerticalAxisScaleMax ) ),
                       at = list( input$VerticalAxisScaleMin:input$VerticalAxisScaleMax ) )
          } 
        }
        
        print( do.call( if( !input$Feladat%in%MapTask ) Hmisc::xYplot else sp::spplot, pars ) )
        
        grid::grid.text( "Ferenci Tamás, 2019", 0, 0.02, gp = grid::gpar( fontface = "bold" ), just = "left" )
        grid::grid.text( "http://research.physcon.", 1, 0.05, gp = grid::gpar( fontface = "bold" ), just = "right" )
        grid::grid.text( "uni-obuda.hu", 1, 0.02, gp = grid::gpar( fontface = "bold" ), just = "right" )
        
      } else {
        
        ICD <- substring( input$ICDModel, 1, 3 )
        RawDataModel <- RawData[ ICDCode==ICD ]
        ModelFormula <- "N ~ "
        
        if( input$YearModel=="Nem-paraméteres" ) {
          ModelFormula <- c( ModelFormula, "Year + ")
          RawDataModel$Year <- factor( RawDataModel$Year )
        } else if( input$YearModel=="Spline" ) {
          ModelFormula <- c( ModelFormula, "rms::rcs( Year ) + " )
        } else {
          ModelFormula <- c( ModelFormula, "Year + " )
        }
        
        if( input$AgeModel=="Nem-paraméteres" ) {
          ModelFormula <- c( ModelFormula, "Age*Sex")
          RawDataModel$Age <- as.factor( RawDataModel$Age )
        } else if( input$AgeModel=="Spline" ) {
          ModelFormula <- c( ModelFormula, "rms::rcs( Age )*Sex" )
        } else {
          ModelFormula <- c( ModelFormula, "Age*Sex" )
        }
        
        if( input$CountyModel=="Nem-paraméteres" ) {
          ModelFormula <- c( ModelFormula, " + County" )
        }
        
        dd <<- rms::datadist( RawDataModel )
        options( datadist = "dd" )
        
        fit <- rms::Glm( as.formula( paste( ModelFormula, collapse = "" ) ), offset = log( Population ),
                    data = RawDataModel, family = poisson )
        
        if( input$CountyModel!="Nem-paraméteres" ) {
          p1 <- plot( rms::Predict( fit, Age, Sex ), anova = anova( fit ), pval = TRUE )
          p2 <- plot( rms::Predict( fit, Year ), anova = anova( fit ), pval = TRUE )
          gridExtra::grid.arrange( p1, p2, ncol = 2, heights = grid::unit( 0.9, "npc" ) )
        } else {
          p1 <- plot( rms::Predict( fit, Age, Sex ), anova = anova( fit ), pval = TRUE )
          p2 <- plot( rms::Predict( fit, Year ), anova = anova( fit ), pval = TRUE )
          p3 <- sp::spplot( sp::merge( MapHunNUTS3, data.table( Predict( fit, County ) )[ , .( NAME = County, yhat ) ] ),
                            "yhat", cuts = 999, col.regions = colorRampPalette( c( "green", "red" ) )( 1000 ) )
          gridExtra::grid.arrange( p1, p2, p3, layout_matrix = rbind( c( 1, 2 ), c( 3, 3 ) ) )
        }
        grid::grid.text( "Ferenci Tamás, 2019", 0, 0.02, gp = grid::gpar( fontface = "bold" ), just = "left" )
        grid::grid.text( "http://research.physcon.", 1, 0.05, gp = grid::gpar( fontface = "bold" ), just = "right" )
        grid::grid.text( "uni-obuda.hu", 1, 0.02, gp = grid::gpar( fontface = "bold" ), just = "right" )
      }
    }
  }
  
  output$EredmenyPlot <- renderPlot( {
    print( plotInput() )
  } )
  
  output$AbraLetoltesPDF <- downloadHandler(
    filename = "RakregiszterVizualizatorPlot.pdf",
    content = function( file ) {
      cairo_pdf( file, width = 9, height = 8 )
      print( plotInput() )
      dev.off( )
    } )
  
  output$AbraLetoltesPNG <- downloadHandler(
    filename = "RakregiszterVizualizatorPlot.png",
    content = function( file ) {
      png( file, width = input$PngWidth, height = input$PngHeight,
           res = 72*min( c( input$PngWidth, input$PngHeight ) )/480, type = "cairo-png" )
      print( plotInput() )
      dev.off( )
    } )
  
  output$SubtaskUI <- renderUI( if( input$Feladat%in%c( "Kor- és/vagy nemspecifikus incidencia",
                                                        "Kor- és/vagy nemspecifikus incidencia alakulása időben" ) )
    selectInput( "Subtask", "Alfeladat", c( "Kor- és nemspecifikus incidencia",
                                            "Korspecifikus incidencia",
                                            "Nemspecifikus incidencia" ) ) else NULL )
  
  output$StratificationUI <- renderUI( if( input$Feladat=="Kor- és/vagy nemspecifikus incidencia" )
    selectInput( "Stratification", "Lebontás", c( "Nincs", "Évente", "Megyénként" ) ) else NULL )
  
  output$StandardUI <- renderUI( if( input$Feladat%in%c( "Standardizált incidencia alakulása időben",
                                                         "Megyénkénti standardizált incidenciák" ) )
    selectInput( "Standard", "Standard", c( "Segi-Doll (1960)" = "StdSegiDoll1960",
                                            "ESP (2013)" = "StdESP2013",
                                            "WHO (2001)" = "StdWHO2001",
                                            "Magyar (2001-2015)" = "StdHUN" ) ) else NULL )
  
  output$CIout <- renderUI( if( !input$Feladat%in%MapTask )
    checkboxInput( "CI", "Konfidenciaintervallum" ) else NULL )
  
  output$CIconfout <- renderUI( if( !is.null( input$CI )&&!input$Feladat%in%MapTask&&input$CI )
    numericInput( "CIconf", "Megbízhatósági szint [%]:", 95, min = 1, max = 99, step = 1 ) else NULL )
  
  output$CIstylout <- renderUI( if( !is.null( input$CI )&&!input$Feladat%in%MapTask&&input$CI )
    selectInput( "CIstyle", "Stílus", c( "Sávok", "Terület" ) ) else NULL )
  
  output$YearSelect <- renderUI( if( !is.null( input$Stratification )&&( 
    (input$Feladat=="Kor- és/vagy nemspecifikus incidencia"&&!input$Stratification=="Évente" ) )||(
      input$Feladat=="Megyénkénti nyers incidenciák")||(input$Feladat=="Megyénkénti standardizált incidenciák") ) {
    selectInput( "Year", "Év", c( "Összes", sort( unique( RawData$Year ) ) ) )
  } )
  
  output$CountySelect <- renderUI( if( !is.null( input$Stratification )&&
                                       input$Feladat=="Kor- és/vagy nemspecifikus incidencia"&&
                                       !input$Stratification=="Megyénként" ) {
    selectInput( "County", "Megye", c( "Összes", sort( unique( RawData$County ) ) ) )
  } )
  
  output$VerticalAxisLogarithmic <- renderUI( if( !input$Feladat%in%MapTask )
    checkboxInput( "VerticalAxisLogarithmic", "Függőleges tengely logaritmikus" ) else NULL )
  
  output$VerticalAxisScaleMinOut <- renderUI( if( input$ManualVerticalAxisScale )
    numericInput( "VerticalAxisScaleMin", "Minimum:", 10 ) else NULL )
  
  output$VerticalAxisScaleMaxOut <- renderUI( if( input$ManualVerticalAxisScale )
    numericInput( "VerticalAxisScaleMax", "Maximum:", 1000 ) else NULL )
  
}

shinyApp( ui = ui, server = server )