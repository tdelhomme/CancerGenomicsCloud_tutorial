####### GERMLINE VARIANT CALLING WITH PLATYPUS ON TCGA LUNG WITH THE CANCERGENOMICCLOUD #######

library("sevenbridges")

all_projects = c("tcga-kirc-germline", "tcga-kirp-germline", "tcga-luad-germline", 
                 "tcga-lusc-germline", "tcga-brca-germline", "tcga-gbm-germline", "tcga-ov-germline", 
                 "tcga-ucec", "tcga-hnsc-germline", "tcga-lgg-germline", "tcga-thca-germline",
                 "tcga-prad-germline", "tcga-skcm-germline", "tcga-coad-germline", "tcga-stad-germline",
                 "tcga-blca-germline", "tcga-lihc-germline", "tcga-cesc-germline", "tcga-sarc-germline",
                 "tcga-paad-germline", "tcga-esca-germline", "tcga-pcpg-germline",
                 "tcga-read-germline", "tcga-tgct-germline", "tcga-thym-germline", "tcga-acc-germline",
                 "tcga-meso-germline", "tcga-uvm-germline", "tcga-dlbc-germline", "tcga-ucs-germline",
                 "tcga-chol-germline", "tcga-kirc-germline")

for(i in 20:32) {
project = all_projects[i]

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

splits = split(1:length(all_bam), ceiling(seq_along(1:length(all_bam))/100))

for( j in 1:length(splits)){
  for( i in splits[j][[1]] ){
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
  print("SLEEPING...")
  Sys.sleep(240)
}


### 3. DOWNLOADING RESULTING VARIANT CALLING VCF ###
library(foreach)
library(doParallel)

cl<-makeCluster(4)
registerDoParallel(cl)

output_folder = paste("~/Documents/Analysis/TCGA/CancerGenomicsCloud/results/", project, "_platypus_", Sys.Date(), sep="")
dir.create(output_folder)

while(TRUE){
  all_vcf = p$file("vcf.gz", complete = TRUE)
  print(length(all_vcf))
  if(length(all_vcf) == length(all_bam)){
    date()
    foreach(i = 1:length(all_vcf)) %dopar% all_vcf[[i]]$download(output_folder) 
    date()
    stopCluster(cl)
    break
  }
  print("SLEEPING...")
  Sys.sleep(600)
}


### 5. VERIFY THERE WAS NO ISSUES WITH THE DOWNLOADING ###
# I could have a problem with AWS machine, which leads to an output vcf.gz containing HTML code (the error).
# example:
#   <?xml version="1.0" encoding="UTF-8"?>
#   <Error><Code>InternalError</Code><Message>We encountered an internal error. Please try again.</Message><RequestId>9A703F4E9B6446C8</RequestId><HostId>7qz1eoEnUWf7lL0wp6G+EIvuSLk2LyfCz6D+CV3LWWE5kyB5iDaeRHwDpcXvCI4tGp7EuVuP2N0=</HostId></Error>
# We should check if the vcf is ok, otherwise relaunch the calling

all_results_vcf = list.files(output_folder)

setwd(output_folder)
sizes = file.size(dir())

if(sum(sizes<100000)==0) {

### 5. COPYING FILES TO THE CLUSTER ###
setwd("~/Documents/Analysis/TCGA/CancerGenomicsCloud/results/")
result_folder = list.files(".")[which(grepl(project,list.files(".") ))]

system(paste("scp -rp ", result_folder, "/", " " , 
             "delhommet@10.10.156.1:/data/delhommet/TCGA/CancerGenomicsCloud/results/VCF/", sep=""))

### 6. REMOVE FILES FROM CGC ###

delete(all_vcf)

} else { cat(project, file="~/Documents/Analysis/TCGA/CancerGenomicsCloud/results/FAILED_PROJECTS.txt", append=T, sep="\n") }  

}




