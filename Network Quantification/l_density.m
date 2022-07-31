function vessel_density = l_density(mat_path)
% Function to extract the vessel length density [1/mm^2]
% Input:
%     mat_math = path to a .mat file containing the verified image
%                parameters, BW image and wireframe
st = load(mat_path);
image_volume = st.imageSize(1)*st.imageSize(2)*20;
vessel_density = (st.metrics.vesselLength/image_volume)/st.image_resolution;
vessel_density = vessel_density*10^6; % To go from um^-2 to mm^-2
end