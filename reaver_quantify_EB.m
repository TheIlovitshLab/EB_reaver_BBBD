function metric_st = reaver_quantify_EB(mat_path,n_px,diffu)
%{
Custom image processing and measurements extraction function.
Input arguements:
    mat_math = path to a .mat file containing the verified image
               parameters, BW image and wireframe
    n_px = Size of neighborhood around a blood vessel (in px)
    diffu = determines if the function extracts the diffusin in multiple or
                signle distance (0 = single, 1 = multiple)
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
warning('off','imageio:tiffmexutils:libtiffWarning');

if isempty(dir(mat_path))
    error('File not found in specified path: %s\n' , mat_path);
end

% Load matlab reaver file
st = load(mat_path);
fov_um = st.image_resolution* st.imageSize(1);

% Load red channel
im_file = [mat_path(1:end-4),'.tif'];
t = Tiff(im_file);
setDirectory(t,1)
redIm = read(t);   % We only need the red channel
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

mean_diams = 2.*all_seg_rads.mean+1;  %Multiply by 2 and add the pixel for the center point to get the diameter
median_diams = 2.*all_seg_rads.median+1;
max_diams = 2.*all_seg_rads.max+1;

mean_segment_diam_um = cell(1,1);
median_segment_diam_um = cell(1,1);
max_segment_diam_um = cell(1,1);

mean_segment_diam_um{1,1} = mean_diams .* (fov_um ./ st.imageSize(1));
median_segment_diam_um{1,1} = median_diams .* (fov_um ./ st.imageSize(1));
max_segment_diam_um{1,1} = max_diams .* (fov_um ./ st.imageSize(1));

metric_st.mean_segment_diam_um = mean_segment_diam_um;
metric_st.median_segment_diam_um = median_segment_diam_um;
metric_st.max_segment_diam_um = max_segment_diam_um;

% TODO: Use maximal segment radius instead of median for dilation
avg_red_px_val = cell(1,1);
switch diffu
    case 0
        avg_red_px_val{1,1} = calc_eb_ext(rcind_seg_cell,all_seg_rads.max,st.derivedPic.BW_2, redIm, n_px);
    case 1
        avg_red_px_val{1,1} = calc_eb_ext_upto_n_px(rcind_seg_cell,all_seg_rads.max,st.derivedPic.BW_2, redIm, n_px);
end
metric_st.avg_red_px_val = avg_red_px_val;
end

