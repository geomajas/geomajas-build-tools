#!/bin/bash

####################################################
# SET SOME VARIABLES FOR EASE OF USE IN THIS SCRIPT.
####################################################

# INFO !!!
# --------
# DELETE THE TARGET FOLDERS FOR REBUILDING THE ENTIRE DOCUMENTATION AND JAVADOC.
# OTHERWISE THIS SCRIPT WILL ONLY PROCESS THE LATEST SNAPSHOTS.

# Set this variable to 0 when running in production.
# Everything else for development mode.
developmentMode=1

# CSV filenames.
artefactsFile=artifacts.csv
projectsFile=projects.csv

# A variable for checking of this script should build everything.
cleanRun=0

# Global counter
counter=0

# When not running in development mode use the following variables.
# Otherwise use temp folders in the home directory for the current user.
if [[ $developmentMode -eq 0 ]]
then
    targetDirForDocumentation="/srv/www/files.geomajas.org/htdocs/documentation"
    targetDirForJavaDoc="/srv/www/files.geomajas.org/htdocs/javadoc"
else
    # Get the user home folder (eg. /home/username) for developmentMode.
    userHomeDirectory=$(eval echo ~${SUDO_USER});
    targetDirForDocumentation="$userHomeDirectory/TEMP/documentation"
    targetDirForJavaDoc="$userHomeDirectory/TEMP/javadoc"
fi

if [[ "$1" == "snapshots" ]]
then
  	buildSnapshots="true";
fi


################################################################
# GLOBAL FUNCTIONS. (Have to be declared before executing them!)
################################################################

#####################################################
# Append a Google analytics script to a html file.
#
# PARAM a location where the html files are residing.
#####################################################
function addGoogleAnalyticsScriptTo()
{
    # Find all html file in the target direcotory and add the Google analytics script to the end of the file.
    find ${1} -type f -iname "*.html" | while read i; do

        #printf "%s%s\n" "- Adding analytics script to: " "$i";

        # Add the script before the closing body tag with some formatting.
        sed -i 's*</BODY>\|</body>*\
        \
        <script type="text/javascript">\
            var _gaq = _gaq || [];\
            _gaq.push(["_setAccount", "UA-8078092-3"]);\
            _gaq.push(["_trackPageview"]);\
        \
            (function() {\
                var ga = document.createElement("script"); ga.type = "text/javascript"; ga.async = true;\
                ga.src = ("https:" == document.location.protocol ? "https://ssl" : "http://www") + ".google-analytics.com/ga.js";\
                var s = document.getElementsByTagName("script")[0]; s.parentNode.insertBefore(ga, s);\
            })();\
        </script>\n\n&*' "$i"

    done
}

