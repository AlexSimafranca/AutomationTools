# AutomationTools
A package of tools for automating GIWAXS processing using the WAXSTools package in Igor Pro.

## Installation Instructions
To install the package, follow these steps:

1. Locate the Igor Pro program folder (it should be under "Applications" or "Programs").
2. Within the Igor Pro program folder, transfer the following files:
   - The **"AutomationTools"** folder goes in the "User Procedures" folder.
   - The **"BootAutomationTools.ipf"** file goes into the "Igor Procedures" folder.

## Dependencies
This package relies on the **Nika** and **WAXSTools** packages. I do not own the right to distribute these dependencies, so please request them from their respective authors.

## Data Importing
Data can be batch imported using the "Load Images From Folder" command under AutomationTools > DataProcessing. Each data file will be automatically imported in its own folder for convenient organization.

Once the desired .tif data files are selected, you are given the option to truncate the data names for ease of processing via a pop-up box. The value entered into the pop-up text field should be the **first unique characters of the name section to be removed**. 

For example, if two data files are named "Sample1_250402.tif" and "Sample2_250402.tif", entering "_2" in the pop-up box will import the data as waves named "Sample1" and "Sample2".

## Data Selection Using WAXSTools
With the exception of calibration steps done through the Nika Beam Center and Geometry Correction panel, selecting data for processing or plotting should be done through the WAXSTools panel. 

To display data in the WAXSTools panel, locate the desired data folder in the Data Browser window (Data > Data Browser), right click the folder and select "Set as Data Folder". Then, click "Read data folder" at the top of the WAXSTools panel.

## Plot Parameter Customization
Default plot parameters are set using values contained in two files: **"AT_plotParameters.csv"** and **"AT_plotColors.csv"**. These files are located in the "AutomationTools" folder contained in the package. 

To permanently set your own default plot parameters, update these files directly. 

To set them temporarily, create your own CSV files and use the "Load Custom Plot Parameters" and "Load Custom Plot Colors" commands in the AutomationTools dropdown menu under Plotting > Plot Parameters.
