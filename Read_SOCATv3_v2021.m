% Read_SOCATv3_v5()
%-------------------------------------------------------------------------%
% This is the routine to get the SOCAT v3.0 (2015)                        %
% to v2020  data into matlab.                                             %
% The data files are the SOCAT V3 to V2020 global and regional zip or tsv %
% files which can be downloaded from the SOCAT Data Download              %
% page on www.socat.info.  It can also read the individual cruise files   %
% from Pangaea (http://doi.pangaea.de) as well as the ascii or csv        %
% files downloaded from the cruise viewer on the SOCAT website.           %
% Several files can be selected, all with the same extension.             %
% For allowed extensions, see the 'exts' variable.                        %
% It reads the file(s) until the column headers are found.                %
% Determines # of columns from # of headers.                              %
% Creates GUI to ask user which columns to import                         %
% If Lat or Lon are selected for import, it creates another GUI           %
%      to ask the user which geographical region to import                %      
% If cruise flags are present and selected for import,                    %
%          it creates a GUI to select which flags to import.              %      
% Likewise with data flags.                                               %
% Data is stored in variables named after (sometimes modified)            %
% column headers                                                          %
% Anything before column headers is stored in 'StartText' variable        %
% For questions, contact:                                                 %
%       Denis Pierrot (Denis.Pierrot@noaa.gov)                            %
%   or  Peter Landschutzer (p.landschutzer@uea.ac.uk)                     %
%-------------------------------------------------------------------------%

clear all
%dbstop at 135;
%--------------------------------------------------------------------------%
%  TO USER:                                                                % 
%  Data file(s) should prefarably be in same directory as this .m file     % 
%  User Input:                                                             %
%   (~line 40)    readlines = number of lines to read to find data header  %
%                                                                          %
%   (~line 100)   dflt    = column number initially selected               % 
%                           to be imported when interface is created       %     
%   (~line 200)   defans  = lat-lon limits of region                       % 
%                           to be imported when interface is created       %     
%--------------------------------------------------------------------------%

readlines=10000;
exts={'.txt';'.tab.tsv';'.tsv';'.csv';'.rtf'};
allexts='.txt; .tab.tsv; .tsv; .csv; .rtf';
cruiseflags={'A','B','C','D','E'};
axts='';for i=1 : size(exts,1),axts=[axts '*' exts{i} ';'];end

%----Gets mfile directory ----------------------------------------------------
if exist(mfilename,'file')==2
    projDir = strrep([mfilename('fullpath') '.m'],[filesep mfilename '.m'],'');
else
    projDir =pwd;
end
%--------------------------------------------------------------------------
mess=sprintf('%s:\n\n\t1) %s\n\n\t2) %s\n\n\t3) %s\n    %s\n\n\t4) %s\n%s','Data Users are requested:',...
    'To report problems by emailing ''submit@socat.info''...',...
    'To generously acknowledge the contribution of SOCAT investigators...',...
    'To inform  ''submit@socat.info''',' of publications in which SOCAT is used...',...
    'To cite SOCAT as detailed in its ''FAIR DATA USE STATEMENT''','     found at ''www.socat.info''');
mmm=msgbox(mess,'WARNING: Data Use Policy','Warn','modal');
% deltaWidth = sum(th.Extent([1,3]))-mh.Position(3) + th.Extent(1);
% deltaHeight = sum(th.Extent([2,4]))-mh.Position(4) + 10;
th = findall(mmm, 'Type', 'Text');                   %get handle to text within msgbox
th.FontSize = 14;                                   %Change the font size
mmm.Position([3,4]) = mmm.Position([3,4]) *1.5;
mmm.Resize = 'on';
uiwait(mmm);

%----Select files to be imported (only 1 kind at a time)-------------------
[fname,fpath] = uigetfile(axts,'Select Data File(s)',[projDir filesep],'MultiSelect','on');
if (fpath==0),return;end
if strcmp(fpath(end),filesep)>0,fpath=fpath(1:end-1);end

%--------------- Detects extensions in files selected  -------------------
% 1 or more files selected
if ischar(fname), lname=1; else, lname=length(fname);  fname=sort(fname);end
cond=0;
if iscell(fname)
    for i=1:size(exts,1)
        for j=1:lname
            cond=cond + ~isempty(regexpi(fname{j},['.' exts{i} '$'], 'match'));
        end
        if cond>0 ,ftype=i; break;end %breaks on first extension detected
    end

else %one file only selected
    for i=1:size(exts,1)
        cond=cond + ~isempty(regexpi(fname,['.' exts{i} '$'], 'match'));
        if cond,ftype=i;break;end
    end
end
if ~cond 
    mmm=msgbox(sprintf('No files with correct extension selected!\n\nAllowed extensions are: %s\n\nProgram aborted.\n\n',allexts),'Error','Input File Error');
    return;
end
if cond<lname
    mmm=msgbox(sprintf('Files selected have different extensions!\n\nProgram aborted.\n\n'),'Error','Input File Error');
    return;
end

% ************************************** txt or tsv files*****************************************************************
switch ftype
    case {1,4,5} %txt, rtf or csv
        mots={'EXPOCODE';'FCO2_RECOMMENDED'};
        dflt=[3 4 6 29];% lon lat fCO2 SST
        tcol=[1 2 11 48];%text columns
    case 2 %tab.tsv   individual cruise files on PANGAEA (http://doi.pangaea.de)
        dflt=[1 2 3 6 12];% Date_Time lon lat temp fCO2 ? columns vary depending on the file
        tcol=[1];%text columns
        mots={'Date/Time';'Flag [#]'};
    case 3%tsv
        dflt=[1 4 5 6 7 8 9 10 11 12 14 15 23 24 26];% Expocode QC_Flag  yr mon day hh mm ss lon lat sal SST GVCO2 fCO2rec fCO2rec_flag
        tcol=[1 2 3 4];%text columns  (expocode, version, doi, QC_Flag)
        mots={'Expocode';'fCO2rec_flag'};
end
%delim=delims{ftype};

for fnum=1:lname
    if lname>1, ff= fopen([fpath filesep fname{fnum}],'r');fs=dir([fpath filesep fname{fnum}]);
    else,  ff=fopen([fpath filesep fname],'r');fs=dir([fpath filesep fname]); end
    
    ln=0;hdr=0;kk=0;
    %--------------------------------------------------------------------------
    % searches for header line
    %--------------------------------------------------------------------------
    
    hdrline=[];
    hdr_in=textscan(ff,'%s',readlines,'delimiter','\n');
    hdr_in1 = strfind(hdr_in{1}, mots{1}); hdr_in2=strfind(hdr_in{1}, mots{2});
    hdr_in1=~cellfun('isempty', hdr_in1);hdr_in2=~cellfun('isempty', hdr_in2);
    hdrline=intersect(find(hdr_in1), find(hdr_in2));
    
    if(isempty(hdrline) | feof(ff)), h=msgbox(sprintf('%s%d%s\n\n%s\n\n%s','Could not find header line in the first ',readlines,' lines.','Increase the value of the ''readlines'' variable','at the beginning of the code and restart.'),'Error','Error');return;end
    
    if length(hdrline)>1, h=msgbox(sprintf('%s\n%s\n','Found several possible header lines...','Check words to look for.'),'Error','Error');return;end
    if (hdrline>0),fseek(ff,0,'bof'); StartText=textscan(ff,'%s',hdrline-1,'delimiter','\n');end
    
    if fnum==1,SText=StartText;
    else, SText{1,1}=cat(1,SText{1,1},StartText{1,1});end
    tline = fgets(ff);
    %gets rid of ending characters [\]
    tline=regexprep(tline,'[\\$]','');
    %--------------------------------------------------------------------------
    % Reads headers and number of columns
    %--------------------------------------------------------------------------
    %get delimiter
    delim='\t';
    if length(strfind(tline,','))> length(strfind(tline,',')), delim=',';end
    hdr2=textscan(tline,'%s','delimiter',delim);
   % fclose(ff);
    if fnum==1
        
        hdrs=hdr2{1,1};
        colmax=length(hdrs);
        
        %--------------------------------------------------------------------------
        % Creates interface
        %--------------------------------------------------------------------------
        [scrsz]=get(0,'ScreenSize');   ht=700;spc=50;ctrln=13;ncolmax=ceil(colmax/ctrln);wd=300*ncolmax;
        
        fig = figure('position', [(scrsz(3)-wd)/2 (scrsz(4)-ht)/2 wd ht]);
        %set(fig,'Color',get(fig,'Color'));
        cols=[];
        for i=1:ncolmax
            cols=[cols 300*(i-1)+50];
        end
        uicontrol ('Style','text','position', [(wd-200)/2 ht-20 200 20],'String','Select Variable to Import','backgroundcolor',get(fig,'color'));
        
        for i=1:colmax
            ncol=ceil(i/ctrln);
            b(i) = uicontrol ('Style','radiobutton','position', [cols(ncol) ht-50-spc*i+(ctrln*spc*(ncol-1)) 50+length(hdrs{i})*10 50],'String',hdrs{i},'backgroundcolor',get(fig,'color'));
            set(b(i),'Value',ismember(i,dflt));
        end
        ccb=uicontrol ('Style','togglebutton','position', [(wd-100) 20 40 20],'String','Cancel','Callback','uiresume(gcbf)');
        okb=uicontrol ('Style','togglebutton','position', [(wd-50) 20 30 20],'String','OK','Callback','uiresume(gcbf)');
        uicontrol(okb);
        uiwait(fig);
        set(fig,'visible','off');
        if ~get(okb,'value'), return;end
        for i=1:colmax,bv(i)=get(b(i),'Value');end
        rcol=find(bv);% columns to read
        
        
        for i=1:colmax % check if certain cols have been selected
            if(regexpi(hdrs{i},'longitude')==1)
                ind2=i;
            elseif(regexpi(hdrs{i},'latitude')==1)
                ind3=i;
            elseif(regexpi(hdrs{i},'QC_Flag')==1)
                ind4=i;
            else
                if(regexpi(hdrs{i},'fco2rec_flag')==1), ind5=i; end
                if(regexpi(hdrs{i},'Flag \[\#\]')==1), ind5=i; end
            end
        end
        
        %--------------------------------------------------------------------------
        % open GUI to set lon-lat borders (PL 17102011)
        %--------------------------------------------------------------------------
        if(bv(ind2)~=0 || bv(ind3)~=0)
            prompt={'Min. Longitude','Max. Longitude', 'Min. Latitude', 'Max. Latitude'};
            if ftype==3, defans={'0','360', '-90', '90'}; else, defans={'-180','180', '-90', '90'}; end
            fields = {'lonmin','lonmax', 'latmin', 'latmax'};
            info = inputdlg(prompt, 'Enter Limits', 1, defans,'on');
            if isempty(info),return;end              %see if user hit cancel
            info = cell2struct(info,fields);
            lonmin = str2double(info.lonmin);%convert string to number
            lonmax = str2double(info.lonmax);
            latmin = str2double(info.latmin);
            latmax = str2double(info.latmax);
            clear prompt defans fields info
        end
        
        
        if exist('ind4','var')
            if bv(ind4)~=0
                %--------------------------------------------------------------------------
                % Creates Cruise Flag Dialog
                %--------------------------------------------------------------------------
                ht=200;wd=500;hdr2s=cruiseflags;cols=[25 100 200 300 400];ctrln=size(cruiseflags,2);htt=100;wdt=500;%htt and wdt are for the txt
                cfdlg = figure('Name','Cruise Flags Selection','NumberTitle','off','position', [(scrsz(3)-wd)/2 (scrsz(4)-ht)/2 wd ht]);
                msg=sprintf('%s\n\n%s\n%s','Select Cruise Flags to Import','see the QC Cookbook', 'www.SOCAT.info - ''About SOCAT'' - ''Publications''');
                uicontrol ('Style','text','FontSize', 14, 'position', [(wd-wdt)/2 ht-htt wdt htt],'String',msg,'backgroundcolor',get(cfdlg,'color'));
                for i=1:ctrln
                    b(i) = uicontrol ('Style','radiobutton','position', [cols(i) 50 50+length(hdrs{i})*10 50],'String',hdr2s{i},'backgroundcolor',get(cfdlg,'color'));
                    set(b(i),'Value',1);
                end
                okb=uicontrol ('Style','togglebutton','position', [(wd-50) 20 30 20],'String','OK','Callback','uiresume(gcbf)','backgroundcolor',get(cfdlg,'color'));
                ccb=uicontrol ('Style','togglebutton','position', [(wd-100) 20 40 20],'String','Cancel','Callback','uiresume(gcbf)','backgroundcolor',get(cfdlg,'color'));
                uiwait(cfdlg);
                set(cfdlg,'visible','off');
                if ~get(okb,'value'), return;end
                for i=1:ctrln,bc(i)=get(b(i),'Value');end
                cf=cruiseflags(find(bc));% cruise flags to read
            end
        end
        
        if exist('ind5','var')
            if bv(ind5)~=0  %if ind5 exists and has been selected
                %--------------------------------------------------------------------------
                % Creates WOCE Flag Dialog
                %--------------------------------------------------------------------------
                ht=150;wd=400;hdr3s={'2 (good)','3 (questionable)','4 (bad)'};cols=[50 175 300];ctrln=size(hdr3s,2);htt=20;wdt=400;
                dfdlg = figure('Name','Data Flag Selection','NumberTitle','off','position', [(scrsz(3)-wd)/2 (scrsz(4)-ht)/2 wd ht]);
                msg=sprintf('%s','Select Data WOCE Flags to Import');
                uicontrol ('Style','text','position', [(wd-wdt)/2 ht-htt wdt htt],'String',msg,'backgroundcolor',get(dfdlg,'color'));
                for i=1:ctrln
                    b(i) = uicontrol ('Style','radiobutton','position', [cols(i) 50 50+length(hdrs{i})*10 50],'String',hdr3s{i},'backgroundcolor',get(dfdlg,'color'));
                    set(b(i),'Value',1);
                end
                okb=uicontrol ('Style','togglebutton','position', [(wd-50) 20 30 20],'String','OK','Callback','uiresume(gcbf)','backgroundcolor',get(dfdlg,'color'));
                ccb=uicontrol ('Style','togglebutton','position', [(wd-100) 20 40 20],'String','Cancel','Callback','uiresume(gcbf)','backgroundcolor',get(dfdlg,'color'));
                uiwait(dfdlg);
                set(dfdlg,'visible','off');
                if ~get(okb,'value'), return;end
                for i=1:ctrln,bd(i)=get(b(i),'Value');end
                df=find(bd(1:ctrln))+1;% cruise flags to read
            end
        end
        
        fstr='';% Creates the format string to read data
        for i=1:colmax
            if ~ismember(i,rcol)
                fstr=[fstr '%*s '];
            elseif ~ismember(i,tcol)
                fstr=[fstr '%f '];
            else
                fstr=[fstr '%s '];
            end
        end
        fstr=[fstr '\n'];
            
    end %of if fnum==1
    clear hdr2;
    
    %--------------------------------------------------------------------------
    % start reading the data according to the format string 'fstr'
    %--------------------------------------------------------------------------
    %tic;
    
    data_in1=textscan(ff,fstr,'delimiter',delim);
    if fnum==1 , data_in=data_in1;ncol=size(data_in1,2);
    else, for j=1:ncol,data_in{1,j}=cat(1,data_in{1,j},data_in1{1,j});end; end    
    fclose(ff);
    
    %toc
end

%--------------------------------------------------------------------------
% remove lines outside lat and lon border (PL 17102011)
%--------------------------------------------------------------------------

if(bv(ind2)~=0) 
    ind=data_in{1,sum(bv(1:ind2))}<lonmin | data_in{1,sum(bv(1:ind2))}>lonmax;
    for i=1:size(data_in,2)
        data_in{1,i}(ind)=[];
    end
    clear ind ind2
end
if(bv(ind3)~=0)
    ind=data_in{1,sum(bv(1:ind3))}<latmin | data_in{1,sum(bv(1:ind3))}>latmax;
    for i=1:size(data_in,2)
        data_in{1,i}(ind)=[];
    end
    clear ind ind3
end
%--------------------------------------------------------------------------
% remove unwanted flags
%--------------------------------------------------------------------------

if exist('ind4','var')
    if(bv(ind4)~=0)  %Cruise Flags
        ind=~ismember(data_in{1,sum(bv(1:ind4))},cf);
        for i=1:size(data_in,2)
            data_in{1,i}(ind)=[];
        end
        clear ind ind4
    end
end
if exist('ind5','var')
    if(bv(ind5)~=0)  %Data Flags
        ind=~ismember(data_in{1,sum(bv(1:ind5))},df);
        for i=1:size(data_in,2)
            data_in{1,i}(ind)=[];
        end
        clear ind ind5
    end
end

if size(data_in{1},1)==0, msgbox(sprintf('No data within the criteria specified.\n\nTry again with different selections\n\n')); end
%--------------------------------------------------------------------------
% Puts each column read in a variable named after column header.
%--------------------------------------------------------------------------
%Cleans hdrs for use as variable name
%gets rid of units
hdrs=regexprep(hdrs,'\s\[\S*\]','');
%gets rid of what is in parentheses
hdrs=regexprep(hdrs,'\s(\S*)','');
%replace (spaces, / or \) by underscore
hdrs=regexprep(hdrs,'[\s/\\]','_');
for i = rcol
    eval([hdrs{i} '=data_in{1,find(rcol==i)};']);
end

%--------------------------------------------------------------------------
% clears unnecessary variables
%--------------------------------------------------------------------------
close all; 
clear hdr_in hdr_in1 hdr_in2 data_in1 readlines fs numlines numlinesi dflt
clear ht wd scrsz cols spc ctrln b okb ccb colmax bv rcol fig h data_in
clear ff fstr hdr i readnum j k kk mots remain str ncol tline filen fnum lname
clear lonmin latmin lonmax latmax 
clear SText axts cond exts ftype ln tcol
clear htt wdt hdr2s cfdlg mmm th
clear hdr3s dfdlg bd df bc cf msg v cruiseflags delim ind5 ncolmax

%--------------------------------------------------------------------------
% code example to plot a variable (plotv) on a map
% to run code, highlight lines in between the "if" statement 
% (lines 385 to 406), right click and select "Evaluate Selection" 
%--------------------------------------------------------------------------
runcode=0;
if runcode==1
    close all;dotsize=3;
    plotv=fCO2rec;  %replace fCO2rec by variable name to be plotted.
    xx=longitude;yy=latitude;
    mx=max(plotv);    plotvc=plotv/mx;
    scatter3(xx,yy,plotv,4,plotvc);
    x1lim=get(gca,'XLim');
    y1lim=get(gca,'YLim');
    hold (gca,'on');

    %Color Bar
    colormap jet; hcb=colorbar; set(hcb,'location','eastoutside','yaxislocation','right');
    yt=get(hcb,'YTick');ytl='';
    for i=1:length(yt)
        ytl=strvcat(ytl,int2str(yt(i)*mx));
        set(hcb,'YTickLabel',ytl);
    end
    
    load coast;
    map_height=mean(plotv); % average of plotted data 
    hh=plot3(long,lat,zeros(size(long,1),1)+map_height,'Parent',gca, 'Marker','none', 'MarkerSize',dotsize, 'MarkerEdgeColor','b', 'MarkerFaceColor','none','LineStyle','-');
    set(gca,'XLim',x1lim,'YLim',y1lim);

end

