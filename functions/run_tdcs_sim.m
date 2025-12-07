function run_tdcs_sim(m2m_folder, mesh_filename, output_dir, anode_cfg, cathode_cfg, current_amp)
% RUN_TDCS_SIM Runs a tDCS simulation with user-defined montage.
%
% Inputs:
%   m2m_folder:    Path to the m2m directory (used to find EEG positions)
%   mesh_filename: Name of the .msh file (e.g., 'A17.msh')
%   output_dir:    Where to save results
%   anode_cfg:     Struct with fields (.label, .dims, .shape)
%   cathode_cfg:   Struct with fields (.label, .dims, .shape)
%   current_amp:   Current intensity in Amps (e.g., 2e-3 for 2mA)

    % 1. Get Coordinates
    % Uses m2m_folder to find the eeg_positions folder correctly
    anode_coords   = get_eeg_coords(m2m_folder, anode_cfg.label);
    cathode_coords = get_eeg_coords(m2m_folder, cathode_cfg.label);
    
    % 2. Setup SimNIBS Session
    S = sim_struct('SESSION');
    S.fnamehead = fullfile(m2m_folder, mesh_filename); % Dynamic mesh path
    S.pathfem   = output_dir;
    
    % --- CRITICAL FIX: Create directory in MATLAB first ---
    if ~exist(S.pathfem, 'dir')
        mkdir(S.pathfem);
    end
    % ----------------------------------------------------
    
    if ~exist(S.fnamehead, 'file')
        error('Mesh file missing: %s', S.fnamehead); 
    end

    S.poslist{1} = sim_struct('TDCSLIST');
    S.poslist{1}.currents = [current_amp, -current_amp]; % Anode (+), Cathode (-)

    % Configure Anode (Channel 1)
    S.poslist{1}.electrode(1).channelnr = 1;
    S.poslist{1}.electrode(1).centre    = anode_coords;
    S.poslist{1}.electrode(1).shape     = anode_cfg.shape;
    S.poslist{1}.electrode(1).dimensions = anode_cfg.dims;
    S.poslist{1}.electrode(1).thickness = 1;         
    S.poslist{1}.electrode(1).sponge_thickness = 4;  

    % Configure Cathode (Channel 2)
    S.poslist{1}.electrode(2).channelnr = 2;
    S.poslist{1}.electrode(2).centre    = cathode_coords;
    S.poslist{1}.electrode(2).shape     = cathode_cfg.shape;
    S.poslist{1}.electrode(2).dimensions = cathode_cfg.dims;
    S.poslist{1}.electrode(2).thickness = 1;
    S.poslist{1}.electrode(2).sponge_thickness = 4;

    run_simnibs(S);
end