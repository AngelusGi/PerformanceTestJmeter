function Get-CurrentDate {
    param (
        [Parameter(Mandatory = $false)]
        [CultureInfo]
        $Culture = 'it-IT'
    )

    return Get-Date -Format $Culture.DateTimeFormat.FullDateTimePattern -AsUTC
}

function Get-StartAndEndDate {
    param (
        [Parameter(Mandatory = $true)]
        [int]
        $TimeSpanInMinutes,
        [Parameter(Mandatory = $true)]
        [int]
        $GracePeriodInMinutes,
        [Parameter(Mandatory = $false)]
        [CultureInfo]
        $Culture = 'it-IT'
    )
    
    $currentDate = Get-CurrentDate
    $dates = Get-StartDateTime -FormatCulture $Culture -CurrentDate $currentDate
    $dates.Add("endDate", (Get-EndDateTime -TimeSpanInMinutes $TimeSpanInMinutes -GracePeriodInMinutes $GracePeriodInMinutes -CurrentDate $currentDate -FormatCulture $Culture))

    return $dates
}

function Get-StartDateTime {
    param (
        [Parameter(Mandatory = $true)]
        $FormatCulture,
        [Parameter(Mandatory = $true)]
        [DateTime]
        $CurrentDate
    )

    process {
        $startDate = Get-Date $CurrentDate -Format $FormatCulture.DateTimeFormat.FullDateTimePattern
        $partitionPrimaryKey = Get-Date $CurrentDate -Format $FormatCulture.DateTimeFormat.SortableDateTimePattern
        return @{"startDate" = $startDate; "partitionPrimaryKey" = $partitionPrimaryKey; }
    }
    
}

function Get-EndDateTime {
    param (
        [Parameter(Mandatory = $true)]
        [int]
        $TimeSpanInMinutes,
        [Parameter(Mandatory = $true)]
        [int]
        $GracePeriodInMinutes,
        [Parameter(Mandatory = $true)]
        $FormatCulture,
        [Parameter(Mandatory = $true)]
        [DateTime]
        $CurrentDate
    )

    $endDate = (Get-Date $CurrentDate).AddMinutes($TimeSpanInMinutes + $GracePeriodInMinutes)
    return (Get-Date $endDate -Format $FormatCulture.DateTimeFormat.FullDateTimePattern)
}

function Convert-DatesFromTable {
    param (
        [Parameter(Mandatory = $true)]
        [string]
        $DateToConvert,
        [Parameter(Mandatory = $false)]
        [CultureInfo]
        $Culture = 'it-IT'
    )
    
    process {
        return (Get-Date $DateToConvert -Format $Culture.DateTimeFormat.FullDateTimePattern)
    }
}

function Convert-DatesToItalianTime {
    param (
        [Parameter(Mandatory = $true)]
        [string]
        $DateToConvert,
        [Parameter(Mandatory = $false)]
        [CultureInfo]
        $Culture = 'it-IT'
    )
    
    process {
        return (Get-Date (Get-Date $DateToConvert -Format (Get-Culture $Culture).DateTimeFormat.FullDateTimePattern))
    }
}
