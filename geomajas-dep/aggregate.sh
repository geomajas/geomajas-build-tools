#! /bin/bash

#set -vx

#TARGETDIR="/home/joachim/tmp/"
TARGETDIR="/srv/www/files.geomajas.org/htdocs/maven/trunk/geomajas"
#TARGETDIR="/tmp/geomajasdocs"
TARGET="$TARGETDIR/temp.html"
FINAL="$TARGETDIR/documentation.html"
#LINKPREFIX="file:/home/joachim/tmp/"
LINKPREFIX="http://files.geomajas.org/maven/trunk/geomajas/"

template_start() {
	rm $TARGET
	echo "<html>" > $TARGET
	echo "<head><title>Geomajas documents</title></head>" >> $TARGET
	echo "<body>" >> $TARGET
	echo "<h1>Geomajas documentation</h1>" >> $TARGET
}

template_end() {
	echo "" >> $TARGET
	echo "</body>" >> $TARGET
	echo "</html>" >> $TARGET
	mv $TARGET $FINAL

	# assure google analytics is used in HTML pages
	perl -e "s/<\/body>/ \
<script type=\"text\/javascript\"> \
var _gaq = _gaq \|\| \[\]; \
_gaq.push(\[\'_setAccount\', \'UA-8078092-3\'\]); \
_gaq.push(\[\'_trackPageview\'\]); \
(function() { \
   var ga = document.createElement(\'script\'); ga.type = \'text\/javascript\'; ga.async = true; \
   ga.src = (\'https:\' == document.location.protocol \? \'https:\/\/ssl\' : \'http:\/\/www\') + \'.google-analytics.com\/ga.js\'; \
   var s = document.getElementsByTagName(\'script\')\[0\]; s.parentNode.insertBefore(ga, s); \
})(); \
<\/script> \
	<\/body>/gi;" -pi $(find $TARGETDIR -name \*.html)

}

# sample link https://oss.sonatype.org/service/local/artifact/maven/redirect?r=snapshots&g=org.geomajas.documentation&a=geomajas-layer-geotools-documentation&v=1.7.0-SNAPSHOT&e=jdocbook
# sample javadoc link https://oss.sonatype.org/service/local/artifact/maven/redirect?r=releases&g=org.geomajas&a=geomajas-api&v=1.7.1&e=jar&c=javadoc
# parameters: groupId, artifactId, version, title, description, state, pdf-filename, javadoc-groupid, javadoc-artifactid, javadoc-version
include() {
	echo "" >> $TARGET
	FILE="docs.zip"
	LOCATION="https://oss.sonatype.org/service/local/artifact/maven/redirect?r=releases&g=$1&a=$2&v=$3&e=jar"
	if [[ "$3" == *"SNAPSHOT"* ]]; then
		LOCATION="http://apps.geomajas.org/nexus/service/local/artifact/maven/redirect?r=latest&g=$1&a=$2&v=$3&e=jar"
	fi
	PWD=`pwd`
	cd $TARGETDIR
	wget -q --no-check-certificate $LOCATION -O docs.zip
	mkdir -p $2
	unzip -q -o docs.zip -d $2
	if [ $? -ne 0 ]; then
		echo ERROR processing $LOCATION
	fi	
	rm docs.zip

	if [ -n "$8" ]
	then
		JDLOCATION="https://oss.sonatype.org/service/local/artifact/maven/redirect?r=releases&g=$8&a=$9&v=${10}&e=jar&c=javadoc"
		if [[ "${10}" == *"SNAPSHOT"* ]]; then
			JDLOCATION="http://apps.geomajas.org/nexus/service/local/artifact/maven/redirect?r=latest&g=$8&a=$9&v=${10}&e=jar&c=javadoc"
		fi	
		wget -q --no-check-certificate $JDLOCATION -O javadocs.zip
		mkdir -p $2/javadoc
		unzip -q -o javadocs.zip -d $2/javadoc
		if [ $? -ne 0 ]; then
			echo ERROR processing $JDLOCATION
		fi	
		rm javadocs.zip
	fi

	cd $PWD
	echo "<h2>$4</h2>" >> $TARGET
	echo "<p class="state">state: $6</p>" >> $TARGET
	echo "<p class="desc">$5</p>" >> $TARGET
	echo "<p class="links">View: <a href="$LINKPREFIX$2/pdf/master.pdf">PDF</a> | <a href="$LINKPREFIX$2/html/master.html">html</a>" >> $TARGET
	if [ -n "$8" ]
	then
		echo " | <a href="$LINKPREFIX$2/javadoc/index.html">javadoc</a>" >> $TARGET
	fi
	echo "</p>" >> $TARGET
}

