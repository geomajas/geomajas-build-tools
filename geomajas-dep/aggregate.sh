#!/bin/bash

####################################################
# SET SOME VARIABLES FOR EASE OF USE IN THIS SCRIPT.
####################################################

# Set thisvariable to 0 when running in production.
# Everything else for development mode.
developmentMode=0

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

fileName=artifacts.csv
oldFileName=oldArtifacts.csv
counter=0

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
	printf "\n%s\n\n" "# ATTACHING GOOGLE ANALYTICS TO ...";

    # Find all html file in the target direcotory and add the Google analytics script to the end of the file.
    find ${1} -type f -iname "*.html" | while read i; do

        printf "%s%s\n" "Adding script to: " "$i";

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

####################################################
# Generate documentation for projects in a CSV file.
####################################################
function generateDocumentation()
{
	# READ A CSV FILE AND GENERATE THE DOCUMENTATION FOR EACH PROJECT.
	##################################################################

	printf "\n%s\n\n" "# GENERATING DOCUMENTATION FOR THE FOLLOWING PROJECTS:";

	# Set permissions to run commands.
	PWD=`pwd`

	# Read the csv file line by line.
	while IFS=, read -r project artifactId groupId name releaseVersion milestoneVersion path
	do
        # Get the latest snapshotVersion for this artifact.
        LATEST=$(curl --silent "http://apps.geomajas.org/nexus/service/local/artifact/maven/resolve?r=snapshots&g=$groupId&a=$artifactId&v=LATEST&e=jar")
        snapshotVersion=$(grep -oPm1 "(?<=<baseVersion>)[^<]+" <<< $LATEST)

	    # When the artifactId has documentation in it's name do the following ...
	    if [[ $artifactId =~ .*documentation*. ]]
	    then

	        counter=$((counter+1))
	        printf "%-10s%-40s%-60s%-30s%-20s%-20s%-20s\n" "$counter" "$project" "$artifactId" "$groupId" "$releaseVersion" "$milestoneVersion" "$snapshotVersion";

	        # Create the documentation for the releaseVersion when there is one.
	        if [ -n "$releaseVersion" ]
	        then
	            LOCATION="https://oss.sonatype.org/service/local/artifact/maven/redirect?r=releases&g=$groupId&a=$artifactId&v=$releaseVersion&e=jar"
	            wget -q --no-check-certificate $LOCATION -O docs.zip

	            # Only execute this when the file exists and is bigger than 0kb.
	            if [ -s docs.zip ]
	            then
	                # Extract to subfolders when a plugin/widget is found
	                if [[ $groupId =~ .*plugin*. ]] || [[ $groupId =~ .*widget*. ]]
	                then
	                    mkdir -p $targetDirForDocumentation/$project/$releaseVersion/plugin/$artifactId
	                    unzip -q -o docs.zip -d $targetDirForDocumentation/$project/$releaseVersion/plugin/$artifactId
	                else
	                    mkdir -p $targetDirForDocumentation/$project/$releaseVersion
	                    unzip -q -o docs.zip -d $targetDirForDocumentation/$project/$releaseVersion
	                fi
	                rm docs.zip
	            fi
	        fi

	        # Create the documentation for the milestoneVersion when there is one.
	        if [ -n "$milestoneVersion" ]
	        then
	            LOCATION="https://oss.sonatype.org/service/local/artifact/maven/redirect?r=releases&g=$groupId&a=$artifactId&v=$milestoneVersion&e=jar"
	            wget -q --no-check-certificate $LOCATION -O docs.zip

	            # Only execute this when the file exists and is bigger than 0kb.
	            if [ -s docs.zip ]
	            then
	                # Extract to subfolders when a plugin/widget is found
	                if [[ $groupId =~ .*plugin*. ]] || [[ $groupId =~ .*widget*. ]]
	                then
	                    mkdir -p $targetDirForDocumentation/$project/$milestoneVersion/plugin/$artifactId
	                    unzip -q -o docs.zip -d $targetDirForDocumentation/$project/$milestoneVersion/plugin/$artifactId
	                else
	                    mkdir -p $targetDirForDocumentation/$project/$milestoneVersion
	                    unzip -q -o docs.zip -d $targetDirForDocumentation/$project/$milestoneVersion
	                fi
	                rm docs.zip
	            fi
	        fi

	         # Create the documentation for the snapshotVersion when there is one.
	        if [ -n "$snapshotVersion" ]
	        then
	            LOCATION="http://apps.geomajas.org/nexus/service/local/artifact/maven/redirect?r=latest&g=$groupId&a=$artifactId&v=$snapshotVersion&e=jar"
	            wget -q --no-check-certificate $LOCATION -O docs.zip

	            # Only execute this when the file exists and is bigger than 0kb.
	            if [ -s docs.zip ]
	            then
	                # Extract to subfolders when a plugin/widget is found
	                if [[ $groupId =~ .*plugin*. ]] || [[ $groupId =~ .*widget*. ]]
	                then
	                    mkdir -p $targetDirForDocumentation/$project/$snapshotVersion/plugin/$artifactId
	                    unzip -q -o docs.zip -d $targetDirForDocumentation/$project/$snapshotVersion/plugin/$artifactId
	                else
	                    mkdir -p $targetDirForDocumentation/$project/$snapshotVersion
	                    unzip -q -o docs.zip -d $targetDirForDocumentation/$project/$snapshotVersion
	                fi
	                rm docs.zip
	            fi
	        fi

	    fi
	done < $fileName
}

