# wayback-archiver

PowerShell script to automate archiving and searching of single URL or import of multiple URLs via text file on the Internet Archive Wayback Machine.

## Usage
#### Archiving
.\wayback-archiver.ps1 -Url "https://www.google.co.uk" -Action Archive -OutputFile "C:\Temp\Results.csv"
.\wayback-archiver.ps1 -FilePath "C:\Temp\Import.txt" -Action Archive -OutputFile "C:\Temp\Results.csv"

#### Search
.\wayback-archiver.ps1 -Url "https://www.google.co.uk" -Action Search -OutputFile "C:\Temp\Results.csv"
.\wayback-archiver.ps1 -FilePath "C:\Temp\Import.txt" -Action Search -OutputFile "C:\Temp\Results.csv"
