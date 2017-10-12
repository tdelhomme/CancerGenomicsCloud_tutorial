####### GERMLINE VARIANT CALLING WITH PLATYPUS ON TCGA LUNG WITH THE CANCERGENOMICCLOUD #######

library("sevenbridges")

### 1. PREPARE THE PROJECT (ADD REF, VERIFY UNIQUE FILES, ...)

a <- Auth(token = "", url = "https://cgc-api.sbgenomics.com/v2/")

p <- a$project(id = "tdelhomme/tcga-lung-germline")

# a$copyFile(id = a$public_file(name = "ucsc.hg19.fasta", exact = TRUE)$id, project = p$id)
# a$copyFile(id = a$public_file(name = "ucsc.hg19.fasta.fai", exact = TRUE)$id, project = p$id)

all_bam = p$file("bam", complete = TRUE)
length(all_bam)
all_bam_names = unlist(lapply(1:length(all_bam), function(i) all_bam[[i]]$name))
sum(duplicated(all_bam_names))

### 2. RUNNING VARIANT CALLING ON SELECTED SAMPLES ###

fasta_input = p$file(name = "ucsc.hg19.fasta", exact = T)

f = "~/Documents/Analysis/TCGA/CancerGenomicsCloud/CWL_tools/platypus.json"
platypus = convert_app(f)
f = "~/Documents/Analysis/TCGA/CancerGenomicsCloud/CWL_tools/bgzip.json"
bgzip = convert_app(f)
platypus_bgzip_workflow = link(platypus, bgzip, "#output_vcf", "#vcf", #replace bgzip by vt_bgzip to include normalization
                               flow_input=c("#CWL_platypus_for_exome_data.bamfile",
                                            "#CWL_platypus_for_exome_data.ref", # correspond to label of platypus, not id
                                            "#CWL_platypus_for_exome_data.output_vcf_name",
                                            "#CWL_bgzip.output_gz_name")) #need to specify all of the inputs otherwise only take bam and ref

p$app_add("platypus_bgzip", platypus_bgzip_workflow) ; last_rev = as.numeric(p$app(name="CWL_platypus_for_exome_data CWL_bgzip", exact=T)$revision) # need explicit revision for task_add()

for( i in 1:length(all_bam) ){
  bamfile = p$file("bam")[[i]]
  taskName <- paste("platypus_bgzip", bamfile$name, gsub("  | ", "-", date()), sep="_")
  tsk = p$task_add(name = taskName,
                   description = paste("platypus bgzip on sample:", bamfile$name, sep=""),
                   app = "tdelhomme/r-api-demo/platypus_bgzip",
                   inputs = list(bamfile = bamfile,
                                 ref = fasta_input,
                                 output_vcf_name = gsub(".bam", "_platypus.vcf", bamfile$name),
                                 output_gz_name = paste(gsub(".bam", "_platypus.vcf", bamfile$name), ".gz", sep="")))
  tsk$run()
}



### 3. DOWNLOADING RESULTING VARIANT CALLING VCF ###

date = "10oct2017"
for( i in 1:length(p$file("vcf.gz", complete = TRUE)) ){
  vcfgz = p$file("vcf.gz")[[i]]
  vcfgz$download(paste("~/Documents/Analysis/TCGA/CancerGenomicsCloud/lung_germline", date, sep="_"))
}


