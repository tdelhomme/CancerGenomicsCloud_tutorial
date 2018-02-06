# CancerGenomicsCloud

## Using the interface to run analyses

### 1. Querying data

### 2. Define an app

Apps have 5 distinct features:
* __general__: Docker, ressources, added files, command and arguments
* __inputs__: tool input ports
* __outputs__: tool output ports
* __additional info__: description, author, license
* __test__

Here the exercise consists in extracting the header of the BAM files using `samtools depth`.  
For that, we need to define the corresponding application.

We can use the nice `biocontainers` repository on DockerHub: `biocontainers/samtools`.  

Resources can be set as default: _CPU=1_, _memory=1000MB_.  
Here it is not needed, but you can have manually created files (for example copy paste a bed or a script, but not a good idea, it is better to have the script in the docker container and the bed in the CGC project).  

Our base command is _samtools view_.  

The result is an _stdout_, and we can define it depending on the input file name:
```
$job.inputs.bam_file.name + "_header.txt"
```

Because we want the header, we need to add an argument: _-H_ (this is the value, not the prefix) at the position _-1_.  

Inputs: we only need an input BAM file. Set at least an ID (_bam_file_) and a type (_File_). We need _bai_ as secondary file: it is defined as _^.bai_. The _^_ replace _.bam_ by _.bai_ in the input file name, we can remove it if bai extension is _.bam.bai_. Finally we include it in the command line at position 0, without prefix.  

Outputs: this is what we want to rescue from AWS instance. We have one output, we can set ID to _header_output_, Type to _File_, and _Glob_ to the same expression we used to define the stdout.  We also can ask to have same metadata as input file.  

Note: we can add input port for output file name, but also for input parameters, defined with a prefix and a value ask when run the tool.  

### 3. Run a task on a file(s)

Two different tabs must be fill in by user when running a task:

#### Set input data
Here the user choose if use _batching_ or not. If _batching_ is chosen, user can batch by _nothing_, _file_ (used in mosy cases) or _metadata_.  
Then user select the input file(s) for each required input (defined with its _label_).  
Then he must set a value for each parameters (_e.g._ output file name, or prefixed parameters).

#### Define app settings
All input values must be define by user when running a task.  
Each parameter expected by the app must have a value that user enter in the corresponding gap.

### 4. Run a task on a batch of files
