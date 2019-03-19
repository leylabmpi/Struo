LLMGP-DB
========

Ley Lab Metagenome Profiler (LLMGP) Database Maker

* Version: 0.1.0
* Authors:
  * Nick Youngblut <nyoungb2@gmail.com>
  * Jacobo de la Cuesta <jacobo.delacuesta@tuebingen.mpg.de>
* Maintainers:
  * Nick Youngblut <nyoungb2@gmail.com>
  * Jacobo de la Cuesta <jacobo.delacuesta@tuebingen.mpg.de>


# Description

## Getting database genomes

### conda env (llmgp-db)

* r-argparse
* r-curl
* r-data.table
* r-dplyr
* ncbi-genome-download

### Downloading genomes

* If using GTDB genomes, run `GTDB_metadata_filter.R`
* If downloading genomes from genbank/refseq, you can use `genome_download.R`

### Input data (`samples.txt` file)

* The pipeline requires a tab-delimited table that includes the following columns:
  * Sample ID
    * This will usually just be the species/strain names
  * Path to the genome assembly fasta file
    * NOTE: these must be gzip'ed
  * taxonomy ID
    * This should be the NCBI taxonomy ID at the species/strain level
      * Needed for Kraken
  * taxonomy
    * This should at least include `g__<genus>;s__<species>`
    * The taxonomy can include higher levels, as long as levels 6 & 7 are genus and species
    * Any taxonomy lacking genus and/or species levels will be labeled:
      * `g__unclassified`  (if no genus)
      * `s__unclassified`  (if no species)
    * This is needed for humann2
    

## Algorithm

* Pre-Input
  * gtdb metadata
    * bac: https://data.ace.uq.edu.au/public/gtdb/release86/bac_metadata_r86.tsv
    * arc: https://data.ace.uq.edu.au/public/gtdb/release86/arc_metadata_r86.tsv
  * filter metadata
    * read via data.table::fread
    * filter:
      * gtdb_representative == 't'
      * cols:
        * ncbi_organism_name
        * ncbi_genbank_assembly_accession
	* scaffold_count
	* contig_count
	* gc_percentage
	* genome_size
	* checkm_completeness
	* checkm_contamination
	* checkm_strain_heterogeneity
	* ncbi_assembly_level
	* ncbi_refseq_category
	* ncbi_species_taxid
	* ncbi_taxonomy
	* gtdb_taxonomy
	* mimag_high_quality
  * use ncbi-genome-download to download genomes
    * `ncbi-genome-download --assembly-accessions {file_of_accs} "archaea,bacteria"`
      * `-p {threads} -r {retries}`
* Input
  * metadata table:
    * genomeID
    * path to genome assembly fasta
    * ncbi_species_taxid
* Kraken db
  * download NCBI taxonomy db
    * make a custom GTDB taxonmoy db??
  * Add taxID to seq names & combine all genomes
  * `kraken2-build --add-to-library`
    * can it be batched?
* Bracken db
  * build based off of Kraken db
* humann2 db
  * gene call for all genomes
    * `Prodigal`
  * diamond mapping vs UniRef
  

# Pipeline overview

Example run on 2 metagenomes. 

![DAG](./llmgp-db_dag.png)


# Instructions

For general instuctions on setting up and running the Ley Lab pipelines, see the [ll_pipeline_docs](https://gitlab.tuebingen.mpg.de/leylabmpi/pipelines/ll_pipeline_docs)



