#' data_dict
#'
#' @description A fct function
#'
#' @return The return value, if any, from executing the function.
#'
#' @noRd

biovars <- tibble::tibble(biovars = c("BIO01", "BIO02", "BIO03", "BIO04", "BIO05", "BIO06", "BIO07", "BIO08", "BIO09",
                                      "BIO10", "BIO11", "BIO12", "BIO13", "BIO14", "BIO15", "BIO16", "BIO17", "BIO18", "BIO19"),
                          descr_de = c("Jahresdurchschnittstemperatur", "Tagestemperaturspanne", "Isothermalität",
                                       "Temperatur-Saisonalität", "Maximaltemperatur des wärmsten Monats",
                                       "Minimaltemperatur des kältesten Monats", "Jahrestemperaturspanne",
                                       "Durchschnittstemperatur des feuchtesten Quartals", "Durchschnittstemperatur des trockensten Quartals",
                                       "Durchschnittstemperatur des wärmsten Quartals", "Durchschnittstemperatur des kältesten Quartals",
                                       "Jahresniederschlag", "Niederschlag im feuchtesten Monat", "Niederschlag im trockensten Monat",
                                       "Niederschlags-Saisonalität", "Niederschlag im feuchtesten Quartal", "Niederschlag im trockensten Quartal",
                                       "Niederschlag im wärmsten Quartal", "Niederschlag im kältesten Quartal"
                          )) %>%
  rowid_to_column()


biovars_c <- c("BIO01" = 1, "BIO02" = 2, "BIO03" = 3, "BIO04" = 4, "BIO05" = 5, "BIO06" = 6, "BIO07" = 7, "BIO08" = 8, "BIO09" = 9,
               "BIO10" = 10, "BIO11" = 11, "BIO12" = 12, "BIO13" = 13, "BIO14" = 14, "BIO15" = 15, "BIO16" = 16, "BIO17" = 17,
               "BIO18" = 18, "BIO19" = 19)

soil_vars_c <- c("STU_EU_DEPTH_ROOTS" = 1,"STU_EU_T_CLAY" = 2,"STU_EU_S_CLAY" = 3,"STU_EU_T_SAND" = 4,"STU_EU_S_SAND" = 5,"STU_EU_T_SILT" = 6,
                 "STU_EU_S_SILT" = 7, "STU_EU_T_OC" = 8,"STU_EU_S_OC" = 9,"STU_EU_T_BD" = 10,"STU_EU_S_BD" = 11,
                 "STU_EU_T_GRAVEL" = 12,"STU_EU_S_GRAVEL" = 13, "SMU_EU_T_TAWC" = 14,"SMU_EU_S_TAWC" = 15,
                 "STU_EU_T_TAWC" = 16, "STU_EU_S_TAWC" = 17)

soil_vars <- tibble::tibble(soilvars = c("STU_EU_DEPTH_ROOTS","STU_EU_T_CLAY","STU_EU_S_CLAY","STU_EU_T_SAND","STU_EU_S_SAND","STU_EU_T_SILT","STU_EU_S_SILT",
                                         "STU_EU_T_OC","STU_EU_S_OC","STU_EU_T_BD","STU_EU_S_BD","STU_EU_T_GRAVEL","STU_EU_S_GRAVEL",
                                         "SMU_EU_T_TAWC","SMU_EU_S_TAWC","STU_EU_T_TAWC", "STU_EU_S_TAWC"),
                            descr_de = c("Wurzelverfügbare Tiefe cm", "Tonanteil % Oberboden", "Tonanteil % Unterboden",
                                         "Sandanteil % Oberboden", "Sandanteil % Unterboden",
                                         "Schluffanteil % Oberboden", "Schluffanteil % Unterboden",
                                         "Anteil org. Kohlenstoff % Oberboden", "Anteil org. Kohlenstoff % Unterboden",
                                         "Schüttdichte Oberboden g/cm^3", "Schüttdichte Unterboden g/cm^3",
                                         "Anteil grobkörniger Fragmente % Oberboden", "Anteil grobkörniger Fragmente % unterboden",
                                         "Insges. verfügbarer Wassergehalt (PTR) Oberboden mm", "Insges. verfügbarer Wassergehalt (PTR) Unterboden mm",
                                         "Insges. verfügbarer Wassergehalt (PTF) Oberboden mm", "Insges. verfügbarer Wassergehalt (PTF) Unterboden mm"
                            )) %>%
  rowid_to_column()


future_dates <- tibble(year = c("2030", "2050", "2070", "2090"),
                       index = seq(4,7))

experiment <- tibble(label = c("Mittleres Szenario (RCP4.5)", "Worst-Case Szenario (RCP8.5)"),
                    id = c("rcp45", "rcp85"))
