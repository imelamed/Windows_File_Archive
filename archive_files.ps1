<#################################################################################################### 
#                This script is devided into two actions                                           # 
#   1. Copy all files & folders from source folder to destination folder and deleting the original # 
#   2. Delete any empty folder in the source folder                                                # 
####################################################################################################> 
 
#Setting Parameters to Script 
param ( 
   [string]$UserName 
) 
<#Foreach ($User in $UserName) 
{ 
   $Computer 
} 
  #> 
 
# Vars. 
$SourceFolder = "F:\Public\UserData\" + $UserName                # Folder to copy from 
$DestinationFolder = "\\ITgenie\Archive\"           # Folder to copy to 
$Time = (get-date).AddDays(-90)                     # Sets the current date minus 90 days 
$Logs_Path = "C:\Scripts\Logs\"                     # Logs folder 
$Exclude = ("Haim","Zana")                          # Excluded folders from the first level 
 
# Date Vars. 
$current_date = Get-Date     # Get the current date 
$day = $current_date.Day     # Set the day 
$month = $current_date.Month # Set the month 
$year = $current_date.Year   # Set the year 
 
#Log name- DD.MM.YY 
$Log_name = $day.ToString() + "." + $month.ToString() + "." + $year.ToString() # create full log name 
#Log file- $logs_path\DD.MM.YY.txt 
$Log_file = $Logs_Path + $UserName + "-" + $Log_name + ".txt" #create full log file name 
$Err_File = $Logs_Path + $UserName + "_Error_" + $Log_name + ".txt" #create Error log file name 
 
#This function delete old logs- keeping last 10 logs 
function delete_Old_Logs 
{ 
    $NumberOfLogs = Get-ChildItem $Logs_path | Measure-Object 
    while ($NumberOfLogs.count -gt 10) 
    { 
        #Find oldest log and delete it 
        $oldest_log = Get-ChildItem $Logs_Path | select name, lastwritetime | sort-object -property lastwritetime  -Descending |Select-Object -last 1 
        $oldest_log = $Logs_Path + $oldest_log.name 
        #Delete the oldest log 
        Remove-Item $oldest_log 
        $NumberOfLogs = Get-ChildItem $Logs_path | Measure-Object 
    } 
} 
 
"Starting job" >> $Log_file 
 
# Phase 1: 
# Copy all files and folders from $SourceFolder to $DestinationFolder that has been modified before 90 days and deleting the file from the source 
 
"Phase 1" >> $Log_file 
 
# Getting the list of first level folders, without excluded folders. 
$FirstLevelFolders = Get-ChildItem $SourceFolder -force -Exclude $Exclude 
 
