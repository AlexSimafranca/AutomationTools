#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

#include ":Igor Procedures:Boot Nika"   // Nika booter
#include ":Igor Procedures:SO_GIWAXS_loader"   // GIWAXSTools booter
#include ":User Procedures:SO_WAXS_panel"   // GIWAXSTools booter
#include ":User Procedures:SO_WAXS_geometry"   // GIWAXSTools booter

Menu "AutomationTools"
	Submenu "Calibration"
		"Open Calibration Panels", AT_loadCalibrationPanels()
		"Load LaB6 Calibration File", AT_loadLaB6()
		"LaB6 Auto-Calibration", AT_LaB6Calibrate()
	end
	
	Submenu "Data Processing"
		"Load Images from Folder", AT_imageLoader()
		"Process Images to I-vs-Q Data", AT_batchProcessImages("IvsQ")
		"Process Images to I-vs-Chi Data", AT_batchProcessImages("IvsChi")
	end

	Submenu "Plotting"
		Submenu "1D"
			"Co-Plot Selected I-vs-Q Data", AT_formattedIvsQ()
			"Co-Plot Selected I-vs-Chi Data", AT_formattedIvsChi()
		end
		
		Submenu "2D"
			"Plot Formatted qz-qxy Image", AT_displayQzqxy()
		end
		
		Submenu "Plot Parameters"
			"Reload Default Plot Parameters", AT_loadPlotParameters()
			"Load Custom Plot Parameters", AT_loadCustomPlotParameters()
			"Reload Default Plot Colors", AT_loadPlotColors()
			"Load Custom Plot Colors", AT_loadCustomPlotColors()
		end
	end
	
	Submenu "Data Manipulation"
		Submenu "Data Arithmetic"
			"Sum Selected Waves\Images", AT_waveArithmetic("add")
			"Subtract Selected Waves\Images", AT_waveArithmetic("subtract")
			"Average Selected Waves\Images", AT_averageWaves()
		end
		
		Submenu "Wave Normalization"
			"Normalize Selected Waves to Max Value", AT_normWaveToMax()
			"Normalize Selected Waves to Max Value w\ Constant Baseline", AT_normWaveToMax_ConstBL()
		end
		
		Submenu "Other"
			"Mask Data Points in Specified Range", AT_maskDataPts()
		end
	end

	Submenu "Misc. Tools"
		"Batch Copy Waves", AT_batchCopyWaves()
	end
end


// ---Calibration Functions--- //
function AT_loadCalibrationPanels()
	// Load Nika package and open 2D calibration panel
	if (WinType("NI1_CreateBmCntrFieldPanel") != 7)
		LoadNika2DSASMacros()   // Load Nika toolkit
		NI1_CreateBmCntrFile()
	endif
	
	// Load GIWAXSTools package & open WAXSTools Panel
	if (WinType("giwaxs_tools") != 7)
		AT_startGiwaxsTools()
	endif
	
	// Use WAXSTools panel to set parameters to SSRL BL11-3 default for Nika
	AT_setSharedBL113Defaults()
	AT_calibSyncWAXSToolsToNika(1)
end


function AT_loadLaB6()
	if ((WinType("NI1_CreateBmCntrFieldPanel") != 7) | (WinType("giwaxs_tools") != 7))
		print "LaB6 Auto-Calibration Error - Calibration panels (SAS 2D -> Beam center & Geometry cor., WAXSTools -> Main Panel) not open."
		print "Please run \"Load Calibration Panels\" procedure (AutomationTools -> Calibration -> Load Calibration Panels)."
		abort
	endif
		
	// Request user to select LaB6 calibration file
	AT_LaB6Loader()
	
	// Transfer calibration parameters from WAXSTools
	AT_calibSyncWAXSToolsToNika(1)
	
	// Make 2D GIWAXS log-intensity image for LaB6 sample
	AT_makeLaB6Image()
end


function AT_LaB6Calibrate()	
	if ((WinType("NI1_CreateBmCntrFieldPanel") != 7) | (WinType("giwaxs_tools") != 7))
		print "LaB6 Auto-Calibration Error - Calibration panels (SAS 2D -> Beam center & Geometry cor., WAXSTools -> Main Panel) not open."
		print "Please run \"Load Calibration Panels\" procedure (AutomationTools -> Calibration -> Load Calibration Panels)."
		abort
	endif
	
	// Run auto-calibration routine on LaB6 image
	AT_calibrationRoutine()
	
	// Sync calibrated parameters between Nika and WAXSTools
	AT_calibSyncWAXSToolsToNika(-1)
	
	// Return user to root folder
	SetDataFolder root:
end


