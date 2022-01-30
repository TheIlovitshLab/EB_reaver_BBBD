function [metric_st, short_lbl_st] = reaver_quantify_network(mat_path)
%{
Image processing and measurements extraction.
Input arguements:
    mat_math = path to a .mat file containing the verified image
               parameters, BW image and wireframe
Output arguements:
    metric_st = structure with all measurements. containing the following
        fields:
            'fov_um'                      
            'umppix'                      
            'vessel_area_fraction'        
            'vessel_length_um'            
            'vessel_length_density_mmpmm2'
            'branchpoint_count'           
            'segment_count'               
            'mean_segment_length_um'      
            'mean_tortuosity'             
            'mean_valency'                
            'mean_segment_diam_um'        
            'all_segment_diam_um'   
    short_lbl_st = structure containing labels for metric_st measured
                   parameters.
%}

if isempty(dir(mat_path))
    error('File not found in specified path: %s\n' , mat_path);
end



% Load matlab reaver file
st = load(mat_path);
fov_um = st.image_resolution* st.imageSize(1);
fov_mm = fov_um/1000;
umppix = st.image_resolution;


% Initialize output struct
metric_st=struct();

% Basic metadata
metric_st.fov_um = fov_um;
metric_st.umppix = umppix;


% Vessel length and Branchpoint density
metric_st.vessel_area_fraction = sum(st.derivedPic.BW_2(:))./prod(st.imageSize);

metric_st.vessel_length_um = nnz(st.derivedPic.wire) * ...
(fov_um/st.imageSize(1));
metric_st.vessel_length_density_mmpmm2 = nnz(st.derivedPic.wire) * ...
    (fov_mm/st.imageSize(1))./(fov_mm).^2;
metric_st.branchpoint_count=size(st.derivedPic.branchpoints,1);


% Vessel tortuosity and # segments
% Add average radius and calssify each lineseg
rcind_seg_cell = skel_2_linesegs(st.derivedPic.wire,...
    fliplr(st.derivedPic.branchpoints),fliplr(st.derivedPic.endpoints));
metric_st.segment_count = size(rcind_seg_cell,1);

metric_st.mean_segment_length_um = mean(cellfun(@(x) size(x,1),rcind_seg_cell)).*umppix;
metric_st.mean_tortuosity = mean(rcind_seg_tortuosity(rcind_seg_cell));
metric_st.mean_valency = size(st.derivedPic.branchpoints,1)./size(rcind_seg_cell,1);


% metric_st.bp_p_segments = metric_st.branchpoint_count ./metric_st.segment_count;

% Measure segment radii and record diameter
[all_seg_rads, ~] = measure_segment_rad(rcind_seg_cell,...
    st.derivedPic.BW_2, fliplr(st.derivedPic.endpoints));
all_seg_diams = 2.*all_seg_rads+1;  %Multiply by 2 and add the pixel for the center point to get the diameter
metric_st.mean_segment_diam_um = mean(all_seg_diams) .* (fov_um ./ st.imageSize(1));
all_segment_diam_um = cell(1,1);
all_segment_diam_um{1,1} = all_seg_diams .* (fov_um ./ st.imageSize(1));
metric_st.all_segment_diam_um = all_segment_diam_um;

% Short hand labels for plotting/display
short_lbl_st.vessel_area_fraction = 'VAF';
short_lbl_st.vessel_length_density_mmpmm2 = 'VLD (mm/mm2)';
short_lbl_st.branchpoint_count = 'BP Count';
short_lbl_st.segment_count = 'Segment Count';
% short_lbl_st.bp_p_segments = 'BP/ Segments';
short_lbl_st.mean_segment_length_um = 'Mean Segment Len. (um)';
short_lbl_st.mean_tortuosity = 'Tortuosity';
short_lbl_st.mean_valency = 'Valency';
short_lbl_st.mean_segment_diam_um = 'Mean Segment Diam (um)';
short_lbl_st.all_segment_diam_um = 'All Segment Diam (um)';

% Build adjacency matrix
% https://www.nas.ewi.tudelft.nl/people/Piet/papers/TUDreport20111111_MetricList.pdf
end

