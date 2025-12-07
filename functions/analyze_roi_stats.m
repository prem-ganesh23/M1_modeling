function stats = analyze_roi_stats(m2m_path, field_file, mni_rois, roi_names, radius)
% ANALYZE_ROI_STATS Extracts volume-weighted E-field stats from MNI ROIs.
%
% Inputs:
%   m2m_path: Path to subject m2m folder (for mni2subject transform)
%   field_file: Path to the .msh simulation output
%   mni_rois: Cell array of [x,y,z] MNI coordinates
%   roi_names: Cell array of strings
%   radius: ROI radius in mm (e.g., 10)

    stats = [];
    
    % 1. Validation
    if ~exist(field_file, 'file')
        warning('Field file missing: %s', field_file);
        return;
    end

    % 2. Transform MNI ROIs to Subject Space
    % We use the 'nonl' (non-linear) transform as in your original script
    n_rois = length(mni_rois);
    sub_rois = cell(n_rois, 1);
    for i = 1:n_rois
        sub_rois{i} = mni2subject_coords(mni_rois{i}, m2m_path, 'nonl');
    end

    % 3. Load Mesh & Extract Gray Matter (Region 2)
    m = mesh_load_gmsh4(field_file);
    gm = mesh_extract_regions(m, 'region_idx', 2);
    
    centers = mesh_get_tetrahedron_centers(gm);
    vols = mesh_get_tetrahedron_sizes(gm);
    
    % Handle different field names (TMS vs TDCS default outputs)
    if isfield(gm.element_data{1}, 'data')
        % Sometimes data is here (SimNIBS v3/v4 variations)
        efield = gm.element_data{1}.data; 
    elseif isfield(gm.element_data{1}, 'tetdata')
        efield = gm.element_data{1}.tetdata;
    else
        % Fallback: look for 'magnE' specifically
        idx = get_field_idx(gm, 'magnE', 'elements');
        efield = gm.element_data{idx}.tetdata;
    end

    % 4. Loop ROIs
    for i = 1:n_rois
        % Euclidean distance
        dists = sqrt(sum(bsxfun(@minus, centers, sub_rois{i}).^2, 2));
        mask = dists < radius;
        
        if sum(mask) == 0
            res.mean = NaN;
            res.max = NaN;
        else
            % Volume-weighted mean
            res.mean = sum(efield(mask) .* vols(mask)) / sum(vols(mask));
            res.max = max(efield(mask));
        end
        res.roi_name = roi_names{i};
        stats = [stats; res];
    end
end