# Ensure you have the Microsoft.Graph module installed
# Install-Module -Name Microsoft.Graph -Scope CurrentUser

# Import the Microsoft.Graph module
# Import-Module Microsoft.Graph

# Connect to Microsoft Graph
Connect-MgGraph -device -Scopes "Group.Read.All", "User.Read.All"

# Get all groups
Write-Host "Getting all groups..."
$groups = Get-MgGroup -All
Write-Host "Found $($groups.Count) groups"

# Initialize an array to hold the results
$results = @()

# Loop through each group
foreach ($group in $groups) {
  Write-Host "Processing group: $($group.DisplayName)"

  # Get the group members
  $members = Get-MgGroupMember -GroupId $group.Id -All

  # Loop through each member and add to results
  foreach ($member in $members) {
    # Get full metadata for the member
    try {
      $memberDetails = Get-MgUser -UserId $member.Id -ErrorAction Stop
      $type = "User"
    }
    catch {
      Write-Host "Member is not a user, trying to get contact details..."
      try {
        $memberDetails = Get-MgContact -OrgContactId $member.Id -ErrorAction Stop
        $type = "Contact"
      }
      catch {
        Write-Host "Member is not a contact, trying to get distribution list details..."
        try {
          $memberDetails = Get-MgGroup -GroupId $member.Id -ErrorAction Stop
          $type = "Distribution List"
        }
        catch {
          Write-Host "Member is not a distribution list, using default values..."
          $memberDetails = [PSCustomObject]@{
            Id                = $member.Id
            DisplayName       = "Unknown"
            UserPrincipalName = "Unknown"
          }
          $type = "Unknown"
        }
      }
    }

    Write-Host "Processing member: $($memberDetails.DisplayName)"

    $results += [PSCustomObject]@{
      GroupId     = $group.Id
      GroupName   = $group.DisplayName
      MemberId    = $memberDetails.Id
      MemberName  = $memberDetails.DisplayName
      MemberEmail = $memberDetails.UserPrincipalName
      MemberType  = $type
      Owner       = $false
    }
  }

  Write-Host "Processed $($members.Count) members"

  # Get the group owners
  $owners = Get-MgGroupOwner -GroupId $group.Id -All

  # Loop through each owner and add to results
  foreach ($owner in $owners) {
    # Get full metadata for the owner
    try {
      $ownerDetails = Get-MgUser -UserId $owner.Id -ErrorAction Stop
      $type = "User"
    }
    catch {
      Write-Host "Owner is not a user, trying to get contact details..."
      try {
        $ownerDetails = Get-MgContact -OrgContactId $owner.Id -ErrorAction Stop
        $type = "Contact"
      }
      catch {
        Write-Host "Owner is not a contact, trying to get distribution list details..."
        try {
          $ownerDetails = Get-MgGroup -GroupId $owner.Id -ErrorAction Stop
          $type = "Distribution List"
        }
        catch {
          Write-Host "Owner is not a distribution list, using default values..."
          $ownerDetails = [PSCustomObject]@{
            Id                = $owner.Id
            DisplayName       = "Unknown"
            UserPrincipalName = "Unknown"
          }
          $type = "Unknown"
        }
      }
    }

    Write-Host "Processing owner: $($ownerDetails.DisplayName)"

    $results += [PSCustomObject]@{
      GroupId     = $group.Id
      GroupName   = $group.DisplayName
      MemberId    = $ownerDetails.Id
      MemberName  = $ownerDetails.DisplayName
      MemberEmail = $ownerDetails.UserPrincipalName
      MemberType  = $type
      Owner       = $true
    }
  }

  Write-Host "Processed $($owners.Count) owners"
}

# Export the results to a CSV file
$results | Export-Csv -Path "./allgroupmembers.csv" -NoTypeInformation

# Disconnect from Microsoft Graph
Disconnect-MgGraph
