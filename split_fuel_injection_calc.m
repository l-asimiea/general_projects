
%{
Title:          split_fuel_injection_calc

Description:    This script calcualtes split fuel injection loads from a
                provided single injection load profiles.
                It should be noted that this script is embedded within a
                modeFRONTIER workflow in which it takes inputs and ouputs.
                
Inputs:         
                Fuel injection load for single pulse (high and load)
                Injection timings for start of injection and control ratio

Outputs:
                Start and end fuel injection timings, and dwells for split
                fuel injections.


Author: Laurel Asimiea
Last Modified: 02/06/2021
%} 


%=============================================== SECTION 1 =================================================%

format short g

% load low or high fuel load using a simple changer  
inj_params = struct;
swt_fuel_load = 0;                                                  
if swt_fuel_load == 0
    inj_params.fuel_data = load('inj10mm3.dat');
else
    inj_params.fuel_data = load('inj20mm3.dat');
end

% Capture injection parameters from the single fuel injection load data                                   
inj_params.timeline = inj_params.fuel_data(:,1);               
inj_params.fuelflowrate = inj_params.fuel_data(:,2);               
inj_params.total_fuel_quantity = trapz(inj_params.timeline,inj_params.fuelflowrate);                
inj_params.fuelflowrate_maxidx = find(inj_params.fuelflowrate == max(inj_params.fuelflowrate));     


%=============================================== SECTION 2 =================================================%
% The injection pulses are calcualted in this section. The section is
% divided into 2 parts; Rise and Fall which model the opening and closing
% dynamics of the fuel injector noozle tip

% ====================
% 1st Injection
% ====================
p1_quantity = 0.95 * inj_params.total_fuel_quantity;                                          % 0.95 is p1_vfp provided from modefrontier

% PART 1: Creation of the pusle (p1) fuel injection profile Rise (r) slope. 
p1_duration_fuelflow_r= inj_params.timeline(1:inj_params.fuelflowrate_maxidx);     
p1_fuel_fuelflow_r = inj_params.fuelflowrate(1:inj_params.fuelflowrate_maxidx);    
p1_fuel_quantity_fuelflow_r = p1_duration_fuelflow_r.*p1_fuel_fuelflow_r;                      % fuel quantity is time and flowrate product
p1_inj_start_time = p1_duration_fuelflow_r(1);                                                 % start time of old injection profile 
[~,p1_closest_idx_r] = min(abs((p1_fuel_fuelflow_r.*(p1_duration_fuelflow_r- p1_inj_start_time)) - p1_quantity));                                                                             
p1_timeline_r = inj_params.timeline(1:p1_closestidx_r);                                                  % time values from 0 to closest quantity time
p1_fuelprofile_r = inj_params.fuelflowrate(1:p1_closestidx_r);                                           % fuel values from 0 to closest quantity fuel
p1_fuelprofile_lastval_r = p1_fuelprofile_r(end);                                                        % last fuel value          

% PART 2: Creation of the p1 profile Fall (f) slope i.e., from peak fuelflow to end fuelflow
p1_duration_fuelflow_f = inj_params.timeline(inj_params.fuelflowrate_maxidx:end);        
p1_fuel_fuelflow_f = inj_params.fuelflowrate(1:inj_params.fuelflowrate_maxidx:end);  
p1_fuel_quantity_fuelflow_f = p1_duration_fuelflow_f.*p1_fuel_fuelflow_f;  
[~,p1_closest_idx_f] = min(abs(p1_fuel_fuelflow_f - p1_fuelprofile_lastval_r));                                                                             
p1_timeline_f = p1_duration_fuelflow_f(p1_closest_idx_f+1:end);                                         % time values from max fuel flowrate to end
p1_fuelprofile_f = p1_fuel_fuelflow_f(p1_closest_idx_f+1:end);                                          % fuel values from max fuel flowrate to end
p1_fuelprofile_lastval_f = p1_fuelprofile_f(end);                                                       % last fuel value 

% Build teh complete timeline and fuel flowrate for pulse 1 (p1)
new_inj_params.p1_timeline = inj_params.timeline(1:length(p1_timeline_f)+length(p1_timeline_r));
new_inj_params.p1_fuelprofile = [p1_fuelprofile_r;p1_fuelprofile_f];

% ====================
% 2nd Injection
% ====================
p2_quantity = inj_params.total_fuel_quantity - p1_quantity;                                             % desired fuel quantity for 2nd injection

