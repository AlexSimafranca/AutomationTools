#pragma rtGlobals=3		// Use modern global access method and strict wave access.

Menu "Macros"
	"Start Automation Tools", startautotools()
end


function startautotools()
	execute /P "INSERTINCLUDE \"AT_main\""
	
	// Create folder for global variables
	string folderPath = "root:Packages:AutomationTools"
	if (!DataFolderExists(folderPath))
		NewDataFolder $folderPath
	endif
	
	// Load plot parameter files
	loadParameterFiles()
end


function loadParameterFiles()
	// Load plot parameters
	loadPlotParameters()
	
	// Load plot colors
	loadPlotColors()
end


function loadPlotParameters()
	SetDataFolder root:Packages:AutomationTools
	
	string path = FunctionPath("")
	path = ParseFilePath(1, path, ":", 1, 1) + "User Procedures:AutomationTools:"	
	
	// Load in plot settings data
	LoadWave /A /O /J /W /M /Q /E=1 /U={1, 0, 1, 0} /B="N=plotParameters;" path + "AT_plotParameters.csv"
		
	// Return to previous data folder
	SetDataFolder root:
end


function loadPlotColors()
	SetDataFolder root:Packages:AutomationTools
	
	string path = FunctionPath("")
	path = ParseFilePath(1, path, ":", 1, 1) + "User Procedures:AutomationTools:"	
	
	// Load in plot settings data
	LoadWave /A /O /J /W /M /Q /E=1 /U={1, 0, 1, 0} /B="N=plotColors;" path + "AT_plotColors.csv"
		
	// Return to previous data folder
	SetDataFolder root:
end