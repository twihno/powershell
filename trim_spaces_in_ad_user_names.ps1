$searchbase = "<SEARCHBASE>"

foreach ($user in (Get-ADUser -Filter * -SearchBase $searchbase -Properties *))
{
    $flag = $false
    $givenName = $user.GivenName
    $surname = $user.Surname

    if($givenName -ne $givenName.Trim()){
        Write-Host "Changed GivenName" $user
        $givenName = $givenName.Trim()
        Set-ADUser $user -GivenName $givenName
        
        flag = $true
    }

    if($surname -ne $surname.Trim()){
        Write-Host "Changed Surname" $user
        $surname = $surname.Trim()
        Set-ADUser $user -Surname $surname
        
        $flag = $true
    }


    if($flag -or ($user.DisplayName -ne "$givenName $surname")){
        Write-Host "Changed DisplayName" $user
        Set-ADUser -Identity $user -DisplayName "$givenName $surname"
        $flag = $true
    }

    if($flag){
        Write-Host "Renamed" $user
        Set-ADUser -DisplayName "$givenName $surname"
        Rename-ADObject -Identity $user -NewName "$givenName $surname"
    }
}