function AT_startGiwaxsTools()
	// Function that makes variables and datafolders, opens the giwaxs tools panel
	variable firstrun
	
	// If package data folder doesn't exist, create one
	if(!DataFolderExists("root:Packages:GIWAXS"))
		newdatafolder/O root:Packages
		newdatafolder/O root:Packages:GIWAXS
		variable/G root:Packages:GIWAXS:g_BCX
		variable/G root:Packages:GIWAXS:g_BCY
		variable/G root:Packages:GIWAXS:g_R
		variable/G root:Packages:GIWAXS:g_incidence = 0.12
		make/O/T/N=1 root:Packages:GIWAXS:thewavelist
		make/O/N=1 root:Packages:GIWAXS:thewavelist_number
		variable/G root:Packages:GIWAXS:g_chi_start = 0
		variable/G root:Packages:GIWAXS:g_chi_end = 90
		variable/G root:Packages:GIWAXS:g_q_start = 0.2
		variable/G root:Packages:GIWAXS:g_q_end = 2
		string/G root:Packages:GIWAXS:g_bkgndname
		variable/G root:Packages:GIWAXS:g_Z_low = 0
		variable/G root:Packages:GIWAXS:g_Z_high = 300
		variable/G root:Packages:GIWAXS:g_pxsizex = 0.073242
		variable/G root:Packages:GIWAXS:g_pxsizey = 0.073242
		variable/G root:Packages:GIWAXS:g_q_range = 2
		variable/G root:Packages:GIWAXS:g_q_res = 0.0015
		variable/G root:Packages:GIWAXS:g_remhor=0
		variable/G root:Packages:GIWAXS:g_remhorqz=0
		variable/G root:Packages:GIWAXS:g_sqsize=300
		string/G root:Packages:GIWAXS:g_stringremove
		variable/G root:Packages:GIWAXS:g_dezingerratio = 1.5
		variable/G root:Packages:GIWAXS:g_dezingertimes = 6
		variable/G root:Packages:GIWAXS:g_BLenergy = 12.735
		variable/G root:Packages:GIWAXS:a_par=0.4
		variable/G root:Packages:GIWAXS:b_par=0.356
		variable/G root:Packages:GIWAXS:gam_par=90
		variable/G root:Packages:GIWAXS:a_perp=0
		variable/G root:Packages:GIWAXS:b_perp=0
		variable/G root:Packages:GIWAXS:c_perp=0.428
		variable/G root:Packages:GIWAXS:g_hkl_min=-2
		variable/G root:Packages:GIWAXS:g_hkl_max=2
		variable/G root:Packages:GIWAXS:index_liveupdate=1
		variable/G root:Packages:GIWAXS:index_h_min=0
		variable/G root:Packages:GIWAXS:index_h_max=1
		variable/G root:Packages:GIWAXS:index_k_min=0
		variable/G root:Packages:GIWAXS:index_k_max=1
		variable/G root:Packages:GIWAXS:index_l_min=0
		variable/G root:Packages:GIWAXS:index_l_max=1
		variable/G root:Packages:GIWAXS:g_remstringuponload=0
		variable/G root:Packages:GIWAXS:g_msize=1.5
	endif

	// Open GIWAXSTools panel
	execute "giwaxs_tools()"
end


function AT_setSharedBL113Defaults()
	// Set SSRL BL11-3 defaults
	variable/G root:Packages:GIWAXS:g_BCX = 1600
	variable/G root:Packages:GIWAXS:g_BCY = 2600
	variable/G root:Packages:GIWAXS:g_pxsizex = 0.073242
	variable/G root:Packages:GIWAXS:g_pxsizey = 0.073242
	variable/G root:Packages:GIWAXS:g_R = 250   // detector distance
	variable/G root:Packages:GIWAXS:g_BLenergy = 12.735
end


function AT_LaB6Loader()
	variable refNum
	string message = "Select a LaB6 calibration file"
	string fileFilters = "TIFF Files (*.tif):.tif;"
	fileFilters += "All Files:.*;"
	
	// Request user to select LaB6 calibration file directory
	Open /D /R /MULT=0 /F=fileFilters /M=message refNum
	string path = StringFromList(0, S_fileName, "\r")
	string path_LaB6 = parsefilepath(1, path, ":", 1, 0)
	string filename_LaB6 = parsefilepath(0, path, ":", 1, 0)
	
	// Update symbolic path
	NewPath /O Convert2Dto1DBmCntrPath, path_LaB6
	SVAR BCPathInfoStr = root:Packages:Convert2Dto1D:BCPathInfoStr
	BCPathInfoStr = path_LaB6
	NI1BC_UpdateBmCntrListBox()
end


function AT_makeLaB6Image()
	// Display LaB6 image
	NI1BC_BmCntrCreateImage()
	
	// Set slider
	NVAR BMMaxCircleRadius=root:Packages:Convert2Dto1D:BMMaxCircleRadius
	Wave BmCntrFieldImg=root:Packages:Convert2Dto1D:BmCntrCCDImg 
	BMMaxCircleRadius=sqrt(DimSize(BmCntrFieldImg, 0 )^2 + DimSize(BmCntrFieldImg, 1 )^2)
	Slider BMHelpCircleRadius,limits={1,BMMaxCircleRadius,0}, win=NI1_CreateBmCntrFieldPanel
	SetVariable BMHelpCircleRadiusV,limits={1,BMMaxCircleRadius,0}, win=NI1_CreateBmCntrFieldPanel
	
	NVAR BMImageRangeMinLimit= root:Packages:Convert2Dto1D:BMImageRangeMinLimit
	NVAR BMImageRangeMaxLimit = root:Packages:Convert2Dto1D:BMImageRangeMaxLimit
	Slider ImageRangeMin,limits={BMImageRangeMinLimit,BMImageRangeMaxLimit,0}, win=NI1_CreateBmCntrFieldPanel
	Slider ImageRangeMax,limits={BMImageRangeMinLimit,BMImageRangeMaxLimit,0}, win=NI1_CreateBmCntrFieldPanel
	
	NI1BC_DisplayHelpCircle()
	NI1BC_DisplayMask()
	TabControl BmCntrTab, value=0, win=NI1_CreateBmCntrFieldPanel
	NI1BC_TabProc("",0)
	ShowInfo /W=CCDImageForBmCntr
	
	// Make LaB6 image log-intensity
	NVAR BmCntrDisplayLogImage=root:Packages:Convert2Dto1D:BmCntrDisplayLogImage
	Wave BmCntrCCDImg=root:Packages:Convert2Dto1D:BmCntrCCDImg
	Wave BmCntrDisplayImage=root:Packages:Convert2Dto1D:BmCntrDisplayImage
	
	redimension/S BmCntrCCDImg
	ImageStats BmCntrCCDImg
	MatrixOp/O BmCntrDisplayImage=log(BmCntrCCDImg)
	V_min=log(V_min)
	V_max=log(V_max)
	
	if(numType(V_min) != 0)
		V_min=0
	endif
	
	NVAR ImageRangeMin= root:Packages:Convert2Dto1D:BMImageRangeMin
	NVAR ImageRangeMax = root:Packages:Convert2Dto1D:BMImageRangeMax
	NVAR ImageRangeMinLimit= root:Packages:Convert2Dto1D:BMImageRangeMinLimit
	NVAR ImageRangeMaxLimit = root:Packages:Convert2Dto1D:BMImageRangeMaxLimit
	SVAR BMColorTableName = root:Packages:Convert2Dto1D:BMColorTableName
	ImageRangeMin=V_min
	ImageRangeMinLimit=V_min
	ImageRangeMax=V_max
	ImageRangeMaxLimit=V_max
	
	Slider ImageRangeMin,win=NI1_CreateBmCntrFieldPanel ,limits={ImageRangeMinLimit,ImageRangeMaxLimit,0}
	Slider ImageRangeMax,win=NI1_CreateBmCntrFieldPanel,limits={ImageRangeMinLimit,ImageRangeMaxLimit,0}

	ModifyImage/W=CCDImageForBmCntr BmCntrDisplayImage, ctab= {ImageRangeMin,ImageRangeMax,$BMColorTableName,0}
