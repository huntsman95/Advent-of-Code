[CmdletBinding()]
param (
    [Parameter()]
    [ValidateScript({ if (-not(Resolve-Path $_)) { throw [system.io.filenotfoundexception]::new() }; return $true })]
    [string]
    $FilePath = "$PSScriptRoot\source_data.txt"
)

class AlmanacRow {
    [Int64]$DestStart
    [Int64]$DestEnd
    [Int64]$SrcStart
    [Int64]$SrcEnd
    [Int64]$Range
    AlmanacRow([Int64]$DestStart, [Int64]$SrcStart, [Int64]$Range) {
        $this.DestStart = $DestStart
        $this.DestEnd = $DestStart + ($Range - 1)
        $this.SrcStart = $SrcStart
        $this.SrcEnd = $SrcStart + ($Range - 1)
        $this.Range = $Range
    }

    AlmanacRow([string]$UnparsedInputInteger) {
        if ($UnparsedInputInteger -notmatch '\d+ \d+ \d+') {
            throw "InputInteger Data in Wrong Format - expected '<INT64> <INT64> <INT64>'"
        }
        $_InputIntegerArray = $UnparsedInputInteger -split ' '
        $this.DestStart = $_InputIntegerArray[0]
        $this.DestEnd = [Int64]$_InputIntegerArray[0] + [Int64]($_InputIntegerArray[2] - 1)
        $this.SrcStart = $_InputIntegerArray[1]
        $this.SrcEnd = [Int64]$_InputIntegerArray[1] + [Int64]($_InputIntegerArray[2] - 1)
        $this.Range = $_InputIntegerArray[2]
    }

    AlmanacRow([Int64]$SeedStart, [Int64]$SeedEnd) {
        $this.DestStart = $SeedStart
        $this.DestEnd = $SeedEnd
        $this.SrcStart = 0
        $this.SrcEnd = 0
        $this.Range = $SeedEnd - $SeedStart + 1
    }

    [string]ToString() {
        return "SrcStart: $($this.SrcStart), DestStart: $($this.DestStart), Range: $($this.Range)"
    }
}

function Get-MapData {
    Param(
        [System.Text.RegularExpressions.MatchCollection]$TableMatches
        ,
        [string]$MapIdentifier
    )
    $TableMatches.Where({ $_.Groups[1].Value -eq $MapIdentifier }).Groups[2].Value.Trim() -split [System.Environment]::NewLine | ForEach-Object { [AlmanacRow]::new([string]$_) }
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
    [System.Collections.Generic.List[SeedRange]]$SeedRanges = [System.Collections.Generic.List[SeedRange]]::new()
    SeedRangeParser([Int64[]]$SeedValues) {
        if (1 -eq $SeedValues.Count % 2) { throw 'Input array must contain an even number of elements' }
        $PairCount = $SeedValues.Count / 2
        for ($i = 1; $i -le $PairCount; $i++) {
            $_Range = [SeedRange]::new(($SeedValues[($i - 1) * 2]), ($SeedValues[($i * 2) - 1]))
            $this.SeedRanges.Add($_Range)
        }
    }
}

class Almanac {
    [Int64[]]$SeedValues
    [AlmanacRow[]]$SeedToSoilMap
    [AlmanacRow[]]$SoilToFertilizerMap
    [AlmanacRow[]]$FertilizerToWaterMap
    [AlmanacRow[]]$WaterToLightMap
    [AlmanacRow[]]$LightToTemperatureMap
    [AlmanacRow[]]$TemperatureToHumidityMap
    [AlmanacRow[]]$HumidityToLocationMap

    #Part 2
    [SeedRange[]]$SeedRanges

    Almanac([string]$FilePath) {
        $SourceData = Get-Content $FilePath -Raw

        # Get seed numbers
        $SeedRegex = 'seeds: ([\d\s]+)'
        $this.SeedValues = [Int64[]](([regex]::Match($SourceData, $SeedRegex).Groups[1].Value).Trim() -split ' ')

        # Get Maps
        $TableMatches = [regex]::Matches($SourceData, '([\w+\-+]+ map):\r\n([\d \r\n]+)\r\n')

        # Get Seed to Soil Map
        $this.SeedToSoilMap = Get-MapData -MapIdentifier 'seed-to-soil map' -TableMatches $TableMatches
        $this.SoilToFertilizerMap = Get-MapData -MapIdentifier 'soil-to-fertilizer map' -TableMatches $TableMatches
        $this.FertilizerToWaterMap = Get-MapData -MapIdentifier 'fertilizer-to-water map' -TableMatches $TableMatches
        $this.WaterToLightMap = Get-MapData -MapIdentifier 'water-to-light map' -TableMatches $TableMatches
        $this.LightToTemperatureMap = Get-MapData -MapIdentifier 'light-to-temperature map' -TableMatches $TableMatches
        $this.TemperatureToHumidityMap = Get-MapData -MapIdentifier 'temperature-to-humidity map' -TableMatches $TableMatches
        $this.HumidityToLocationMap = Get-MapData -MapIdentifier 'humidity-to-location map' -TableMatches $TableMatches

        $this.SeedRanges = [SeedRangeParser]::new($this.SeedValues).SeedRanges
    }

