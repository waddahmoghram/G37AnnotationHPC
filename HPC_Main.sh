#!/bin/bash

#BME 5320 Bioinformatics Techniques
#Final Project Due Friday 12/15/2017
#Waddah Moghram

# Follow the steps listed below after transferring the required files: 
# This is the first program, and it is supposed to do the following:
# * Set up NCBI blast program
# * Download the organism genome protein
# * Check that all proteins are complete for said organism
# * Run perl program "ProteinFilterHits.pl" that will break up that genome into manageable chunks (10 by default)
# * Invoke HPC_BLAST.job via qsub to whichever slots are available.

#---------------------------------------------
#Note: Type "chmod +x HPC_Main.sh" to let the program run first by modifying its properties to make it executable
#---------------------------------------------

# 01. Transfer the following additional files -- before running "HPC_Main.sh" into the same folder before running the program:
#		ProteinBreakup.pl
#       ProteinFilterHits.pl
#       GCF_000027325.1_ASM2732v1_protein.faa (if the download does not complete)
# 	    HPC_BLAST.sh
#       HPC_Annotate.sh
	# then run the starter BASH file by typing "./HPC_Main.sh"

#---------------------------------------------
# Notes about copying files into HPC cluster from local computer: 
# 	replace wmoghram with your HawkID
# 	scp -P 40 file1 wmoghram@neon.hpc.uiowa.edu:file1
# 	sftp -o port=40 wmoghram@neon.hpc.uiowa.edu
# To transfer files, use 'put':
# 	sftp> put file1
# To create new directory, use 'mkdir'
# 	sftp> mkdir remote
# To tranfer all files from local/ to remote/
# 	sftp> put local/* remote/
# To surface the content of the destination folder to ensure upload:
# 	sftp> ls remote/


#---------------------------------------------
# 02. Setting up the BLAST Database & Program Paths

echo $'**Setting up the BLAST DataBase and Path.\n'
export BLASTDB=/Shared/class-BME5320-dkristensen/database/
export PATH=$PATH:/Shared/class-BME5320-dkristensen/bin

# - Alternatively run the following bash by uncommenting the next step:
#./Shared/class-BME5320-dkristensen/blast_setup.sh 
#---------------------------------------------

# 03. Choosing our organism of choice, which is the recommended "Mycoplasma genitalium (ID 747)
#	 https://www.ncbi.nlm.nih.gov/genome/474?genome_assembly_id=166957
# 	or "Mycoplasma genitalium G37" (Henceforth, MGG37) using another assembly
# 	https://www.ncbi.nlm.nih.gov/genome/474?genome_assembly_id=300158
# - Navigating to personal directory to download sequence file. Create a directory called "Project" if it does not exist

cd ~
mkdir -p Project
cd Project
echo $'**Downloading then unzipping the genome for Mycoplasma genitalium (ID 747) as a protein sequence.\n'

# - Downloading & uncompressing the genome from, although it is probably best to use the protein sequence instead in the next step:
# 	Otherwise, download from the links, then transfer to the HPC computer using "sftp" or "scp" as mentioned before.

#wget ftp://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/027/325/GCF_000027325.1_ASM2732v1/GCF_000027325.1_ASM2732v1_genomic.fna.gz
#gunzip GCF_000027325.1_ASM2732v1_genomic.fna.gz 
wget ftp://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/027/325/GCF_000027325.1_ASM2732v1/GCF_000027325.1_ASM2732v1_protein.faa.gz
gunzip GCF_000027325.1_ASM2732v1_protein.faa.gz

#---------------------------------------------
# 04.Checking the count of protein sequences starting with ">" in the downloaded protein file. 
#	They should be 515 proteins for MGG37

ProteinCount=$(cat GCF_000027325.1_ASM2732v1_protein.faa| grep ">" | wc -l)
echo 'There are '$ProteinCount' Proteins counted'
	#Note: Barware of all the spaces around "=". The code will work if the spacing is not exactly the same.
