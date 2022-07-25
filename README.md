# REAVER for BBB opening
Rapid Editable Analysis of Vessel Elements Routine, utilized for quantification of perivascular EB extravasation during BBB opening.


## Dependencies:
* Tested on MATLAB 2021a, requires image processing toolbox.

## Initialization
1. Open the extracted folder and open the app EB_reaver (double click)
	-The following window will pop-up:
![screenshot](resources/guiUI.png)

## Vessel segmentation
1. type *"REAVER_GUI"* on the MATLAB terminal and press "enter"
	- This will open the REAVER application
2. Follow the REAVER pipeline described in: https://github.com/uva-peirce-cottler-lab/public_REAVER
	- The app works only with 8-bit images 
	(for batch conversion of 16-bit to 8 bit use the imageJ macro "batch convert 8bit.ijm")
	- Use the FITC-dextran (green) channl for segmentation

## Batch analysis of segmented images
1. type *EB_analysis_entire_folder(n_px)*, replace n_px with the desired perivascular are width in pixels.
    - The function will prompt you to choose the segmented images folder.
2. run the same script on the control and test data.

## Comparison of control and test groups
1. create an "EB_analysis" object using the following syntax:
	> object = EB_analysis.
	- This will prompt you to load the EB_analysis_npx.m files of the control and test groups

The EB_analysis object has the following plotting methods:

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