####### GERMLINE VARIANT CALLING WITH PLATYPUS ON TCGA LUNG WITH THE CANCERGENOMICCLOUD #######

library("sevenbridges")

project = "tcga-kirc-germline"

### 1. PREPARE THE PROJECT (ADD REF, VERIFY UNIQUE FILES, ...)

a <- Auth(token = "", url = "https://cgc-api.sbgenomics.com/v2/")

p <- a$project(id = paste("tdelhomme/", project, sep=""))

a$copyFile(id = a$public_file(name = "Homo_sapiens_assembly38.fasta", exact = TRUE)$id, project = p$id)
a$copyFile(id = a$public_file(name = "Homo_sapiens_assembly38.fasta.fai", exact = TRUE)$id, project = p$id)

all_bam = p$file("bam", complete = TRUE)
length(all_bam)
all_bam_names = unlist(lapply(1:length(all_bam), function(i) all_bam[[i]]$name))
sum(duplicated(all_bam_names))

### 2. RUNNING VARIANT CALLING ON SELECTED SAMPLES ###

fasta_input = p$file(name = "Homo_sapiens_assembly38.fasta", exact = T)

f = "~/Documents/Analysis/TCGA/CancerGenomicsCloud/CWL_tools/platypus.json"
platypus = convert_app(f)
f = "~/Documents/Analysis/TCGA/CancerGenomicsCloud/CWL_tools/bgzip.json"
bgzip = convert_app(f)
platypus_bgzip_workflow = link(platypus, bgzip, "#output_vcf", "#vcf", #replace bgzip by vt_bgzip to include normalization
                               flow_input=c("#CWL_platypus_for_exome_data.bamfile",
                                            "#CWL_platypus_for_exome_data.ref", # correspond to label of platypus, not id
                                            "#CWL_platypus_for_exome_data.output_vcf_name",
                                            "#CWL_bgzip.output_gz_name")) #need to specify all of the inputs otherwise only take bam and ref

p$app_add("platypus_bgzip", platypus_bgzip_workflow) 

start=1
for( i in start:length(all_bam) ){
  bamfile = all_bam[[i]]
  taskName <- paste("platypus_bgzip", bamfile$name, gsub("  | ", "-", date()), sep="_")
  tsk = p$task_add(name = taskName,
                   description = paste("platypus bgzip on sample:", bamfile$name, sep=""),
                   app = paste("tdelhomme/", project, "/platypus_bgzip", sep=""),
                   inputs = list(bamfile = bamfile,
                                 ref = fasta_input,
                                 output_vcf_name = gsub(".bam", "_platypus.vcf", bamfile$name),
                                 output_gz_name = paste(gsub(".bam", "_platypus.vcf", bamfile$name), ".gz", sep="")))
  tsk$run()
}



### 3. DOWNLOADING RESULTING VARIANT CALLING VCF ###
library(foreach)
library(doParallel)

cl<-makeCluster(8)
registerDoParallel(cl)

output_folder = paste("~/Documents/Analysis/TCGA/CancerGenomicsCloud/results/", project, "_platypus_", Sys.Date(), sep="")
dir.create(output_folder)

all_vcf = p$file("vcf.gz", complete = TRUE); length(all_vcf)

date()
foreach(i = 1:length(all_vcf)) %dopar% all_vcf[[i]]$download(output_folder) 
date()
stopCluster(cl)


### 5. VERIFY THERE WAS NO ISSUES WITH THE DOWNLOADING ###
# I could have a problem with AWS machine, which leads to an output vcf.gz containing HTML code (the error).
# example:
#   <?xml version="1.0" encoding="UTF-8"?>
#   <Error><Code>InternalError</Code><Message>We encountered an internal error. Please try again.</Message><RequestId>9A703F4E9B6446C8</RequestId><HostId>7qz1eoEnUWf7lL0wp6G+EIvuSLk2LyfCz6D+CV3LWWE5kyB5iDaeRHwDpcXvCI4tGp7EuVuP2N0=</HostId></Error>
# We should check if the vcf is ok, otherwise relaunch the calling

all_results_vcf = list.files(output_folder)

setwd(output_folder)
sizes = file.size(dir())
sum(sizes<100000)

### 5. COPYING FILES TO THE CLUSTER ###
setwd("~/Documents/Analysis/TCGA/CancerGenomicsCloud/results/")
i=2
result_folder = list.files(".")[i]
  
all_results_vcf = list.files(result_folder) ; length(all_results_vcf)

cl<-makeCluster(8)
registerDoParallel(cl)

date()
foreach(i = 1:length(all_results_vcf)) %dopar% system(paste("scp ", result_folder, "/", all_results_vcf[i], " ",
                                                            "delhommet@10.10.156.1:/data/delhommet/TCGA/CancerGenomicsCloud/results/",
                                                            result_folder,"/", sep=""))
date()
stopCluster(cl)
