classdef EBreaverApp < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        EBreaverUIFigure                matlab.ui.Figure
        StartDistLabel                  matlab.ui.control.Label
        startDistSpinner                matlab.ui.control.Spinner
        ExporttoExcelButton             matlab.ui.control.Button
        NormalizeredCheckBox            matlab.ui.control.CheckBox
        CreateanalysisobjectButton      matlab.ui.control.Button
        OpenREAVERGUIButton             matlab.ui.control.Button
        BrowseMBstButton                matlab.ui.control.Button
        BrowseNBstButton                matlab.ui.control.Button
        BrowseControlButton             matlab.ui.control.Button
        ProcessfoldersButton            matlab.ui.control.Button
        perivascularwidthpxSpinner      matlab.ui.control.Spinner
        perivascularwidthpxSpinnerLabel  matlab.ui.control.Label
        MBsdirectoryEditField          matlab.ui.control.EditField
        MBsdirectoryEditFieldLabel     matlab.ui.control.Label
        NBsdirectoryEditField          matlab.ui.control.EditField
        NBsdirectoryEditFieldLabel     matlab.ui.control.Label
        ControldirectoryEditField       matlab.ui.control.EditField
        ControldirectoryEditFieldLabel  matlab.ui.control.Label
    end

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app)
            try
                evalin("base",'depndenciesImported')
            catch 
                DEV_INITIALIZE;
                assignin("base",'depndenciesImported',true)
            end
            
        end

        % Button pushed function: ProcessfoldersButton
        function ProcessfoldersButtonPushed(app, event)
            control_dir = app.ControldirectoryEditField.Value;
            MBs_dir = app.MBsdirectoryEditField.Value;
            NBs_dir = app.NBsdirectoryEditField.Value;
            n_px = app.perivascularwidthpxSpinner.Value;
            diffu = app.startDistSpinner.Value;
            normalize_red = app.NormalizeredCheckBox.Value;
            if ~isempty(control_dir)
                disp('Starting to work on control files')
                analyze_entire_folder(n_px,control_dir,normalize_red,diffu);
                disp('Finished processing control files')
            end
            if ~isempty(MBs_dir)
                disp('Starting to work on MBs files')
                analyze_entire_folder(n_px,MBs_dir,normalize_red,diffu); 
                disp('Finished processing MBs files')
            end
            if ~isempty(NBs_dir)
                disp('Starting to work on NBs files')
                analyze_entire_folder(n_px,NBs_dir,normalize_red,diffu); 
                disp('Finished processing NBs files')
            end
        end

        % Button pushed function: BrowseControlButton
        function BrowseControlButtonPushed(app, event)
            control_dir = uigetdir(pwd,'Choose control directory');
            app.ControldirectoryEditField.Value = control_dir;
            figure(app.EBreaverUIFigure)
        end

        % Button pushed function: BrowseMBstButton
        function BrowseMBstButtonPushed(app, event)
            MBs_dir = uigetdir(pwd,'Choose MBs directory');
            app.MBsdirectoryEditField.Value = MBs_dir;
            figure(app.EBreaverUIFigure)
        end
        
        % Button pushed function: BrowseNBsButton
        function BrowseNBsButtonPushed(app, event)
            NBs_dir = uigetdir(pwd,'Choose NBs directory');
            app.NBsdirectoryEditField.Value = NBs_dir;
            figure(app.EBreaverUIFigure)
        end

        % Button pushed function: OpenREAVERGUIButton
        function OpenREAVERGUIButtonPushed(app, event)
            REAVER_GUI;
        end

        % Button pushed function: CreateanalysisobjectButton
        function CreateanalysisobjectButtonPushed(app, event)
            results = EB_analysis;
            assignin("base","results",results);
        end

        % Button pushed function: ExporttoExcelButton
        function ExporttoExcelButtonPushed(app, event)
            [control_filename,control_path] = ...
                uiputfile({'.csv','.xlsx'},...
                'Save control file','Control.csv');
            [MB_filename,MB_path] = ...
                uiputfile({'.csv','.xlsx'},...
                'Save MBs file','MB.csv');
            [NB_filename,NB_path] = ...
                uiputfile({'.csv','.xlsx'},...
                'Save NBs file','NB.csv');
            results = evalin('base','results');
            ths = 2:10;
            results.writecsv(ths,fullfile(control_path,control_filename),...
                fullfile(MB_path, MB_filename),fullfile(NB_path, NB_filename));
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create EBreaverUIFigure and hide until all components are created
            app.EBreaverUIFigure = uifigure('Visible', 'off');
            app.EBreaverUIFigure.Color = [0.9412 0.9412 0.9412];
            app.EBreaverUIFigure.Position = [100 100 535 368];
            app.EBreaverUIFigure.Name = 'EB reaver';

            % Create ControldirectoryEditFieldLabel
            app.ControldirectoryEditFieldLabel = uilabel(app.EBreaverUIFigure);
            app.ControldirectoryEditFieldLabel.HorizontalAlignment = 'right';
            app.ControldirectoryEditFieldLabel.Position = [70 270 94 22];
            app.ControldirectoryEditFieldLabel.Text = 'Control directory';

            % Create ControldirectoryEditField
            app.ControldirectoryEditField = uieditfield(app.EBreaverUIFigure, 'text');
            app.ControldirectoryEditField.Position = [179 269 204 23];

            % Create MBsdirectoryEditFieldLabel
            app.MBsdirectoryEditFieldLabel = uilabel(app.EBreaverUIFigure);
            app.MBsdirectoryEditFieldLabel.HorizontalAlignment = 'right';
            app.MBsdirectoryEditFieldLabel.Position = [70 231 77 22];
            app.MBsdirectoryEditFieldLabel.Text = 'MBs directory';

            % Create MBsdirectoryEditField
            app.MBsdirectoryEditField = uieditfield(app.EBreaverUIFigure, 'text');
            app.MBsdirectoryEditField.Position = [179 230 204 23];

            % Create NBsdirectoryEditFieldLabel
            app.NBsdirectoryEditFieldLabel = uilabel(app.EBreaverUIFigure);
            app.NBsdirectoryEditFieldLabel.HorizontalAlignment = 'right';
            app.NBsdirectoryEditFieldLabel.Position = [70 192 77 22];
            app.NBsdirectoryEditFieldLabel.Text = 'NBs directory';

            % Create NBsdirectoryEditField
            app.NBsdirectoryEditField = uieditfield(app.EBreaverUIFigure, 'text');
            app.NBsdirectoryEditField.Position = [179 191 204 23];

            % Create perivascularwidthpxSpinnerLabel
            app.perivascularwidthpxSpinnerLabel = uilabel(app.EBreaverUIFigure);
            app.perivascularwidthpxSpinnerLabel.HorizontalAlignment = 'right';
            app.perivascularwidthpxSpinnerLabel.Position = [70 160 124 22];
            app.perivascularwidthpxSpinnerLabel.Text = 'perivascular width [px]';

            % Create perivascularwidthpxSpinner
            app.perivascularwidthpxSpinner = uispinner(app.EBreaverUIFigure);
            app.perivascularwidthpxSpinner.Position = [209 155 56 31];

            % Create ProcessfoldersButton
            app.ProcessfoldersButton = uibutton(app.EBreaverUIFigure, 'push');
            app.ProcessfoldersButton.ButtonPushedFcn = createCallbackFcn(app, @ProcessfoldersButtonPushed, true);
            app.ProcessfoldersButton.Position = [283 137 122 30];
            app.ProcessfoldersButton.Text = 'Process folders';

            % Create BrowseControlButton
            app.BrowseControlButton = uibutton(app.EBreaverUIFigure, 'push');
            app.BrowseControlButton.ButtonPushedFcn = createCallbackFcn(app, @BrowseControlButtonPushed, true);
            app.BrowseControlButton.Position = [404 270 72 22];
            app.BrowseControlButton.Text = 'Browse';

            % Create BrowseMBsButton
            app.BrowseMBstButton = uibutton(app.EBreaverUIFigure, 'push');
            app.BrowseMBstButton.ButtonPushedFcn = createCallbackFcn(app, @BrowseMBstButtonPushed, true);
            app.BrowseMBstButton.Position = [404 231 72 22];
            app.BrowseMBstButton.Text = 'Browse';

            % Create BrowseNBsButton
            app.BrowseNBstButton = uibutton(app.EBreaverUIFigure, 'push');
            app.BrowseNBstButton.ButtonPushedFcn = createCallbackFcn(app, @BrowseNBsButtonPushed, true);
            app.BrowseNBstButton.Position = [404 192 72 22];
            app.BrowseNBstButton.Text = 'Browse';

            % Create OpenREAVERGUIButton
            app.OpenREAVERGUIButton = uibutton(app.EBreaverUIFigure, 'push');
            app.OpenREAVERGUIButton.ButtonPushedFcn = createCallbackFcn(app, @OpenREAVERGUIButtonPushed, true);
            app.OpenREAVERGUIButton.Position = [173 306 215 34];
            app.OpenREAVERGUIButton.Text = 'Open REAVER GUI for segmentation';

            % Create CreateanalysisobjectButton
            app.CreateanalysisobjectButton = uibutton(app.EBreaverUIFigure, 'push');
            app.CreateanalysisobjectButton.ButtonPushedFcn = createCallbackFcn(app, @CreateanalysisobjectButtonPushed, true);
            app.CreateanalysisobjectButton.Position = [181 60 208 25];
            app.CreateanalysisobjectButton.Text = 'Create analysis object';

            % Create NormalizeredCheckBox
            app.NormalizeredCheckBox = uicheckbox(app.EBreaverUIFigure);
            app.NormalizeredCheckBox.Text = 'Normalize red';
            app.NormalizeredCheckBox.Position = [421 139 97 25];

            % Create ExporttoExcelButton
            app.ExporttoExcelButton = uibutton(app.EBreaverUIFigure, 'push');
            app.ExporttoExcelButton.ButtonPushedFcn = createCallbackFcn(app, @ExporttoExcelButtonPushed, true);
            app.ExporttoExcelButton.Position = [221 21 121 27];
            app.ExporttoExcelButton.Text = 'Export to Excel';

            % Create startDistSpinner
            app.startDistSpinner = uispinner(app.EBreaverUIFigure);
            app.startDistSpinner.Position = [209 117 57 31];

            % Create StartDistLabel
            app.StartDistLabel = uilabel(app.EBreaverUIFigure);
            app.StartDistLabel.HorizontalAlignment = 'right';
            app.StartDistLabel.Position = [31 121 164 22];
            app.StartDistLabel.Text = 'Distance from vessel wall [px]';

            % Show the figure after all components are created
            app.EBreaverUIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = EBreaverApp

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.EBreaverUIFigure)

            % Execute the startup function
            runStartupFcn(app, @startupFcn)

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.EBreaverUIFigure)
        end
    end
end