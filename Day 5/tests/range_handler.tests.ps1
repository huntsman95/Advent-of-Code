BeforeAll {
    . $PSScriptRoot\..\range_handler.ps1
}
Describe 'Overlapping ranges detected' {
    It 'Returns True in the Overlaps Property' {
        [RangeOverlapCalculator]::new(([PSRange]::new(1, 4)), ([PSRange]::new(2, 5))).Overlaps | Should -Be $true
    }
    It 'Returns False in the Overlaps Property' {
        [RangeOverlapCalculator]::new(([PSRange]::new(1, 4)), ([PSRange]::new(6, 9))).Overlaps | Should -Be $false
    }
    It 'Detects a LEFT overlap' {
        $a = [PSRange]::new(10, 25)
        $b = [PSRange]::new(5, 20)
        $ot = [RangeOverlapCalculator]::new($a, $b)
        $ot.Overlaps | Should -Be $true
        $ot.OverlapType | Should -Be 'LEFT'
        $ot.NonOverlappingRanges.Start | Should -Contain 21
        $ot.NonOverlappingRanges.End | Should -Contain 25
        $ot.OverlappingRanges.Start | Should -Contain 10
        $ot.OverlappingRanges.End | Should -Contain 20
    }
    It 'Detects a RIGHT overlap' {
        $a = [PSRange]::new(5, 20)
        $b = [PSRange]::new(10, 25)
        $ot = [RangeOverlapCalculator]::new($a, $b)
        $ot.Overlaps | Should -Be $true
        $ot.OverlapType | Should -Be 'RIGHT'
        $ot.NonOverlappingRanges.Start | Should -Contain 5
        $ot.NonOverlappingRanges.End | Should -Contain 9
        $ot.OverlappingRanges.Start | Should -Contain 10
        $ot.OverlappingRanges.End | Should -Contain 20
    }
    It 'Detects a CENTER overlap' {
        $a = [PSRange]::new(5, 20)
        $b = [PSRange]::new(1, 25)
        $ot = [RangeOverlapCalculator]::new($a, $b)
        $ot.Overlaps | Should -Be $true
        $ot.OverlapType | Should -Be 'CENTER'
        $ot.NonOverlappingRanges | Should -BeNullOrEmpty
        $ot.OverlappingRanges.Start | Should -Contain 5
        $ot.OverlappingRanges.End | Should -Contain 20
    }
    It 'Detects an INVERSE overlap' {
        $a = [PSRange]::new(1, 25)
        $b = [PSRange]::new(5, 20)
        $ot = [RangeOverlapCalculator]::new($a, $b)
        $ot.Overlaps | Should -Be $true
        $ot.OverlapType | Should -Be 'INVERSE'
        $ot.NonOverlappingRanges.Start | Should -Contain 1
        $ot.NonOverlappingRanges.Start | Should -Contain 21
        $ot.NonOverlappingRanges.End | Should -Contain 4
        $ot.NonOverlappingRanges.End | Should -Contain 25
        $ot.OverlappingRanges.Start | Should -Contain 5
        $ot.OverlappingRanges.End | Should -Contain 20
    }
}