end


function AT_calibrationRoutine()
	nvar refineBeamCenter = root:Packages:Convert2Dto1D:BMFitBeamCenter
	nvar refineSaDetDist = root:Packages:Convert2Dto1D:BMFitSDD
	nvar refineWavelength = root:Packages:Convert2Dto1D:BMFitWavelength
	nvar refineTilts = root:Packages:Convert2Dto1D:BMFitTilts
	Make /O /N=(10,1) ringToggles
	Make /O /N=(10,1) ringWidths
	
	// Set general calibration settings
	nvar numSectors = root:Packages:Convert2Dto1D:BMRefNumberOfSectors
	numSectors = 360
	
	// Set calibrant to LaB6
	AT_calibrantLaB6()	
	
	// Refine beam center	
	// First cycle - Innermost ring only w/ beam center & sa-det distance, 120 width
	NI1BC_TabProc("NI1_CreateBmCntrFieldPanel:BmCntrTab", 1)	
	ringToggles = 0
	ringToggles[0] = 1   // enable only innermost diffraction ring
	ringWidths += 15
	ringWidths[0] = 120   // set innermost ring width wide for first calibration cycle
	
	AT_selectCalibrantRings(ringToggles)
	AT_setRingWidths(ringWidths)

	NI1BC_TabProc("NI1_CreateBmCntrFieldPanel:BmCntrTab", 2)	
	refineBeamCenter = 1
	refineSaDetDist = 1
	refineTilts = 0
	NI1BC_RunRefinement()
	
	// Second cycle - Rings 1-3 w/ beam center & sa-det distance, 60 width
	NI1BC_TabProc("NI1_CreateBmCntrFieldPanel:BmCntrTab", 1)	
	variable i
	for (i = 0; i < 3; i += 1)
		ringToggles[i] = 1
		ringWidths[i] = 60
	endfor
	
	AT_selectCalibrantRings(ringToggles)
	AT_setRingWidths(ringWidths)

	NI1BC_TabProc("NI1_CreateBmCntrFieldPanel:BmCntrTab", 2)	
	NI1BC_RunRefinement()
	
	// Third cycle - Rings 1-3 w/ tilts, 60 width
	NI1BC_TabProc("NI1_CreateBmCntrFieldPanel:BmCntrTab", 1)	
	for (i = 0; i < 3; i += 1)
		ringWidths[i] = 60
	endfor
	
	AT_selectCalibrantRings(ringToggles)
	AT_setRingWidths(ringWidths)

	NI1BC_TabProc("NI1_CreateBmCntrFieldPanel:BmCntrTab", 2)	
	refineBeamCenter = 0
	refineSaDetDist = 0
	refineTilts = 1
	NI1BC_RunRefinement()	

	// Fourth & fifth cycles - Rings 1-3 w/ beam center, sa-det distance, & tilts, 30 width
	variable j
	for (j = 0; j < 2; j += 1)
		NI1BC_TabProc("NI1_CreateBmCntrFieldPanel:BmCntrTab", 1)	
		for (i = 0; i < 3; i += 1)
			ringWidths[i] = 30
		endfor
		
		
		AT_selectCalibrantRings(ringToggles)
		AT_setRingWidths(ringWidths)
	
		NI1BC_TabProc("NI1_CreateBmCntrFieldPanel:BmCntrTab", 2)	
		refineBeamCenter = 1
		refineSaDetDist = 1
		refineTilts = 1
		NI1BC_RunRefinement()	
	endfor

	// Sixth & seventh cycles - Rings 1-7 w/ beam center, sa-det distance, & tilts, 30 width
	for (j = 0; j < 2; j += 1)
		NI1BC_TabProc("NI1_CreateBmCntrFieldPanel:BmCntrTab", 1)	
		for (i = 0; i < 7; i += 1)
			ringToggles[i] = 1
			ringWidths[i] = 30
		endfor
		
		AT_selectCalibrantRings(ringToggles)
		AT_setRingWidths(ringWidths)
	
		NI1BC_TabProc("NI1_CreateBmCntrFieldPanel:BmCntrTab", 2)	
		refineBeamCenter = 1
		refineSaDetDist = 1
		refineTilts = 1
		NI1BC_RunRefinement()	
	endfor
	
	// Eighth cycle - Rings 1-7 w/ beam center, sa-det distance, & tilts, 20 width
	NI1BC_TabProc("NI1_CreateBmCntrFieldPanel:BmCntrTab", 1)	
	for (i = 0; i < 7; i += 1)
		ringToggles[i] = 1
		ringWidths[i] = 20
	endfor
	
	AT_selectCalibrantRings(ringToggles)
	AT_setRingWidths(ringWidths)

	NI1BC_TabProc("NI1_CreateBmCntrFieldPanel:BmCntrTab", 2)	
	refineBeamCenter = 1
	refineSaDetDist = 1
	refineTilts = 1
	NI1BC_RunRefinement()	
	
	// Kill waves containing calibration parameters
	KillWaves ringToggles, ringWidths
end


