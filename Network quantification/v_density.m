function vessel_density = v_density(mat_path)
% Function to extract the capillary density as described by: Kolinko et. al
% (2015)
% Input:
%     mat_math = path to a .mat file containing the verified image
%                parameters, BW image and wireframe
st = load(mat_path);
valance = zeros(length(st.derivedPic.branchpoints),1);
for i = 1: length(st.derivedPic.branchpoints)
    bp_coords = st.derivedPic.branchpoints(i,:);
    valance(i) = sum(st.derivedPic.wire(bp_coords(2)-1:bp_coords(2)+1,...
        bp_coords(1)-1:bp_coords(1)+1),'all')-1;
end
[P_n,edges] = histcounts(valance);
N = (edges(1:end-1)+edges(2:end))/2;
N_mv = sum(((N-2)./2).*P_n);
image_volume = st.imageSize(1)*st.imageSize(2)*20;
vessel_density = (N_mv/image_volume)/(st.image_resolution^2);
vessel_density = vessel_density*10^9; % To go from um^-3 to mm^-3
end