function readVersion()
{
	lookupProject=$1
	unset projectVersion;

	while IFS=, read -r myProject releaseVersion snapshotVersion
	do
		if [ "$myProject" == "$lookupProject" ]
		then
			projectVersion=$releaseVersion;
		fi
	done < $projectsFile
}
####################################################
# Generate documentation for projects in a CSV file.
####################################################
function generateDocumentation()
{
	# READ A CSV FILE AND GENERATE THE DOCUMENTATION FOR EACH PROJECT.
	##################################################################

	printf "\n%s\n" "# PROCESSING DOCUMENTATION FOR THE FOLLOWING ARTIFACTS:";

	# Set permissions to run commands.
	PWD=`pwd`

	# Read the csv file line by line.
	while IFS=, read -r project artifactId groupId name path
	do
		readVersion $project;
		releaseVersion=$projectVersion;

        # Get the latest snapshotVersion for this artifact.
        if [ -n "$buildSnapshots" ]
        then
        	LATEST=$(curl --silent "http://apps.geomajas.org/nexus/service/local/artifact/maven/resolve?r=snapshots&g=$groupId&a=$artifactId&v=LATEST&e=jar")
        	snapshotVersion=$(grep -oPm1 "(?<=<baseVersion>)[^<]+" <<< $LATEST)
        fi

	    # When the artifactId has documentation in it's name do the following ...
	    if [[ $artifactId =~ .*documentation*. ]] || [[ $groupId =~ .*documentation*. ]]
	    then

			counter=$((counter+1))
			printf "\n%-10s%-40s%-60s%-20s%-20s%-20s\n" "$counter" "$project" "$artifactId" "$releaseVersion" "$milestoneVersion" "$snapshotVersion";

			# Create the documentation for the releaseVersion when there is one.
			if [ -n "$releaseVersion" ] && [[ $cleanRun -eq 1 ]]
			then
				# Extract to subfolders when a plugin/widget is found
				if [[ $groupId =~ .*plugin*. ]] || [[ $groupId =~ .*widget*. ]]
				then
					directory=$targetDirForDocumentation/$project/$releaseVersion/plugin/$artifactId;
					if [ ! -d "$directory" ]
					then
						LOCATION="https://oss.sonatype.org/service/local/artifact/maven/redirect?r=releases&g=$groupId&a=$artifactId&v=$releaseVersion&e=jar"
						wget -q --no-check-certificate $LOCATION -O docs.zip
						# Only execute this when the file exists and is bigger than 0kb.
						if [ -s docs.zip ]
						then
							mkdir -p $directory
							unzip -q -o docs.zip -d $directory
							# Add Google analytics script to extracted content.
							addGoogleAnalyticsScriptTo $directory
							rm docs.zip
						fi
					fi
				else
					directory=$targetDirForDocumentation/$project/$releaseVersion/$artifactId;
					if [ ! -d "$directory" ]
					then
						LOCATION="https://oss.sonatype.org/service/local/artifact/maven/redirect?r=releases&g=$groupId&a=$artifactId&v=$releaseVersion&e=jar"
						wget -q --no-check-certificate $LOCATION -O docs.zip
						# Only execute this when the file exists and is bigger than 0kb.
						if [ -s docs.zip ]
						then
							mkdir -p $directory
							unzip -q -o docs.zip -d $directory
							# Add Google analytics script to extracted content.
							addGoogleAnalyticsScriptTo $directory
							rm docs.zip
						fi
					fi
				fi
			fi
		fi

		 # Create the documentation for the snapshotVersion when there is one.
		if [ -n "$snapshotVersion" ] && [ -n "$buildSnapshots" ]
		then
			LOCATION="http://apps.geomajas.org/nexus/service/local/artifact/maven/redirect?r=latest&g=$groupId&a=$artifactId&v=$snapshotVersion&e=jar"
			wget -q --no-check-certificate $LOCATION -O docs.zip

			# Only execute this when the file exists and is bigger than 0kb.
			if [ -s docs.zip ]
			then
				# Extract to subfolders when a plugin/widget is found
				if [[ $groupId =~ .*plugin*. ]] || [[ $groupId =~ .*widget*. ]]
				then
					mkdir -p $targetDirForDocumentation/$project/snapshot/plugin/$artifactId
					unzip -q -o docs.zip -d $targetDirForDocumentation/$project/snapshot/plugin/$artifactId
					# Add Google analytics script to extracted content.
					addGoogleAnalyticsScriptTo $targetDirForDocumentation/$project/snapshot/plugin/$artifactId
				else
					mkdir -p $targetDirForDocumentation/$project/snapshot/$artifactId
					unzip -q -o docs.zip -d $targetDirForDocumentation/$project/snapshot/$artifactId
					# Add Google analytics script to extracted content.
					addGoogleAnalyticsScriptTo $targetDirForDocumentation/$project/snapshot/$artifactId
				fi
				rm docs.zip
			fi
		fi
	done < $artefactsFile
}

