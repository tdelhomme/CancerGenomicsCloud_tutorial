### Data queries with Datasets API

The Datasets API is an HTTP API for programmatically `browsing` and `querying` datasets based on metadata attributes of files. This API is reachable from R, to query data to be analysed.  

Queries can do 2 operations:
  * __Filter__ entities based on a specific criteria
  * __Count__ entities based on your criteria

To __filter__ a dataset on metadata, 2 steps are needed:    
  * `GET` request to obtain available entities and available metadata fields by consulting the metadata schema
  * `POST` request to executing a filter which are pairs of key-value (key being the metadata field)
  * use `offset=n` to display the first n+1 results (this does not work for the moment)

__Examples__:  

To list all entities of the TCGA project:
```
a <- Auth(token = your_token, url = "https://cgc-datasets-api.sbgenomics.com/datasets/tcga/v0")
names(a$api(path = "", method = "GET")$`_links`)
```

To list first-level metadata of files entities:
```
names(a$api(path = "files/schema", method = "GET"))
```  

To list all available values of a specific metadata field (`hasDataType` for instance):
```
unlist(a$api(path = "files/schema", method = "GET")$hasDataType$values)
```

Once the metadata filters are chosen, you can request a particular query. Here for example, count the number of lung whole-exomes (replace `path=query/total` by `path=query` to have the corresponding files):
```
> body = list(
  entity = "files",
  hasExperimentalStrategy = "WXS",
  hasDataType = "Raw sequencing data",
  hasDataSubtype = "Aligned reads",
  hasDiseaseType = c("Lung Adenocarcinoma", "Lung Squamous Cell Carcinoma")
)

> a$api(path = "query/total", body = body, method = "POST")
$total
[1] 2541
```

To copy files from a query into a CGC project:
```
> get_id = function(obj){
    sapply(obj$"_embedded"$files, function(x) x$id)
  }

> res = a$api(path = "query", body = body, method = "POST")
> ids = get_id(res)

> a$copyFile(id = ids, project = "tdelhomme/tests")


```

__TIPS:__
If you want a particular set of data, where your request merges several entities fields, as instance:
  - `Files` hasExperimentalStrategy = "WXS"
  - `Samples` hasSampleType = "Blood Derived Normal"

You need to mimic what you can do on the data browser on the website:
```
body = list(
  entity = "files",
  hasExperimentalStrategy = "WXS", #from files entities
  hasSample = list("hasSampleType" = c("Blood Derived Normal", "Solid Tissue Normal")) #from samples entities
)
```


<img align="center" src="https://github.com/tdelhomme/CancerGenomicsCloud/blob/master/images/data_browser.png" width="600">

An other solution is to find the `linked fields` to the entities we are working with, and to find the possible values of these fields:
```
> names(a$api(path = "files/schema", method = "GET")$`_links`)
[1] "hasPortion" "self"       "hasAliquot" "hasCase"    "hasSample"  "hasAnalyte"

> unlist(a$api(path = "samples/schema", method = "GET")$hasSampleType$values)
 [1] "Additional - New Primary"                         
 [2] "Metastatic"                                       
 ...                             
 [14] "Recurrent Blood Derived Cancer - Peripheral Blood"
 [15] "Blood Derived Normal"                             
 ...
```
