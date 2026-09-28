function Test-InstalledPrograms6 {

    $RegistryPath = 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall'

    $Errors = @()

    $RegistryKeys = Get-ChildItem -LiteralPath $RegistryPath -ErrorAction Stop |
        Where-Object {

            $RegistryEntry = Get-ItemProperty `
                -LiteralPath $_.PSPath `
                -ErrorAction SilentlyContinue

            $RegistryEntry.DisplayName -notlike "*Microsoft*"
        }

# ---->
#      |
#      |
#      \/
    $asd = Get-ItemProperty "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*" | Select-Object DisplayName , PSChildName, InstallSource, PSPath
    foreach ($dsa in $asd){
        if ($dsa.InstallSource -eq '' -or $dsa.InstallSource -eq "*" -or $dsa.InstallSource -eq "*:" -or $dsa.InstallSource -eq "*:\"){
            Write-Host "================ PUSTY INSTALL SOURCE WOGOLE BEZ SCIERZKI ================" -ForegroundColor Yellow
            Write-Host "nie wykryto scierzki w InstallSource w kluczu o nazwie: $($dsa.PSChildName)" -ForegroundColor Red
            Write-Host "==========================================================================" -ForegroundColor Yellow

            $AnswerBefore = Read-Host "usunac wpis? (Y/Yes, N/No)"
            if ($AnswerBefore -match '^(Y|Yes)$'){
                Remove-Item -Path $dsa.PSpath
                Write-Host "usunieto wpis: $($dsa.PSChildName)" -ForegroundColor Green
            }
            elseif ($Answer -match '^(N|No)') {
                break
            }
        } 
    }
    Write-Host ''
    Write-Host ''



    foreach ($RegistryKey in $RegistryKeys) {
        try {
            $App = Get-ItemProperty -LiteralPath $RegistryKey.PSPath -ErrorAction Stop
        }
        catch {
            Write-Host "[BLAD REJESTRU] $($RegistryKey.Name)" -ForegroundColor Red
            continue
        }
        if ([string]::IsNullOrWhiteSpace([string]$App.InstallSource)) {
            continue
        }
        $InstallSource = ([string]$App.InstallSource).Trim().Trim('"')
        if ([string]::IsNullOrWhiteSpace([string]$App.DisplayName)) {
            $ProgramName = $RegistryKey.PSChildName
        }
        else {
            $ProgramName = [string]$App.DisplayName
        }
        if ([string]::IsNullOrWhiteSpace([string]$App.Publisher)) {
            $Publisher = 'Brak informacji'
        }
        else {
            $Publisher = [string]$App.Publisher
        }

        if (-not (Test-Path -LiteralPath $InstallSource)) {

            $Errors += [PSCustomObject]@{
                Program          = $ProgramName
                Publisher        = $Publisher
                InstallSource    = $InstallSource
                RegistryKey      = $RegistryKey.PSChildName
                RegistryPath     = $RegistryKey.PSPath
                RegistryFullName = $RegistryKey.Name
            }
            Write-Host `
                "[BLEDNA SCIEZKA] $ProgramName -> $InstallSource" `
                -ForegroundColor Red
        }
    }

    Write-Host ''
    Write-Host `
        '================== NIEWLASCIWY INSTALL SOURCE Z BLEDNA  ==================' `
        -ForegroundColor Yellow

    if ($Errors.Count -eq 0) {

        Write-Host `
            'Nie znaleziono BLEDNYCH SCIEZEK InstallSource.' `
            -ForegroundColor Green

        return
    }

    $Errors = @(
        $Errors |
            Sort-Object Program, InstallSource -Unique
    )

    $Errors |
        Format-Table Program, Publisher, InstallSource, RegistryKey -AutoSize

    Write-Host ''
    Write-Host `
        '================ USUWANIE WPISOW ================' `
        -ForegroundColor Yellow

    $YesAll = $false

    $DoNotRemove = @()

    foreach ($ErrorEntry in $Errors) {

        Write-Host ''
        Write-Host "Program:       $($ErrorEntry.Program)" -ForegroundColor Cyan
        Write-Host "Publisher:     $($ErrorEntry.Publisher)"
        Write-Host "InstallSource: $($ErrorEntry.InstallSource)"
        Write-Host "RegistryKey:   $($ErrorEntry.RegistryKey)"


        if ($YesAll) {

            Write-Host `
                "Usuwam wpis: $($ErrorEntry.Program)" `
                -ForegroundColor Yellow

            Remove-Item `
                -LiteralPath $ErrorEntry.RegistryPath `
                -Recurse `
                -Force `
                -ErrorAction Continue

            continue
        }

        $Answer = Read-Host "usunac wpis? (Y/Yes, N/No, YesAll, NoAll, Exit)"
        
        if ($Answer -match '^(Y|Yes)$') {

            Write-Host `
                "Usuwam wpis: $($ErrorEntry.Program)" `
                -ForegroundColor Yellow

            Remove-Item `
                -LiteralPath $ErrorEntry.RegistryPath `
                -Recurse `
                -Force `
                -ErrorAction Continue

            continue
        }

        elseif ($Answer -match '^(N|No)$') {

            Write-Host `
                "Zostawiam wpis: $($ErrorEntry.Program)" `
                -ForegroundColor Green

            $DoNotRemove += $ErrorEntry

            continue
        }

        elseif ($Answer -match '^YesAll$') {

            $YesAll = $true

            Write-Host `
                'Wybrano YesAll. Usuwam aktualny i wszystkie kolejne wpisy.' `
                -ForegroundColor Yellow

            Remove-Item `
                -LiteralPath $ErrorEntry.RegistryPath `
                -Recurse `
                -Force `
                -ErrorAction Continue

            continue
        }

        elseif ($Answer -match '^NoAll$') {

            Write-Host `
                'Wybrano NoAll. Pozostale wpisy nie zostana usuniete.' `
                -ForegroundColor Green

            break
        }

        else {

            Write-Host `
                'Niepoprawna odpowiedz. Wpis zostaly pominiety.' `
                -ForegroundColor Red

            $DoNotRemove += $ErrorEntry

            continue
        }
    }

    Write-Host ''
    Write-Host `
        '================ POMINIETE WPISY ================' `
        -ForegroundColor Yellow

    if ($DoNotRemove.Count -eq 0) {

        Write-Host `
            'Nie zapisano zadnych pojedynczo pominietych wpisow.' `
            -ForegroundColor Green
    }
    else {

        $DoNotRemove |
            Format-Table Program, Publisher, InstallSource, RegistryKey -AutoSize
    }

    Write-Host ''
    Write-Host 'Skrypt zakonczyl dzialanie.' -ForegroundColor Cyan
}
Test-InstalledPrograms6
Pause

# made by Api._.23© 