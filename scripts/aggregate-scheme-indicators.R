
source("scripts/libraries.R")

all_schemes <- c("MNREGA", "PMAGY")
all_years <- c("2018-19","2019-20")
indicator_list <- readr::read_csv("data/indicators/indicator_list.csv")

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
    
    indicator_df_ac <-
      geo_indicators %>% group_by(g_ac) %>% summarise(across(scheme_indicators$indicator_list,sum))
    indicator_df_ac$level <- "AC"
    indicator_df_pc <-
      geo_indicators %>% group_by(g_pc) %>% summarise(across(scheme_indicators$indicator_list,sum))
    indicator_df_pc$level <- "PC"
    indicator_df <- bind_rows(indicator_df_ac, indicator_df_pc)
    indicator_df$scheme <- scheme_title
    indicator_df$year <- year_title
    geo_indicator_df <- bind_rows(geo_indicator_df, indicator_df)
  }
}

readr::write_csv(geo_indicator_df, "data/indicators/ac_pc_aggregates.csv")



