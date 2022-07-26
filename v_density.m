function vessel_density = v_density(mat_path)
% Function to extract the vessel density as fraction of the frame area
% covered by vessels (0-1)
% Input:
%     mat_math = path to a .mat file containing the verified image
%                parameters, BW image and wireframe
st = load(mat_path);
vessel_image = st.derivedPic.BW_2;
vessel_density = mean(vessel_image,'all');
end