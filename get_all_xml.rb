require 'bio'
require 'trollop'

opts = Trollop::options do
  opt :dumpfile, "Provide the dump file with gi id-tax id pairs using the -d argument.", :type => :string, :short => "-d"
  opt :seqfile, "Provide the 16s sequences in a FASTA format file using the -s argument.", :type => :string, :short => "-s"
end

gi_taxid_nucl_dmp_file = File.open(opts[:dumpfile], "r")
microbial_ncbi_fasta_file = Bio::FlatFile.auto(opts[:seqfile])
#xml_file = File.open("all_xml_strings.txt", "w")
tax_id_file = File.open("tax_id_for_16s.txt", "w")

count_seqs = 0
microbial_ncbi_hash = {}
microbial_ncbi_fasta_file.each do |entry|
	count_seqs += 1
	#puts entry.definition
	gi_id = entry.definition.split("|")[1]
	full_header = entry.definition.gsub(" ", "_")
	na_seq = entry.naseq.upcase
	microbial_ncbi_hash[gi_id] = [full_header, na_seq]
end
#puts microbial_ncbi_hash
puts "Number of sequences in the FASTA file are: #{count_seqs}"

count_tax_id_found = 0
gi_taxid_nucl_hash = {}
gi_taxid_nucl_dmp_file.each do |line|
	line_split = line.split("\t")
	gi_id = line_split[0].strip
	tax_id = line_split[1].strip
	#puts gi_id
	if microbial_ncbi_hash.key?(gi_id)
		#puts gi_id, microbial_ncbi_hash[gi_id]
		count_tax_id_found += 1
		gi_taxid_nucl_hash[gi_id] = tax_id
		tax_id_file.puts("#{gi_id}\t#{tax_id}")
	end
end
#puts gi_taxid_nucl_hash
puts "Number of sequences whose gi id corresponded to tax id which were found in the dump file: #{count_tax_id_found}"

=begin
gi_taxid_nucl_hash.each do |gi_id, tax_id|
	ncbi = Bio::NCBI::REST::EFetch.new
	xml_string = ncbi.taxonomy(tax_id, "xml")
	xml_file.puts(xml_string)
end
=end