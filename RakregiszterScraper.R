library(data.table)
ftfy <- reticulate::import("ftfy") # https://github.com/rspeer/python-ftfy

years <- rvest::html_attr(rvest::html_elements(rvest::read_html("http://stat.nrr.hu/"),
                                               xpath = "//select[@id='edit-eve']/option"), "value")[-1]
counties <- rvest::html_text(rvest::html_elements(rvest::read_html("http://stat.nrr.hu/"),
                                                  xpath = "//select[@id='edit-megye']/option"), "value")[-1]
counties <- data.frame(do.call(rbind, strsplit(counties, " - ")))
colnames(counties) <- c("CountyNo", "County")
counties$CountyNo <- as.numeric(counties$CountyNo)
counties$County[counties$County=="Györ-Moson-Sopron megye"] <- "Győr-Moson-Sopron megye"
ICDs <- rvest::html_text(rvest::html_elements(rvest::read_html("http://stat.nrr.hu/"),
                                              xpath = "//select[@id='edit-diagkod']/option"), "value")[-1]
ICDs <- data.table(ICDCode = substring(ICDs, 1, 3), ICDName = substring(ICDs, 7, 41))
saveRDS(ICDs, file = "ICDs.rds")

tab <- rbindlist(lapply(years, function(year) {
  print(year)
  
  res <- httr::POST("http://stat.nrr.hu/",
                    body = list("diagkod[]" = "000", "eve[]" = year, "sex[]" = "0",
                                "megye[]" = "00", "megyechk" = "1", "op" = "Szűrés", "form_id" = "nrr_stat"))
  res <- httr::content(res)
  
  ids <- rvest::html_text(rvest::html_nodes(res, xpath = "//div[@id='dialog']/node()[not(self::div)]"))
  ids <- ids[grepl("Neme", ids)]
  
  tab <- rvest::html_table(res)
  tab <- tab[sapply(tab, ncol)==20]
  for(i in 1:length(tab)) {
    names(tab[[i]]) <- sapply(names(tab[[i]]), ftfy$fix_text)
    tab[[i]]$Diagkód <- sapply(iconv(tab[[i]]$Diagkód, "utf-8", "latin1", sub = ""), ftfy$fix_text)
  }
  tab <- rbindlist(lapply(1:length(tab), function(i) data.table(tab[[i]], id = ids[i])))
  
  tab <- tab[Diagkód!="Összesen", !"Összesen"]
  tab$Sex <- as.numeric(substr(tab$id, 8, 8))
  tab$CountyNo <- substr(tab$id, 19, 20)
  tab <- tab[!CountyNo%in%c("", "00")]
  tab$CountyNo <- as.numeric(tab$CountyNo)
  tab$Year <- year
  tab$ICDCode <- sapply(strsplit(tab$Diagkód, "-"), `[`, 1)
  tab <- merge(CJ(ICDCode = ICDs$ICDCode, Sex = 1:2, CountyNo = 1:20, Year = year), tab, all.x = TRUE)
  tab[is.na(Diagkód)][, 6:23] <- 0
  tab[, !c("Diagkód", "id")]
}))

colnames(tab)[grepl("-", colnames(tab))] <- paste0("Age", seq(0, 85, 5))
tab$Year <- as.numeric(tab$Year)
tab$Sex <- ifelse(tab$Sex==1, "Férfi", "Nő")
tab <- merge(tab, counties)
tab <- tab[, c("ICDCode", paste0("Age", seq(0, 85, 5)), "Year", "County", "Sex")]

write.csv2(tab, "RawDataWide.csv", row.names = FALSE)

tab <- melt(tab, id.vars = c("ICDCode", "Year", "County", "Sex"), variable.name = "Age", value.name = "N")
tab$Age <- as.numeric(substring(tab$Age, 4))

write.csv2(tab, gzfile("RawDataLong.csv.gz"), row.names = FALSE)

PopPyramid <- rbind(
  fread("Nepesseg_OtevesKor_Nemenkent_Megyenkent_1990_2016.csv", dec = ",", skip = 6, header = TRUE,
        check.names = TRUE),
  fread("Nepesseg_OtevesKor_Nemenkent_Megyenkent_2017_2019.csv", dec = ",", skip = 6, header = TRUE,
        check.names = TRUE)
)[, -7]
PopPyramid$Időszak[PopPyramid$Időszak==""] <- NA
PopPyramid$Nem[PopPyramid$Nem==""] <- NA
PopPyramid$Korév[PopPyramid$Korév==""] <- NA
PopPyramid <- tidyr::fill(PopPyramid, Időszak, Nem, Korév, Terület)
PopPyramid$Időszak <- as.numeric(substring(PopPyramid$Időszak, 1, 4))
PopPyramid$Korév <- as.numeric(substring(PopPyramid$Korév, 1, 2))
names(PopPyramid) <- c("Year", "Sex", "Age", "County", "PopJan1", "PopMidYear")
write.csv2(PopPyramid, "PopPyramid.csv", row.names = FALSE)
saveRDS(PopPyramid, "Nepesseg_OtevesKor_Nemenkent_Megyenkent_1990_2019.rds")

tab <- merge(tab, PopPyramid[, .(Year, Sex, Age, County, Population = PopMidYear)],
             by = c("County", "Sex", "Age", "Year"))

write.csv2(tab, gzfile("RawDataLongWPop.csv.gz"), row.names = FALSE)
saveRDS(tab, file = "RawDataLongWPop.rds")

StdPops <- fread("StdPops18.csv")
StdPops <- merge(StdPops, tab[, .(sum(Population)), .(Age, Sex)][, .(Age, StdHUN = V1/sum(V1)*1e6), .(Sex)])
write.csv2(StdPops, "StdPops.csv", row.names = FALSE)
saveRDS(StdPops, file = "StdPops.rds")

MapHunNUTS3 <- rgdal::readOGR("OSM_kozighatarok", "admin6", encoding = "UTF8", use_iconv = TRUE,
                              stringsAsFactors = FALSE)
saveRDS(MapHunNUTS3, file = "MapHunNUTS3.rds")
