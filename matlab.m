function image_enhancement_final()
    clc; close all;
    
    % 1. Cleanup old connections
    if ~isempty(serialportlist), delete(serialportlist); end
    
    % 2. Load the Image
    [file, path] = uigetfile({'*.jpg;*.png;*.bmp'}, 'Open Image');
    if isequal(file,0), return; end
    full_img = im2double(imread(fullfile(path, file)));
    
    % Resize for real-time preview
    preview_img = imresize(full_img, [250, nan]); 
    [M, N, C] = size(preview_img);
    [u, v] = meshgrid(1:N, 1:M);
    D_grid = sqrt((u - N/2).^2 + (v - M/2).^2);
    
    % 3. Setup Serial
    ports = serialportlist();
    if isempty(ports), error('No ESP32 found!'); end
    s = serialport(ports(end), 115200); 
    configureTerminator(s, "LF");
    flush(s);
    
    % 4. UI Setup
    fig = uifigure('Name', 'ESP32 DSP Console', 'Position', [100 100 750 650]);
    ax = uiaxes(fig, 'Position', [75 120 600 480]);
    hImg = imshow(preview_img, 'Parent', ax); 
    hTitle = title(ax, 'SYSTEM READY');
    
    % Parameters
    eff.sharp = 25; eff.bright = 0; eff.cont = 1; eff.sat = 1; 
    eff.red = 0; eff.blue = 0; eff.vig = 0; eff.shd = 1.0;
    
    lastLayer = 1;
    isLocked = [true true true true]; 
    snapPots = [0 0 0 0];
    lastSaveState = 1; 
    
    while ishandle(fig)
        if s.NumBytesAvailable > 0
            data = readline(s);
            vals = str2double(split(data, ","));
            
            if numel(vals) >= 7 && ~any(isnan(vals))
                saveBtn  = vals(5); 
                layerVal = vals(6); 
                resetBtn = vals(7); 
                
                % Layer Swap Logic
                if layerVal ~= lastLayer
                    isLocked = [true true true true];
                    snapPots = vals(1:4); 
                    lastLayer = layerVal;
                end
                
                % Unlock Logic
                for i = 1:4
                    if isLocked(i) && abs(vals(i) - snapPots(i)) > 70
                        isLocked(i) = false;
                    end
                end
                
                % Reset Action
                if resetBtn == 0
                    eff.bright = 0; eff.cont = 1; eff.sat = 1; 
                    eff.red = 0; eff.blue = 0; eff.vig = 0; eff.shd = 1.0;
                    title(ax, '!!! PARAMETERS RESET !!!');
                    flush(s); % Clear buffer after Mario sound pause
                end
                
                % Mapping
                p = vals(1:4); 
                if layerVal == 1
                    if ~isLocked(1), eff.sharp  = (p(1)/1023)*50 + 5; end
                    if ~isLocked(2), eff.bright = (p(2)/1023) - 0.5; end
                    if ~isLocked(3), eff.cont   = (p(3)/1023)*2; end
                    if ~isLocked(4), eff.sat    = (p(4)/1023)*2; end
                    set(hTitle, 'String', 'BASIC MODE', 'Color', 'b');
                else
                    if ~isLocked(1), eff.shd  = (p(1)/1023)*1.5 + 0.5; end
                    if ~isLocked(2), eff.vig  = (p(2)/1023); end
                    if ~isLocked(3), eff.blue = (p(3)/1023) - 0.5; end
                    if ~isLocked(4), eff.red  = (p(4)/1023) - 0.5; end
                    set(hTitle, 'String', 'CREATIVE MODE', 'Color', [0.5 0 0.5]);           
                end
                
                out = apply_fx_pro(preview_img, eff, D_grid);
                set(hImg, 'CData', out);
                
                if lastSaveState == 1 && saveBtn == 0
                    title(ax, 'SAVING...'); drawnow;
                    [f, p_path] = uiputfile('*.png', 'Save Image', 'Result.png');
                    if ~isequal(f,0)
                        final = apply_fx_pro(full_img, eff, []);
                        imwrite(final, fullfile(p_path, f));
                    end
                    flush(s);
                end
                lastSaveState = saveBtn;
            end
        end
        drawnow limitrate;
    end
end

function out = apply_fx_pro(img, e, D_in)
    [M, N, C] = size(img);
    if isempty(D_in)
        [u,v] = meshgrid(1:N,1:M); D = sqrt((u-N/2).^2+(v-M/2).^2);
    else, D = D_in; end
    H = 1 - exp(-(D.^2) / (2 * e.sharp^2));
    out = zeros(size(img));
    for ch = 1:C
        F = fftshift(fft2(img(:,:,ch)));
        out(:,:,ch) = img(:,:,ch) + 1.2 * real(ifft2(ifftshift(F .* H)));
    end
    out = e.cont * (out - 0.5) + 0.5 + e.bright;
    out(:,:,1) = out(:,:,1) + e.red;
    out(:,:,3) = out(:,:,3) + e.blue;
    out = max(0, min(1, out)).^e.shd;
    if C == 3
        hsv = rgb2hsv(out); hsv(:,:,2) = hsv(:,:,2) * e.sat; out = hsv2rgb(hsv);
    end
    v_rad = max(M,N) * (1.1 - e.vig*0.6);
    V = exp(-(D.^2) / (2 * v_rad^2));
    out = max(0, min(1, out .* V));
end
