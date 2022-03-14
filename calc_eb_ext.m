function eb_ext_in_segments = calc_eb_ext(rcind_seg_cell,all_seg_rads,bw_vessels, redIm, n_px)
%{
    Function to calculate EB extravasation around deifferent vessel segments
    according to previous vessel segmentation.
    Input arguements:
        rcind_seg_cell = cell array with every cell containing [row,col]
            coordinates of a vessel segment
        all_seg_rads = radii of segments. for dilation.
        bw_vessels = processed binary image of blood vessles and background
        redIm = image of EB channel
        n_px = how many pixels of extravasation (use according to diffusion
            theory)
    Output arguements:
        eb_ext_in_segments = vector the length of number of segments.
            Every element contains the average pixel value of a n_px 
            neighborhood around the i-th segment in the EB image
%}
eb_ext_in_segments = zeros(length(rcind_seg_cell),1); % Create a placeholder

for n=1:size(rcind_seg_cell,1)  % loop through all segments
    se_wire = strel('disk',ceil(all_seg_rads(n)),0); % Create a specific structure element for wire dilation 
    lind_seg = sub2ind(size(bw_vessels), rcind_seg_cell{n}(:,1),rcind_seg_cell{n}(:,2));    % get all wire-frame elements of the segment (represent the middle-line)
    single_seg_bw = false(size(redIm));
    single_seg_bw(lind_seg) = 1;    % set only the segment wireframe to True
    single_vessel_mask = blockdilate(single_seg_bw,se_wire); % Dilate the wire
    single_vessel_mask = single_vessel_mask & bw_vessels; % constrain to only what is inside the vessel
    se_peri = strel('disk',ceil(n_px),0); % Create a specific structure element for perivascular dilation 
    dilated_n_wire = blockdilate(single_vessel_mask,se_peri); % Dilate the single vessel
    single_vessel_perivasc_mask = logical((dilated_n_wire | bw_vessels)-bw_vessels);
    eb_ext_in_segments(n) = ...
        double(median(redIm(single_vessel_perivasc_mask),'all'));
    % Visualization if needed for debugging and n_px optimzation
%     extra_vessel_red = redIm.*uint8(~bw_vessels); % remove vessles from red channel
%     k = cat(3,extra_vessel_red,zeros(size(extra_vessel_red)),...
%         2^6.*uint8(single_vessel_perivasc_mask));
%     k = k + 2^8*uint8(repmat(single_seg_bw,1,1,3));
%     imshow(k); 
%     pause(0.5);
    %
end

end