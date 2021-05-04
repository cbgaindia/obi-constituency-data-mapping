## Methodology

**Objective**

Verify the mapping of geographic entities (District, Block, Gram Panchayat) between scheme budget data and other geographic datasets prepared by the team at CBGA. 

**States**

- Bihar
- Chattisgarh
- Jharkhand
- Maharashtra
- Odisha
- Uttar Pradesh

**Schemes**

- MNREGA

**Process**

- CBGA conducts a mapping exercise between Gram Panchayats and Assembly/Parliamentary constituencies for each state.
- The file prepared and shared by CBGA has to be verified against the scheme budget/expenditure data downloaded through the scheme portals.
- For verification, we follow a hierarchical process and find the mapping percentage between entities:
  - First check is for the **districts** in the geography file that are present in the scheme file 
  - For districts where we don't find a match, we do a [fuzzy join](https://github.com/dgrtwo/fuzzyjoin/blob/master/README.md) between the files using the [string distance approach](https://cran.r-project.org/web/packages/fuzzyjoin/vignettes/stringdist_join.html) and match all districts where we find a match within a distance of 1.
  - Districts that are mapped through the fuzzy join approach are then renamed to their respective districts present in the scheme file. This step ensures that we get a one-to-one mapping between the two datasets.
  - At this stage, their might be a few districts in the scheme file against which we could not locate a direct or a fuzzy match. We ignore those entities. *This means that we wont be able to calculate the aggregate statistics for these entities.* 
  - We then follow the same process to map **scheme blocks** to geography blocks for each district which is then followed by mapping the **gram panchayats**, present in the scheme file, for each district and block to the gram panchayats present in the geography file against their updated districts and blocks.

**Exclusions**

At every step (district/block/gp) we exclude rows where:
- We don't find a direct or a fuzzy match (within a string distance of 1).
- Where multiple entities in the scheme file map to one entity of the geography file and vice-versa.

**Output**

A mapping between the entities of the scheme file and the geography file. The geography file comprises of these columns:
- State
- District (mapped to scheme)
- Block (mapped to scheme)
- GramPanchayat (mapped to scheme)
- AssemblyConstituency (AC)
- ParliamentaryConstituency (PC)

This file shall assist us in calculating the budget indicators for constituencies by aggregating indicators for each GramPanchayat.

**Results**

1. Summary of results for the mapping exercise for each state are [here](../results.md) 
2. Summary of the total Gram Panchayats mapped in each block and district. A sample file for Odisha is [here](../data/Results/odisha.csv)

_Note: We might not be able to get a 100% match between entities in the scheme and gepgraphy files after this process. We will share the results of the verification exercise with CBGA. This will help them in identifying the entities that were not mapped and suggest changes so we can increase the match between entities._  

**References**

1. [FuzzyJoin](https://github.com/dgrtwo/fuzzyjoin)
2. [Constituency-wise Expenditure Dashboard 101 | Primer Document](https://docs.google.com/document/d/1SLoBna7NNczMfiySusZpdykNrQk2bIRNA5yfZlnd8ig/edit) 