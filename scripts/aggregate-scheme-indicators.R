
source("scripts/libraries.R")

all_schemes <- c("MNREGA", "PMAGY")
all_years <- c("2018-19","2019-20")
indicator_list <- readr::read_csv("data/indicators/indicator_list.csv",col_types = cols())

# File template - https://docs.google.com/spreadsheets/d/1IZWf5di_7ohTq4Nka0G2xUuYDKHcz77swiapwlpPT-g/edit#gid=0

preepare_constituency_file <- function(constituency_df){
  names_df <- data.frame("colname"=names(constituency_df))
  names_df <- left_join(names_df, scheme_indicators, by=c('colname'='indicator_list'))
  names_df <- names_df[!is.na(names_df$updated_name),]
  names(constituency_df)[2:(ncol(constituency_df)-1)] <- names_df$updated_name
  return(constituency_df)
}

geo_indicator_df <- c()
for(i in 1:length(all_schemes)){
  for(j in 1:length(all_years)){
    scheme_title <- all_schemes[i]
    year_title <- all_years[j]
    scheme_title_lower <- str_to_lower(scheme_title)
    year_title_y1 <- str_split_fixed(year_title, pattern = "-",n = 2)[[1,1]]
    print(glue("{scheme_title} -- {year_title}\n"))
    
    scheme_ind_file_path <-
      glue(
        "data/scheme/{scheme_title}/odisha/{year_title}/updated/odisha-{scheme_title_lower}-{year_title_y1}-updated.csv"
      )
    scheme_ind_file <- read_csv(scheme_ind_file_path, col_types = cols())
    
    geo_mapping_file_path <- glue("data/results/{str_to_lower(scheme_title)}-{year_title}-geography-mapping-summary.csv")
    geo_mapping_file <- read_csv(geo_mapping_file_path,col_types = cols())
    
    scheme_indicators <-
      indicator_list %>% filter(scheme == scheme_title &
                                  year == year_title)
    
    
    # Merge files to get scheme_indicators for all geographies
    geo_indicators <-
      left_join(geo_mapping_file,
                scheme_ind_file,
                by =  "s_id")
    
    geo_indicators_file_path <- glue("data/indicators/gp-level-indicators/{scheme_title}-{year_title}-gp_indicators.csv")
    readr::write_csv(geo_indicators, geo_indicators_file_path)
    
    indicator_df_ac <-
      geo_indicators %>% group_by(g_ac) %>% summarise(across(scheme_indicators$indicator_list, sum, na.rm =
                                                                             TRUE))
    names(indicator_df_ac)[which(names(indicator_df_ac) == "g_ac")] <- "constituency"
    indicator_df_ac$level <- "AC"
    
    indicator_df_ac <- preepare_constituency_file(indicator_df_ac)
    indicator_df_ac$scheme <- scheme_title
    indicator_df_ac$year <- year_title
    g_ac_code <- str_split_fixed(indicator_df_ac$constituency, pattern = " ", n = 2)[,1]
    g_ac_name <- str_split_fixed(indicator_df_ac$constituency, pattern = " ", n = 2)[,2]
    indicator_df_ac$constituency <- str_squish(g_ac_name)
    indicator_df_ac$constituency_code <- str_squish(g_ac_code)
    starting_cols <- c(
      "constituency",
      "constituency_code",
      "level",
      "scheme",
      "year")
    indicator_list_cols <- names(indicator_df_ac)[!names(indicator_df_ac) %in% starting_cols]
    indicator_df_ac <-
      indicator_df_ac[,c(starting_cols,indicator_list_cols)]
    ac_file_path <- glue("data/indicators/{scheme_title}-{year_title}-AC-aggregates.csv")
    write_csv(x = indicator_df_ac, file = ac_file_path)
    
    indicator_df_pc <-
      geo_indicators %>% group_by(g_pc) %>% summarise(across(scheme_indicators$indicator_list,sum, na.rm=TRUE))
    indicator_df_pc$level <- "PC"
    names(indicator_df_pc)[which(names(indicator_df_pc) == "g_pc")] <- "constituency"
    indicator_df_pc <- preepare_constituency_file(indicator_df_pc)
    indicator_df_pc$scheme <- scheme_title
    indicator_df_pc$year <- year_title
    starting_cols <- c(
      "constituency",
      "level",
      "scheme",
      "year")
    indicator_list_cols <- names(indicator_df_pc)[!names(indicator_df_pc) %in% starting_cols]
    indicator_df_pc <-
      indicator_df_pc[,c(starting_cols,indicator_list_cols)]
    pc_file_path <- glue("data/indicators/{scheme_title}-{year_title}-PC-aggregates.csv")
    write_csv(x = indicator_df_pc, file = pc_file_path)
    
    
    # Combined Files
    indicator_df <- bind_rows(indicator_df_ac, indicator_df_pc)
    geo_indicator_df <- bind_rows(geo_indicator_df, indicator_df)
  }
}

readr::write_csv(geo_indicator_df, "data/indicators/all_ac_pc_aggregates.csv")