    [pscustomobject] GetPuzzleAnswerPart1() {
        # Gets the lowest location number that corresponds to any of the initial seed numbers
        $Answer = $this.SeedValues | ForEach-Object { $_ | Get-MappingNumber -AlmanacRows $this.SeedToSoilMap `
            | Get-MappingNumber -AlmanacRows $this.SoilToFertilizerMap `
            | Get-MappingNumber -AlmanacRows $this.FertilizerToWaterMap `
            | Get-MappingNumber -AlmanacRows $this.WaterToLightMap `
            | Get-MappingNumber -AlmanacRows $this.LightToTemperatureMap `
            | Get-MappingNumber -AlmanacRows $this.TemperatureToHumidityMap `
            | Get-MappingNumber -AlmanacRows $this.HumidityToLocationMap
        } | Sort-Object -Top 1
        return [PSCustomObject]@{
            Answer = $Answer
        }
    }

    [pscustomobject] BruteForcePuzzleAnswerPart2() {
        $buffer = [System.Collections.Generic.List[Int64]]::new()
        # Gets the lowest location number that corresponds to any of the initial seed number ranges by brute force
        $i = 1
        $this.SeedRanges | ForEach-Object {
            # Write-Progress -Activity "Working on SeedRange $i of $($SeedRanges.Count)" -PercentComplete ($i / $SeedRanges.Count * 100)
            ($_.SeedStart)..($_.SeedEnd) | ForEach-Object {
                Write-Progress -Activity "SeedNumber $($_) of $($this.SeedRanges[$i-1].SeedEnd)" -PercentComplete ($_ / $($this.SeedRanges[$i - 1].SeedEnd) * 100)
                $Value = $_ | Get-MappingNumber -AlmanacRows $this.SeedToSoilMap `
                | Get-MappingNumber -AlmanacRows $this.SoilToFertilizerMap `
                | Get-MappingNumber -AlmanacRows $this.FertilizerToWaterMap `
                | Get-MappingNumber -AlmanacRows $this.WaterToLightMap `
                | Get-MappingNumber -AlmanacRows $this.LightToTemperatureMap `
                | Get-MappingNumber -AlmanacRows $this.TemperatureToHumidityMap `
                | Get-MappingNumber -AlmanacRows $this.HumidityToLocationMap
                $buffer.Add($Value)
            }
            $i++
        }
        return [PSCustomObject]@{
            Answer = $buffer | Sort-Object -Top 1
        }
    }
}


class OverlapChecker {
    [AlmanacRow]$NoOverlap
    [AlmanacRow]$LeftOverlap
    [AlmanacRow]$RightOverlap
    OverlapChecker([AlmanacRow]$SourceAlmanacRow, [AlmanacRow[]]$DestinationMap) {
        foreach ($_Row in $DestinationMap) {
            if (-not($SourceAlmanacRow.DestStart -le $_Row.SrcEnd -and $_Row.SrcStart -le $SourceAlmanacRow.DestEnd)) {
                break #Dont bother processing if there is no intersect
            }
            if ($_Row.SrcStart -lt $SourceAlmanacRow.DestStart) {
                $this.NoOverlap = ($SourceAlmanacRow.DestStart - $_Row.SrcStart) + $SourceAlmanacRow.DestStart
            }
            elseif ($_Row.SrcStart -gt $SourceAlmanacRow.DestStart) {
                $this.NoOverlap = $SourceAlmanacRow.DestEnd - ($SourceAlmanacRow.DestEnd - $_Row.DestStart)
            }
            ###
            # Case 1 - Center overlap (source smaller than dest and in middle)
            # Case 2 - Spillover overlap (Source larger than dest and dest falls in middle)
            # Case 3 - Left overlap ()
        }
    }
}

function Invoke-Day5Puzzle {
    param (
        [string]$FilePath
    )
    $Almanac = [Almanac]::new($FilePath)
    # $Almanac.GetPuzzleAnswerPart1()
    $Almanac.GetPuzzleAnswerPart2()
}

$Almanac = [Almanac]::new($FilePath)