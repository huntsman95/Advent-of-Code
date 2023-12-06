. $PSScriptRoot\..\index.ps1

It "Should be able to create a new AlmanacRow object from a string" {
    $AlmanacRow = [AlmanacRow]::new("1 2 3")
    $AlmanacRow.ToString() | Should -Be "SrcStart: 2, DestStart: 1, Range: 3"
    $AlmanacRow.DestEnd | Should -Be 3
    $AlmanacRow.SrcEnd | Should -Be 4
}

It "Should be able to create a valid SeedRange from input" {
    $SeedRange = [SeedRange]::new(1, 3)
    $SeedRange.SeedStart | Should -Be 1
    $SeedRange.SeedEnd | Should -Be 3
}

It "Should be able to create valid SeedRanges from input" {
    $SeedValues = @(1,2,3,4)
    $SeedRangeParser = [SeedRangeParser]::new($SeedValues)
    $SeedRangeParser.SeedRanges[0].SeedStart | Should -Be 1
    $SeedRangeParser.SeedRanges[0].SeedEnd | Should -Be 2
    $SeedRangeParser.SeedRanges[1].SeedStart | Should -Be 3
    $SeedRangeParser.SeedRanges[1].SeedEnd | Should -Be 6
}