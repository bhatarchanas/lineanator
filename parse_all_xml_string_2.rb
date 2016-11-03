require 'bio'
require 'nokogiri'
require 'trollop'

opts = Trollop::options do
	opt :seqfile, "Provide the 16s sequences in a FASTA format file using the -s argument.", :type => :string, :short => "-s"
  	opt :tablineageoutfile, "Provide the name of the output file which will contain the lineage in a tab delimited format using the -t argument.", :type => :string, :short => "-t"
	opt :fastalineageoutfile, "Provide the name of the output FASTA file in which the headers have the lineage using the -f argument.", :type => :string, :short => "-f"
end

# NOTE: Got the all_xml_strings file and tax_id_for_16s.txt from get_all_xml.rb

# Read the file which maps the tax_id to gi_id (only for ones in NCBI)
tax_id_file = File.open("tax_id_for_16s.txt", "r")

# open the doc with all the xml strings as fragments suing nokogiri
doc = Nokogiri::XML::DocumentFragment.parse File.read("all_xml_strings.txt")

# File with all the origianl NCBI 16s seqs
ncbi_fasta_file = Bio::FlatFile.auto(opts[:seqfile])

# Write lineage with gi id into a file
lineage_file = File.open(opts[:tablineageoutfile], "w")
lineage_file.puts("gi_id\tkingdom\tphylum\tclass\torder\tfamily\tgenus\tspecies")

# Write the lineage along with seqs in this FASTA file
ncbi_lineage = File.open(opts[:fastalineageoutfile], "w") 

# Get a hash of all gi and tax id pairs
tax_gi_ids_hash = {}
tax_id_file.each_line do |line|
	gi_id = line.split("\t")[0].chomp  
	tax_id = line.split("\t")[1].chomp ### Has repeats
 	tax_gi_ids_hash[gi_id] = tax_id
end
#puts tax_gi_ids_hash.length

# Creating hashes which record the lineage
all_taxa_hash = {}
no_rank_hash = {}

# loop through each child node from the fragmenting
doc.children.each do |child|
	
	#puts child

	# Get the child node for each taxaset
	if child.to_s.start_with?("<TaxaSet")
			
		# convert taxaset into an xml string 
		xml_string = child.to_s
		xml_string_noko = Nokogiri::XML(xml_string)
		
		# get taxa ranks and scientific names for each org and store in arrays
		rank_array = []
		scientific_name_array = []
		taxID = ""
	
		xml_string_noko.xpath('//TaxaSet').each do |taxaSet_element|
			#puts taxaSet_element
			taxID = taxaSet_element.xpath('//TaxId').first.text
			taxaSet_element.xpath('//Rank').each do |rank_element|
				rank = rank_element.text
				#puts rank
				rank_array.push(rank)
			end
			taxaSet_element.xpath('//ScientificName').each do |scientific_name_element|
				scientific_name = scientific_name_element.text
				#puts scientific_name 
				scientific_name_array.push(scientific_name)
			end
		end
		#puts taxID
		#puts rank_array
		#puts scientific_name_array
	
		tax_gi_ids_hash.each do |gi_id, tax_id|
			if tax_id == taxID
				# Assign null strings to all the attributes 
				all_taxa_hash[gi_id] = {"kingdom" => "", "phylum" => "", "class" => "", "order" => "", "family" => "", "genus" => "", "species" => ""}
				# array within the no_rank_hash			
				array_in_no_rank = []

				(0..rank_array.length-1).each do |each_rank|
					#puts rank_array[each_rank]
					if rank_array[each_rank] == "superkingdom"
						all_taxa_hash[gi_id]["kingdom"] = scientific_name_array[each_rank]
					elsif rank_array[each_rank] == "phylum"
						all_taxa_hash[gi_id]["phylum"] = scientific_name_array[each_rank]
					elsif rank_array[each_rank] == "class"
						all_taxa_hash[gi_id]["class"] = scientific_name_array[each_rank]
					elsif rank_array[each_rank] == "order"
						all_taxa_hash[gi_id]["order"] = scientific_name_array[each_rank]
					elsif rank_array[each_rank] == "family"
						all_taxa_hash[gi_id]["family"] = scientific_name_array[each_rank]
					elsif rank_array[each_rank] == "genus"
						all_taxa_hash[gi_id]["genus"] = scientific_name_array[each_rank]
					elsif rank_array[each_rank] == "species"
						all_taxa_hash[gi_id]["species"] = scientific_name_array[each_rank]
					end

					# Get the no_rank_hash
					if rank_array[each_rank] == "no rank"
						array_in_no_rank.push(scientific_name_array[each_rank])
						no_rank_hash[gi_id]= array_in_no_rank
					end

				end

			end	

		end

	end

end
#puts all_taxa_hash.length
#puts all_taxa_hash
#puts no_rank_hash 

