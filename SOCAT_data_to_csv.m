% After running 'Read_SOCATv3_v2021.m', this script will combine the data 
% variables into one csv file. 
%
% Date Created: 06/16/21
% Last Edited: 06/16/21
% Lexi Jones

concat_data = [yr,mon,day,hh,latitude,longitude,pCO2water_equ_wet]; %add any variables you want to this list

%% Remove nan values
% Here I'm completely removing the data point if pCO2 = NaN to make the
% dataset smaller for now

concat_data(any(isnan(concat_data), 2), :) = [];

%% Save the data to a .csv
% Data will save in current directory. Make sure to change the file name for
% each download, or otherwise it will overwrite the other file.

header = {'Year','Month','Day','Hour','Lat','Lon','pCO2_water_equ_wet'}; %Header for each column
data_with_header = [header; num2cell(concat_data)]; %Add the header to top of dataset

% Uncomment this line when ready to save 
writecell(data_with_header,'SOCAT_data_North_Pacific.csv','Delimiter','comma')
