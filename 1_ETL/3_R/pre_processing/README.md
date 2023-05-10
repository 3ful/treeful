# Pre Processing

Scripts in this folder are not automated and are intended to be run only once to build up subsequent datasets. 
Technically all these steps could be automated but it needs to handle things like authentication. So for now, manual process. 

## Manual Steps

### Build common tree list Europe

This is the list of native European trees it combines two sources
This is Wikipedia list https://en.wikipedia.org/wiki/Category:Trees_of_Europe
Plus EU stuff https://forest.jrc.ec.europa.eu/en/european-atlas/atlas-download-page/
Those were just copied by hand and the latter was cut off using reg-ex "^[^-]+"

### Download Tree Cadastres from Open Data Portals

Refer to Excel file in Doku with links. Download all as csv/json. 

### Download Try Species List with Login

### Download Copernicus Rasters with Login