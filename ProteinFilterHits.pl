#BME 5320 Bioinformatics Techniques
#Final Project Due 12/15/2017
#Waddah Moghram

#use warnings;
use Data::Dumper;

# This code will do the following:
# 1. Identify the query sequence from the results
# 2. Provide a check against E-value (of at least 1, being due to complete chance) -- even though that is redundant since this can be provided as a parameter for blastp
# 3. Check for the coverage length of the hit (or at least 50-75% of query sequence)
# 4. Eliminate other hits from the same organism [Mycoplasma genitalium]
# 5. Eliminate self-hits of the query protein
# 


# Intput file will be blastp results in output format 7 -outfmt 7.
# Input file will be brought as an argument after the filename
$filename=shift @ARGV || die "Error - need filename to work with! (hint: ProteinOutput**.txt)\n";     	# getting the first argument of command-line arguments (i.e., filename)
open(IN, "<".$filename) or die "ERROR - Unable to open $filename\n";     								# opening file for input or issue error message

$filenameOut = substr($filename,0,-4);                    # Remove.txt from filename
$filenameOut = ">".$filenameOut."Annotated.txt";
#print $filenameOut;
open(OUT, $filenameOut) or die "ERROR - Unable to write to $filenameOut";   #Creating an output file

my $shell = '/bin/bash';


