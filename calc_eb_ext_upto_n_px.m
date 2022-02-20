function eb_ext_in_segments = calc_eb_ext_upto_n_px(rcind_seg_cell,all_seg_rads,bw_vessels, redIm, n_px)
%{
    Function to calculate EB extravasation around deifferent vessel segments
    according to previous vessel segmentation. return statistics for all
    sements in 10 different extravasation distances in rnage (0,n_px]
    Input arguements:
        rcind_seg_cell = cell array with every cell containing [row,col]
            coordinates of a vessel segment
        all_seg_rads = radii of segments. for dilation.
        bw_vessels = processed binary image of blood vessles and background
        redIm = image of EB channel
        n_px = how many pixels of extravasation
    Output arguements:
        eb_ext_in_segments = matrix of size n_segments x 10
            the i,j element contains the median pixel value of a (j/10)*n_px 
            neighborhood around the i-th segment in the EB image
%}
n_seg = length(rcind_seg_cell); % total nu,ber of segments
eb_ext_in_segments = zeros(n_seg,10); % Create a placeholder
perivasc_dist = round(n_px/10);



for i=1:n_seg  % loop through all segments
    lind_seg = sub2ind(size(bw_vessels), rcind_seg_cell{i}(:,1),rcind_seg_cell{i}(:,2));    % get all wire-frame elements of the segment (represent the middle-line)
    single_seg_bw = false(size(redIm));
    single_seg_bw(lind_seg) = 1;    % set only the segment wireframe to True
    dilated_n_wire = zeros(size(redIm,1),size(redIm,2),11);
    se_wire = strel('disk',ceil(all_seg_rads(i)+ perivasc_dist),8); % Create a specific structure element for wire dilation 
    dilated_n_wire(:,:,1) = blockdilate(single_seg_bw,se_wire);
    for j = 1:10
        se_wire = strel('disk',ceil(perivasc_dist),8); % Create a specific structure element for wire dilation 
        dilated_n_wire(:,:,j+1) = blockdilate(dilated_n_wire(:,:,j),se_wire);        
        single_vessel_mask = bw_vessels & dilated_n_wire(:,:,1); % Area within the vessel (inside the specific segment)
        single_vessel_perivasc_mask = ...
            (dilated_n_wire(:,:,j+1) - dilated_n_wire(:,:,j));
        single_vessel_perivasc_mask = ...
            logical((single_vessel_perivasc_mask | bw_vessels) - bw_vessels);
        eb_ext_in_segments(i,j) = ...
            double(median(redIm(single_vessel_perivasc_mask),'all'))/...
            double(median(redIm(single_vessel_mask),'all'));
      %% Visualization if needed for debugging and n_px optimzation
        extra_vessel_red = redIm.*uint16(~bw_vessels); % remove vessles from red channel
        k = cat(3,extra_vessel_red,2^14.*uint16(single_vessel_perivasc_mask),...
            2^14.*uint16(single_vessel_mask));
        imshow(k); 
        pause(0.1);
      %%
    end
end

end