% PART 1: Creation of the pusle (p2) fuel injection profile Rise (r) slope. 
p2_duration_fuelflow_r= inj_params.timeline(1:inj_params.fuelflowrate_maxidx);     
p2_fuel_fuelflow_r = inj_params.fuelflowrate(1:inj_params.fuelflowrate_maxidx);    
p2_fuel_quantity_fuelflow_r = p2_duration_fuelflow_r.*p2_fuel_fuelflow_r; 
p2_inj_start_time = p2_duration_fuelflow_r(1);
[~,p2_closest_idx_r] = min(abs((p2_fuel_fuelflow_r.*(p2_duration_fuelflow_r- p2_inj_start_time)) - p2_quantity));  
p2_timeline_r = inj_params.timeline(1:p2_closestidx_r);
p2_fuelprofile_r = inj_params.fuelflowrate(1:p2_closestidx_r); 
p2_fuelprofile_lastval_r = p2_fuelprofile_r(end); 

% PART 2: Creation of the p1 profile Fall (f) slope i.e., from peak fuelflow to end fuelflow
p2_duration_fuelflow_f = inj_params.timeline(inj_params.fuelflowrate_maxidx:end);        
p2_fuel_fuelflow_f = inj_params.fuelflowrate(1:inj_params.fuelflowrate_maxidx:end);  
p2_fuel_quantity_fuelflow_f = p2_duration_fuelflow_f.*p2_fuel_fuelflow_f;  
[~,p2_closest_idx_f] = min(abs(p2_fuel_fuelflow_f - p2_fuelprofile_lastval_r));                                                                             
p2_timeline_f = p2_duration_fuelflow_f(p2_closest_idx_f+1:end);                                         % time values from max fuel flowrate to end
p2_fuelprofile_f = p2_fuel_fuelflow_f(p2_closest_idx_f+1:end);                                          % fuel values from max fuel flowrate to end
p2_fuelprofile_lastval_f = p2_fuelprofile_f(end);

% Build the complete timeline and fuel flowrate for pulse 2 (p2)
new_inj_params.p2_timeline = inj_params.timeline(1:length(p2_timeline_f)+length(p2_timeline_r));
new_inj_params.p2_fuelprofile = [p2_fuelprofile_r;p2_fuelprofile_f];

%=============================================== SECTION 3 =================================================%
% ===============
% Outputs
% ===============
% Outputs to FIRE .ssf file via modeFRONTIER. Fire requires the following injection paramters:
rpm = 1500;     % engine speed

% For p1:
p1_q = p1_quantity/6;                                                      % desired quantity per nozzle hole
%SoI_p1 = ??;
first_time_p1 = new_inj_params.p1_timeline(1);                              % first time value of 1st injection in ms
last_time_p1 = new_inj_params.p1_timeline(end);                             % last time value of 1st injection in ms
p1_duration_ms = last_time_p1 - first_time_p1;                             
p1_duration_CA = (p1_duration_ms/1000) * 6 * rpm;                                                         
%p1_last_time_CA = (last_time_p1/1000) * 6 * rpm;                           
p1_time_values = (new_inj_params.p1_timeline/1000) * 6 * rpm;               % 1st injection time values in CA
p1_fuel_values = p1_fuelprofile;                                            % 1st injection fuel values
p1_length = length(p1_time_values);

% For p2:
p2_q = p2_quantity/6;                                                       
%SoI_p2 = ??;
p2_time_duration_ms = ((10/(6*1500))*1000) + new_inj_params.p2_timeline;    % 10CA is dwell from modeFRONTIER converted to ms
first_time_p2 = p2_time_duration_ms(1);
last_time_p2 = p2_time_duration_ms(end);                                   % last time value of 2nd injection in ms
p2_duration_ms = last_time_p2 - first_time_p2;
p2_duration_CA = (p2_duration_ms/1000) * 6 * rpm;
%last_time_p2_CA = (last_time_p2/1000) * 6 * rpm;                          % last time value of 2nd injection in CA                                              %2nd injection time law in CA
p2_time_values = (p2_time_duration_ms/1000) * 6 *rpm;                      % 2nd injection time values in CA
p2_fuel_values = p2_fuelprofile;                                           % 2nd injection fuel vlaues
p2_length = length(p2_time_values);

% ===============
% Plots
% ===============
% p1 and single fuel injection 
figure(1)
plot(new_inj_params.p1_timeline,new_inj_params.p1_fuelprofile, 'r')                                   % plot of p1 profile
hold on
plot(inj_params.timeline,inj_params.fuelflowrate, 'b')

% p2 and single fuel injection
figure (2)
plot(new_inj_params.p2_timeline,new_inj_params.p2_fuelprofile, 'g')                                   % plot of p2 profile
hold on
plot(inj_params.timeline,inj_params.fuelflowrate, 'b')                                                % plot of old profile

figure (3)
plot(new_fuel_inj_params.p1_timeline,new_inj_params.p1_fuelprofile, 'r')
hold on
plot(new_fuel_inj_params.p2_timeline,new_inj_params.p2_fuelprofile, 'g')
hold on
plot(inj_params.timeline, inj_params.fuelflowrate, 'b')



%SoI_p1, EoI_p1 & SoI_p2, EoI_p2 are obtained from the calculator in
%modeFRONTIER. 




        
       
                    