while($line=<IN>)       										# lines are fed one at a time in the file
{
	#chomp($line);    											# strip "\n" at end of lines
	if (substr($line,0,1) eq "#") {								# 1. if the first character is "#", it will the header of BLASTp Results in -outfmt 7
		$found = 0;											    # Reset the variable that the top hit is not found yet
		#print "============================\n";
		#push @QueryList, $line;								# Appends the sequence header to the list "QueryList"
	
		$Query = index($line, "Query");							# returns -1 if not found. Searching for Query line 
		if ($Query ne "-1") {									# Check that query line is not found 
			#print OUT "============================\n";
			print OUT $line;								
			
			@CurrentLine = split(" ",$line);					# Read lines and split the values delimited by whitespace
			#$size = scalar(@CurrentLine);						# Obtains the size of the array. 
			#print @CurrentLine[2], "\n";						# Extracts the query sequence of the hit
			
			#NOW run "blastdbcmd" to annotate the query protein, and find its length for "Coverage Percentage"  
			#use 'qx' to return results instead of 'exec' or 'system'  #$QueryDetail = system("blastdbcmd", @args);	
			# since 'system' also has a "exit return status", which confuses the output. 'exec' does not return the STDOUT.
			my @args = ("-entry", $CurrentLine[2], "-db", "refseq_protein", "-target_only");    # arguments list for blastdb							
			$QueryDetail = qx/"blastdbcmd" @args/;												# calling blastdbcmd on bash. Make sure path & database are defined using blast_setup.sh before
			#print $QueryDetail, "\n\n";														# This is the returned QueryDetail
			
			@CurrentLine = split("\n",$QueryDetail);											# Read lines and split the values delimited by newline.
			$lineNum = scalar(@CurrentLine);													# number of query lines.
			$QueryLength = 0;																	# Reset query length variable
			for ($i = 0; $i< $lineNum ; $i++){
				if (substr($CurrentLine[$i],0,1) eq ">") {											# Identify the sequence header of blastdbcmd annotation result
					$Initial = index($CurrentLine[$i], "[");
					$Last = index($CurrentLine[$i], "]");
					$QueryOrganismName = substr($CurrentLine[$i], $Initial + 1, $Last - $Initial - 1);				#Extract the name of the organism in query that is between brackets [...]
					#print "Query Organism is: ", $QueryOrganismName, "\n";
					# Maybe extract the query Accession number from here later. although it is present in the blast results -outfmt in the first column.
				}
				else {																			# Actual sequence of the bastdbcmd annotation result
					chomp($CurrentLine[$i]);														# Remove "\n" from lines since they will count as characters
					$QueryLength = $QueryLength + length($CurrentLine[$i]);							# Adding to length counter
					#print "Current Querry Length: ", $QueryLength, "\n";
					#print "Current Line Length: ", length($CurrentLine[$i]), "\n";
				}
			}
			#print "Final Query Length: ", $QueryLength, "\n\n";
			# Note: If $QueryLength = 0, then it was not found in blastdbcmd -refseq_protein database.
			# In this case case assume a default query length of 40 amino acids

		}	
	}	
	else{									#actual hit results for query protein
		if ($found eq 0) { 
			@CurrentLine = split("\t",$line);						# Read lines and split the values delimited by tab.	
									
			$Evalue = $CurrentLine[10];								# 11th Column is the E-value for the subject
			$EvalueThreshold = 1;									# Thresold for E-value hits desired (of at least 1, being due to complete chance)	
			if ($Evalue <= $EvalueThreshold) {																			# 2. Check that the E-value is less than or equal to that value.
				$SubjectLength = $CurrentLine[3];																		# 4th Column is the length for the subject	
				#print "Final Subject Length: ", $SubjectLength, "\n";	
				#print "\nFinal Query Length: ", $QueryLength, "\n";
				if ($QueryLength eq 0) {
					$QueryLength = 40;				#If no query is returned, use a default minimum amino acid length of 40
					$QueryOrganismName = "Mycoplasma genitalium";     #NO HIT, but it should still be Mycoplasma genitalium if it is a query
				}
				$PercentCoverage = $SubjectLength/ $QueryLength;
				#print " Percent Coverage: ", $PercentCoverage, "\n";		
				$PercentCoverageThreshold = 0.50;							# 3. Desired Percent Coverage desired.												
				#$PercentIdentity = 	$CurrentLine[2]						# Percent identity between hit 														
				if ($PercentCoverage > $PercentCoverageThreshold) {														# check if the hit is greater than the desired hit.
					$SubjectHit = $CurrentLine[1];							# 2nd Column is the "Subject Accession Number"
					#print $SubjectHit , "\n";	
					
					#NOW run "blastdbcmd" to annotate the query protein, and find its length for "Coverage Percentage"  
					#use 'qx' to return results instead of 'exec' or 'system'  #$QueryDetail = system("blastdbcmd", @args);	
					# since 'system' also has a "exit return status", which confuses the output. 'exec' does not return the STDOUT.
					my @args = ("-entry", $SubjectHit, "-db", "refseq_protein", "-target_only");    					# arguments list for blastdb
					$SubjectDetail = qx/"blastdbcmd" @args/;	
					#print $SubjectDetail, "\n";					
					#print "--------------------\n";		
					
					@CurrentLine = split("\n",$SubjectDetail);											# Read lines and split the values delimited by newline.					
					
					if (substr($SubjectDetail,0,1) eq ">") {															# Identify the sequence header of blastdbcmd annotation result for subject hits
						$Initial = index($SubjectDetail, "[");
						$Last = index($SubjectDetail, "]");
						$SubjectOrganismName = substr($SubjectDetail, $Initial + 1, $Last - $Initial - 1);				# Extract the name of the organism in subject hit that is between brackets [...]
						print "Subject Organism is: ", $SubjectOrganismName, "\n";
						print "Query Organism is: ", $QueryOrganismName, "\n";				
						if ($SubjectOrganismName ne $QueryOrganismName) {												# 4. Check that this is not coming from the same organism that is already included in the database.											
							#print OUT  "Top Subject Hit: \n";
							#print $SubjectDetail;											# ************ this is the top hit that meets the filtering criteria. Comes with "\n" at the end.	****************
							print OUT $CurrentLine[0], "\n";									# printing only the header of the hit instead of all the details.
							print OUT $line;					# hasa built in "\n"
							$found = 1;											# Moving on to next query
						}
						else {
							#print OUT "Same organism", "\n";
							next;
						}					
					}
					else {																								# Actual sequence of the bastdbcmd annotation result
						chomp($CurrentLine[$i]);																		# Remove "\n" from lines since they will count as characters
						$QueryLength = $QueryLength + length($CurrentLine[$i]);							# Adding to length counter
						#print "Current Query Length: ", $QueryLength, "\n";
						#print "Current Line Length: ", length($CurrentLine[$i]), "\n";
					}
				}				 
			}	
		}
	}
}
close IN;
close OUT;