# Getting all files and folders of the required first level folders. 
$AllFiles = Get-ChildItem $FirstLevelFolders -recurse -force  | Where-Object { $_.Attributes -ne "Directory"} 
"Copying and removing the following files:" >> $Log_file 
foreach ($file in $AllFiles) 
{ 
    # Checking if the file was edited in those days. 
    if (($file.LastWriteTime -lt $Time) -and  !($file.mode -match "d")) 
    { 
        # FullPath is used to create the full path in the destination folder. 
        #$file.FullName >> $Log_file             #Documenting the file to be copied and removed 
        $TxtToLogFile = "Processing File : " + $file.FullName   #Debugging reasons 
        $TxtToLogFile | Out-File -Append $Log_file 
        $fullPath = $file.DirectoryName 
        #$fullPath >> $Log_file                  #Debugging reasons 
        $ToNetPath = $fullPath.TrimStart("F:\Public\UserData") 
        #$fullPath >> $Log_file                  #Debugging reasons 
        # NewPath is used to set the new destination folder for the copy command 
        $NewPath = $DestinationFolder + $ToNetPath + "\" 
        #$NewPath >> $Log_file                   #Debugging reasons 
        # Creating the FullPath in the destination folder. Checking first to see if the path exsist. 
        $status = Test-Path $NewPath 
        #$status >> $Log_file                    #Debugging reasons 
        if ($status -eq $False) 
        { 
            New-Item -ItemType "Directory" -Path $DestinationFolder -Name $ToNetPath 
#           $status = Test-Path $NewPath        #Debugging reasons 
            if ($?) 
            {#If create folder is sucsessfull send only to log file 
            $TxtToLogFile =  "Successfully Folder Create: " + $? + " - " + $NewPath    #Debugging reasons 
            $TxtToLogFile | Out-File -Append $Log_file 
            } 
            else 
            {#If create folder failed send to log file and error to error file 
            $TxtToLogFile =  "Successfully Folder Create: " + $? + " - " + $NewPath    #Debugging reasons 
            $TxtToLogFile | Out-File -Append $Log_file 
            error[0] | Out-File $Err_File -Append 
            } 
        } 
 
        #Copying the file and Deleting the file 
        Copy-Item -path $file.FullName -Destination $NewPath -force 
        if ($?) 
        {#If copy is sucsessfull send only to log file 
        $TxtToLogFile = "Successfully   Copy   File: " + $? + " - " + $file.FullName + " To Destination: " + $NewPath   #Debugging reasons 
        $TxtToLogFile | Out-File -Append $Log_file 
        } 
        else 
        {#If copy failed send to log file and error to error file 
        $TxtToLogFile = "Successfully   Copy   File: " + $? + " - " + $file.FullName + " To Destination: " + $NewPath   #Debugging reasons 
        $TxtToLogFile | Out-File -Append $Log_file 
        $error[0] | Out-File $Err_File -Append 
        } 
 
        Remove-Item -path $file.FullName -Force 
        if ($?) 
        {#If Remove is sucsessfull send only to log file 
        $TxtToLogFile = "Successfully Removing File: " + $? + " - " + $file.FullName   #Debugging reasons 
        $TxtToLogFile | Out-File -Append $Log_file 
        $TxtToLogFile = "---------------------------------------------------------------------------------------------------" 
        $TxtToLogFile | Out-File -Append $Log_file 
        } 
        else 
        {#If Remove failed send to log file and error to error file 
        $TxtToLogFile = "Successfully Removing File: " + $? + " - " + $file.FullName   #Debugging reasons 
        $TxtToLogFile | Out-File -Append $Log_file 
        $TxtToLogFile = "---------------------------------------------------------------------------------------------------" 
        $TxtToLogFile | Out-File -Append $Log_file 
        $error[0] | Out-File $Err_File -Append 
        } 
 
    } 
} 
 
 
# Phase 2: 
# Delete empty folders 
# Getting a list of all files and folders in the source folder 
 
"Phase 2" >> $Log_file 
 
$List = Get-ChildItem $SourceFolder -Recurse -force 
 
"Deleting the following folders:" >> $Log_file 
 
foreach($ListItem in $List) 
{ 
    # Checking if the folder is empty- counting how many files are inside. 
    if ($ListItem.mode -match "d") 
    { 
        $i=0 
        Get-ChildItem -path $ListItem.FullName -Recurse -Force | ForEach-Object {$i++} 
 
        # Checking if the last command was successful (problem with 260 length) 
        if ($?) 
        { 
            $continue = $True 
        } 
        else 
        { 
            $continue = $False 
        } 
 
        #Checking if the folder is empty and the last command was successful 
        if ( ($i -eq 0) -and ($continue) ) 
        { 
            #Removing The Empty Folder 
            remove-item $ListItem.FullName 
            $RemovalScore = $? #Setting Removal variable if removal has been sucsessfull or not 
            if ($RemovalScore) 
            { #If sucsessfull write to logfile only 
            $TxtToLogFile = "Successfully Removing Item: " + $RemovalScore + " - " + $ListItem.FullName #Debugging reasons 
            $TxtToLogFile | Out-File -Append $Log_file 
            } 
            else 
            { # If not sucsessfultt write to log file and to error file the last error. 
            $error[0] | Out-File $Err_File -Append 
            $TxtToLogFile = "Successfully Removing Item: " + $RemovalScore + " - " + $ListItem.FullName #Debugging reasons 
            $TxtToLogFile | Out-File -Append $Log_file 
            } 
 
        } 
    } 
} 
 
# delete_old_logs 