function AT_calibrantLaB6()
	// Set calibrant to LaB6
	NVAR BMCalibrantD1=root:Packages:Convert2Dto1D:BMCalibrantD1
	NVAR BMCalibrantD2=root:Packages:Convert2Dto1D:BMCalibrantD2
	NVAR BMCalibrantD3=root:Packages:Convert2Dto1D:BMCalibrantD3
	NVAR BMCalibrantD4=root:Packages:Convert2Dto1D:BMCalibrantD4
	NVAR BMCalibrantD5=root:Packages:Convert2Dto1D:BMCalibrantD5
	NVAR BMCalibrantD6=root:Packages:Convert2Dto1D:BMCalibrantD6
	NVAR BMCalibrantD7=root:Packages:Convert2Dto1D:BMCalibrantD7
	NVAR BMCalibrantD8=root:Packages:Convert2Dto1D:BMCalibrantD8
	NVAR BMCalibrantD9=root:Packages:Convert2Dto1D:BMCalibrantD9
	NVAR BMCalibrantD10=root:Packages:Convert2Dto1D:BMCalibrantD10

	// Numbers from Peter Lee, taken from WAXSTools
	BMCalibrantD1=4.15690	//[100]/rel int 60
	BMCalibrantD2=2.93937	//110 /100
	BMCalibrantD3=2.39999	//111/45
	BMCalibrantD4=2.07845	//200/23.6
	BMCalibrantD5=1.85902	//210/55
	BMCalibrantD6=1.6970539	
	BMCalibrantD7=1.4696918	
	BMCalibrantD8=1.3856387	
	BMCalibrantD9=1.3145323	
	BMCalibrantD10=1.2533574	
end


function AT_selectCalibrantRings(ringToggles)
	Wave ringToggles
	NVAR BMUseCalibrantD1=root:Packages:Convert2Dto1D:BMUseCalibrantD1
	NVAR BMUseCalibrantD2=root:Packages:Convert2Dto1D:BMUseCalibrantD2
	NVAR BMUseCalibrantD3=root:Packages:Convert2Dto1D:BMUseCalibrantD3
	NVAR BMUseCalibrantD4=root:Packages:Convert2Dto1D:BMUseCalibrantD4
	NVAR BMUseCalibrantD5=root:Packages:Convert2Dto1D:BMUseCalibrantD5
	NVAR BMUseCalibrantD6=root:Packages:Convert2Dto1D:BMUseCalibrantD6
	NVAR BMUseCalibrantD7=root:Packages:Convert2Dto1D:BMUseCalibrantD7
	NVAR BMUseCalibrantD8=root:Packages:Convert2Dto1D:BMUseCalibrantD8
	NVAR BMUseCalibrantD9=root:Packages:Convert2Dto1D:BMUseCalibrantD9
	NVAR BMUseCalibrantD10=root:Packages:Convert2Dto1D:BMUseCalibrantD10
	
	BMUseCalibrantD1=ringToggles[0]
	BMUseCalibrantD2=ringToggles[1]
	BMUseCalibrantD3=ringToggles[2]
	BMUseCalibrantD4=ringToggles[3]
	BMUseCalibrantD5=ringToggles[4]
	BMUseCalibrantD6=ringToggles[5]
	BMUseCalibrantD7=ringToggles[6]
	BMUseCalibrantD8=ringToggles[7]
	BMUseCalibrantD9=ringToggles[8]
	BMUseCalibrantD10=ringToggles[9]
end


function AT_setRingWidths(ringWidths)
	Wave ringWidths
	NVAR BMCalibrantD1LineWidth=root:Packages:Convert2Dto1D:BMCalibrantD1LineWidth
	NVAR BMCalibrantD2LineWidth=root:Packages:Convert2Dto1D:BMCalibrantD2LineWidth
	NVAR BMCalibrantD3LineWidth=root:Packages:Convert2Dto1D:BMCalibrantD3LineWidth
	NVAR BMCalibrantD4LineWidth=root:Packages:Convert2Dto1D:BMCalibrantD4LineWidth
	NVAR BMCalibrantD5LineWidth=root:Packages:Convert2Dto1D:BMCalibrantD5LineWidth
	NVAR BMCalibrantD6LineWidth=root:Packages:Convert2Dto1D:BMCalibrantD6LineWidth
	NVAR BMCalibrantD7LineWidth=root:Packages:Convert2Dto1D:BMCalibrantD7LineWidth
	NVAR BMCalibrantD8LineWidth=root:Packages:Convert2Dto1D:BMCalibrantD8LineWidth
	NVAR BMCalibrantD9LineWidth=root:Packages:Convert2Dto1D:BMCalibrantD9LineWidth
	NVAR BMCalibrantD10LineWidth=root:Packages:Convert2Dto1D:BMCalibrantD10LineWidth

	BMCalibrantD1LineWidth=ringWidths[0]
	BMCalibrantD2LineWidth=ringWidths[1]
	BMCalibrantD3LineWidth=ringWidths[2]
	BMCalibrantD4LineWidth=ringWidths[3]
	BMCalibrantD5LineWidth=ringWidths[4]
	BMCalibrantD6LineWidth=ringWidths[5]
	BMCalibrantD7LineWidth=ringWidths[6]
	BMCalibrantD8LineWidth=ringWidths[7]
	BMCalibrantD9LineWidth=ringWidths[8]
	BMCalibrantD10LineWidth=ringWidths[9]
end


