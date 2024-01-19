function [LIQWATER,SSNOW] = SNOW_MODULE(DD,TT,P,T,SSNOW)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% MATLAB code developed by Mojtaba Sadegh (mojtabasadegh@gmail.com) and Amir AghaKouchak, 
% Center for Hydrometeorology and Remote Sensing (CHRS)
% University of California, Irvine
%
% Last modified on January 5, 2017
%
% Please contact Dr. Amir AghaKouchak (amir.a@uci.edu) for permission to alter the package.
%
% Please contact Mojtaba Sadegh (mojtabasadegh@gmail.com) with any issue.
%
%
%Sadegh M, AghaKouchak A, Flores A, Mallakpour I, Nikoo MR, 2019, A Multi-Model Nonstationary Rainfall-Runoff Modeling Framework: Analysis and Toolbox, Water Resources Management, doi: 10.1007/s11269-019-02283-y
%
% Disclaimer:
% This program (hereafter, software) is designed for instructional, educational and research use only.
% Commercial use is prohibited. The software is provided 'as is' without warranty 
% of any kind, either express or implied. The software could include technical or other mistakes,
% inaccuracies or typographical errors. The use of the software is done at your own discretion and 
% risk and with agreement that you will be solely responsible for any damage and that the authors
% and their affiliate institutions accept no responsibility for errors or omissions in the software
% or documentation. In no event shall the authors or their affiliate institutions be liable to you or
% any third parties for any special, indirect or consequential damages of any kind, or any damages whatsoever. 
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% INPUTS:
% DD: DEGREE DAY FACTOR (MM/TEMP/DAY), INDICATITING DECREASE OF WATER CONTENT IN SNOW COVER CAUSED BY 1 DEGREE ABOVE FREEZING THRESHHOLD IN ONE DAY
% TT: FREEZING THRESHHOLD, CONVENIENTLY SET TO 0 DEGREE CENTIGRADE
% DATA: FIRST COLUMN IS PET (MM/DAY), SECOND COLUMN IS PRECIPITATION (MM/DAY), THIRD COLUMN IS TEMPERATURE (MM/DAY)
% SSNOW: SNOW COVERAGE STORAGE AT THE BEGINIG OF TIME STEP t
% 
% OUTPUTS:
% LIQWATER: LIQUID WATER AT TIME STEP t THAT WILL BE ROUTED THROUGH SOIL MEDIUM
% SSNOW: SNOW STORAGE AT THE END OF TIME STEP t
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% FOR DESCRIPTION OF THE MODEL, REFER TO 
% REF1: AghaKouchak A., Habib E., 2010, Application of a Conceptual Hydrologic Model in Teaching Hydrologic Processes, International Journal of Engineering Education, 26(4), 963-973. 
% REF2: AghaKouchak A., Nakhjiri N., and Habib E., 2012, An educational model for ensemble streamflow simulation and uncertainty analysis, Hydrology and Earth System Sciences Discussions, 9, 7297-7315, doi:10.5194/hessd-9-7297-2012.
% MATLAB CODE IS ALSO AVAILABLE AT:
% http://amir.eng.uci.edu/software.php
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% MATLAB code developed by Mojtaba Sadegh (msadegh@uci.edu) and Amir AghaKouchak, 
% on July 29, 2016
% Center for Hydrometeorology and Remote Sensing (CHRS)
% University of California, Irvine
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% IF TEMPERATURE BELOW FREEZING THRESHOLD, LIQUID WATER IS ZERO AND SNOW ACCUMULATION OCCURS
% FIG 1 OF REF 1
if T < TT
    % ACCUMULATE SNOW
    SSNOW = SSNOW + P;
    % LIQUID WATER WILL BE ZERO
    LIQWATER = 0;
else % IF TEMPERATURE ABOVE FREEZING THRESHOLD, LIQUID WATER IS SUMMATION OF PRECIP AND SNOW MELT
    % SNOW MELT: EQ1 OF REF 1
    SNM = min( SSNOW, DD*(T-TT) );
    % UPDATE SNOW STORAGE
    SSNOW = SSNOW - SNM;
    % ESTIMATE LIQUID WATER: PRECIP + SNOW MELT
    LIQWATER = P + SNM;
end
    