##############################################
# Generate javadoc for projects in a CSV file.
##############################################
function generateJavaDoc()
{

	printf "\n%s\n" "# PROCESSING JAVADOC FOR THE FOLLOWING ARTIFACTS:";

	while IFS=, read project artifactId groupId name releaseVersion milestoneVersion path
	do
		readVersion $project;
		releaseVersion=$projectVersion;

		# Get the latest snapshotVersion for this artifact.
        if [ -n "$buildSnapshots" ]
        then
			LATEST=$(curl --silent "http://apps.geomajas.org/nexus/service/local/artifact/maven/resolve?r=snapshots&g=$groupId&a=$artifactId&v=LATEST&e=jar")
			snapshotVersion=$(grep -oPm1 "(?<=<baseVersion>)[^<]+" <<< $LATEST)
		fi

		# Create the javadoc for the releaseVersion when there is one.
		if [ -n "$releaseVersion" ] && [[ $cleanRun -eq 1 ]]
		then
			# Extract to subfolders when a plugin/widget is found
			if [[ $groupId =~ .*plugin*. ]] || [[ $groupId =~ .*widget*. ]]
			then
				directory=$targetDirForJavaDoc/$project/$releaseVersion/plugin/$artifactId;
				if [ ! -d "$directory" ]
				then
					LOCATION="https://oss.sonatype.org/service/local/artifact/maven/redirect?r=releases&g=$groupId&a=$artifactId&v=$releaseVersion&e=jar&c=javadoc"
					wget -q --no-check-certificate $LOCATION -O javadocs.zip

					# Only execute this when the file exists and is bigger than 0kb.
					if [ -s javadocs.zip ]
					then
						printf "\n%-30s%s\n" "- JAVADOC FOR RELEASE FOUND: " $LOCATION;

						mkdir -p $directory
						unzip -q -o javadocs.zip -d $directory
						# Add Google analytics script to extracted content.
						addGoogleAnalyticsScriptTo $directory
						rm javadocs.zip
					fi
				fi
			else
				directory=$targetDirForJavaDoc/$project/$releaseVersion/plugin/$artifactId;
				if [ ! -d "$directory" ]
				then
					LOCATION="https://oss.sonatype.org/service/local/artifact/maven/redirect?r=releases&g=$groupId&a=$artifactId&v=$releaseVersion&e=jar&c=javadoc"
					wget -q --no-check-certificate $LOCATION -O javadocs.zip

					# Only execute this when the file exists and is bigger than 0kb.
					if [ -s javadocs.zip ]
					then
						printf "\n%-30s%s\n" "- JAVADOC FOR RELEASE FOUND: " $LOCATION;

						mkdir -p $targetDirForJavaDoc/$project/$releaseVersion/$artifactId
						unzip -q -o javadocs.zip -d $targetDirForJavaDoc/$project/$releaseVersion/$artifactId
						# Add Google analytics script to extracted content.
						addGoogleAnalyticsScriptTo $targetDirForJavaDoc/$project/$releaseVersion/$artifactId
						rm javadocs.zip
					fi
				fi
			fi
		else
			printf "\n%-30s%s\n" "- JDOC FOR RELEASE MISSING: " $LOCATION;
		fi

		# Create the javadoc for the snapshotVersion when there is one.
		if [ -n "$snapshotVersion" ] && [ -n "$buildSnapshots" ]
		then
		    LOCATION="http://apps.geomajas.org/nexus/service/local/artifact/maven/redirect?r=snapshots&g=$groupId&a=$artifactId&v=LATEST&e=jar&c=javadoc"
		    wget -q --no-check-certificate $LOCATION -O javadocs.zip

		    # Only execute this when the file exists and is bigger than 0kb.
		    if [ -s javadocs.zip ]
		    then
		        printf "\n%-30s%s\n" "- JAVADOC FOR SNAPSHOT: " $LOCATION;

		        # Extract to subfolders when a plugin/widget is found
		        if [[ $groupId =~ .*plugin*. ]] || [[ $groupId =~ .*widget*. ]]
		        then
		            mkdir -p $targetDirForJavaDoc/$project/snapshot/plugin/$artifactId
		            unzip -q -o javadocs.zip -d $targetDirForJavaDoc/$project/snapshot/plugin/$artifactId
		            # Add Google analytics script to extracted content.
	                addGoogleAnalyticsScriptTo $targetDirForJavaDoc/$project/snapshot/plugin/$artifactId
		        else
		            mkdir -p $targetDirForJavaDoc/$project/snapshot/$artifactId
		            unzip -q -o javadocs.zip -d $targetDirForJavaDoc/$project/snapshot/$artifactId
		            # Add Google analytics script to extracted content.
	                addGoogleAnalyticsScriptTo $targetDirForJavaDoc/$project/snapshot/$artifactId
		        fi
		        rm javadocs.zip
            else
                printf "\n%-30s%s\n" "- JDOC FOR SNAPSHOT MISSING: " $LOCATION;
		    fi
		fi

	done < $artefactsFile
}


###################################################
# Delete all snapshot directories for a given path.
###################################################
function deleteSnapshotDirectoriesFrom()
{
	printf "\n%s%s\n\n" "# DELETING ALL SNAPSHOT DIRECTORIES FROM: " "${1}";

    # Find all snapshot directories and delete them.
    find ${1} -type d -iname "snapshot" -prune -exec rm -rvf {} \;

}

#########################################################################################
###                   ###################################################################
### SCRIPT EXECUTION  ###################################################################
###                   ###################################################################
#########################################################################################

# Only process the snapshots when the target directories already exist.
# Otherwise set cleanRun to process everything from scratch.
if [ -n "$buildSnapshots" ] && [ -d "$targetDirForDocumentation" ] || [ -n "$buildSnapshots" ] && [ -d "$targetDirForJavaDoc" ]
then
	deleteSnapshotDirectoriesFrom $targetDirForDocumentation;
	deleteSnapshotDirectoriesFrom $targetDirForJavaDoc;
else
	cleanRun=1
fi

generateDocumentation;

generateJavaDoc;

printf "\n%s\n\n" "# SCRIPT IS FINISHED.";
