# CancerGenomicsCloud

## Sevenbridges cancer genomics cloud tutorial

There is a [complete tutorial](https://www.bioconductor.org/help/course-materials/2016/BioC2016/ConcurrentWorkshops4/Yin/bioc-workflow.html) on using R for the Sevenbridges Cancer Genomics Cloud, by Tengfei Yin.

I have also wrote two additional READMEs, to support the pratical and theoretical course I give in IARC in feb. 2017:  
* [using Cancer Genomics Cloud interface to run our first analysis](https://github.com/tdelhomme/CancerGenomicsCloud_tutorial/blob/master/READMEs/CGC_interface.md)
* [using R and CWL to run reproducible analyses](https://github.com/tdelhomme/CancerGenomicsCloud_tutorial/blob/master/READMEs/CGC_R_API_CWL.md)

### 1. R api to analyse TCGA data on the Cancer Genomics Cloud

### 1.1 Introduction

Sevenbridges maintained a GitHub repository for API client, CWL schema, meta schema and SDK helper in R, [here](https://github.com/sbg/sevenbridges-r).  

[Tutorials](https://github.com/sbg/sevenbridges-r#tutorials) from Tengfei Yin for multiple tasks can be found on the GitHub, including intersting ones for TCGA data analysis:

  - [Use R on the CancerGenomicsCloud](http://www.tengfei.name/sevenbridges/vignettes/bioc-workflow.html)
  - [Describe and execute Common Workflow Language (CWL) Tools and Workflows in R](http://www.tengfei.name/sevenbridges/vignettes/apps.html)
  - [Browse data on the Cancer Genomics Cloud via the Data Explorer, a SPARQL query,
or the Datasets API](http://www.tengfei.name/sevenbridges/vignettes/cgc-sparql.html)  

A good schema for using R api to analyse TCGA data is the following:  

  1. Create your `docker` image or use an existing one.
  2. Choose the `machine` you want (default is _m4.2xlarge (8 CPUs, 32Gb_, _40cts/h_) You pay at least 1 hour.
  3. Create a `tool` or a `workflow` (directly in R or import CWL file, which can be written also on JSON or YAML)
  4. Add specific data to your project (use the `queries` to keep reproducibility)  
  5. `Run` your analysis with a loop on your files

### 1.2 Examples of tools

#### Platypus / bgzip Workflow

 - [JSON file to describe bgzip tool](https://github.com/tdelhomme/CancerGenomicsCloud_tutorial/blob/master/code/bgzip.json)
 - [JSON file to describe platypus tool](https://github.com/tdelhomme/CancerGenomicsCloud_tutorial/blob/master/code/platypus.json)

### 1.3 Data queries

 * [Filter and count TCGA entities with dataset API](https://github.com/tdelhomme/CancerGenomicsCloud/blob/master/READMEs/dataset_API.md)  
 * [GUI Data Browser tutorial](https://www.youtube.com/watch?v=MOOQ1BFA_JU&index=1&list=PLWTWIYwwk-kfiPNnOn5QPyJNs4LT0OIXN). __CAUTION:__ filters after "file" entity are not considered if you want to add the querying files to your project.

### 1.4 Example of TCGA analysis: germline calling on lung samples

Steps are the following:
  * use GUI to add lung BAM files to your project
  * use [this](https://github.com/tdelhomme/CancerGenomicsCloud/blob/master/code/TCGA_germline_platypus.r) R script to:
    * 1. load platypus and bgzip JSON tools
    * 2. connect them into a workflow
    * 3. add the workflow to your project (these 2 previous steps can be skipped if your app is already present in the project)
    * 4. loop over the BAM file to run the variant calling on each sample
    * 5. download locally each VCF file
    * 6. transfer each VCF from local computer to the IARC HPC
    * 7. delete VCF files on the CGC (don't forget the checking of VCF files downloading before this)


### 1.5 Task monitoring

R api could be use to analyse several task features, such as:
  * task execution time (queue + run)
  * task price (computing + storage)

[This script](https://github.com/tdelhomme/CancerGenomicsCloud/blob/master/code/task_monitoring.r) is an example of task analysis, which produce [this sort of picture](https://github.com/tdelhomme/CancerGenomicsCloud_tutorial/blob/master/images/task_monitor_kirc.png).

### 1.6 Issues (API is currently in development)

- [query is limited to the 100 first files](https://github.com/sbg/sevenbridges-r/issues/60)
- If upload a JSON file in the GUI, can not run a task using this app in R

### 2. Amazon Web Services (AWS) utils

### 2.1 Spot Instances
The CGC uses two types of Amazon EC2 pricing for instances: On-Demand and Spot. On-Demand instances are purchased at a fixed rate, while the price of Spot Instances varies according to supply and demand.

 * CGC strategy is to __bid the On-Demand__ instance price for spot instances
 * AWS EC2 will __terminate__ your spot instance if __bid price < market price__
 * in this case, task will continue on an __On-Demand__ instance  
 * if spot instance is terminated before 1h of running, __not charged__  
 * spot instance are not recommended for __critical-time__ jobs
