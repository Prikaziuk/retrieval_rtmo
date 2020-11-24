function data_queue_present = check_compatibility()

    ver_out = ver;
    toolboxes = {ver_out.Name};
    
    if ~verLessThan('matlab', '9.8')  % >= R2020a
        warning('We guarantee preformance up until R2019b, your matlab version is higher. If it fails, please, report')
    end

    % required
    assert(any(strcmp('Optimization Toolbox', toolboxes)), ...
        'Please, install Optimization Toolbox to use this code')

    % optional: actually it slows everything down because internally used by lsqnonlin()
    data_queue_present = false;
    if any(strcmp('Parallel Computing Toolbox', toolboxes))
        if ~verLessThan('matlab', '9.2')  % >= R2017a
            fprintf(['You have Parallel Computing Toolbox and your Matlab is > 2017a\n' ...
                'If you want you can use parfor loop instead of for loop and write output data to file after each iteration\n'])
            data_queue_present = true;
        else
            fprintf(['You have Parallel Computing Toolbox,\n'...
                'If you want you can use parfor loop instead of for loop (slower but the results are not lost in case)\n'])
        end
        %% parallel computing
        % uncomment these lines
        % select N_proc you want (<= CPUs)
        % change for-loop to parfor-loop somewhere in main.m or main_sat.m
        % parfor will also work by itself, these lines just keep the number of processes under control

        % N_proc = 3;
        % if isempty(gcp('nocreate'))
        % %     prof = parallel.importProfile('local_Copy.settings');
        % %     parallel.defaultClusterProfile(prof);
        %     parpool(N_proc, 'IdleTimeout', Inf);
        % end
    else
        fprintf('You do not have Parallel Computing Toolbox but it is ok\n')
    end
end