function AT_calibSyncWAXSToolsToNika(direction)
	variable direction
	// define variable references from GIWAXS tool:
	nvar BCX = root:Packages:GIWAXS:g_BCX
	nvar BCY = root:Packages:GIWAXS:g_BCY
	nvar pxsizex = root:Packages:GIWAXS:g_pxsizex
	nvar pxsizey = root:Packages:GIWAXS:g_pxsizey
	nvar R = root:Packages:GIWAXS:g_R // detector distance
	nvar BLenergy = root:Packages:GIWAXS:g_BLenergy
	
	// define variable for Nika:
	nvar Rx = root:Packages:Convert2Dto1D:PixelSizeX
	nvar Ry = root:Packages:Convert2Dto1D:PixelSizeY
	nvar xrayenergy = root:Packages:Convert2Dto1D:XrayEnergy
	nvar Wavelength = root:Packages:Convert2Dto1D:Wavelength
	nvar CCDDistance = root:Packages:Convert2Dto1D:SampleToCCDDistance
	nvar BeamCenterX = root:Packages:Convert2Dto1D:BeamCenterX
	nvar BeamCenterY = root:Packages:Convert2Dto1D:BeamCenterY
	
	// send values from GIWAXS tool to Nika:
	if (direction == 1)
			wavelength = 12.398424437/BLenergy
			xrayenergy = BLenergy
			CCDDistance = R
			Rx=pxsizex
			Ry=pxsizey
			BeamCenterX = BCX
			BeamCenterY = BCY	
	else 
			BLenergy = xrayenergy
			R = CCDDistance
			pxsizex = Rx
			pxsizey = Ry
			BCX = BeamCenterX
			BCY = BeamCenterY	
	endif
end


// ---Data Processing Functions--- //
function /S AT_imageLoader()
   variable refNum
	string message = "Select one or more files"
	string outputPaths
	string fileFilters = "TIFF Files (*.tif):.tif;"
	fileFilters += "All Files:.*;"
 
	Open /D /R /MULT=1 /F=fileFilters /M=message refNum
	outputPaths = S_fileName
 
	if (strlen(outputPaths) == 0)
		Print "Cancelled"
	else
		variable numFilesSelected = ItemsInList(outputPaths, "\r")
		
		// Prompt user for start of string to remove
		string stringToRemove
		Prompt stringToRemove, "Enter first characters just past the sample name portion to keep:"
		DoPrompt "Truncate Filenames", stringToRemove
		
		variable i
		for(i = 0; i < numFilesSelected; i += 1)
			string path = StringFromList(i, outputPaths, "\r")
			print(path)
			
			// Declare the loaded image as a wave; need to get the filename from the path string
			string foldername = parsefilepath(0, path, ":", 1, 1)
			string imagename = parsefilepath(0, path, ":", 1, 0)
			
			// Get just the fileName but with the extension remove.
			string wName = ParseFilePath(3, path, ":", 0, 0)
			
			// Create new folder in root on first pass with name of folder containing images
			if (i == 0) 
				NewDataFolder /O /S root:$foldername
			endif 
			
			// Create a folder within images folder for current image
			wName = CleanupName(wName, 0)	// Change 0 to 1 if you want to allow liberal names
			NewDataFolder /S :$wName
			
			// Save images within its folder with truncated name if requested
			print(wName)
			string wName_sample
			
			if (strlen(stringToRemove) == 0)
				wName_sample = stringfromlist(0, wName)
			else
				wName_sample = stringfromlist(0, wName, stringToRemove)
				
				// Append last character of data name, assumed to be the scan number
				variable nameLen = strlen(wName) / strlen(wName[0])
				wName_sample = wName_sample + "_" + wName[nameLen - 1]
			endif
			
			ImageLoad /T=tiff /N=$wName_sample path
			Redimension /S $wName_sample
			SetDataFolder root:$foldername
		endfor
	endif
end


function AT_batchProcessImages(processCode)
	string processCode
	
	duplicate /O root:Packages:GIWAXS:thewavelist_number root:Packages:GIWAXS:wavenum_localCopy
	wave wavenum_localCopy = root:Packages:GIWAXS:wavenum_localCopy
	wave thewavelist_number = root:Packages:GIWAXS:thewavelist_number
	string thewavelist = wavelist("*", ";", "")

	variable i
	for (i = 0; i < numpnts(wavenum_localCopy); i += 1)
		// Determine whether wave is selected
		if (wavenum_localCopy[i] == 1)
			// Retrieve wave name
			string thisWaveStem = stringfromlist(i, thewavelist)
		
			// Process selected image
			AT_processImage(thisWaveStem, processCode)
		endif
	endfor
end


function AT_processImage(thisWaveStem, processCode)
	string thisWaveStem
	string processCode
	
	// Load GIWAXSTools package & open WAXSTools Panel
  	if (WinType("giwaxs_tools") != 7)
		startgiwaxstools()
		Execute "giwaxs_tools()"   // open panel
	endif
	
	// Read current data folder
	AT_updateWaveList()
	
	
	// --- TIFF to 2D Conversion --- //
	// Convert 2D GIWAXS image to qzqxy
	wave thewavelist_number = root:Packages:GIWAXS:thewavelist_number
	string thewavelist = wavelist("*", ";", "")
	
	AT_switchWave(thisWaveStem)
	AT_qzqxyConvert()
	
	// Display calculated qzqxy image
	AT_updateWaveList()
	AT_switchWave(thisWaveStem + "_qzqxy")
	
	AT_displayQzqxy()
	string plotName = winName(0,1)   // store name of newly created plot
	
	
	// --- 2D to 1D Integrations --- //
	if (stringMatch(processCode, "IvsQ"))
		// Full integration
		AT_setWedgeParams(0, 89, 0.2, 2)		
		AT_wedge2Dto1D(thisWaveStem, plotName, processCode)
		
		// Out-of-Plane Integration
		AT_setWedgeParams(0, 10, 0.2, 2)
		AT_wedge2Dto1D(thisWaveStem, plotName, processCode)
		
		// In-Plane Integration
		AT_setWedgeParams(80, 89, 0.2, 2)
		AT_wedge2Dto1D(thisWaveStem, plotName, processCode)	
	
	elseif (stringMatch(processCode, "IvsChi"))
		// Full integration
		AT_wedge2Dto1D(thisWaveStem, plotName, processCode)	
	endif
end


function AT_setWedgeParams(new_chi_start, new_chi_end, new_q_start, new_q_end)
	variable new_chi_start, new_chi_end, new_q_start, new_q_end
	NVAR chi_start = root:Packages:GIWAXS:g_chi_start
	NVAR chi_end = root:Packages:GIWAXS:g_chi_end
	NVAR q_start = root:Packages:GIWAXS:g_q_start
	NVAR q_end = root:Packages:GIWAXS:g_q_end
	
	chi_start = new_chi_start
	chi_end = new_chi_end
	q_start = new_q_start
	q_end = new_q_end
