function Set-ProjectAuthentication {
    param(
        [string]
        $ProjectNameToEncrypt,
        [string]
        $EncryptionKey
    )

    process {
        $UnencryptedFile = New-TemporaryFile
        $EncryptedFile = New-TemporaryFile
        $ProjectNameToEncrypt > $UnencryptedFile.FullName
        openssl enc -k "$EncryptionKey" -aes256 -base64 -e -in $UnencryptedFile.FullName -out $EncryptedFile.FullName
        $EncryptedText = $(Get-Content $EncryptedFile.FullName)
        Remove-Item $UnencryptedFile.FullName -Force
        Remove-Item $EncryptedFile.FullName -Force
        return $EncryptedText
    }
    # $TextCrypted = Set-ProjectAuthentication -CleanText "${{ parameters.Project_Name }}" -EncryptionKey "$(ServiceAMQ_DecriptKey)"
    # Write-host "Project-Crypted: $TextCrypted"
    # Write-Host "##vso[task.setvariable variable=TextCrypted]$TextCrypted"
}

function Test-ProjectAuthentication {
    param(
        [string]
        $EncryptedText,
        [string]
        $EncryptionKey,
        [string]
        $ProjectName
    )

    process {
        $EncryptedFile = New-TemporaryFile
        $UnencryptedFile = New-TemporaryFile
        $EncryptedText > $EncryptedFile.FullName
        openssl enc -k "$EncryptionKey" -aes256 -base64 -d -in $EncryptedFile.FullName -out $UnencryptedFile.FullName
        $UnencryptedText = $(Get-Content $UnencryptedFile.FullName)
        Remove-Item $EncryptedFile.FullName -Force
        Remove-Item $UnencryptedFile.FullName -Force

        if ( $UnencryptedText -ne $ProjectName ) {
            Write-Host "Project '$ProjectName' is not authorized with passed 'tokenAuth'" -ForegroundColor Red
            exit 1
        }
        else {
            Write-Host "Project '$ProjectName' is authorized" -ForegroundColor Blue
        }

        # return $UnencryptedText
    }
}
