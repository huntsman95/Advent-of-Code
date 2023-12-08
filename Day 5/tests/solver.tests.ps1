BeforeAll {
    . $PSScriptRoot\..\solver.ps1 -FilePath "$PSScriptRoot\..\source_data.test.txt"
}

Describe 'AlmanacRow Class' {
    It 'Should be able to create a new AlmanacRow object from a string' {
        $AlmanacRow = [AlmanacRow]::new('1 2 3')
        $AlmanacRow.ToString() | Should -Be 'SrcStart: 2, DestStart: 1, Range: 3'
        $AlmanacRow.DestEnd | Should -Be 3
        $AlmanacRow.SrcEnd | Should -Be 4
    }
}

Describe 'SeedRange Class' {
    It 'Should be able to create a valid SeedRange from input' {
        $SeedRange = [SeedRange]::new(1, 3)
        $SeedRange.SeedStart | Should -Be 1
        $SeedRange.SeedEnd | Should -Be 3
    }
}

Describe 'SeedRangeParser Class' {
    It 'Should be able to create valid SeedRanges from input' {
        $SeedValues = @(1, 2, 3, 4)
        $SeedRangeParser = [SeedRangeParser]::new($SeedValues)
        $SeedRangeParser.SeedRanges[0].SeedStart | Should -Be 1
        $SeedRangeParser.SeedRanges[0].SeedEnd | Should -Be 2
        $SeedRangeParser.SeedRanges[1].SeedStart | Should -Be 3
        $SeedRangeParser.SeedRanges[1].SeedEnd | Should -Be 6
    }
}

Describe 'Puzzle 1 Solver' {
    It 'Should be able to solve puzzle 1 sample data' {
        $Almanac = [Almanac]::new($FilePath)
        $Almanac.GetPuzzleAnswerPart1() `
        | Select-Object -ExpandProperty Answer `
        | Should -Be 35
    }
}

Describe 'Puzzle 2 Solver' {
    It 'Should be able to solve puzzle 2 sample data' {
        $Almanac = [Almanac]::new($FilePath)
        $Almanac.GetPuzzleAnswerPart2() `
        | Select-Object -ExpandProperty Answer `
        | Should -Be 46
    }
}