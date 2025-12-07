function coords = get_eeg_coords(m2m_path, electrode_label)
% GET_EEG_COORDS Extracts [x,y,z] for a specific electrode from SimNIBS output.

    % Standard SimNIBS path for the EEG file
    csv_path = fullfile(m2m_path, 'eeg_positions', 'EEG10-20_extended_SPM12.csv');
    
    if ~isfile(csv_path)
        error('EEG file not found: %s', csv_path);
    end
    
    % Read without headers (Cols: 1=Index, 2=X, 3=Y, 4=Z, 5=Label)
    T = readtable(csv_path, 'ReadVariableNames', false);
    
    % Find the row with the matching label
    idx = find(strcmpi(T.Var5, electrode_label));
    
    if isempty(idx)
        error('Electrode %s not found in subject file.', electrode_label);
    end
    
    coords = [T.Var2(idx), T.Var3(idx), T.Var4(idx)];
end
