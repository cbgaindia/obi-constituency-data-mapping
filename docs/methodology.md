## Methodology

### Objective

Verify the extent to which the geographic entities (District, Block, Gram Panchayat) in the geography file align (one to one map) with the geographic entities in the scheme datasets. 

### States

1. Odisha

### Schemes

1. MNREGA 2018-19
2. MNREGA 2019-20
3. PMAGY 2019-20

### Premise

- CBGA team curated a mapping file that links all Gram Panchayats to an assembly and a parliamentary constituency in a state. 
- The scheme indicators are downloaded from the scheme MIS dashboard for all Gram Panchayats in a state. 
- Aggregate indicators for constituencies can be calculated by linking the two files using Gram Panchayat as the key

### Process

The process to verify the total GP's that match between the two files is listed below:

1. Districts across both files are matched. If we find districts in the scheme file that are __not matching directly_ with the districts in the geography file, we do a [fuzzy join](https://github.com/dgrtwo/fuzzyjoin/blob/master/README.md) between the files using the [string distance approach](https://cran.r-project.org/web/packages/fuzzyjoin/vignettes/stringdist_join.html) and match all districts where we find a match within a **distance of 1**. 
2. At this stage, it is possible that we could not find a match for all districts present in the scheme file. We ignore those entities. *This means that we wont be able to calculate the aggregate statistics for these entities*.
3. A similar process is followed to match the **Blocks** and **Gram Panchayats** present within each district.

**Exclusions** 
At every step (district/block/gp) we exclude rows where:

1. We don't find a direct or a fuzzy match (within a string distance of 1).
2. Where multiple entities in the scheme file map to one entity of the geography file and vice-versa. This step ensures that we get a one-to-one mapping between the two datasets.


### Results

1. Summary of results for the mapping exercise for the schemes listed above are [here](https://cbgaindia.github.io/obi-constituency-data-mapping/scripts/scheme-wise-mapping-results.html) 
2. This [file](https://github.com/cbgaindia/obi-constituency-data-mapping/blob/main/data/results/mnrega-2018-19-geography-mapping-summary.csv) contains details for all geography that were mapped/not mapped between the geography file and the MNREGA 2018-19 scheme file. Similar files for other schemes can be explored/downloaded at this [link](https://github.com/cbgaindia/obi-constituency-data-mapping/tree/main/data/results)
3. Updated scheme file (with updated district/block/gp names as per the names in the geogrpahy file) for MNREGA 2018-19 can be explored [here](https://github.com/cbgaindia/obi-constituency-data-mapping/blob/main/data/scheme/MNREGA/odisha/2018-19/updated/odisha-mnrega-2018-updated.csv). Files for other states/schemes, can be accessed in this order of file hierarchy: _data/scheme/[scheme-name]/[state-name]/[year]/updated/[file-name]_

**Note**

1. We have taken the geography file as the base for this process. Updation (renaming entities) of geographies will be done on the scheme file.

### References

1. [FuzzyJoin](https://github.com/dgrtwo/fuzzyjoin)
2. [Constituency-wise Expenditure Dashboard 101 | Primer Document](https://docs.google.com/document/d/1SLoBna7NNczMfiySusZpdykNrQk2bIRNA5yfZlnd8ig/edit) 