template_start

# Versions
documentation_version=1.12.0-SNAPSHOT

server_version=1.15.1
server_version_snapshot=1.16.0-SNAPSHOT

gwt_version=1.15.0-M2
gwt_version_snapshot=1.15.0-SNAPSHOT

gwt2_version=2.0.0-M1
gwt2_version_snapshot=2.1.0-SNAPSHOT

# main guides

include "org.geomajas.documentation" "docbook-gettingstarted" "$documentation_version" \
    "Getting started" \
    "How to get your project up-and-running." \
    "incubating" "Getting_Started.pdf" \
    "org.geomajas" "geomajas-command" "$server_version"

include "org.geomajas.documentation" "docbook-devuserguide" "$documentation_version" \
    "User guide for developers" \
    "Reference guide detailing architecture, implementation and extension possibilities of the back-end core." \
    "incubating" "User_Guide_for_Developers.pdf" \
    "org.geomajas" "geomajas-api" "$server_version"

include "org.geomajas.documentation" "docbook-contributorguide" "$documentation_version" \
    "Contributors guide" \
    "Information for contributors of the project." \
    "incubating" "Contributor_Guide.pdf" \
    "" "" ""

# projects

include "org.geomajas.project" "geomajas-project-api-annotation" "1.1.0-SNAPSHOT" \
    "API annotations project" \
    "Set of annotations to allow detailed marking of the supported API." \
    "incubating" "master.pdf" \
    "org.geomajas.project" "geomajas-project-api-annotation" "1.0.0"

include "org.geomajas.project" "geomajas-project-codemirror-gwt-documentation" "3.13.0-SNAPSHOT" \
    "Codemirror GWT wrapper project" \
    "In-browser code editing made bearable. Based on CodeMirror version 3.1." \
    "incubating" "master.pdf" \
    "org.geomajas.project" "geomajas-project-codemirror-gwt" "3.1.1"

include "org.geomajas.project" "geomajas-project-geometry-documentation" "1.4.0-SNAPSHOT" \
    "Geometry DTO project" \
    "Set of GWT compatible Geometry DTOs and services to manipulate them." \
    "incubating" "master.pdf" \
    "org.geomajas.project" "geomajas-project-geometry-core" "1.3.0"

include "org.geomajas.project" "geomajas-project-sld-documentation" "1.3.0-SNAPSHOT" \
    "SLD DTO project" \
    "Set of GWT compatible SLD DTOs and services to read/write them." \
    "incubating" "master.pdf" \
    "org.geomajas.project" "geomajas-project-sld-api" "1.2.0"

include "org.geomajas.documentation" "geomajas-project-profiling-documentation" "1.2.0-SNAPSHOT" \
    "Generic profiling project." \
    "Generic utility profiling code for gathering number of invocations and total execution time, possible surfacing this as JMX bean. project" \
    "incubating" "master.pdf" \
    "" "" ""
#    "org.geomajas.project" "geomajas-project-profiling-api" "1.0.0"


include "org.geomajas.project" "geomajas-project-sld-documentation" "1.3.0-SNAPSHOT" \
    "SLD project" \
    "SLD project." \
    "incubating" "master.pdf" \
    "org.geomajas.project" "geomajas-project-sld-api" "1.2.0"

include "org.geomajas.project" "geomajas-project-sld-editor-documentation" "1.0.0-SNAPSHOT" \
    "SLD editor project" \
    "SLD editor project." \
    "incubating" "master.pdf" \
    "org.geomajas.project" "geomajas-project-sld-editor-expert-gwt" "1.0.0-M2"

include "org.geomajas.project" "geomajas-project-geometry-documentation" "1.4.0-SNAPSHOT" \
    "Geometry project" \
    "Geometry project." \
    "incubating" "master.pdf" \
    "org.geomajas.project" "geomajas-project-geometry-core" "1.3.0"

# clients

include "org.geomajas.documentation" "geomajas-face-gwt-documentation" "$gwt_version_snapshot" \
    "GWT client" \
    "GWT client for building powerful AJAX web user interfaces in Java using SmartGWT." \
    "incubating" "gwt_face.pdf" \
    "org.geomajas" "geomajas-gwt-client" "$gwt_version"

include "org.geomajas" "geomajas-client-common-gwt-documentation" "$gwt2_version_snapshot" \
    "Common-GWT " \
    "Common module which is used by both the GWT and PureGWT faces." \
    "incubating" "master.pdf" \
    "org.geomajas" "geomajas-client-common-gwt" "$gwt2_version"

