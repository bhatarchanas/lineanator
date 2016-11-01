require 'trollop'

opts = Trollop::options do
	opt :dumpfile, "Provide the dump file with gi id-tax id pairs using the -d argument.", :type => :string, :short => "-d"
  	opt :seqfile, "Provide the 16s sequences in a FASTA format file using the -s argument.", :type => :string, :short => "-s"
  	opt :tablineageoutfile, "Provide the name of the output file which will contain the lineage in a tab delimited format using the -t argument.", :type => :string, :short => "-t"
	opt :fastalineageoutfile, "Provide the name of the output FASTA file in which the headers have the lineage using the -f argument.", :type => :string, :short => "-f"
	opt :placeholdernamesfile, "Provide the name of the file in which the placeholder names are present using the -p argument.", :type => :string, :short => "-p"
end

##### Assigning variables to the input and making sure we got all the inputs
opts[:dumpfile].nil?              == false  ? dump_file = opts[:dumpfile]                    : abort("Must supply a dump file which has all the gi id-tax id pairs using the '-d' argument.")
opts[:seqfile].nil?               == false  ? seq_file = opts[:seqfile]                      : abort("Must supply a FASTA file which has all the 16s sequences using the '-s' argument.")
opts[:tablineageoutfile].nil?     == false  ? tab_out_file = opts[:tablineageoutfile]        : abort("Must supply an output file name which will contain the lineage in a tab format using the '-t' argument.")
opts[:fastalineageoutfile].nil?   == false  ? fasta_out_file = opts[:fastalineageoutfile]    : abort("Must supply an output file name which will contain the lineage in a FASTA format using the '-f' argument.")
opts[:placeholdernamesfile].nil?  == false  ? ph_names_file = opts[:fastalineageoutfile]     : abort("Must supply a file which contains the place holder names using the '-p' argument.")
out_fasta_basename = File.basename(fasta_out_file, ".*")

# Run the script which gives a file with all the xmls
puts "Getting the file with XMLs for all tax id's ready..."
`ruby get_all_xml.rb -d #{dump_file} -s #{seq_file}`

# Run the script which parses the file with all xmls
puts "Parsing the file with all XMLs..."
`ruby parse_all_xml_string_2.rb -s #{seq_file} -t #{tab_out_file} -f #{fasta_out_file}` 

# Run the command to remove place holder names
puts "Removing place holder names..."
`usearch -fastx_getseqs #{fasta_out_file} -label_words #{ph_names_file} -label_field tax -notmatched #{out_fasta_basename}_filtered.fasta -fastaout excluded.fa`

# Run the command to train the sequences and obtain confidences
puts "Training the sequences to give a file with confidences..."
`usearch -utax_train #{out_fasta_basename}_filtered.fasta -taxconfsout #{out_fasta_basename}_confidence.tc -utax_splitlevels NVpcofgs -utax_trainlevels dpcofgs`

# Run the command to build the DB file
puts "Making the DB file! Final step..."
`usearch -makeudb_utax #{fasta_out_file} -taxconfsin #{out_fasta_basename}_confidence.tc -output #{out_fasta_basename}_reference_database.udb`