####################################################
# Generate documentation for projects in a CSV file.
####################################################
function generateOldDocumentation()
{
	# READ A CSV FILE AND GENERATE THE DOCUMENTATION FOR EACH PROJECT.
	##################################################################

	printf "\n%s\n\n" "# GENERATING DOCUMENTATION FOR THE FOLLOWING PROJECTS:";

	# Read the csv file line by line.
	while IFS=, read -r project artifactId groupId releaseVersion
	do
	    # Correct permissions ...?
	    PWD=`pwd`

	    # When the artifactId has documentation in it's name do the following ...
	    if [[ $artifactId =~ .*documentation*. ]]
	    then

	        counter=$((counter+1))
	        printf "%-10s%-40s%-60s%-30s%-20s%-20s%-20s\n" "$counter" "$project" "$artifactId" "$groupId" "$releaseVersion";

	        # Create the documentation for the releaseVersion when there is one.
	        if [ -n "$releaseVersion" ]
	        then
	            LOCATION="https://oss.sonatype.org/service/local/artifact/maven/redirect?r=releases&g=$groupId&a=$artifactId&v=$releaseVersion&e=jar"
	            wget -q --no-check-certificate $LOCATION -O docs.zip

	            # Only execute this when the file exists and is bigger than 0kb.
	            if [ -s docs.zip ]
	            then
	                # Extract to subfolders when a plugin/widget is found
	                if [[ $groupId =~ .*plugin*. ]] || [[ $groupId =~ .*widget*. ]]
	                then
	                    mkdir -p $targetDirForDocumentation/$project/$releaseVersion/plugin/$artifactId
	                    unzip -q -o docs.zip -d $targetDirForDocumentation/$project/$releaseVersion/plugin/$artifactId
	                else
	                    mkdir -p $targetDirForDocumentation/$project/$releaseVersion
	                    unzip -q -o docs.zip -d $targetDirForDocumentation/$project/$releaseVersion
	                fi
	                rm docs.zip
	            fi
	        fi

	    fi
	done < $oldFileName
}

