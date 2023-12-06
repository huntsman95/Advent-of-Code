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

    AlmanacRow([string]$UnparsedInput) {
        if ($UnparsedInput -notmatch '\d+ \d+ \d+') {
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

class Almanac {
    [Int64[]]$SeedValues
    [Object[]]$SeedToSoilMap #Type AlmanacRow
    [Object[]]$SoilToFertilizerMap
    [Object[]]$FertilizerToWaterMap
    [Object[]]$WaterToLightMap
    [Object[]]$LightToTemperatureMap
    [Object[]]$TemperatureToHumidityMap
    [Object[]]$HumidityToLocationMap

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

    [void] LowestLocationNumberForSeedInputs() {
        $this.SeedValues | ForEach-Object {
            $__ = $_
            $this.SeedToSoilMap.where({ $_.SrcStart -le $__ -and $_.SrcStart + $_.Range -gt $__ }) | ForEach-Object {
                $__ = $_
                $this.SoilToFertilizerMap.where({ $_.SrcStart -le $__ -and $_.SrcStart + $_.Range -gt $__ }) | ForEach-Object {
                    $__ = $_
                    $this.FertilizerToWaterMap.where({ $_.SrcStart -le $__ -and $_.SrcStart + $_.Range -gt $__ }) | ForEach-Object {
                        $__ = $_
                        $this.WaterToLightMap.where({ $_.SrcStart -le $__ -and $_.SrcStart + $_.Range -gt $__ }) | ForEach-Object {
                            $__ = $_
                            $this.LightToTemperatureMap.where({ $_.SrcStart -le $__ -and $_.SrcStart + $_.Range -gt $__ }) | ForEach-Object {
                                $__ = $_
                                $this.TemperatureToHumidityMap.where({ $_.SrcStart -le $__ -and $_.SrcStart + $_.Range -gt $__ }) | ForEach-Object {
                                    $__ = $_
                                    $this.HumidityToLocationMap.where({ $_.SrcStart -le $__ -and $_.SrcStart + $_.Range -gt $__ }) | ForEach-Object {
                                        
                                        Write-Host $_.DestStart
                                    }
                                }
                            }
                        }
                    }  
                }
            }
        }
        # return $null #comment this out later
    }
}


$SrcFilePath = "$PSScriptRoot\source_data.txt"
$Almanac = [Almanac]::new($SrcFilePath)



# $TableMatches = [regex]::Matches($SourceData, '([\w+\-+]+ map):\r\n([\d \r\n]+)\r\n')

# $TableMatches[0].Groups[2].Value.trim() -split [System.Environment]::NewLine | ForEach-Object {[AlmanacRow]::new($_)} -OutVariable testttt