include "org.geomajas" "geomajas-client-gwt2-documentation" "$gwt2_version_snapshot" \
    "GWT2 client" \
    "GWT client for building powerful web user interfaces in Java using GWT." \
    "incubating" "master.pdf" \
    "org.geomajas" "geomajas-client-gwt2-api" "$gwt2_version"



# server plug-ins

include "org.geomajas.documentation" "geomajas-face-rest-documentation" "$server_version_snapshot" \
    "REST face" \
    "face for communication with the Geomajas back-end using REST and GeoJSON." \
    "incubating" "master.pdf" \
    "org.geomajas" "geomajas-face-rest" "$server_version"

include "org.geomajas.plugin" "geomajas-layer-geotools-documentation" "$server_version_snapshot" \
    "Geotools layer" \
    "This is a layer which allows accessing GIS data through GeoTools, for example for accessing WFS data." \
    "graduated" "Geotools_layer.pdf" \
    "org.geomajas.plugin" "geomajas-layer-geotools" "$server_version"

include "org.geomajas.plugin" "geomajas-layer-googlemaps-documentation" "$server_version_snapshot" \
    "Google layer" \
    "This is a layer which allows accessing Google images as raster layer." \
    "graduated" "Google_layer.pdf" \
    "org.geomajas.plugin" "geomajas-layer-googlemaps" "$server_version"

include "org.geomajas.plugin" "geomajas-layer-hibernate-documentation" "$server_version_snapshot" \
    "Hibernate layer" \
    "This is a layer which allows accessing data in a GIS database using Hibernate and Hibernate Spatial." \
    "graduated" "Hibernate_layer.pdf" \
    "org.geomajas.plugin" "geomajas-layer-hibernate" "$server_version"

include "org.geomajas.plugin" "geomajas-layer-openstreetmap-documentation" "$server_version_snapshot" \
    "Openstreetmap layer" \
    "This is a layer which allows accessing Openstreetmap images as raster layer." \
    "graduated" "Openstreetmap_layer.pdf" \
    "org.geomajas.plugin" "geomajas-layer-openstreetmap" "$server_version"

include "org.geomajas.plugin" "geomajas-layer-common-documentation" "$server_version_snapshot" \
    "Common layer tools" \
    "This plug-in contains common classes used by layers. (to help with proxying and security)." \
    "incubating" "master.pdf" \
    "org.geomajas.plugin" "geomajas-plugin-layer-common" "$server_version"

include "org.geomajas.plugin" "geomajas-layer-tms-documentation" "$server_version_snapshot" \
    "TMS layer" \
    "This is a layer which allows accessing TMS images as raster layer." \
    "incubating" "master.pdf" \
    "org.geomajas.plugin" "geomajas-layer-tms" "$server_version"

include "org.geomajas.plugin" "geomajas-layer-wms-documentation" "$server_version_snapshot" \
    "WMS layer" \
    "This is a layer which allows accessing WMS images as raster layer." \
    "graduated" "WMS_layer.pdf" \
    "org.geomajas.plugin" "geomajas-layer-wms" "$server_version"

include "org.geomajas.plugin" "geomajas-plugin-staticsecurity-documentation" "$server_version_snapshot" \
    "Staticsecurity plug-in" \
    "Geomajas security plug-in which allows all users and policies to be defined as part of spring configuration." \
    "graduated" "staticsecurity.pdf" \
    "org.geomajas.plugin" "geomajas-plugin-staticsecurity" "$server_version"

include "org.geomajas.plugin" "geomajas-client-gwt2-plugin-wms-documentation" "$gwt2_version_snapshot" \
    "WMS client plugin" \
    "WMS client plugin." \
    "incubating" "master.pdf" \
    "org.geomajas.plugin" "geomajas-client-gwt2-plugin-wms" "$gwt2_version"

# include "org.geomajas.plugin" "geomajas-plugin-profiling-documentation" "1.0.0-SNAPSHOT" \
#    "Profiling plug-in" \
#    "Geomajas extension for profiling using JMX." \
#    "incubating" "master.pdf" \
#    "org.geomajas.plugin" "geomajas-plugin-profiling" "1.0.0-SNAPSHOT"

include "org.geomajas.plugin" "geomajas-plugin-cache-documentation" "$server_version_snapshot" \
    "Caching plug-in" \
    "Caching to allow data to be calculated only once and cached for later use." \
    "graduated" "caching.pdf" \
    "org.geomajas.plugin" "geomajas-plugin-cache" "$server_version"

include "org.geomajas.plugin" "geocoder-documentation" "$server_version_snapshot" \
    "Geocoder plug-in" \
    "Convert a location description to map coordinates." \
    "graduated" "geocoder.pdf" \
    "org.geomajas.plugin" "geomajas-plugin-geocoder" "$server_version"