##############################################
# Generate javadoc for projects in a CSV file.
##############################################
function generateJavaDoc()
{

	printf "\n%s\n\n" "# CREATING JAVADOC FOR THE FOLLOWING PROJECTS:";

	while IFS=, read project artifactId groupId name releaseVersion milestoneVersion path
	do
		# Get the latest snapshotVersion for this artifact.
        LATEST=$(curl --silent "http://apps.geomajas.org/nexus/service/local/artifact/maven/resolve?r=snapshots&g=$groupId&a=$artifactId&v=LATEST&e=jar")
        snapshotVersion=$(grep -oPm1 "(?<=<baseVersion>)[^<]+" <<< $LATEST)

		# Create the javadoc for the releaseVersion when there is one.
		if [ -n "$releaseVersion" ]
		then
		    LOCATION="https://oss.sonatype.org/service/local/artifact/maven/redirect?r=releases&g=$groupId&a=$artifactId&v=$releaseVersion&e=jar&c=javadoc"
		    wget -q --no-check-certificate $LOCATION -O javadocs.zip

		    # Only execute this when the file exists and is bigger than 0kb.
		    if [ -s javadocs.zip ]
		    then
		        # Extract to subfolders when a plugin/widget is found
		        if [[ $groupId =~ .*plugin*. ]] || [[ $groupId =~ .*widget*. ]]
		        then
		            mkdir -p $targetDirForJavaDoc/$project/$releaseVersion/plugin/$artifactId
		            unzip -q -o javadocs.zip -d $targetDirForJavaDoc/$project/$releaseVersion/plugin/$artifactId
		        else
		            mkdir -p $targetDirForJavaDoc/$project/$releaseVersion
		            unzip -q -o javadocs.zip -d $targetDirForJavaDoc/$project/$releaseVersion
		        fi
		        # https://oss.sonatype.org/service/local/artifact/maven/redirect?r=releases&g=org.geomajas.widget&a=geomajas-widget-utility&v=1.15.0-M2&e=jar&c=javadoc
		        printf "%-30s%s\n" "- JAVADOC FOR RELEASE FOUND: " $LOCATION;
		        rm javadocs.zip
            else
                printf "%-30s%s\n" "- JDOC FOR RELEASE MISSING: " $LOCATION;
		    fi
		fi

		# Create the javadoc for the milestoneVersion when there is one.
		if [ -n "$milestoneVersion" ]
		then
		    LOCATION="https://oss.sonatype.org/service/local/artifact/maven/redirect?r=releases&g=$groupId&a=$artifactId&v=$milestoneVersion&e=jar&c=javadoc"
		    wget -q --no-check-certificate $LOCATION -O javadocs.zip

		    # Only execute this when the file exists and is bigger than 0kb.
		    if [ -s javadocs.zip ]
		    then
		        # Extract to subfolders when a plugin/widget is found
		        if [[ $groupId =~ .*plugin*. ]] || [[ $groupId =~ .*widget*. ]]
		        then
		            mkdir -p $targetDirForJavaDoc/$project/$milestoneVersion/plugin/$artifactId
		            unzip -q -o javadocs.zip -d $targetDirForJavaDoc/$project/$milestoneVersion/plugin/$artifactId
		        else
		            mkdir -p $targetDirForJavaDoc/$project/$milestoneVersion
		            unzip -q -o javadocs.zip -d $targetDirForJavaDoc/$project/$milestoneVersion
		        fi
		        # https://oss.sonatype.org/service/local/artifact/maven/redirect?r=milestones&g=org.geomajas.widget&a=geomajas-widget-utility&v=1.15.0-M2&e=jar&c=javadoc
		        printf "%-30s%s\n" "- JAVADOC FOR milestone FOUND: " $LOCATION;
		        rm javadocs.zip
            else
                printf "%-30s%s\n" "- JDOC FOR milestone MISSING: " $LOCATION;
		    fi
		fi

		# Create the javadoc for the snapshotVersion when there is one.
		if [ -n "$snapshotVersion" ]
		then
		    LOCATION="http://apps.geomajas.org/nexus/service/local/artifact/maven/redirect?r=snapshots&g=$groupId&a=$artifactId&v=LATEST&e=jar&c=javadoc"
		    wget -q --no-check-certificate $LOCATION -O javadocs.zip

		    # Only execute this when the file exists and is bigger than 0kb.
		    if [ -s javadocs.zip ]
		    then
		        # Extract to subfolders when a plugin/widget is found
		        if [[ $groupId =~ .*plugin*. ]] || [[ $groupId =~ .*widget*. ]]
		        then
		            mkdir -p $targetDirForJavaDoc/$project/$snapshotVersion/plugin/$artifactId
		            unzip -q -o javadocs.zip -d $targetDirForJavaDoc/$project/$snapshotVersion/plugin/$artifactId
		        else
		            mkdir -p $targetDirForJavaDoc/$project/$snapshotVersion
		            unzip -q -o javadocs.zip -d $targetDirForJavaDoc/$project/$snapshotVersion
		        fi
		        printf "%-30s%s\n" "- JAVADOC FOR SNAPSHOT FOUND: " $LOCATION;
		        rm javadocs.zip
            else
                printf "%-30s%s\n" "- JDOC FOR SNAPSHOT MISSING: " $LOCATION;
		    fi
		fi

	done < $fileName
}

#################################
# Clean all snapshot directories.
#################################
function deleteSnapshotDirectoriesFrom()
{
	printf "\n%s\n\n" "# DELETING SNAPSHOT DIRECTORIES ...";

    # Find all dir ...
    find ${1} -type d -iname "*SNAPSHOT" -exec rm -rf {} \;

}

##################
# Test some stuff.
##################
function testData()
{
	awk 'BEGIN{FS="^\"|\",\"|\"$"}
	{
	        printf("%s\n%s\n%s\n%s\n%s\n%s\n%s\n",$1, $2, $3, $4, $5, $6, $7, $8)

	}' $fileName
}

#########################################################################################
###                   ###################################################################
### SCRIPT EXECUTION  ###################################################################
###                   ###################################################################
#########################################################################################

deleteSnapshotDirectoriesFrom $targetDirForDocumentation;

generateDocumentation;

generateOldDocumentation;

addGoogleAnalyticsScriptTo $targetDirForDocumentation;

generateJavaDoc;

addGoogleAnalyticsScriptTo $targetDirForJavaDoc;

#testData;

printf "\n%s\n\n" "# SCRIPT IS FINISHED.";
