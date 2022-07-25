# REAVER for BBB opening
Rapid Editable Analysis of Vessel Elements Routine, utilized for quantification of perivascular EB extravasation during BBB opening.


## Dependencies:
* Tested on MATLAB 2021a, requires image processing toolbox.
* Before starting the process make sure the control and test tiff files are placed in seperate folders

## Initialization
1. Open the extracted folder in matlab and run the main app by executing:
	>EBreaverApp.<br>
in the MATLAB command terminal
The following window will pop-up:
![App GUI](resources/guiUI.png)

## Vessel segmentation
1. Open the REAVER GUI via the dedicated push button
2. Follow the REAVER segmentation pipeline described in: *[REAVER](https://github.com/uva-peirce-cottler-lab/public_REAVER)*
- Use the FITC-dextran (green) channl for segmentation
- This will create a ".mat" file for each segmented tiff file
- It will also create a "UserVerified.mat" file that points to verified files for future analysis

## Batch analysis of segmented images
1. Choose control file directory and test file directory.
- These should contain the already segmented tiff files
2. Specify the perivascular width (d) and the distance from vessel wall (w_i) to fit your experiment:
![screenshot](resources/perivascularArea.png)
3. Check the "normalize red" checkbox to perform frame-level normalization of the red channel to a range of [0,1]
4. Press the process folders push button
- This will create an "EB_analysis_<hyper_parameters>.mat" file in each of the directories
- The created file name indicated the analysis hyper-parameters

## Create a summary object
1. Press the "Create analysis object" push button
2. Choose the approperiate EB_analysis file from the control directory
3. Choose the appropriate EB_analysis file from the test directory
- This will generate a summary object of class "EB_analysis" and save it to the open matlab workspace as "results"

The EB_analysis class object has the following plotting methods:

**scatterPlot**
Creates a scatter plot where each point represents a vessel segment and the axis are:
x = vessel diameter, y = Mean red intensity in perivascular area 
The control and test measurements are marked with different colors

**fitplot**
Creates two lines on a single plot, one for control and one for test data.
Each line represents the Mean red intensity in perivascular area as function
of the diameter with error bars (in the specified diameters).
The lines are also fitted with an equation based on the specfied model (e.g. linear/quadratic)

**boxplot**
creates a box plot for control and test data side-by-side for the specified diameter groups.

**barplot**
creates a bar plot for the specified diameter groups.
optional flag for which class groups to plot (test, control and test, subtraction)

**redDistrebution**
Plots the distribution histogram of red intensity in perivascular area for control and test groups.
The histograms are plotted seperately for each diameter group specified.

**diamHist**
Plots the histogram of diameters of all segmented vessels.

**openedHist**
plots the fraction of opened vessels in different diameters of vessels (in specified diameter groups)

**regionHistogram**
plots the number of vessels in each treated brain by brain region.