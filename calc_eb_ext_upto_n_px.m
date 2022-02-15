function eb_ext_in_segments = calc_eb_ext_upto_n_px(rcind_seg_cell,all_seg_rads,bw_vessels, redIm, n_px)
%{
    Function to calculate EB extravasation around deifferent vessel segments
    according to previous vessel segmentation. return statistics for all
    sements in 10 different extravasation distances from 1 to n pixels
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
eb_ext_in_segments = zeros(length(rcind_seg_cell),10); % Create a placeholder


for i=1:size(rcind_seg_cell,1)  % loop through all segments
    se_wire = strel('disk',ceil(all_seg_rads(i)+ n_px),0); % Create a specific structure element for wire dilation 
    lind_seg = sub2ind(size(bw_vessels), rcind_seg_cell{i}(:,1),rcind_seg_cell{i}(:,2));    % get all wire-frame elements of the segment (represent the middle-line)
    single_seg_bw = false(size(redIm));
    single_seg_bw(lind_seg) = 1;    % set only the segment wireframe to True
    dilated_n_wire = imdilate(single_seg_bw,se_wire); % Dilate the wire
    for j = 1:10
        se_vessel = strel('disk',ceil((j/10)*(n_px/2)),0); % Create a universal structure element for vessel dilation
        vessel_dilated = imdilate(bw_vessels,se_vessel); % dilate the vessel surrounding by n_px
        perivasc = vessel_dilated - bw_vessels;
        single_vessel_perivasc_mask = dilated_n_wire & perivasc;
        single_vessel_mask = bw_vessels & dilated_n_wire; % Area within the vessel (inside the specific segment)
        eb_ext_in_segments(i,j) = ...
            double(median(redIm(single_vessel_perivasc_mask),'all'))/...
            double(median(redIm(single_vessel_mask),'all'));
%       %% Visualization if needed for debugging and n_px optimzation
%       extra_vessel_red = redIm.*uint16(~bw_vessels); % remove vessles from red channel
%       k = cat(3,extra_vessel_red,2^14.*uint16(single_vessel_perivasc_mask),...
%           2^14.*uint16(vessel_dilated-bw_vessels));
%       k = k + 2^16*uint16(repmat(single_seg_bw,1,1,3));
%       imshow(k); 
%       pause(0.1);
%       %%
    end
end

end