function Update-Ticket(){
    param(
        $ticket_id,
        $board,
        $header
    )
        $header.Add("Content-Type", "application/json")
        $body = "[
        `n  {
        `n    `"op`": `"replace`",
        `n    `"path`": `"board`",
        `n    `"value`": {`"id`": $board}
        `n  }
        `n]"
        $response = Invoke-RestMethod "https://api-eu.myconnectwise.net/v4_6_release/apis/3.0/service/tickets/$ticket_id" -Method 'PATCH' -Headers $headers -Body $body
        $response | ConvertTo-Json
}
function Get-Alltickets(){
    param(
        $cwm_tickets,$enteredby,$header
    )
    $new_cwm_tickets = CWMtickets -enteredby $enteredby -Status 'New' -header $header
    $pgr_cwm_tickets = CWMtickets -enteredby $enteredby -Status 'In Progress' -header $header
    $hld_cwm_tickets = CWMtickets -enteredby $enteredby -Status 'On Hold' -header $header
    $wcr_cwm_tickets = CWMtickets -enteredby $enteredby -Status 'Waiting Client Response' -header $header
    $SCHTickets = CWMtickets -enteredby $enteredby -Status 'Scheduled' -header $header
    $REOTickets = CWMtickets -enteredby $enteredby -Status 'Re-Opened' -header $header
    $ASSTickets = CWMtickets -enteredby $enteredby -Status 'Assigned' -header $header
    $WAVTickets = CWMtickets -enteredby $enteredby -Status 'Waiting on Vendor' -header $header
    $ESCTickets = CWMtickets -enteredby $enteredby -Status 'Escalate' -header $header
    if($new_cwm_tickets){$cwm_tickets += $new_cwm_tickets}
    if($pgr_cwm_tickets){$cwm_tickets += $pgr_cwm_tickets}
    if($hld_cwm_tickets){$cwm_tickets += $hld_cwm_tickets}
    if($wcr_cwm_tickets){$cwm_tickets += $wcr_cwm_tickets}
    if($SCHTickets){$cwm_tickets += $SCHTickets}
    if($ASSTickets){$cwm_tickets += $ASSTickets}
    if($WAVTickets){$cwm_tickets += $WAVTickets}
    if($REOTickets){$cwm_tickets += $REOTickets}
    if($ESCTickets){$cwm_tickets += $ESCTickets}
    return $cwm_tickets
}
function Get-Board(){
   param(
    $api_call,$header
   )
    $response = Invoke-RestMethod $api_call -Method 'GET' -Headers $header
    $response | ConvertTo-Json
    return $response
}

function CWMconnect() {
    param(
        $board_pattern, $ticket_subject, $ticket_body
    )
    $CWMConnectionInfo = @{
        Server     = 'api-eu.myconnectwise.net'
        Company    = 'turrito'
        pubkey     = 'pFCHgD73GVYMRrBd'
        privatekey = 'X3dAuAZKL009fnmX'
        clientid   = '7682c495-9be9-4f25-a4a2-91f0a65184ba'
    }
    Connect-CWM @CWMConnectionInfo -Force    
}
function CWMtickets() {
    param (
        $status, $enterdby,$header
    )
    
    $page_size = 1000
    $page = 1
    $tickets = $true   
    while ($tickets) {
        $tickets = Invoke-RestMethod "https://api-eu.myconnectwise.net/v4_6_release/apis/3.0/service/tickets/?conditions=status/name='$status'%20and%20$enteredby&pagesize=$page_size&page=$page" -Method 'GET' -Headers $header
        if ($tickets) {
            $response += $tickets
            $page++
        }
    }
    return $response | ConvertTo-Json -Depth 10 | ConvertFrom-Json 
}

#hashkey{client_id,board_id}.
$dsd_hash=@{20382=48;19348=41;20840=49;20667=42;20051=45;20539=46}
CWMconnect
$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.Add("clientid", "7682c495-9be9-4f25-a4a2-91f0a65184ba")
$headers.Add("Authorization", "Basic dHVycml0bytwRkNIZ0Q3M0dWWU1SckJkOlgzZEF1QVpLTDAwOWZubVg=")
#Had to call this function twice because I couldnt make -or condition to work
$all_tickets = Get-Alltickets -cwm_tickets ($all_tickets=@()) -enteredby "_info/enteredby='Automate'" -header $headers
$all_tickets = Get-Alltickets -cwm_tickets $all_tickets -enteredby "_info/enteredby='nocAPI'" -header $headers

foreach($ticket in $all_tickets){
    if($dsd_hash.ContainsKey($ticket.company.id) -and $dsd_hash[$ticket.company.id] -ne $ticket.board.id){
        $dsd_board=Get-Board -api_call "https://api-eu.myconnectwise.net/v4_6_release/apis/3.0/service/boards/$($dsd_hash[$ticket.company.id])" -header $headers
        Update-Ticket -ticket_id $ticket.id -board $dsd_board.id -header $headers
    }
}


