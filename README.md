# REAVER for EB
Rapid Editable Analysis of Vessel Elements Routine, utilized for quantification of perivascular EB extravasation during BBB opening.


## Dependencies:
* Tested on MATLAB 2021a, requires image processing toolbox.

## Initialization
1. Open the extracted folder and open "USER_INITILIZE.m"
2. Run the script file by pressing the run button in the ribbon menu (green triangle). All matlab files in repository will get added to the matlab path and REAVER will open.

## Using REAVER for vessel segmentation
1. Once open, go to the menu "File >> Load Directory", and browse to the directory in images to be analyzed.
2. Image names will population the image table on the left. Select the image to be analyzed in the table and the image will load.
3. Enter the image resolution in units of micrometer per pixel.
3. Visualize the channels as necessary for visual inspection by controlling which are visible with the "Displayed Channel" panel.
5. Select the color channel that is meant to be processed in the "Input Channel" panel.
6. Click on Segment image.
7. The image will be displayed with a green outline and white skeleton by default (color can be changed in "Image" menu).
8. Inspect the image as necessary and change parameter if needed, including the grey threshold (pixel level above background) or the parameters that are accessed by clicking on the gear button.
9. To compare the segmentation to the original image, select the "Displayed Channels" and "Secondary Binary" image to inspect, and then hit spacebar to quickly toggle between them.
10. Manually add to the segmentation (what is considered vessel, surrounded by green border) by left clicking and dragging. Right click and dragging will remove pixels from segmentation. Adjust the cursor edit size as necessary.
11. When done click "Save Data".
12. Move onto the next image, or auto process all images at once in the folder by going to "Data >> Process All Images".

## Output Metrics
1. run the "EB_analysis_entire_folder" function on the pre-processed tiff folder.
    > The script will analyze the data and return a 'EB_analysis_npx.m' file in the processed folder 
2. run the same script on the control and test data.
3. Initialize an experiment object using the "EB_analysis" class. this will prompt you to load the EB_analysis_npx.m files from the control and test data folders
4. Use the built-in class methods to extract beautiful visualiations.
