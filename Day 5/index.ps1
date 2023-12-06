class MappingTable {
    [System.Collections.Generic.List[AlmanacRow[]]] $Rows
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
    [int]$DestStart
    [int]$SrcStart
    [int]$Range
    AlmanacRow([int]$DestStart,[int]$SrcStart,[int]$Range){
        $this.DestStart = $DestStart
        $this.SrcStart = $SrcStart
    }
}