#!/bin/bash
export PATH=/usr/local/bin:$PATH
export PATH=/opt/rasdaman/bin:$PATH

RECIPE="templates/wcs_delete_coverage.xml"

for LINE in `rasql -q 'select c from RAS_COLLECTIONNAMES as c' --out string`
do
        if [[ "$LINE" =~ "ESM20" ]]
        then
		echo curl -X GET 'http://localhost:8080/rasdaman/ows?SERVICE=WCS&VERSION=2.0.1&REQUEST=DeleteCoverage&COVERAGEID='$LINE
#		CADENA=`sed s/"#COLLECTION#"/$LINE/g $RECIPE`
#		echo $CADENA > wcs_delete_collection_$LINE.xml
#		wget -O /home/mario.nunez/script/result_delete_coverage_$LINE.xml --header='Content-Type:text/xml' --post-file=wcs_delete_collection_$LINE.xml http://localhost:8080/rasdaman/ows
        fi
done
