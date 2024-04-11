# REAVER for BBB opening
Rapid Editable Analysis of Vessel Elements Routine, utilized for quantification of perivascular EB extravasation during BBB opening.

## Paper

This repository provides the UNet segmentation in the following papers:

**Enhanced capillary delivery with nanobubble-mediated blood-brain barrier opening** <br/>
[Roni Gattegno](https://www.linkedin.com/in/roni-gattegno/), [Lilach Arbel](https://www.linkedin.com/in/lilach-arbel/), [Noa Riess](https://www.linkedin.com/in/noa-riess-228807217/), [Hila Shinar](https://www.linkedin.com/in/hila-shinar/?originalSubdomain=il), [Sharon Katz](https://www.linkedin.com/in/sharon-kz/) and [Tali Ilovitsh](https://www.linkedin.com/in/tali-ilovitsh/) <br/>
Tel Aviv University <br/>
Journal of Controlled Release ([JCR](https://www.sciencedirect.com/journal/journal-of-controlled-release)) <br/>
[paper](https://www.sciencedirect.com/science/article/abs/pii/S0168365924002220?via%3Dihub) | [code](https://github.com/TheIlovitshLab/EB_reaver_BBBD)

**Protocol to assess extravasation of fluorescent molecules in mice after ultrasound-mediated blood-brain barrier opening** <br/>
[Lea Peko](https://www.linkedin.com/in/lea-peko/), [Sharon Katz](https://www.linkedin.com/in/sharon-kz/), [Roni Gattegno](https://www.linkedin.com/in/roni-gattegno/) and [Tali Ilovitsh](https://www.linkedin.com/in/tali-ilovitsh/) <br/>
Tel Aviv University <br/>
[STAR Protocols](https://www.cell.com/star-protocols/home) <br/>
[paper](https://www.sciencedirect.com/science/article/pii/S2666166723007372) | [code](https://github.com/TheIlovitshLab/BBBD-REAVER)

**Diameter-dependent assessment of microvascular leakage following ultrasound-mediated blood brain barrier opening** <br/>
[Sharon Katz](https://www.linkedin.com/in/sharon-kz/), [Roni Gattegno](https://www.linkedin.com/in/roni-gattegno/), [Lea Peko](https://www.linkedin.com/in/lea-peko/), [Romario Zarik](https://www.linkedin.com/in/romariozarik/), [Yulie Hagani](https://www.linkedin.com/in/yulie-hagani/) and [Tali Ilovitsh](https://www.linkedin.com/in/tali-ilovitsh/) <br/>
Tel Aviv University <br/>
[iScience](https://www.sciencedirect.com/journal/iscience) <br/>
[paper](https://www.sciencedirect.com/science/article/pii/S2589004223010428) | [code](https://github.com/TheIlovitshLab/BBBD-REAVER)


## Citation
If you use this code for your research, please cite our paper:
```
@article{gattegno2023enhanced,
  title={Enhanced capillary delivery with nanobubble-mediated blood-brain barrier opening and advanced high resolution vascular segmentation},
  author={Gattegno, Roni and Arbel, Lilach and Riess, Noa and Kats, Sharon and Ilovitsh, Tali},
  journal={bioRxiv},
  pages={2023--12},
  year={2023},
  publisher={Cold Spring Harbor Laboratory}
}

@article{peko2024protocol,
  title={Protocol to assess extravasation of fluorescent molecules in mice after ultrasound-mediated blood-brain barrier opening},
  author={Peko, Lea and Katz, Sharon and Gattegno, Roni and Ilovitsh, Tali},
  journal={STAR protocols},
  volume={5},
  number={1},
  pages={102770},
  year={2024},
  publisher={Elsevier}
}

@article{katz2023diameter,
  title={Diameter-dependent assessment of microvascular leakage following ultrasound-mediated blood-brain barrier opening},
  author={Katz, Sharon and Gattegno, Roni and Peko, Lea and Zarik, Romario and Hagani, Yulie and Ilovitsh, Tali},
  journal={Iscience},
  volume={26},
  number={6},
  year={2023},
  publisher={Elsevier}
}

## Dependencies:
* Tested on MATLAB 2021a, requires image processing toolbox.
* Before starting the process make sure the control and test tiff files are placed in seperate folders

## Example files
Try the pipeline on the *[Example files](https://github.com/TheIlovitshLab/EB_reaver/blob/master/Examples)*
 
# EB reaver Pipeline
## Initialization
1. Open the extracted folder in matlab and run the main app by executing:
	>EBreaverApp

in the MATLAB command terminal.<br>
The following window will pop-up:

<img src="resources/guiUI.png">

## Vessel segmentation
1. Open the REAVER GUI via the dedicated push button
2. Follow the *[REAVER segmentation workflow](https://github.com/TheIlovitshLab/EB_reaver/blob/master/REAVER%20GUI/REAVER%20GUI%20workflow.md)*
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

## Summary Analysis
The EB_analysis class object has the following plotting methods:

### scatterPlot
Creates a scatter plot where each point represents a vessel segment and the axis are:
x = vessel diameter, y = Median red intensity in perivascular area 
The control and test measurements are marked with different colors

<img src="resources/scatterPlot.png" width="420" height="315">

### fitplot
Creates two lines on a single plot, one for control and one for test data.
Each line represents the median red intensity in perivascular area as function
of the diameter with error bars.
The lines are also fitted with an equation based on the user-specfied model (e.g. linear/quadratic)

<img src="resources/fitPlot.png" width="420" height="315">

### violinplot
Implements a violin plot for control and test data side-by-side for the specified diameter groups.
>Bechtold, Bastian, 2016. Violin Plots for Matlab, Github Project
https://github.com/bastibe/Violinplot-Matlab, DOI: 10.5281/zenodo.4559847

<img src="resources/violinPlot.png" width="420" height="315">

### barplot
creates a bar plot for the specified diameter groups.
optional flag for which class groups to plot (1 = test, 2 = control and test, 0 = subtraction, -1 = control)

<img src="resources/barPlot.png" width="420" height="315">

### redDistrebution
Plots the distribution histogram of red intensity in perivascular area for control and test groups.
The histograms are plotted seperately for each diameter group specified.
The histograms can be plotted with or without a line indicated number of SDs above the control mean
The histogram can be plotted as bar histogram or as 'psd' by applying a kernel density

<img src="resources/redDistribution.png" width="420" height="315">

### diamHist
Plots the histogram of diameters of all segmented vessels. Also adds a comparison (2-way ANOVA) between control and test distributions.

![diameter histogram](resources/diamHist.png)

### openedHist
plots the fraction of opened vessels in different diameters of vessels (in specified diameter groups)
Also returns a table of opening percentage per frame and diameter for statistical analysis in GraphPad

<img src="resources/openedHist.png" width="420" height="315">

### regionHistogram
plots the number of vessels in each treated brain by brain region (beta version)

## Other EB_analysis class methods

### subarea
Create a new EB_analysis object with vessels only from a user specified brain region

### writecsv
Write the summary table into 2 csv objects (control and test) for GraphPad analysis

### keep_diameters
Remove all vessels with diameters outside the specified thresholds

### match_histogram
Create a new EB_analysis object where for each diameter group the extreme vessels are removed
from the group with more vessels (control or test) to eliminate class imbalance
