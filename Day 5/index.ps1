class MappingTable {
    [System.Collections.Generic.List[Object[]]] $Rows
    [string] $TableName
    MappingTable($TableName) {
        <# Initialize the class. Use $this to reference the properties of the instance you are creating #>
        $this.TableName = $TableName
    }

    [void] AddRow([AlmanacRow]$RowContent) {
        $this.Rows.Add($RowContent)
    }
}

class AlmanacRow {
    [Int64]$DestStart
    [Int64]$SrcStart
    [Int64]$Range
    AlmanacRow([Int64]$DestStart, [Int64]$SrcStart, [Int64]$Range) {
        $this.DestStart = $DestStart
        $this.SrcStart = $SrcStart
        $this.Range = $Range
    }

    AlmanacRow([string]$UnparsedInput){
        if($UnparsedInput -notmatch '\d+ \d+ \d+'){
            throw "Input Data in Wrong Format - expected '<INT64> <INT64> <INT64>'"
        }
        $_InputArray = $UnparsedInput -split " "
        $this.DestStart = $_InputArray[0]
        $this.SrcStart = $_InputArray[1]
        $this.Range = $_InputArray[2]
    }

    [pscustomobject[]] Explode() {
        #DO NOT USE THIS WITH LARGE NUMBERS --WARNING--
        $buffer = [System.Collections.Generic.List[pscustomobject]]::new()
        for ($i = 0; $i -lt $this.Range; $i++) {
            $_iteration = [PSCustomObject]@{
                Destination = $this.DestStart + $i
                Source      = $this.SrcStart + $i
            }
            $buffer.Add($_iteration)
        }
        return $buffer
    }
}

function New-PSObjectArrayFromAlmanacRow {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [Int64]
        $SourceStart
        ,
        [Parameter(Mandatory)]
        [Int64]
        $DestinationStart
        ,
        [Parameter(Mandatory)]
        [Int64]
        $Range
    )
    [AlmanacRow]::new($DestinationStart, $SourceStart, $Range).ToPSObjectArray()
}


# class DataParser {
#     [string]$SeedToSoilMap
#     static [string]$SeedToSoilRegex = ""

#     DataParser([string]$FilePath){
#         $SrcData = Get-Content -Path $FilePath -Raw
#         $
#     }
# }

class Almanac {
    [Int64[]]$SeedValues
    [Object[]]$SeedToSoilMap #Type AlmanacRow
    [Object[]]$SoilToFertilizerMap
    [Object[]]$FertilizerToWaterMap
    [Object[]]$WaterToLightMap
    [Object[]]$LightToTemperatureMap
    [Object[]]$TemperatureToHumidityMap
    [Object[]]$HumidityToLocationMap
}


$SrcFilePath = "$PSScriptRoot\source_data.txt"

$SourceData = Get-Content $SrcFilePath -Raw

$SeedRegex = "seeds: ([\d\s]+)"
[Int64[]]$SeedValues = [Int64[]](([regex]::Match($SourceData, $SeedRegex).Groups[1].Value).Trim() -split " ") | Sort-Object

$regexOptions = [System.Text.RegularExpressions.RegexOptions]::Singleline -bor [System.Text.RegularExpressions.RegexOptions]::IgnoreCase -bor [System.Text.RegularExpressions.RegexOptions]::CultureInvariant

$TableMatches = [regex]::Matches($SourceData, '([\w+\-+]+ map):\r\n([\d \r\n]+)\r\n')

$TableMatches[0].Groups[2].Value.trim() -split [System.Environment]::NewLine | ForEach-Object {[AlmanacRow]::new($_)} -OutVariable testttt