end


// ---Plotting Functions--- //
function AT_formattedIvsQ() 
	string thiswavename
	string wavenamelist = wavelist("*", ";", "")
	wave thewavelist_number = root:Packages:GIWAXS:thewavelist_number
	wave colors = root:Packages:AutomationTools:plotColors
	
	variable colorRow
	variable c = 0
	variable R
	variable G
	variable B

	variable i
	variable ii = 0
	
	for(i = 0; i < numpnts(thewavelist_number); i += 1)
		if(thewavelist_number[i] == 1)
			thiswavename = stringfromlist(i, wavenamelist)
			
			if (ii == 0)
				// Create new plot with first data wave
				Preferences 0; Display $thiswavename; DelayUpdate
				execute "logIvsq();Preferences 1"

				ii += 1
			else
				// Append data wave to plot
				appendtograph $thiswavename			
			endif
			
			// Set trace color
			colorRow = mod(c, DimSize(colors, 0))
			
			R = colors[colorRow][0] * (65535 / 255)
			G = colors[colorRow][1] * (65535 / 255)
			B = colors[colorRow][2] * (65535 / 255)

			ModifyGraph rgb($thiswavename)=(R, G, B)
			
			c += 1
		endif
	endfor
	
	// Format plot
	AT_formatPlot()
end


function AT_formattedIvsChi() 
	string thiswavename
	string wavenamelist = wavelist("*", ";", "")
	wave thewavelist_number = root:Packages:GIWAXS:thewavelist_number
	wave colors = root:Packages:AutomationTools:plotColors
	
	variable colorRow
	variable c = 0
	variable R
	variable G
	variable B
	
	variable i
	variable ii = 0
	for(i = 0; i < numpnts(thewavelist_number); i += 1)
		if(thewavelist_number[i] == 1)
			// Retrieve name of selected wave
			thiswavename = stringfromlist(i, wavenamelist)
			
			// Scale wave x-axis to degrees
			variable oldStart = pnt2x($thiswavename, 0)
			variable oldDelta = deltaX($thiswavename)
			variable newStart = (oldStart * (180 / pi))
			variable newDelta = (oldDelta * (180 / pi))
			SetScale/P x newStart,newDelta,"", $thiswavename

			if (ii == 0)
				// Create new plot with first data wave
				Preferences 0; Display $thiswavename; DelayUpdate
				execute "WAXStool_IvsChi_plot();Preferences 1"
				
				ii += 1
			else
				// Append data wave to plot
				appendtograph $thiswavename
			endif
			
			// Set trace color
			colorRow = mod(c, DimSize(colors, 0))
			
			R = colors[colorRow][0] * (65535 / 255)
			G = colors[colorRow][1] * (65535 / 255)
			B = colors[colorRow][2] * (65535 / 255)

			ModifyGraph rgb($thiswavename)=(R, G, B)
			
			c += 1
		endif
	endfor
	
	// Format plot
	AT_formatPlot()
end


function AT_formatPlot()
	wave plotSettings = root:Packages:AutomationTools:plotParameters
	variable numRows = DimSize(plotSettings, 0)
	string parameter
	variable value
	
	// Apply plot settings from plot settings file
	variable i
	for (i = 0; i < numRows; i += 1)
		parameter = GetDimLabel(plotSettings, 0, i)
		value = plotSettings[i][0]

		Execute "ModifyGraph " + parameter + "=" + num2str(value)
	endfor
		
	// Plot labels
	Label bottom "\\Z20q\\Z18 (Å\\S-1\\M\\Z18)"
	Label left   "\\Z20Counts\\Z18"
end


function AT_updateWaveList()
	string thewaves = Wavelist("*", ";", "")
	
	// Create lists for indexing selected wave
	make /T /O /N=(ItemsInList(thewaves,";")) root:Packages:GIWAXS:thewavelist = stringfromlist(p,thewaves,";")
	make /O /N=(itemsinlist(thewaves,";")) root:Packages:GIWAXS:thewavelist_number
end


function AT_qzqxyConvert()
	string thiswavename
	string wavenamelist = wavelist("*", ";", "")
	
	wave thewavelist_number = root:Packages:GIWAXS:thewavelist_number
	NVAR g_BCX = root:Packages:GIWAXS:g_BCX
	NVAR g_BCY = root:Packages:GIWAXS:g_BCY
	NVAR g_R = root:Packages:GIWAXS:g_R
	NVAR g_incidence = root:Packages:GIWAXS:g_incidence
	NVAR g_pxsizex = root:Packages:GIWAXS:g_pxsizex
	NVAR g_pxsizey = root:Packages:GIWAXS:g_pxsizey
	NVAR g_q_range = root:Packages:GIWAXS:g_q_range
	NVAR g_q_res = root:Packages:GIWAXS:g_q_res
	NVAR g_BLenergy = root:Packages:GIWAXS:g_BLenergy
	
	variable i
	for(i = 0; i < numpnts(root:Packages:GIWAXS:thewavelist_number); i += 1)
		if(thewavelist_number[i] == 1)
			thiswavename=stringfromlist(i, wavenamelist)
			distcorr2($thiswavename, g_BCX, g_BCY, g_R, g_incidence, g_pxsizex, g_pxsizey, g_q_range, g_q_res, g_BLenergy)
		endif
	endfor
	
	update_wavelist()
end


