# Firms-Analysis
Firm's analysis using WEBs for formal and informal firms

## Informal + Micro formal enterprises firms analysis 
Analysis using the Informal and Micro Enterprise Survey, compares micro formal firms and informal firms from 18 cities in eight SSA countries
Combines micro-enterprises data from Zambia, Mozambique, Somalia, Ghana, Central African Republic and Zimbabwe (WBES, public data, separate files per country ), with the Informal enterprise survey database (version May, 7, 2025). 8  Informal Enterprise Surveys & 6  Micro Enterprise Surveys for 8 SSA countries (Zimbabwe (2017), Zambia (2020), Tanzania (2023), Somalia (2019),  Sudan(2022), Mozambique (2018), Ghana (2022), and the Central African Republic (2023). The list below of Dofiles and R Markups includes the steps and files for the analysis
1. Harmonized methodology: merge IE & Micro
2. Master2: Clean variables and labelling 
3. WBES survey Informal and Micro Enterprises analysis: only analysis on firm size per city (rest of analysis in Analysis_all_IE_2)
4. Analysis_all_IE: analysis on IE & Micro 
5. Informal Enterprise by category: Figure 12 replication: workers by category replication of Figure from Cunningham et. al., with minor changes in categories due to data harmonization

## Firms' productivity, Density and Employment distribution

Analysis using firms’ productivity (sales per worker) for over 12,000 firms at the city level across 59 countries and 131 cities from 2014 to 2024, to examine the relationship between city density and firms’ performance productivity
Additional tests were performed to review the firm’s productivity relationship with job uniformity (Lasyam inverse), the spatial spread of economic clusters (Batty entropy = cluster spread), and the size of the economic clusters (Shannon entropy = cluster evenness).
1. Combined WBES: Combine all Enterprise survey data & TFP Firm level
2. Filter WBES combined data: select variables of interest and the latest WBES from each country
3. Filter to only data at the city level (remove regional data) & convert firms ‘sales to 2009 PPP
4. Firms productivity analysis with density, jobs uniformity (Lasyam inverse), spread of economic activity, and the size of the economic clusters


The repository contains:

- Raw data: WBES public data and GHSL public data are included in the repository. Oxford Economics and Cluster Employment Distribution data are not public. The  files with non-public data are stored in the respective WBOneDrive folder 
- Processed datasets (containing only public data)
