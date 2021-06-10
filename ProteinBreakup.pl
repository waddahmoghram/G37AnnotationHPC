# BME 5320 Bioinformatics Techniques
# Final Project Due 12/15/2017
# Waddah Moghram

# This program takes as input the protein sequence and the number of sequences, and chunk them into as many files as needed.
# If no number is given, assume a default value of 10 sequences per sub-file.

use warnings;
use Data::Dumper;

# Open the Protein sequence to be divided up
$filename=shift @ARGV;                                                                  # getting the first argument of command-line arguments (i.e., filename)
if (defined $filename) {
	open(IN, "<".$filename) or die "ERROR - Unable to open $filename\n";            # opening file for input or issue error message
} else {
	print "No Protein Sequence File was given!\n";
	exit;
}
print "File to be chunked: ", $filename,"\n";

$SequencesEach=shift @ARGV;
if (!defined $SequencesEach) { 
	print "No number is given for sequences per output sub-file. Using a default value of 10 sequences per file.\n";
	$SequencesEach = 10;
} else {
	print "Number of sequences per chunked file: ", $SequencesEach,"\n";
}


my $SeqNum;								# Counter of Sequence Number. Initialized to 0
my $fileNum;								# Counter of the number of files created. Initialized to 1
my $fileName;
$SeqNum = 0;								# Initialize at -1 so that the first iterations is 0 with ++
$fileNum = 1;
$fileName = "ProteinInput1.faa";		# Initial file name.


print "Starting the process of chunking ", $filename, " into sub-files of ", $SequencesEach, " sequences each.\n";

# Creating an output file
open(OUT, ">ProteinInput1.faa") or die "ERROR - Unable to write to ProteinInput1.faa\n";     	#Creating the first output file. 


# >>>How many proteins sequences can there normally be? Assuming 1,000,0000 sequences. About 10 sequences each? 


while($line=<IN>) {      						#lines are fed 50 characters at a time from FASTA File, unless "\n" is found
	if (substr($line,0,1) eq ">") {				#if the first character is ">" of ">Sequence"
		$SeqNum++;               				
		if ( (($SeqNum-1) % $SequencesEach eq 0 )&& ($SeqNum) ne 1 ) {
			close OUT;							#close last file in series
			$fileNum++;
			$fileName = sprintf(">ProteinInput%d.faa", $fileNum);		#No Pad file names with left-zeros. Make them easier to read/sort in folders
			$fileName =~ tr/ //;						#Remove all the padded space in filename
			open(OUT,$fileName) or die "ERROR - Unable to write to $fileName\n"    #Open the next file in sequence
		}
	}	
	print OUT $line;			#spit out the content of the current line to the latest file in sequence
	#print OUT $SeqNum, " " , $line;	
}
close IN;
close OUT;

print "Total number of sequences processed are: " , $SeqNum, "\n";
exit;