function AT_wedge2Dto1D(thisWaveStem, plotName, processCode)
	string thisWaveStem
	string plotName
	string processCode
	
	NVAR chi_start = root:Packages:GIWAXS:g_chi_start
	NVAR chi_end = root:Packages:GIWAXS:g_chi_end
	NVAR q_start = root:Packages:GIWAXS:g_q_start
	NVAR q_end = root:Packages:GIWAXS:g_q_end
	
	// Switch to "qz(qxy) to chi(q)" tab
	DoWindow/F giwaxs_tools
	TabProc("qzqxy", 1)   // Fix later - doesn't update tab icon....
	
	// Display cake slice
	DoWindow/F $plotName
	
	// Convert qz-qxy data to chi-q data
	wave thewavelist_number = root:Packages:GIWAXS:thewavelist_number
	NVAR remhor = root:Packages:GIWAXS:g_remhor
	NVAR remhorqz = root:Packages:GIWAXS:g_remhorqz
	
	qchiconvert($(thisWaveStem + "_qzqxy"), (chi_start * Pi/180),(chi_end * Pi/180), q_start, q_end, remhor, remhorqz)
	
	// Append integration range to wave name
	string newWaveName = thisWaveStem + "_chiq_" + num2str(chi_start) + "to" + num2str(chi_end) + "_" + num2str(q_start) + "to" + num2str(q_end)
	rename $(thisWaveStem + "_chiq") $newWaveName
	
	if (stringMatch(processCode, "IvsQ"))
		// Integrate chi-q data to I-q
		integrateimage($newWaveName)
			
	elseif (stringMatch(processCode, "IvsChi"))
		// Integrate chi-q data to I-chi
		integrateimage2($newWaveName)	
	endif
	
	update_wavelist()
end


function AT_switchWave(wavenameToSelect)
	string wavenameToSelect
	wave wavelist_number = root:Packages:GIWAXS:thewavelist_number
	string wavenamelist = wavelist("*", ";", "")
	
	// Check for updates to waves in data folder
	AT_updateWaveList()

	// Deselect all waves, then select specified wave
	wavelist_number = 0
	
	variable i
	for (i = 0; i < numpnts(wavelist_number); i += 1)
		if (stringMatch(stringfromlist(i, wavenamelist), wavenameToSelect))
			wavelist_number[i] = 1
		endif
	endfor
end


function AT_displayQzqxy()
	string thiswavename
	string wavenamelist = wavelist("*", ";", "")
	wave thewavelist_number = root:Packages:GIWAXS:thewavelist_number
	
	variable i
	for(i = 0; i < numpnts(thewavelist_number); i += 1)
		if(thewavelist_number[i] == 1)
			// Retrieve name of data wave to plot
			thiswavename = stringfromlist(i, wavenamelist)
			
			// Plot selected wave
			Preferences 0; Display; AppendImage $thiswavename; DelayUpdate
			execute "qzqxy_full(); Preferences 1"
			ModifyImage $thiswavename ctab= {0, 200, Rainbow, 1}
	
			// Plot settings
			ModifyGraph width=500, height=250
			SetAxis bottom -2,2
			SetAxis left 0,2
			Label bottom "\\Z20q\\Bxy\\M\\Z18 (Å\\S-1\\M\\Z18)"
			Label left "\\Z20q\\Bz\\M\\Z18 (Å\\S-1\\M\\Z18)"
		endif
	endfor
end


function AT_loadPlotParameters()
	// Store current data folder, then move to AutomationTools folder
	string currentFolder = getDataFolder(1)
	SetDataFolder root:Packages:AutomationTools
	
	// Locate plot settings file in User Procedures > Automation Tools
	string path = FunctionPath("")
	path = ParseFilePath(1, path, ":", 1, 0)	
	
	// Load in plot settings data
	LoadWave /A /O /J /W /M /Q /E=1 /U={1, 0, 1, 0} /B="N=plotParameters;" path + "AT_plotParameters.csv"
		
	// Return to previous data folder
	SetDataFolder $currentFolder
end


function AT_loadCustomPlotParameters()
	// Store current data folder, then move to AutomationTools folder
	string currentFolder = getDataFolder(1)
	SetDataFolder root:Packages:AutomationTools
	
	// Load in plot settings data
	LoadWave /A /O /J /W /M /Q /E=1 /U={1, 0, 1, 0} /B="N=plotParameters;"
		
	// Return to previous data folder
	SetDataFolder $currentFolder
end


function AT_loadPlotColors()
	// Store current data folder, then move to AutomationTools folder
	string currentFolder = getDataFolder(1)
	SetDataFolder root:Packages:AutomationTools
	
	// Locate plot settings file in User Procedures > Automation Tools
	string path = FunctionPath("")
	path = ParseFilePath(1, path, ":", 1, 0)	
	
	// Load in plot settings data
	LoadWave /A /O /J /W /M /Q /E=1 /U={1, 0, 1, 0} /B="N=plotColors;" path + "AT_plotColors.csv"
		
	// Return to previous data folder
	SetDataFolder $currentFolder
end


function AT_loadCustomPlotColors()
	// Store current data folder, then move to AutomationTools folder
	string currentFolder = getDataFolder(1)
	SetDataFolder root:Packages:AutomationTools
	
	// Load in plot settings data
	LoadWave /A /O /J /W /M /Q /E=1 /U={1, 0, 1, 0} /B="N=plotColors;"
		
	// Return to previous data folder
	SetDataFolder $currentFolder
end


// ---Data Manipulation Functions--- //
function AT_waveArithmetic(operation)
	string operation

	// Refresh wave lists
	AT_updateWaveList()

	// Average selected waves
	wave thewavelist_number = root:Packages:GIWAXS:thewavelist_number
	string wavenamelist = wavelist("*", ";", "")

	variable i, firstWave = 0
	for (i = 0; i < numpnts(thewavelist_number); i += 1)
		if (thewavelist_number[i])
			string thiswavename = stringfromlist(i, wavenamelist)
			wave thiswave = $thiswavename
			
			if (firstWave == 0) 
				// Duplicate first selected wave
				string suffix
				if (stringMatch(operation, "add"))
					suffix = "_add"
				elseif (stringMatch(operation, "subtract"))
					suffix = "_sub"
				endif
				
				string newwavename = (thiswavename + suffix)
				Duplicate $thiswavename $newwavename
				wave newwave = $newwavename
				
				firstWave += 1
			else
				// Perform arithmetic with next wave
				if (stringMatch(operation, "add"))
					newwave += thiswave
				elseif (stringMatch(operation, "subtract"))
					newwave -= thiswave
				endif
			endif
		endif
	endfor
		
	// Refresh wave lists
	AT_updateWaveList()
