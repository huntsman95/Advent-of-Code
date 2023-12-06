[CmdletBinding()]
param (
    [Parameter()]
    [ValidateScript({ if (-not(Test-Path $_)) { throw [system.io.filenotfoundexception]::new() } })]
    [string]
    $FilePath = "$PSScriptRoot\source_data.txt"
)

class AlmanacRow {
    [Int64]$DestStart
    [Int64]$SrcStart
    [Int64]$Range
    AlmanacRow([Int64]$DestStart, [Int64]$SrcStart, [Int64]$Range) {
        $this.DestStart = $DestStart
        $this.SrcStart = $SrcStart
        $this.Range = $Range
    }

    AlmanacRow([string]$UnparsedInputInteger) {
        if ($UnparsedInputInteger -notmatch '\d+ \d+ \d+') {
            throw "InputInteger Data in Wrong Format - expected '<INT64> <INT64> <INT64>'"
        }
        $_InputIntegerArray = $UnparsedInputInteger -split " "
        $this.DestStart = $_InputIntegerArray[0]
        $this.SrcStart = $_InputIntegerArray[1]
        $this.Range = $_InputIntegerArray[2]
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

    [string]ToString() {
        return [PSCustomObject]@{
            SrcStart  = $this.SrcStart
            DestStart = $this.DestStart
            Range     = $this.Range
        }
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

function Get-MapData {
    Param(
        [System.Text.RegularExpressions.MatchCollection]$TableMatches
        ,
        [string]$MapIdentifier
    )
    $TableMatches.Where({ $_.Groups[1].Value -eq $MapIdentifier }).Groups[2].Value.Trim() -split [System.Environment]::NewLine | ForEach-Object { [AlmanacRow]::new($_) }
}

function Get-MappingNumber {
    param (
        [Parameter(ValueFromPipeline = $true)]
        [Int64]$Number
        ,
        [AlmanacRow[]]$AlmanacRows
    )
    $results = $AlmanacRows.where({ $Number -ge $_.SrcStart -and $Number -lt $_.SrcStart + $_.Range })
    if ($null -eq $results) {
        return $Number
    }
    else {
        $dstNumber = ($Number - $results.SrcStart) + $results.DestStart
        return $dstNumber
    }
}

#Part 2 Seed Class
class SeedRange {
    [Int64]$SeedStart
    [Int64]$SeedEnd
    SeedRange([Int64]$Start, [Int64]$Range) {
        $this.SeedStart = $Start
        $this.SeedEnd = $Start + ($Range - 1)
    }
    [bool] WithinRange([Int64]$InputInteger) {
        return ($InputInteger -le $this.SeedEnd) -and ($InputInteger -ge $this.SeedStart)
    }
}

class SeedRangeParser {
    [SeedRange[]]$SeedRanges
    SeedRangeParser([Int64[]]$SeedValues){
        if(1 -eq $SeedValues.Count % 2){throw "Input array must contain an even number of elements"}
        $PairCount = $SeedValues.Count / 2
        for ($i = 1; $i -le $PairCount; $i++) {
            $_Range = [SeedRange]::new(($SeedValues[$PairCount * 2 - 1]),($SeedValues[$PairCount * 2]))
            $this.SeedRanges += $_Range
        }
    }
}

class Almanac {
    [Int64[]]$SeedValues
    [Object[]]$SeedToSoilMap
    [Object[]]$SoilToFertilizerMap
    [Object[]]$FertilizerToWaterMap
    [Object[]]$WaterToLightMap
    [Object[]]$LightToTemperatureMap
    [Object[]]$TemperatureToHumidityMap
    [Object[]]$HumidityToLocationMap

    #Part 2
    [SeedRange[]]$SeedRanges

    Almanac([string]$FilePath) {
        $SourceData = Get-Content $FilePath -Raw

        # Get seed numbers
        $SeedRegex = "seeds: ([\d\s]+)"
        $this.SeedValues = [Int64[]](([regex]::Match($SourceData, $SeedRegex).Groups[1].Value).Trim() -split " ")

        # Get Maps
        $TableMatches = [regex]::Matches($SourceData, '([\w+\-+]+ map):\r\n([\d \r\n]+)\r\n')

        # Get Seed to Soil Map
        $this.SeedToSoilMap = Get-MapData -MapIdentifier "seed-to-soil map" -TableMatches $TableMatches
        $this.SoilToFertilizerMap = Get-MapData -MapIdentifier "soil-to-fertilizer map" -TableMatches $TableMatches
        $this.FertilizerToWaterMap = Get-MapData -MapIdentifier "fertilizer-to-water map" -TableMatches $TableMatches
        $this.WaterToLightMap = Get-MapData -MapIdentifier "water-to-light map" -TableMatches $TableMatches
        $this.LightToTemperatureMap = Get-MapData -MapIdentifier "light-to-temperature map" -TableMatches $TableMatches
        $this.TemperatureToHumidityMap = Get-MapData -MapIdentifier "temperature-to-humidity map" -TableMatches $TableMatches
        $this.HumidityToLocationMap = Get-MapData -MapIdentifier "humidity-to-location map" -TableMatches $TableMatches
    }

    [pscustomobject] GetPuzzleAnswerPart1() {
        # Gets the lowest location number that corresponds to any of the initial seed numbers
        $Answer = $this.SeedValues | ForEach-Object { $_ | Get-MappingNumber -AlmanacRows $Almanac.SeedToSoilMap `
            | Get-MappingNumber -AlmanacRows $Almanac.SoilToFertilizerMap `
            | Get-MappingNumber -AlmanacRows $Almanac.FertilizerToWaterMap `
            | Get-MappingNumber -AlmanacRows $Almanac.WaterToLightMap `
            | Get-MappingNumber -AlmanacRows $Almanac.LightToTemperatureMap `
            | Get-MappingNumber -AlmanacRows $Almanac.TemperatureToHumidityMap `
            | Get-MappingNumber -AlmanacRows $Almanac.HumidityToLocationMap
        } | Sort-Object -Top 1
        return [PSCustomObject]@{
            Answer = $Answer
        }
    }

    [pscustomobject] GetPuzzleAnswerPart2() {
        # Gets the lowest location number that corresponds to any of the initial seed numbers
        $parser = [SeedRangeParser]::new($this.SeedValues)
        return [PSCustomObject]@{
            Answer = $parser.SeedRanges
        }
    }
}

$Almanac = [Almanac]::new($FilePath)

# $Almanac.GetPuzzleAnswerPart1()
$Almanac.GetPuzzleAnswerPart2()