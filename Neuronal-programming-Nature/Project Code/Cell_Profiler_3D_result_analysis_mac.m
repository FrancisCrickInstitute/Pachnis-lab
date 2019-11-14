% /*
% * Copyright (C) 2019 Todd Fallesen <todd.fallesen at crick dot ac dot uk>
% *
% * This program is free software: you can redistribute it and/or modify
% * it under the terms of the GNU General Public License as published by
% * the Free Software Foundation, either version 3 of the License, or
% * (at your option) any later version.
% *
% * This program is distributed in the hope that it will be useful,
% * but WITHOUT ANY WARRANTY; without even the implied warranty of
% * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% * GNU General Public License for more details.
% *
% * You should have received a copy of the GNU General Public License
% * along with this program.  If not, see <http://www.gnu.org/licenses/>.

%%
%The difference between PC and MAC in this case is the folder seperator
%(i.e. / vs \).  It could be fixed in a later version using proper file
%seperator calls, but this works.  

%%
%%Script to make a table for the data from the spreadsheets from the
%%project Cell Profiler pipeline. For a mac.

%The input files are ging to be 'MyExpt_Image.csv' which will have the file
%names of the two channels (Spots and Nucleus) and the corresponding image
%number
%
%The second input file is 'MyExpt_SpotsInCells_merged.csv' which will have
%the image number, the object number, and the integrated intensity.  The
%object number here is the merged version of the spots, called from
%SplitOrMergeObjects module in cell profiler.

%%The third file is going to be MyExpt_Cells_Primary_Objects.csv, which
%%will have the object numbers and the corresponding tracked object numbers


% -- The information that they want is the Filename, Tracked ID number, original cell ID, integrated intensity of spots, and the file names.

%Read in the files and make MATLAB tables that can be easily edited and
%played with

selpath = uigetdir([],'Select the Folder with The results files');  %Selects the folder with the csv files
cd(selpath)  %change the directory to the path we just selected

Filename_data_filename = strcat(selpath , '/MyExpt_Image.csv');  %makes a path for the csv file that has the filenames in it
Tracking_data_filename = strcat(selpath , '/MyExpt_Cells_Primary_objects.csv'); %makes a path for the csv file that has the cell primary object data in it
Spots_data_filename = strcat(selpath , '/MyExpt_SpotsInCells_merged.csv'); %makes a path for the csv file that has the merged spot data, including intesnity in it
Filename_table = readtable(Filename_data_filename, 'Delimiter', ','); %read in the data for the filenames
Tracking_table = readtable(Tracking_data_filename,'Delimiter', ','); %read in the data for the cell primary objects
Spots_table = readtable(Spots_data_filename, 'Delimiter', ','); %read in the data for the merged spots and their intensities

File_table.ImageNumber = table2array(Filename_table(:,'ImageNumber'));  %read in the image numbers from the Cell Profiler Spreadsheet.  Use table2array to get the values so we can use math operations on them
File_table.CellsFile = table2array(Filename_table(:,'FileName_Cells')); %read in the file name of the Cells Hu Channel from the CellProfiler Spreadsheet, 
File_table.SpotsFile = table2array(Filename_table(:,'FileName_Spots')); %read in the file name of the RNAScope channel from the CellProfiler spreadsheet

max_image_number = max(File_table.ImageNumber);  %Set the max once, so we don't have to do a mathematical operation each iteration

Tracking_ids = table2array(Tracking_table(:,'TrackObjects_Label_50'));
max_Track_id = max(Tracking_ids);


%%%% Initialize structure
data_table = struct;   %Declare a structure, because they are the best suited for this project

data_table(1).ID = [];                  %The tracking ID from the tracking module
data_table(1).Slice.ImageID = [];               %Slices that the tracking showed up in 
data_table(1).Slice.Original_objects = [];  %Original object numbers inside slices
data_table(1).Slice.Original_objects(1).Int_intensity = []; %Integrated intensity of the spots of each object inside the original frame
data_table(1).Slice.filenames.spots = [];    %Filenames for each slice
data_table(1).Slice.filenames.cells = [];
data_table(1).Total_Intensity = [];     %Total intensity for each ID




for j = 1:max_Track_id   %run through a loop of tracked ID's
    
    index_TrackTable_byTrackID = Tracking_table{:,'TrackObjects_Label_50'} == j; %Make a logical index vector table for the Tracking_table that is just 1 or 0 if the value in the column 'TrackObjects_Label_50' is equal to the number we're iterating over
    data_table(j).ID = j;    %set the ID for the tracked object (this will be the cell number)
    data_table(j).Slice.ImageID = Tracking_table(index_TrackTable_byTrackID, 'ImageNumber');  %set the Image ID (this is the slice the objects come from)
    data_table(j).Slice.Original_objects = Tracking_table(index_TrackTable_byTrackID, 'ObjectNumber'); %set the original objects (where we can read their intensity)
    
     
end

%set file names
for j = 1:max_Track_id
    for k = table2array(data_table(j).Slice.ImageID)'  %this is a bit interesting.  We're iterating over an array that is made up from the table of the Slices that correspond to a tracked object
        Filename_index = Filename_table{:,'ImageNumber'} == k;  %make a logical index
        
        data_table(j).Slice.filenames.spots{k,1} = Filename_table(Filename_index,'FileName_Spots');  %read the row given by the index, and set the filename for spots
        data_table(j).Slice.filenames.cells{k,1} = Filename_table(Filename_index,'FileName_Cells');  %read the row given by the index, and set the filename for cells
    
    end
end

%Sanitize the data entry from the spots table.  The spots table, as it
%comes in, only has data for the primary objects where there were in fact
%spots.  This means the script will fail for any objects where there
%weren't spots detected in one or more frames.  We can fix this by just
%adding those objects to the end of the spots table, with intensities of
%zero.
spots_compare = Spots_table(:,1:2);
track_compare = Tracking_table(:,1:2);

if size(track_compare,1) > size(spots_compare,1)
    table_diff = setdiff(track_compare, spots_compare); %This gives us the difference between the two tables 
    
else
    table_diff = setdiff(spots_compare, track_compare);  %only if for some reasons the spots table is bigger than the track table
    warning('Spots table was bigger than track table');
end

%initilize a blank table
blank_table = array2table(zeros(size(table_diff,1),size(Spots_table,2)));

%set variable names of 'blank_table' to that of the Spots_table
blank_table.Properties.VariableNames = Spots_table.Properties.VariableNames;

%copy over the objects we're adding to account for the difference between
%tables
blank_table(:,'ImageNumber') = table_diff(:,'ImageNumber');
blank_table(:,'ObjectNumber') = table_diff(:,'ObjectNumber');

%add the blank table to the end of the Spots_table
Spots_table = [Spots_table;blank_table];


%Set intensity per tracked object

for j = 1:max_Track_id
    
clear Original_Objects  %These need to be cleared every loop so 
clear Original_slices
clear Original_slices_objects
clear Intensity_index
    Original_Objects = data_table(j).Slice.Original_objects.ObjectNumber;  %Fetch the list of original objects from the data_struct
    Original_slices = table2array(data_table(j).Slice.ImageID);            %Fetch the list of slices that correspond to the objects
    Original_slices_objects(:,1) = Original_slices;                        %Set an array of slice_number and Object_number
    Original_slices_objects(:,2) = Original_Objects;


    for k = 1:size(Original_slices_objects,1)  %iterate over the slices, per tracked object!! (i.e. these are just the slices that are present in the current tracked object)
            Intensity_index = Spots_table{:,'ImageNumber'} == Original_slices_objects(k,1) & Spots_table{:,'ObjectNumber'} == Original_slices_objects(k,2) ;  %filter the objects by those that have both the current slice number we are iterating over and the current object number
            intensities = Spots_table{Intensity_index, 'Intensity_IntegratedIntensity_Spots_eroded'};  %get that intensity for the matched slice and object number
            data_table(j).Slice.intensities(k) =  Spots_table{Intensity_index, 'Intensity_IntegratedIntensity_Spots_eroded'};  %set the intensities into the data structure
            %data_table(j).Slice.intensities(k) = data_table(j).Slice.intensities(k)';
    end
 
end

%%%Find the total intensity for each Tracked object and link that in.

for j = 1:size(data_table,2)   %iterate over all tracked cells
    tot_intensity = 0;  %start counting intensity from zero
    for k = 1:length(data_table(j).Slice.intensities) %iterate over all spot intensities for the tracked cells
        tot_intensity = tot_intensity + data_table(j).Slice.intensities(k);  %add the spots intensities per cell per slice up
    end
    data_table(j).Total_Intensity = tot_intensity;  %save the total intensity added up for all spots in all frames up per tracked object
end


 %%Write out results to csv table
 %Convert to table
 data_output_table = struct2table(rmfield(data_table,'Slice'));

 %Write out csv file
 first_file = Filename_table{1,2};  %get the filename of the first file
 first_file = first_file{1};  %turn the filename into a string
 first_file_prefix = first_file(1:end-23);  %cut the end off the string to make it more human friendly
 first_file_channel = first_file(end-6:end-4); %grab the channel, so we can append it to the end
 first_file_prompt = strcat(first_file_prefix,'_', first_file_channel, '_.xlsx');  %tag on the channel and an excel file extension so the computer saves it to excel
 [out_file,out_path] = uiputfile(first_file_prompt);  %open dialog box for saving the file
 
 output_name = strcat(out_path, out_file);  %create the output filename
 writetable(data_output_table, output_name); %save the output file
 
 workspace_name = strcat(out_path, out_file, '_workspace.m');  %save the Workspace
 save(workspace_name);
 
 