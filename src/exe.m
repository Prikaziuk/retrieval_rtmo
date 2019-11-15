try
%     helpers.generate_synthetic()
    lut.lut_workflow()
%     main
%     main_sat
    fprintf('\nSUCCESS: The run is finished\n')
catch ME
    fprintf('ERROR: %s\n', ME.message)
end

fprintf('\nPress any key to close the window')
pause