# Filling the taxa levels which were unavailable from the xml using the no rank levels 
all_taxa_hash.each do |gi_id, sub_hash|
	#puts key
	#puts value
	counter = 0
	sub_hash.each do |rank, sc|
		if sc == ""
			counter += 1
			#puts tax_id, rank, sc
			#puts no_rank_hash[gi_id].length
	
			# When the first null attribute is getting filled
			if counter == 1
				if no_rank_hash[gi_id].length-1 > 1
					if no_rank_hash[gi_id][0] != "cellular organisms"
						sub_hash["species"] = no_rank_hash[gi_id][0]
						sub_hash[rank] = "unsure_"+no_rank_hash[gi_id][2]
					else
						sub_hash[rank] = "unsure_"+no_rank_hash[gi_id][1]
					end
				elsif no_rank_hash[gi_id].length-1 == 1
					if no_rank_hash[gi_id][0] != "cellular organisms"
						sub_hash["species"] = no_rank_hash[gi_id][0]
						sub_hash[rank] = "unclassified"
					else
						sub_hash[rank] = "unsure_"+no_rank_hash[gi_id][1]
					end
				else
					sub_hash[rank] = "unclassified"
				end	
				all_taxa_hash[gi_id] = sub_hash
			
			# When the second null attribute is getting filled
			elsif counter == 2
				#puts no_rank_hash[gi_id]
				if no_rank_hash[gi_id].length-1 > 2
					if no_rank_hash[gi_id][0] != "cellular organisms"
						sub_hash[rank] = "unsure_"+no_rank_hash[gi_id][3]
					else
						sub_hash[rank] = "unsure_"+no_rank_hash[gi_id][2]
					end
				elsif no_rank_hash[gi_id].length-1 == 2
					if no_rank_hash[gi_id][0] != "cellular organisms"
						sub_hash[rank] = "unclassified"
					else
						sub_hash[rank] = "unsure_"+no_rank_hash[gi_id][2]
					end
				else
					sub_hash[rank] = "unclassified"
				end	
				all_taxa_hash[gi_id] = sub_hash

			# When the third null attribute is getting filled
			elsif counter == 3
				#puts no_rank_hash[gi_id]
				if no_rank_hash[gi_id].length-1 > 3
					if no_rank_hash[gi_id][0] != "cellular organisms"
						sub_hash[rank] = "unsure_"+no_rank_hash[gi_id][4]
					else
						sub_hash[rank] = "unsure_"+no_rank_hash[gi_id][3]
					end
				elsif no_rank_hash[gi_id].length-1 == 3
					if no_rank_hash[gi_id][0] != "cellular organisms"
						sub_hash[rank] = "unclassified"
					else
						sub_hash[rank] = "unsure_"+no_rank_hash[gi_id][3]
					end
				else
					sub_hash[rank] = "unclassified"
				end	
				all_taxa_hash[gi_id] = sub_hash

			# If there are more than 3 null attributes, just call it "unclassified"
			else
				sub_hash[rank] = "unclassified"
				all_taxa_hash[gi_id] = sub_hash
			end	
		end	
	end	
end
#puts all_taxa_hash.length
#puts all_taxa_hash

# Writing lineage to files 
ncbi_fasta_file.each do |entry|
	gi_id = entry.definition.split("|")[1].chomp
	
	if all_taxa_hash.key?(gi_id)
		
		# Split and modify the species names and definition lines
		def_mod_split = entry.definition.chomp.split("|")
    	def_string = def_mod_split[0]+"|"+def_mod_split[1]+"|"+def_mod_split[2]+"|"+def_mod_split[3]+";"
    	def_string_2 = def_string.tr("\s","")
  		species_name = def_mod_split[4].split(" ")[0..1].join("_").tr('^A-Za-z0-9_', '')
    	species_name_1 = ",s:"+species_name+";"

    	# Make sure the sceintific names of each taxa level has no special characters and replace the spaces with "_"
    	kingdom = all_taxa_hash[gi_id]["kingdom"].tr('^A-Za-z0-9_ ', '').tr(" ", "_")
    	phylum = all_taxa_hash[gi_id]["phylum"].tr('^A-Za-z0-9_ ', '').tr(" ", "_")
    	clas = all_taxa_hash[gi_id]["class"].tr('^A-Za-z0-9_ ', '').tr(" ", "_")
    	order = all_taxa_hash[gi_id]["order"].tr('^A-Za-z0-9_ ', '').tr(" ", "_")
    	family = all_taxa_hash[gi_id]["family"].tr('^A-Za-z0-9_ ', '').tr(" ", "_")
    	genus = all_taxa_hash[gi_id]["genus"].tr('^A-Za-z0-9_ ', '').tr(" ", "_")

		# Get the lineage and write in the FASTA file 
		tax_string = "tax=d:"+kingdom+",p:"+phylum+",c:"+clas+",o:"+order+",f:"+family+",g:"+genus
		to_print = (">"+def_string_2+tax_string+species_name_1)
    	ncbi_lineage.puts(to_print)
    	ncbi_lineage.puts(entry.naseq.upcase)
    
    	# Get the lineage and write in the tab delimited file 
    	lineage_file.puts("#{gi_id}\t#{kingdom}\t#{phylum}\t#{clas}\t#{order}\t#{family}\t#{genus}\t#{species_name}")
	end
end
	
ncbi_lineage.close
lineage_file.close