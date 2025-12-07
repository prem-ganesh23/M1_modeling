function run_tms_sim(simnibs_path, m2m_folder, mesh_filename, output_dir, coil_name, target_label, angle_from_midline, max_didt, pct_intensity)
% RUN_TMS_SIM Runs a TMS simulation with midline-relative orientation.
%
% Inputs:
%   simnibs_path:       Path to 'matlab_tools' (from your wrapper)
%   m2m_folder:         Path to the m2m directory
%   mesh_filename:      Name of the .msh file
%   output_dir:         Where to save results
%   coil_name:          Name of coil file (e.g., 'Magstim_70mm_Fig8.ccd')
%   target_label:       String (e.g., 'C3')
%   angle_from_midline: Degrees (e.g., 45)
%   max_didt:           Maximum dI/dt
%   pct_intensity:      Stimulator output percentage

    % --- 1. DYNAMIC COIL SEARCH ---
    % Step up one level from 'matlab_tools' to the SimNIBS root
    simnibs_root = fileparts(simnibs_path); 
    
    % Recursively search (**) for the coil file inside the root
    % This finds it even if buried in simnibs_env/lib/python3.11/...
    coil_search = dir(fullfile(simnibs_root, '**', coil_name));
    
    if isempty(coil_search)
        error('Coil file "%s" not found recursively in %s', coil_name, simnibs_root);
    end
    
    % Construct the full path using the first match
    coil_full_path = fullfile(coil_search(1).folder, coil_search(1).name);
    fprintf('  Coil found: %s\n', coil_full_path);

    % --- 2. COORDINATES & ORIENTATION ---
    center_coords = get_eeg_coords(m2m_folder, target_label);
    
    ref_vec = [0, 10, 0]; 
    if center_coords(1) < 0
        theta = deg2rad(-angle_from_midline);
        fprintf('  Target %s (Left): Rotating %.1f deg (CW).\n', target_label, angle_from_midline);
    else
        theta = deg2rad(angle_from_midline);
        fprintf('  Target %s (Right): Rotating %.1f deg (CCW).\n', target_label, angle_from_midline);
    end
    
    Rz = [cos(theta), -sin(theta), 0; sin(theta), cos(theta), 0; 0, 0, 1];
    ref_rot = (Rz * ref_vec(:))';
    pos_ydir_vec = center_coords + ref_rot;

    % --- 3. SETUP SIMNIBS ---
    S = sim_struct('SESSION');
    S.fnamehead = fullfile(m2m_folder, mesh_filename);
    S.pathfem   = output_dir;
    
    % Ensure output directory exists
    if ~exist(S.pathfem, 'dir')
        mkdir(S.pathfem); 
    end
    
    if ~exist(S.fnamehead, 'file')
        error('Mesh file missing: %s', S.fnamehead); 
    end
    
    % Configure TMS
    S.poslist{1} = sim_struct('TMSLIST');
    S.poslist{1}.fnamecoil = coil_full_path; % Use the dynamic path we found
    S.poslist{1}.pos(1).centre   = center_coords;
    S.poslist{1}.pos(1).pos_ydir = pos_ydir_vec;
    S.poslist{1}.pos(1).didt     = max_didt * (pct_intensity / 100);
    
    run_simnibs(S);
end