end


function AT_averageWaves()
	// Refresh wave lists
	AT_updateWaveList()

	// Average selected waves
	wave thewavelist_number = root:Packages:GIWAXS:thewavelist_number
	string wavenamelist = wavelist("*", ";", "")

	variable i, numWaves = 0, firstWave = 0
	for (i = 0; i < numpnts(thewavelist_number); i += 1)
		if (thewavelist_number[i])
			string thiswavename = stringfromlist(i, wavenamelist)
			wave thiswave = $thiswavename
			
			if (firstWave == 0) 
				// Duplicate first selected wave
				string avgwavename = (thiswavename + "_Avg")
				Duplicate $thiswavename $avgwavename
				wave avgwave = $avgwavename
				
				firstWave += 1
			else
				// Average in selected wave
				avgwave += thiswave
			endif
			
			numWaves += 1
		endif
	endfor
	
	avgwave /= numWaves
	
	// Refresh wave lists
	AT_updateWaveList()
end


function AT_normWaveToMax()
	// Refresh wave lists
	AT_updateWaveList()

	// Normalize selected waves
	wave thewavelist_number = root:Packages:GIWAXS:thewavelist_number
	string wavenamelist = wavelist("*", ";", "")

	variable i
	for (i = 0; i < numpnts(thewavelist_number); i += 1)
		if (thewavelist_number[i])
			string thiswavename = stringfromlist(i, wavenamelist)
			wave thiswave = $thiswavename
			
			// Divide wave by wave max value
			variable maxValue = wavemax(thiswave)
			
			string normwavename = (thiswavename + "_Norm")
			Duplicate $thiswavename $normwavename
			wave normwave = $normwavename
			
			normwave /= maxValue
		endif
	endfor
		
	// Refresh wave lists
	AT_updateWaveList()
end


function AT_normWaveToMax_ConstBL()
	// Refresh wave lists
	AT_updateWaveList()

	// Prompt user for baseline sampling range
	string BLRangeString
	Prompt BLRangeString, "Enter baseline sampling range (R1,R2), new baseline value C, and new max value M in format 'R1,R2,C,M':"
	DoPrompt "Baseline Sampling Range", BLRangeString
	
	if (strlen(BLRangeString) != 0)
		// Extract specified baseline sampling range
		variable lowerBound, upperBound, newBLValue, newMaxValue
		lowerBound = str2num(stringfromlist(0, BLRangeString, ","))
		upperBound = str2num(stringfromlist(1, BLRangeString, ","))
		newBLValue = str2num(stringfromlist(2, BLRangeString, ","))
		newMaxValue = str2num(stringfromlist(3, BLRangeString, ","))
		
		// Normalize selected waves
		wave thewavelist_number = root:Packages:GIWAXS:thewavelist_number
		string wavenamelist = wavelist("*", ";", "")
	
		variable i
		for (i = 0; i < numpnts(thewavelist_number); i += 1)
			if (thewavelist_number[i])
				string thiswavename = stringfromlist(i, wavenamelist)
				wave thiswave = $thiswavename
				
				// Subtract constant baseline value
				string normwavename = (thiswavename + "_Norm")
				Duplicate $thiswavename $normwavename
				wave normwave = $normwavename
				
				variable constBLValue = mean(thiswave, lowerBound, upperBound)
				normwave -= constBLValue
				
				// Divide wave by wave max value
				variable maxValue = wavemax(normwave)
				normwave /= maxValue
				
				// Add in artificial baseline value
				normwave *= (newMaxValue - newBLValue)
				normwave += newBLValue
			endif
		endfor
	endif
		
	// Refresh wave lists
	AT_updateWaveList()
end

function AT_maskDataPts()
	// Refresh wave lists
	AT_updateWaveList()	

	// Prompt user for baseline sampling range
	string dataRangeString
	Prompt dataRangeString, "Enter range of data (R1,R2) to mask in format 'R1,R2':"
	DoPrompt "Data Masking Range", dataRangeString
	
	if (strlen(dataRangeString) != 0)
		// Extract specified data masking range
		variable lowerBound, upperBound
		lowerBound = str2num(stringfromlist(0, dataRangeString, ","))
		upperBound = str2num(stringfromlist(1, dataRangeString, ","))
	
		// Mask specified data range
		wave thewavelist_number = root:Packages:GIWAXS:thewavelist_number
		string wavenamelist = wavelist("*", ";", "")
	
		variable i
		for (i = 0; i < numpnts(thewavelist_number); i += 1)
			if (thewavelist_number[i])
				string thiswavename = stringfromlist(i, wavenamelist)
				wave thiswave = $thiswavename
				
				// Mask specified datarange
				variable lowerPt = x2pnt(thiswave, lowerBound)
				variable upperPt = x2pnt(thiswave, upperBound)
				
				print(lowerPt)
				print(upperPt)
				print(pnt2x(thiswave, lowerPt))
				print(pnt2x(thiswave, upperPt))
				
 				string maskwavename = (thiswavename + "_Mask")
				Duplicate $thiswavename $maskwavename
				wave maskwave = $maskwavename
 
 				variable j
 				for (j = lowerPt; j <= upperPt; j += 1)
 					maskwave[j] = NaN
				endfor
			endif
		endfor
	endif
end


// ---Miscellaneous Functions--- //
function AT_batchCopyWaves()
	// Refresh wave lists
	AT_updateWaveList()

	// Duplicate selected waves
	wave thewavelist_number = root:Packages:GIWAXS:thewavelist_number
	string wavenamelist = wavelist("*", ";", "")

	variable i 
	for (i = 0; i < numpnts(thewavelist_number); i += 1)
		if (thewavelist_number[i])
			string thiswavename = stringfromlist(i, wavenamelist)
			
			Duplicate $thiswavename $(thiswavename + "_Copy")
		endif
	endfor
	
	// Refresh wave lists
	AT_updateWaveList()
end