include "org.geomajas.plugin" "rasterizing-documentation" "$server_version_snapshot" \
    "Rasterizing plug-in" \
    "Allows tiles to be rasterized server-side." \
    "graduated" "master.pdf" \
    "org.geomajas.plugin" "geomajas-plugin-rasterizing" "$server_version"


include "org.geomajas.plugin" "geomajas-plugin-print-documentation" "$server_version_snapshot" \
    "Printing plug-in" \
    "Geomajas extension for printing." \
    "graduated" "printing.pdf" \
    "org.geomajas.plugin" "geomajas-plugin-print" "$server_version"

include "org.geomajas.plugin" "geomajas-plugin-runtimeconfig-documentation" "$server_version_snapshot" \
    "Runtimeconfig plug-in" \
    "Runtimeconfig plug-in." \
    "incubating" "master.pdf" \
    "org.geomajas.plugin" "geomajas-plugin-runtimeconfig" "$server_version"

include "org.geomajas.plugin" "geomajas-plugin-vendorspecificpipeline" "$server_version_snapshot" \
    "Vendor specific pipeline plugin" \
    "Vendor specific pipeline plugin." \
    "incubating" "master.pdf" \
    "org.geomajas.plugin" "geomajas-plugin-vendorspecificpipeline" "$server_version"

include "org.geomajas.plugin" "geomajas-plugin-deskmanager" "$server_version_snapshot" \
    "Deskmanager plug-in" \
    "Deskmanager plug-in." \
    "incubating" "master.pdf" \
    "org.geomajas.plugin" "geomajas-plugin-deskmanager" "$server_version"



# GWT plug-ins



include "org.geomajas.widget" "geomajas-widget-advancedviews-documentation" "$gwt_version_snapshot" \
    "Advanced views widget plug-in" \
    "Advanced views widget plug-in." \
    "incubating" "master.pdf" \
    "org.geomajas.widget" "geomajas-widget-advancedviews" "$gwt_version"

include "org.geomajas.widget" "geomajas-widget-featureinfo-documentation" "$gwt_version_snapshot" \
    "Feature info widget plug-in" \
    "Feature info widget plug-in." \
    "incubating" "master.pdf" \
    "org.geomajas.widget" "geomajas-widget-featureinfo" "$gwt_version"

include "org.geomajas.widget" "geomajas-widget-layer-documentation" "$gwt_version_snapshot" \
    "Layer widget plug-in" \
    "Layer widget plug-in." \
    "incubating" "master.pdf" \
    "org.geomajas.widget" "geomajas-widget-layer" "$gwt_version"

include "org.geomajas.widget" "geomajas-widget-searchandfilter-documentation" "$gwt_version_snapshot" \
    "Search and filter widget plug-in" \
    "Search and filter widget plug-in." \
    "incubating" "master.pdf" \
    "org.geomajas.widget" "geomajas-widget-searchandfilter" "$gwt_version"

include "org.geomajas.plugin" "geomajas-plugin-deskmanager-gwt" "$gwt_version_snapshot" \
    "Deskmanager plug-in" \
    "Deskmanager plug-in." \
    "incubating" "master.pdf" \
    "org.geomajas.plugin" "geomajas-plugin-deskmanager-gwt" "$gwt_version"

include "org.geomajas.widget" "geomajas-widget-utility-documentation" "$gwt_version_snapshot" \
    "Utility widgets for GWT" \
    "Utility widgets for GWT" \
    "incubating" "master.pdf" \
    "org.geomajas.widget" "geomajas-widget-utility" "$gwt_version"

include "org.geomajas.plugin" "geomajas-plugin-javascript-api-documentation" "$gwt_version_snapshot" \
    "JavaScript API plug-in" \
    "JavaScript API wrapper around the GWT faces for client side integration support." \
    "incubating" "master.pdf" \
    "org.geomajas.plugin" "geomajas-plugin-javascript-api" "$gwt_version"

include "org.geomajas.plugin" "geomajas-plugin-editing-documentation" "$gwt_version_snapshot" \
    "Editing plug-in" \
    "Geomajas extension for more powerful editing." \
    "incubating" "master.pdf" \
    "org.geomajas.plugin" "geomajas-plugin-editing-gwt" "$gwt_version"

# GWT2 plug-ins

include "org.geomajas.plugin" "geomajas-client-gwt2-plugin-corewidget-documentation" "$gwt2_version_snapshot" \
    "Core widgets for the PureGWT face" \
    "Set of widgets which alow you to make a PureGWT map more expressive." \
    "incubating" "master.pdf" \
    "org.geomajas.plugin" "geomajas-client-gwt2-plugin-corewidget" "$gwt2_version"



template_end

exit 0
