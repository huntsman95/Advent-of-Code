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
        $_InputIntegerArray = $UnparsedInputInteger -split " "
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
        $this.Range = $SeedEnd - $SeedStart
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
        if (1 -eq $SeedValues.Count % 2) { throw "Input array must contain an even number of elements" }
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

    [pscustomobject] GetPuzzleAnswerPart2() {
        $buffer = [System.Collections.Generic.List[Int64]]::new()
        # Gets the lowest location number that corresponds to any of the initial seed numbers
        # $parser = [SeedRangeParser]::new($this.SeedValues)
        # $SeedRanges = $parser.SeedRanges
        # Gets the lowest location number that corresponds to any of the initial seed numbers
        $i = 1
        $this.SeedRanges | ForEach-Object {
            # Write-Progress -Activity "Working on SeedRange $i of $($SeedRanges.Count)" -PercentComplete ($i / $SeedRanges.Count * 100)
            ($_.SeedStart)..($_.SeedEnd) | ForEach-Object {
                Write-Progress -Activity "SeedNumber $($_) of $($SeedRanges[$i-1].SeedEnd)" -PercentComplete ($_ / $($SeedRanges[$i - 1].SeedEnd) * 100)
                $Value = $_  | Get-MappingNumber -AlmanacRows $this.SeedToSoilMap `
                    $buffer.Add($Value)
            }
            $i++
        }
        return [PSCustomObject]@{
            Answer = $buffer
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



# Invoke-Day5Puzzle -FilePath $FilePath

$Almanac = [Almanac]::new($FilePath)

#Start with list of locations (FLOOR)
$HtoL = [System.Linq.Enumerable]::OrderBy(($Almanac.HumidityToLocationMap), [Func[Object, Object]] { $args[0].DestStart })

function Get-ValidMapResults {
    [CmdletBinding()]
    param (
        [Parameter()]
        [AlmanacRow[]]
        $Map
        ,
        [Parameter(ValueFromPipeline = $true)]
        [AlmanacRow]
        $SourceRow
    )
    process {
        $Map.where({ $SourceRow.SrcStart -ge $_.DestStart -and $SourceRow.SrcEnd -le $_.SrcEnd })
    }
}


function Get-ValidSubTableValues {
    [CmdletBinding()]
    param (
        [Parameter()]
        [AlmanacRow[]]
        $Map
        ,
        [Parameter(ValueFromPipeline = $true)]
        [AlmanacRow]
        $SourceRow
    )
    process {
        $Map.where({ $SourceRow.DestStart -ge $_.SrcStart -and $SourceRow.DestEnd -le $_.SrcEnd })
    }
}

function Test-InputForIntersect {
    [CmdletBinding()]
    param (
        [Parameter()]
        [AlmanacRow]
        $SourceRow
        ,
        [Parameter()]
        [AlmanacRow]
        $DestRow
    )
    process {
        $a1 = $SourceRow.DestStart
        $a2 = $SourceRow.DestEnd
        $b1 = $DestRow.SrcStart
        $b2 = $DestRow.DestEnd

        [int64]::IsPositive([math]::Min($a2, $b2) - [Math]::Max($a1, $b1) + 1)
    }
}

$j = $Almanac.SeedRanges | foreach-object {
    [AlmanacRow]::new([int64]$_.SeedStart, [int64]$_.SeedEnd)
}

for ($i = 0; $i -lt $j.Count; $i++) {
    $Almanac.SeedToSoilMap | foreach-object {
        if (Test-InputForIntersect -SourceRow $j[$i] -DestRow $_) {
            $_
        }
    }
}



# function Get-SeedWithinRangeResult {

# }

# $HtoL | ForEach-Object {
#     $HumidityToLocationMapValidVals = $_ | Get-ValidMapResults -Map $Almanac.TemperatureToHumidityMap | Select-Object -Unique

#     [PSCustomObject]@{
#         LocationNumberStart = $_.DestStart
#         LocationNumberEnd = $_.DestEnd
#         HumidityToLocationMapValidVals = $HumidityToLocationMapValidVals | Select-Object DestStart, DestEnd
#     }
# }
# $TtoH = $Almanac.TemperatureToHumidityMap.where({ $HtoL[0].SrcStart -ge $_.DestStart -and $HtoL[0].SrcEnd -le $_.SrcEnd })
# $LtoT = $Almanac.LightToTemperatureMap.where({ $TtoH[0].SrcStart -ge $_.DestStart -and $TtoH[0].SrcEnd -le $_.SrcEnd })
# $WtoL = $Almanac.WaterToLightMap.where({ $LtoT[0].SrcStart -ge $_.DestStart -and $LtoT[0].SrcEnd -le $_.SrcEnd })
# $FtoW = $Almanac.FertilizerToWaterMap.where({ $WtoL[0].SrcStart -ge $_.DestStart -and $WtoL[0].SrcEnd -le $_.SrcEnd })
# $StoF = $Almanac.SoilToFertilizerMap.where({ $FtoW[0].SrcStart -ge $_.DestStart -and $FtoW[0].SrcEnd -le $_.SrcEnd })

# $Almanac.TemperatureToHumidityMap



# # $Almanac.GetPuzzleAnswerPart1()
# $Almanac.GetPuzzleAnswerPart2()