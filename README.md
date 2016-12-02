Author - Archana S Bhat

###Introduction:

Lineanator uses USEARCH and NCBI to create a database file with confidences up to the species level. 
This database file can be used in MC-SMRT to assign taxonomy and confidences to OTUs in a microbiome community.


###Installation and Dependencies: 

1) Ruby gems such as bio, troloop and nokogiri are required for Lineanator to function. Use the "gem install {name_of_the_gem}" command to install these gems.

2) Download and install usearch v8.1.
   Create a soft link pointing towards this version of usearch and name it "usearch". The soft link name **HAS TO BE** usearch, this is **VERY IMPORTANT**.


###Usage: 

ruby lineanator.rb 	[-h] [-d DUMP_FILE] [-s SEQ_FILE] <br /> 
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[-t TAB_DELIMITED_LINEAGE_OUTPUT_FILE] <br />
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[-f FASTA_LINEAGE_OUTPUT_FILE] <br />
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[-p PLACE_HOLDER_NAMES_FILE] <br />


###Arguments explained:

1) DUMP_FILE - This text file serves as a source to map between the gi id's in the SEQ_FILE and get the tax id's corresponding to each gi id. 
   The dump file we used was taken from NCBI's taxonomy FTP (ftp://ftp.ncbi.nlm.nih.gov/pub/taxonomy/). 
   The directory called gi_taxid_nucl.zip in the FTP had a file with gi id in the first column and tax id in the second column (no headers).
   The file "sample_gi_taxid_nucl.dmp" is an example of the dump file that can be used. 

2) SEQ_FILE - This is a FASTA file with all the 16s sequences which you want to build a database from. 
   The headers of the FASTA file should look like the sequences in the file "sample_16sMicrobial_ncbi.fasta" for example.
   When all the 16s sequences are taken from NCBI - Command will be up soon, the headers appear in this format at once. This is what we used to create our database.

3) TAB_DELIMITED_LINEAGE_OUTPUT_FILE - This is the name of an output file which will have the lineage as a tab delimited file along with the gi id as one of the columns.

4) FASTA_LINEAGE_OUTPUT_FILE - This is the name of the FASTA output file which will have the lineage in the headers. 
   The lineage in the header is in the format which is required by USEARCH to create the database file. 

5) PLACE_HOLDER_NAMES_FILE - This is the file which will contain a list (a column) of all the words which can confuse the training process for building a database. 
   Each line of the text file contains  a word to match the label/header in the FASTA file. All the sequence headers which match to any of the words in this list will be removed before training the database.


###Output files:

Two of the output files are the ones which you gave as arguments to lineanator, these are expalined above.

The basename of the FASTA_LINEAGE_OUTPUT_FILE given by you is used for creating other files using USEARCH commands. 
For example, if the name of your FASTA_LINEAGE_OUTPUT_FILE is "16sMicrobial_ncbi_lineage.fasta", the output files created will be:

1) 16sMicrobial_ncbi_lineage_filtered.fasta - File without the placeholder names.

2) 16sMicrobial_ncbi_lineage_confidence.tc - File after training the sequences, also has the confidences.

3) 16sMicrobial_ncbi_lineage_reference_database.udb - Final database file in udb format

 
###Built with: 

ruby 2.2.1p85 (2015-02-26 revision 49769) [x86_64-linux]