#!/bin/bash
# runFiles.sh
# A Bash script to manaage splitting, triplifying and reasoning files.  We assume the 
# configuration file has been made and the pre-processing routine has been run.

# Arguments
# Display help and exit if arguments not equal to the expected number
if [ $# -ne 2 ] 
then
   echo "Invalid number of arguments"
   echo "runFiles.sh {project} {filename.csv}"
   exit 1
fi

# project = the short name of the project we are working with (e.g. npn, pep725)
project=$1
# inputFilename = the name of the input file to work with. This file is a CSV
# format file appearing in the directory specified by the output_csv_dir property
inputFilename=$2

curdir=$PWD

# prop function for adding in script properties
# replace content in square brackets with project variable
function prop {
    grep -w "${1}" $curdir/build.properties|cut -d'=' -f2 | sed "s/\[project\]/$project/g"
}

# Reason
# execute the reasoning process for a list of files
# NOTE: this function will be simplified greatly when ontopilot comes
# up with a separate build task for instance data.  Currently, there
# are coded here several work-arounds to make it work before this happens.
function reason {
    echo "#=========================================================="
    echo "# Reason "
    echo "#=========================================================="
    #The base ontology file could not be found: /Users/jdeck/IdeaProjects/pheno_paper/data/npn/output_unreasoned_n3/test_1.csv.ttl
    files=$1
    for file in $split_files
    do
	# get just the filename
	localFileName=$(basename $file)
	incomingFile=$(prop 'unreasoned_dir')$localFileName.ttl

	# set file paths
	outgoingFile=Outgoing/$localFileName.owl
	reasonedFile=$curdir/build/$localFileName-reasoned.owl
	destinationFile=$(prop 'reasoned_dir')$localFileName.owl

	# clean build directory before running
	rm -f $curdir/build/*

	# adjust configuration file
	sed -i "s|^base_ontology_file =.*|base_ontology_file = $incomingFile|" $(prop 'reasoner_config')
	sed -i "s|^ontology_file =.*|ontology_file = $outgoingFile|" $(prop 'reasoner_config')

	cd $(prop 'ppo_pre_reasoner_dir')
	# run ontopilot
	$(prop 'ontopilot') --reason make ontology \
		-c $(prop 'reasoner_config') \
		2> $outgoingFile.err

	echo "    writing $destinationFile"
	mv $reasonedFile $destinationFile
	cd $curdir

    done
}

# Triplify 
# execute the triplify process for a list of files
function triplify {
    echo "#=========================================================="
    echo "# Triplify "
    echo "#=========================================================="
    files=$1
    # clean build directory before running
    rm -f $curdir/output/*
    for file in $split_files
    do
        java -Xmx4048m -jar $(prop 'triplifier') \
	    -i $file \
	    -o $(prop 'unreasoned_dir') \
	    -c $(prop 'triplifier_config') \
	    -F TURTLE
    done
}

# Return all of the files that have been split WITHOUT the extension
function getSplitFiles {
    lfilename=$(basename "$inputFilename")
    #just extension
    lextension="${lfilename##*.}"
    #filename w/out extension
    lfilename="${lfilename%.*}"
    # return files without extension
    split_files=$(prop 'output_csv_split_dir')$lfilename"_*.csv"
}

# Split Files
# Run the file splitting process
# splits incoming files into 50,000 sets numbered _1,_2, etc...
function split {
    python fileSplitter.py \
        $(prop 'output_csv_dir')$inputFilename \
	$(prop 'output_csv_split_dir')
}

# Split Files
split

# Fetch Split Files into split_files global array
getSplitFiles 

# Triplify Files
triplify 

# Reason Files
reason 
