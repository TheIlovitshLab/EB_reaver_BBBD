function [metric_st, short_lbl_st] = reaver_quantify_EB(mat_path)
%{
Custom image processing and measurements extraction function.
Input arguements:
    mat_math = path to a .mat file containing the verified image
               parameters, BW image and wireframe
Output arguements:
    metric_st = structure with all measurements. containing the following
        fields:                   
            'vessel_area_fraction'        
            'vessel_length_um'            
            'segments_diam_um'
            'avg_red_px_val'
    short_lbl_st = structure containing labels for metric_st measured
                   parameters.
%}

if isempty(dir(mat_path))
    error('File not found in specified path: %s\n' , mat_path);
end

% Predifined vars
n_px = 4; % Size of neighborhood around a blood vessel

% Load matlab reaver file
st = load(mat_path);
fov_um = st.image_resolution* st.imageSize(1);
fov_mm = fov_um/1000;

umppix = st.image_resolution;

% Load red channel
im_file = [mat_path(1:end-4),'.tif'];
t = Tiff(im_file);
setDirectory(t,1)
redIm = im2uint16(read(t));   % We only need the red channel
% Initialize output struct
metric_st=struct();

% Vessel length and Branchpoint density
metric_st.vessel_area_fraction = sum(st.derivedPic.BW_2(:))./prod(st.imageSize);

% Add average radius and calssify each lineseg
rcind_seg_cell = skel_2_linesegs(st.derivedPic.wire,...
    fliplr(st.derivedPic.branchpoints),fliplr(st.derivedPic.endpoints));

% Measure segment radii and record diameter
[all_seg_rads, ~] = measure_segment_rad(rcind_seg_cell,...
    st.derivedPic.BW_2, fliplr(st.derivedPic.endpoints));
all_seg_diams = 2.*all_seg_rads.median+1;  %Multiply by 2 and add the pixel for the center point to get the diameter
metric_st.mean_segment_diam_um = mean(all_seg_diams) .* (fov_um ./ st.imageSize(1));
all_segment_diam_um = cell(1,1);
avg_red_px_val = all_segment_diam_um;
all_segment_diam_um{1,1} = all_seg_diams .* (fov_um ./ st.imageSize(1));
metric_st.all_segment_diam_um = all_segment_diam_um;
% TODO: Use maximal segment radius instead of median for dilation
avg_red_px_val{1,1} = calc_eb_ext(rcind_seg_cell,all_seg_rads.max,st.derivedPic.BW_2, redIm, n_px);
metric_st.avg_red_px_val = avg_red_px_val;
% Short hand labels for plotting/display
short_lbl_st.vessel_area_fraction = 'VAF';
short_lbl_st.mean_segment_length_um = 'Mean  Len. (um)';
short_lbl_st.segments_diam_um = 'All Segment Diam (um)';
short_lbl_st.avg_red_px_val = 'All segments EB extravasation (mean px intensity)';
end

