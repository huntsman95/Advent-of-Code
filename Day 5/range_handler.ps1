# $LeftOverlapWithRightNoOverlap

class PSRange {
    $Start
    $End
    $Range
    PSRange ([Int64]$Start, [Int64]$End) {
        $this.Start = $Start
        $this.End = $End
        $this.Range = $End - $Start + 1
    }
    [string] ToString() {
        return '{0}-{1}' -f $this.Start, $this.End
    }
}

class RangeOverlapCalculator {
    [bool]$Overlaps
    [string]$OverlapType
    [System.Collections.Generic.List[PSRange]]$NonOverlappingRanges = [System.Collections.Generic.List[PSRange]]::new()
    [System.Collections.Generic.List[PSRange]]$OverlappingRanges = [System.Collections.Generic.List[PSRange]]::new()
    RangeOverlapCalculator([PSRange]$RangeA, [PSRange]$RangeB) {
        if (-not($RangeA.Start -le $RangeB.End -and $RangeB.Start -le $RangeA.End)) {
            $this.Overlaps = $false
            return #Dont bother processing if there is no intersect
        }
        else {
            $this.Overlaps = $true
        }
        if ($RangeA.Start -lt $RangeB.Start -and $RangeA.End -le $RangeB.End) {
            # A is skewed left of B, causing the RIGHT of A to overlap with the left of B
            $this.OverlapType = 'RIGHT'
            $this.OverlappingRanges.Add([PSRange]::new($RangeB.Start, $RangeA.End))
            $this.NonOverlappingRanges.Add([PSRange]::new($RangeA.Start, $RangeB.Start - 1))
        }
        elseif ($RangeA.Start -ge $RangeB.Start -and $RangeA.End -gt $RangeB.End) {
            # A is skewed right of B, causing the LEFT of A to overlap the right of B
            $this.OverlapType = 'LEFT'
            $this.OverlappingRanges.Add([PSRange]::new($RangeA.Start, $RangeB.End))
            $this.NonOverlappingRanges.Add([PSRange]::new($RangeB.End + 1, $RangeA.End))
        }
        elseif ($RangeA.Start -ge $RangeB.Start -and $RangeA.End -le $RangeB.End) {
            # A falls entirely in the CENTER of B
            $this.OverlapType = 'CENTER'
            $this.OverlappingRanges.Add([PSRange]::new($RangeA.Start, $RangeA.End))
        }
        elseif ($RangeA.Start -lt $RangeB.Start -and $RangeA.End -gt $RangeB.End) {
            # A is larger than B and has non-overlapping ranges on both sides
            $this.OverlapType = 'INVERSE'
            $this.OverlappingRanges.Add([PSRange]::new($RangeB.Start, $RangeB.End))
            $this.NonOverlappingRanges.Add([PSRange]::new($RangeA.Start, $RangeB.Start - 1))
            $this.NonOverlappingRanges.Add([PSRange]::new($RangeB.End + 1, $RangeA.End))
        }
    }

}

function Get-OverlappingRanges {
    [CmdletBinding()]
    param (
        [Parameter()]
        [Int64]
        $RangeAStart
        ,
        [Parameter()]
        [Int64]
        $RangeAEnd
        ,
        [Parameter()]
        [Int64]
        $RangeBStart
        ,
        [Parameter()]
        [Int64]
        $RangeBEnd
    )
    $_a = New-Object PSRange $RangeAStart, $RangeAEnd
    $_b = New-Object PSRange $RangeBStart, $RangeBEnd
    return New-Object RangeOverlapCalculator $_a, $_b
}