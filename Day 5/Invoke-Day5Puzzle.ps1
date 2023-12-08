
param (
    [string]$FilePath = "$PSScriptRoot\source_data.txt"
)
. $PSScriptRoot\solver.ps1 -FilePath $FilePath

[PSCustomObject]@{
    Part1_Answer = $Almanac.GetPuzzleAnswerPart1().Answer
    Part2_Answer = $Almanac.GetPuzzleAnswerPart2().Answer
}
