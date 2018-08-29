library( data.table )

tab <- do.call( rbind, lapply( 2001:2015, function( year ) {
  print( year )
  
  res <- httr::POST( "http://www.onkol.hu/hu/rakregiszter-statisztika",
                     body = list( "diagkod[]" = "000", "eve[]" = year, "sex[]" = "0",
                                  "megye[]" = "00", "megyechk" = "1",
                                  "op" = "Szűrés", "form_id" = "nrr_stat" ) )
  res <- httr::content( res )
  
  ids <- rvest::html_text( rvest::html_nodes( res, xpath = '//div[@id="dialog"]/node()[not(self::div)]' ) )
  
  tab <- rvest::html_table( res )
  tab <- tab[ lapply( tab, ncol )==21 ]
  tab <- lapply( 1:length( tab ), function( i ) data.frame( tab[[ i ]], id = ids[ i ], stringsAsFactors = FALSE ) )
  tab <- do.call( rbind, tab )
  
  tab <- tab[ tab$Diagkod!="Összesen", ]
  tab <- tab[ , colnames( tab )!="Összesen" ]
  tab <- data.frame( tab, trimws( do.call( rbind, strsplit( tab$id, "," ) )[ , 1:3 ] ), stringsAsFactors = FALSE )
  tab <- tab[ , colnames( tab )!="id" ]
  
  tab
} ) )

names( tab ) <- c( "ICDCode", "ICDName", paste0( "Age", seq( 0, 85, 5 ) ), "Year", "County", "Sex" )
tab$ICDName <- enc2utf8( tab$ICDName )
tab$Sex <- enc2utf8( tab$Sex )
tab$Year <- as.numeric( tab$Year )
tab$County[ tab$County=="Györ-Moson-Sopron megye" ] <- "Győr-Moson-Sopron megye"
tab$County <- enc2utf8( tab$County )

write.csv2( tab, "RawDataWide.csv", row.names = FALSE )

saveRDS( unique( tab[ , 1:2 ] ), file = "ICDs.dat" )

tab <- tab[ , colnames( tab )!="ICDName" ]

tab <- reshape( tab, varying = paste0( "Age", seq( 0, 85, 5 ) ), v.names = "N", timevar = "Age",
                times = seq( 0, 85, 5 ), direction = "long" )
tab <- tab[ , colnames( tab )!="id" ]

write.csv2( tab, gzfile( "RawDataLong.csv.gz" ), row.names = FALSE )

tab <- tab[ tab$County!="Megyen kívüli", ]

PopPyramid <- KSHStatinfoScraper::GetPopulationPyramidKSH( Type = "MidYear", Years = 2001:2015,
                                                           AgeGroup = "FiveYear", GeographicArea = "NUTS3" )
names( PopPyramid ) <- c( "Year", "Sex", "Age", "County", "Population" )
PopPyramid <- PopPyramid[ !PopPyramid$County%in%c( "Az ország területre nem bontható adatai",
                                                   "Országhatáron kívüli tevékenység" ), ]
PopPyramid$Sex <- ifelse( PopPyramid$Sex=="Male", "Férfi", "Nő" )
write.csv2( PopPyramid, "PopPyramid.csv", row.names = FALSE )

tab <- data.table( tab )
PopPyramid <- data.table( PopPyramid )
tab <- merge( tab, PopPyramid )

write.csv2( tab, gzfile( "RawDataLongWPop.csv.gz" ), row.names = FALSE )
saveRDS( tab, file = "RawDataLongWPop.dat" )

StdPops <- fread( "StdPops18.csv" )
StdPops <- merge( StdPops, tab[ , .( StdHUN = sum( Population ) ), by = .( Sex, Age ) ] )

write.csv2( StdPops, "StdPops.csv", row.names = FALSE )
saveRDS( StdPops, file = "StdPops.dat" )

MapHunNUTS3 <- rgdal::readOGR( "OSM_kozighatarok", "admin6", encoding = "UTF8", use_iconv = TRUE, stringsAsFactors = FALSE )
MapHunNUTS3$NAME <- enc2utf8( MapHunNUTS3$NAME )
saveRDS( MapHunNUTS3, file = "MapHunNUTS3.dat" )
