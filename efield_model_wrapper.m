%% SimNIBS Pipeline: Single Subject Wrapper
clear; clc;

%% --- 1. USER CONFIGURATION -----------------------------------------
% PATHS
simnibs_path = '/Applications/SimNIBS-4.5/matlab_tools'; % update this to point to your installation of SimNIBS
% Point DIRECTLY to the subject's folder (e.g., .../m2m_sub01)
m2m_folder   = '/path/to/m2m/folder'; 
output_dir   = '/path/to/desired/output/directory'; 

% EXPERIMENT SETTINGS
mode = 'TMS';  % Options: 'TMS' or 'TDCS'

% TMS PARAMETERS
tms.target   = 'C3';                     % EEG Electrode Target
tms.coil     = 'Magstim_70mm_Fig8.ccd';
tms.angle    = 45;                       % Angle vs midline (auto-flips L/R)
tms.didt     = 1.147e8;                  % Max dI/dt (A/s)
tms.pct      = 50;                       % Intensity (% MSO)

% tDCS PARAMETERS
tdcs.current = 2e-3;                     % Current (Amps)
tdcs.anode   = struct('label', 'C3',  'shape', 'rect', 'dims', [50, 50]);
tdcs.cathode = struct('label', 'Fp2', 'shape', 'rect', 'dims', [50, 50]);

% ROI ANALYSIS PARAMETERS
roi.mni      = [-38, -24, 56];           % MNI Coordinates [x, y, z]
roi.radius   = 10;                       % Radius in mm
% --------------------------------------------------------------------

%% 2. EXECUTION
addpath(simnibs_path); 
addpath('./functions'); 

% --- DYNAMIC MESH SEARCH ---
% Search for any .msh file inside the m2m folder
msh_search = dir(fullfile(m2m_folder, '*.msh'));

if isempty(msh_search)
    error('No .msh file found in %s', m2m_folder);
end

% Automatically use the first .msh file found
mesh_filename = msh_search(1).name;

% Extract Subject ID cleanly
[~, folder_name] = fileparts(m2m_folder);
subID = strrep(folder_name, 'm2m_', ''); 

fprintf('Processing Subject: %s | Mesh Found: %s\n', subID, mesh_filename);

try
    if strcmpi(mode, 'TMS')
        final_out = fullfile(output_dir, subID, 'TMS', tms.target);
        
        % Run TMS Engine 
        % CHANGED: Passing m2m_folder (for EEG lookup) AND mesh_filename (for S.fnamehead)
        run_tms_sim(simnibs_path,m2m_folder, mesh_filename, final_out, tms.coil, tms.target, ...
                    tms.angle, tms.didt, tms.pct);
        
    elseif strcmpi(mode, 'TDCS')
        final_out = fullfile(output_dir, subID, 'TDCS', [tdcs.anode.label '_' tdcs.cathode.label]);
        
        % Run tDCS Engine
        % CHANGED: Passing m2m_folder AND mesh_filename
        run_tdcs_sim(m2m_folder, mesh_filename, final_out, tdcs.anode, tdcs.cathode, tdcs.current);
    end
    
    fprintf('  Simulation saved to: %s\n', final_out);
    
catch ME
    error('  Simulation failed: %s', ME.message);
end

%% 3. ANALYSIS
% Find the resulting mesh file in the output directory
sim_files = dir(fullfile(final_out, '*.msh'));

if ~isempty(sim_files)
    field_file = fullfile(sim_files(1).folder, sim_files(1).name);
    
    % Run ROI Analysis
    stats = analyze_roi_stats(m2m_folder, field_file, {roi.mni}, {'Target'}, roi.radius);
    
    fprintf('\n--- RESULTS ---\n');
    fprintf('Mean E-field: %.4f V/m\n', stats(1).mean);
    fprintf('Max E-field:  %.4f V/m\n', stats(1).max);
else
    warning('  No simulation output found to analyze.');
end