if [ $ProteinCount -eq 515 ]
then
  echo "Protein count is complete"
else
  echo "Protein count is not as expected. Please download the protein file again."
  exit
fi

#---------------------------------------------
# 05. Calling the perl program "PerlBreakup.pl" to chunk the bacteria genome into n-sequences each.
# 	Protein subfiles sequences are called "ProteinInput******.faa", where ******* are digits starting from 1 
# 	The default choice is 10 sequences each, but it can be changed by adding a third argument

perl -w ProteinBreakup.pl GCF_000027325.1_ASM2732v1_protein.faa
 
# - Moving Input to the same folder. Clean up any previous ones if it exists. Override any errors

rm -rf Protein_Input/
mkdir -p  Protein_Input
mv ProteinInput* Protein_Input/

# - Counting the sequence files for jobs
# NOTE: This variable will be used in the subsequent bash files submitted to the clusters.
JobCount=$(ls Protein_Input/ | wc -l)
echo 'There are '$JobCount' Jobs to be submitted to HPC'

# EXTRA OPTIONAL STEPS FOR LATER to choose the most number of nodes
# - Check for the Nodes available on Clusters:   It is in the 5th column
#NodesUI=$( qstat -g c -q UI |grep UI | sed 's/|/ /'  | awk ' {print $5}')
#echo 'There are '$NodesUI' available on the UI queues
#NodesDK=$( qstat -g c -q DK |grep DK | sed 's/|/ /'  | awk ' {print $5}')
#echo 'There are '$NodesUI' available on the UI queues


#---------------------------------------------
# 06. Run BLASTP of query sequences through a qsub job
#	Main Command is the following inside that script:
#	blastp -query Protein_Input/ProteinInput1.faa -db refseq_protein -out FIRSTTRIALout.txt
#	holding next jobs until BLAST is complete.

hold_JID=$(qsub -terse -t 1:$JobCount HPC_BLAST.job | awk -F. '{print $1}')

#---------------------------------------------
# 07. invoke another qsub for annotation of sequences
# put this job until BLAST jobs are done.

echo "My job #ID for BLAST is: $hold_JID"
echo `date`

qsub -hold_jid $hold_JID HPC_Annotate.job
echo `date`


#---------------------------------------------
#***** QUESTIONS THAT I NEED TO ADDRESS
# Since protein sequences do not interact with each, we can use high throughput computing.
# The next step is to chunk up the protein query sequence it into manageable bites:
# 515 total number of chunks: 
#******How many cores can I use at a given time? How many threads does each core have?
#****What is the proper way of dividing the task? How many files? How many sequences in each file? 
# ****When I submit each job? Do I specify the number of threads in blastp? or do I let the scheduler handle it? 
# *** How can I go about submitting the jobs online? 
#**** how will I divide up the file? Do I use a perl script or do I use a unix script? It seems a perl script is the best way.
# c) Why we will not use the tag -num_threads = 20? What are some of the complications that will overcome any potential speedup in the process. See note in Project Description.
# For the neon cluster? How will tasks be assigned? Are you going to be given an entire cluster/Node/Core/Part of Core? I need to understand how the job is delivered, executed and then finally retrieved.
# d) what is the ideal size of each unit? or batch? Estimate of time it takes to track each "sequence" against the database. Time it, then try to project the amount of time it normally takes before it gets killed by ITS? 
# d) Also, try to see how many cores you can get assigned simultaneously? or if I should just push jobs one at a time until finished with "whatever I can get" fashion?
# e) How will you compiled the post-BLAST job? in parallel or in serial? 
# e) What post-BLAST analyses do I need to run and why? 



# The proper Basic Local Alignment Search Tool (BLAST) will use:
# Protein sequence as query, protein reference sequence (refseq_protein) which is present on the HCP cluster
# As such, "blastp" is the propre BLAST software to be used in this annotation process.



# *** Queues I am allowed access to: COE, DK, UI, UI-HM, all.q, sandbox *** Found by typing 'whichq'


